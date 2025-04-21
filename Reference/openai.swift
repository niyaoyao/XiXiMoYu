import Foundation
import Foundation

// 顶级响应结构体
struct ChatCompletionResponse: Codable {
    let id: String
    let provider: String
    let model: String
    let object: String
    let created: Int
    let choices: [Choice]
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, provider, model, object, created, choices, usage
    }
}

// Choice 结构体
struct Choice: Codable {
    let logprobs: Logprobs?
    let finishReason: String
    let nativeFinishReason: String
    let index: Int
    let message: Message
    let refusal: String?
    let reasoning: String
    
    enum CodingKeys: String, CodingKey {
        case logprobs
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case index, message, refusal, reasoning
    }
}

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

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(Int)
    case parsingFailed(Error)
}
class NetworkService {
    
    func makeChatCompletionRequest() async throws -> ChatCompletionResponse {
        let key = "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"
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("cyberpi.tech", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Eva", forHTTPHeaderField: "X-Title")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "deepseek/deepseek-r1-zero:free",
            "messages": [
                [
                    "role": "user",
                    "content": "How to prove 1+1=2?"
                ]
            ]
        ]
        print("????????")
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        print("request: \(request)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("!!!!!!!!!!")
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("badServerResponse")

            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        print("decoder: \(decoder)")

        return try decoder.decode(ChatCompletionResponse.self, from: data)
    }
}

// 调用示例
Task {
    do {
        print("NetworkService")
        let service = NetworkService()
        let response = try await service.makeChatCompletionRequest()
        print("ID: \(response.id)")
        print("Provider: \(response.provider)")
        if let firstChoice = response.choices.first {
            print("Assistant response: \(firstChoice.message.content)")
        }
    } catch {
        print("Request or parsing failed: \(error)")
    }
}