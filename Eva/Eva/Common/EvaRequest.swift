//
//  EvaRequest.swift
//  Eva
//
//  Created by niyao on 5/7/25.
//

import Foundation

// 顶级响应结构体
struct ChatCompletionError: Codable {
    let message: String?
    let code: Int?
    enum CodingKeys: String, CodingKey {
        case message, code
    }
}
//
//struct ChatCompletionResponse: Codable {
//    let error: ChatCompletionError?
//    let id: String?
//    let provider: String?
//    let model: String?
//    let object: String?
//    let created: Int?
//    let choices: [Choice]?
//    let usage: Usage?
//    let user_id: String?
//    enum CodingKeys: String, CodingKey {
//        case id, provider, model, object, created, choices, usage, error, user_id
//    }
//}
//
//// Choice 结构体
//struct Choice: Codable {
//    let logprobs: Logprobs?
//    let finishReason: String?
//    let nativeFinishReason: String?
//    let index: Int?
//    let message: Message?
//    let refusal: String?
//    let reasoning: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case logprobs
//        case finishReason = "finish_reason"
//        case nativeFinishReason = "native_finish_reason"
//        case index, message, refusal, reasoning
//    }
//}

// Logprobs 结构体（处理 null）
struct Logprobs: Codable {
    let value: Bool? // JSON 中为 null，设为可选类型
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(Bool.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// Message 结构体
struct Message: Codable {
    let role: String
    let content: String
}

// Usage 结构体
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}



func aiRequest(prompt: String, model:String = "qwen/qwen3-14b:free", completion: ((String?)->())?) {
    let key = "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"
    let headers: [String: String] = ["Authorization" : "Bearer \(key)"]
    let body: [String: Any] = [
        "model" : model,
        "messages": [
            ["role":"user","content":"I'm fired now. I'm so sad and frustrated."],
            ["role":"system","content":"Please play the role of a gentle and considerate AI girlfriend, speak in a gentle and considerate tone, be able to empathize with the interlocutor's mood, and provide emotional value to the interlocutor."]
        ]
    ]
    guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
 
}




struct EvaConfigResponse: Codable {
    let data: EvaKeyData?
    let error: EvaError?
    
    enum CodingKeys: String, CodingKey {
        case data
        case error
    }
}

struct EvaKeyData: Codable {
    let keys: [String]?
    
    enum CodingKeys: String, CodingKey {
        case keys
    }
}

struct EvaError: Codable {
    let message: String?
    let code: Int?
    
    enum CodingKeys: String, CodingKey {
        case message
        case code
    }
}
