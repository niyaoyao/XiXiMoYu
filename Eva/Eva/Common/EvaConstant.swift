//
//  EvaConstant.swift
//  Eva
//
//  Created by niyao on 4/25/25.
//

import Foundation
import UIKit
var isIPhoneX: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
        && (max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) >= 375
                && max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) >= 812)
}

/// 状态栏高度
let kStatusBarHeight: CGFloat = (isIPhoneX == true ? 44 : 20)
/// 导航栏高度
let kNavigationBarHeight = (kStatusBarHeight + 44)
/// 自定义 TabBar 高度
let kTabBarHeight: CGFloat = (isIPhoneX == true ? (49 + 34) : 49)
/// 底部安全距离高度
let kBottomSafeHeight: CGFloat = isIPhoneX == true ? 34.0: 0.0
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width

enum WeStudyResponseStatus {
    case initialized
    case loading
    case failed
    case success
    case noData
}

enum WeStudyResponseError: Error {
    case requestFailed
    case decodingError
}


// 将字典转换为 Data
func dictionaryToData(dictionary: [String: Any]) -> Data? {
    return try? JSONSerialization.data(withJSONObject: dictionary, options: [])
}

func convertToArray<T: Codable>(from dictionaryArray: [[String: Any]]) -> [T]? {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryArray) else {
        return nil
    }
    
    let decoder = JSONDecoder()
    do {
        let result = try decoder.decode([T].self, from: jsonData)
        return result
    } catch {
        print("Error decoding JSON: \(error)")
        return nil
    }
}

func convertToModel<T: Codable>(from dictionary: [String: Any]) -> T? {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary) else {
        return nil
    }
    
    let decoder = JSONDecoder()
    do {
        let model = try decoder.decode(T.self, from: jsonData)
        return model
    } catch {
        print("Error decoding JSON: \(error)")
        return nil
    }
}


// 自定义错误类型
enum ConversionError: Error {
    case serializationFailed(String) // JSON 序列化失败
    case decodingFailed(String)      // JSON 解码失败
}

// 将字典转换为 Codable 模型
func convertToModel<T: Codable>(from dictionary: [String: Any]) throws -> T {
    // 序列化为 JSON 数据
    guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary) else {
        throw ConversionError.serializationFailed("Failed to serialize dictionary to JSON data")
    }
    
    // 解码为目标模型
    let decoder = JSONDecoder()
    do {
        let model = try decoder.decode(T.self, from: jsonData)
        return model
    } catch {
        throw ConversionError.decodingFailed("Failed to decode JSON to \(T.self): \(error.localizedDescription)")
    }
}
// 将 Data 解码为模型
func dataToModel<T: Codable>(data: Data, type: T.Type) -> T? {
    let decoder = JSONDecoder()
    return try? decoder.decode(T.self, from: data)
}


import Foundation



// 自定义错误类型
enum NetworkError: Error {
    case invalidBodySerialization(String)
    case noDataReceived
    case invalidResponse(String)
}

// 将字典转换为 form-urlencoded 格式的辅助函数
private func bodyToFormData(body: [String: Any]) -> Data? {
    let components = body.map { key, value in
        let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
        let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
        return "\(escapedKey)=\(escapedValue)"
    }
    let queryString = components.joined(separator: "&")
    return queryString.data(using: .utf8)
}

// 发起网络请求的公共函数（async/await 版本）
func request(
    url: URL,
    method: HTTPMethod = .GET,
    headers: [String: String]? = nil,
    body: [String: Any]? = nil,
    bodyIsFormEncoded: Bool = false
) async throws -> Data {
    // 创建 URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    
    // 设置 HTTP Header
    if let headers = headers {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    // 设置 Content-Type
    if bodyIsFormEncoded {
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
    
    // 设置 HTTP Body（仅 POST 和 PUT 支持）
    if let body = body, (method == .POST || method == .PUT) {
        if bodyIsFormEncoded {
            // 转换为 form-urlencoded 格式
            guard let formData = bodyToFormData(body: body) else {
                throw NetworkError.invalidBodySerialization("Failed to encode body to form-urlencoded format")
            }
            request.httpBody = formData
        } else {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // 转换为 JSON 格式
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                request.httpBody = jsonData
            } catch {
                throw NetworkError.invalidBodySerialization("Failed to serialize body to JSON: \(error.localizedDescription)")
            }
        }
    }
    
    // 使用 URLSession 的 async API
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // 验证响应
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse("Invalid response: \(String(describing: response))")
    }
    
    // 验证数据
    guard !data.isEmpty else {
        throw NetworkError.noDataReceived
    }
    
    return data
}
