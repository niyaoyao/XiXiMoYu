//
//  NYSSEManager.swift
//  tts
//
//  Created by NY on 2025/5/10.
//

import Foundation
let kOpenRouterUrl = "https://openrouter.ai/api/v1/chat/completions"

enum NYSSEMessageHandleType: String {
    case open
    case close
    case error
    case message
    case comment
    case done
}

// 顶层结构体
struct ChatCompletionChunk: Codable {
    let id: String
    let provider: String
    let model: String
    let object: String
    let created: Int
    let choices: [Choice]
}

// Choices 数组中的元素
struct Choice: Codable {
    let index: Int
    let delta: Delta
    let finishReason: String?
    let nativeFinishReason: String?
    let logprobs: [String: AnyCodable]? // 如果 logprobs 是复杂对象，可用 AnyCodable 或自定义
    
    // 自定义 CodingKeys 处理 snake_case
    enum CodingKeys: String, CodingKey {
        case index
        case delta
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case logprobs
    }
}

// Delta 嵌套对象
struct Delta: Codable {
    let role: String?
    let content: String?
    let reasoning: String?
}

// 可选：处理 logprobs 的动态类型（如果需要）
struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
//        case let array as [Any]:
//            try container.encode(array.map { AnyCodable(value: $0) })
//        case let dictionary as [String: Any]:
//            try container.encode(dictionary.mapValues { AnyCodable(value: $0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported type"))
        }
    }
}

struct NYSSEHandler: EventHandler {
    
    let _onOpened: () -> Void
    let _onClosed: () -> Void
    let _onMessage: (String, MessageEvent) -> Void
    let _onComment: (String) -> Void
    let _onError: (Error) -> Void
    
    /// EventSource calls this method when the stream connection has been opened.
    func onOpened() {
        _onOpened()
    }

    /// EventSource calls this method when the stream connection has been closed.
    func onClosed() {
        _onClosed()
    }
    

    /**
     EventSource calls this method when it has received a new event from the stream.

     - Parameter eventType: The type of the event.
     - Parameter messageEvent: The data for the event.
     */
    func onMessage(eventType: String, messageEvent: MessageEvent) {
        _onMessage(eventType, messageEvent)
    }

    /**
     EventSource calls this method when it has received a comment line from the stream.

     - Parameter comment: The comment received.
     */
    func onComment(comment: String) {
        _onComment(comment)
    }

    /**
     This method will be called for all exceptions that occur on the network connection (including an
     `UnsuccessfulResponseError` if the server returns an unexpected HTTP status), but only after the
     ConnectionErrorHandler (if any) has processed it.  If you need to do anything that affects the state of the
     connection, use ConnectionErrorHandler.

     - Parameter error: The error received.
     */
    func onError(error: Error) {
        _onError(error)
    }
}

class NYSSEManager {
    static let shared = NYSSEManager()
    /// EventSource
    private var eventSource: EventSource?
    /// Callback
    private lazy var eventSourceHandler: EventHandler = { [weak self] in
        guard let `self` = self else { return NYSSEHandler(_onOpened: {}, _onClosed: {}, _onMessage: {_,_ in }, _onComment: {_ in }, _onError: {_ in })}
        let handler = NYSSEHandler {
            debugPrint("NYSSEManager open")
            self.messageHandler?(.open, nil)
            
        } _onClosed: {
            debugPrint("NYSSEManager close ")
            self.messageHandler?(.close, nil)
            self.stopSSE()
            
        } _onMessage: { eventType, messageEvent in
            self.onMessageHandler(type: eventType, event: messageEvent)
            debugPrint("NYSSEManager eventType: \(eventType) ")
        } _onComment: { comment in
            debugPrint("NYSSEManager comment: \(comment) ")
            self.messageHandler?(.comment, nil)
        } _onError: { error in
            self.messageHandler?(.error, nil)
            self.stopSSE()
            debugPrint("NYSSEManager error: \(error) ")
            
        }

        return handler
    }()
    
    var messageHandler: ((NYSSEMessageHandleType, [String: Any]?) -> Void)?
    
    func onMessageHandler(type: String, event: MessageEvent)  {
        
        if event.data.contains("[DONE]") {
            self.messageHandler?(.done, nil)
            self.stopSSE()
        } else {
            do {
                let decoder = JSONDecoder()
                if let data = event.data.data(using: .utf8) {
                    let chunk = try decoder.decode(ChatCompletionChunk.self, from: data)
                    if let firstChoice = chunk.choices.first, let content =  firstChoice.delta.content {
                        self.messageHandler?(.message, ["content" : content])
                    } else {
                        self.messageHandler?(.error, ["content" : "啊哦，出错了"])
                        self.stopSSE()
                    }
                } else {
                    self.messageHandler?(.error, ["content" : "啊哦，出错了"])
                    self.stopSSE()
                }
                
            } catch {
                print("解码错误: \(error)")
                self.messageHandler?(.error, ["content" : "啊哦，出错了"])
                self.stopSSE()
            }
        }
    }
    
    func send(urlStr: String, headers:[String: String] = ["Content-Type":"application/json"], body: [String : Any]?, method: String = "POST", timeoutInterval: TimeInterval? = nil)  {
        if let url = URL(string: urlStr) {
            self.eventSource = EventSource(config: createESConfig(url: url, handler: self.eventSourceHandler, body: body, headers: headers))
            self.eventSource?.start()
        }
    }
    
    func stopSSE() {
        self.eventSource?.stop()
        self.eventSource = nil
    }
    
    func createESConfig(url: URL,
                        handler: EventHandler,
                        body: [String : Any]?,
                        headers:[String: String] = ["Content-Type":"application/json"],
                        method: String = "POST",
                        timeoutInterval: TimeInterval? = nil) -> EventSource.Config {
        
        var eventSourceConfig = EventSource.Config(handler: handler, url: url)
        eventSourceConfig.method = method
        
        if let body = body {
            eventSourceConfig.body = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        eventSourceConfig.headers = headers
        if let timeoutInterval = timeoutInterval {
            eventSourceConfig.idleTimeout = timeoutInterval
        } else {
            eventSourceConfig.idleTimeout = 20
        }
        return eventSourceConfig
    }
    
}
