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
    case verification
    case recognition
    case notification
    case finish
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
            self.messageHandler?(.open, nil)
        } _onClosed: {
            self.messageHandler?(.close, nil)
        } _onMessage: { eventType, messageEvent in
            self.onMessageHandler(type: eventType, event: messageEvent)
        } _onComment: { comment in
            
        } _onError: { error in
            self.messageHandler?(.error, nil)
        }

        return handler
    }()
    
    var messageHandler: ((NYSSEMessageHandleType, [String: Any]?) -> Void)?
    
    func onMessageHandler(type: String, event: MessageEvent)  {
        debugPrint("Message Type: \(type) Event: \(event)")
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
