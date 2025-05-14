//
//  EvaThreadSafeModels.swift
//  Eva
//
//  Created by NY on 2025/5/14.
//

import Foundation

class EvaThreadSafeContentsManager {
    // 共享数组
    private var waitToSpeakContents: [String] = []
    
    // 并发队列，启用 barrier
    private let queue = DispatchQueue(label: "com.example.subtitleManager", attributes: .concurrent)
    
    // 写操作：添加内容
    func appendContent(_ content: String) {
        queue.async(flags: .barrier) {
            self.waitToSpeakContents.append(content)
        }
    }
    
    // 写操作：移除内容
    func removeFirstContent() -> String? {
        var result: String?
        queue.sync(flags: .barrier) {
            result = self.waitToSpeakContents.isEmpty ? nil : self.waitToSpeakContents.removeFirst()
        }
        return result
    }
    
    // 读操作：获取所有内容
    func getAllContents() -> [String] {
        var result: [String] = []
        queue.sync {
            result = self.waitToSpeakContents
        }
        return result
    }
    
    func getAllContentsString() -> String {
        return getAllContents().joined(separator: " ")
    }
    
    // 读操作：获取内容数量
    func getContentCount() -> Int {
        var count = 0
        queue.sync {
            count = self.waitToSpeakContents.count
        }
        return count
    }
    
    // 新增：移除所有内容
    func removeAllContents() {
        queue.async(flags: .barrier) {
            self.waitToSpeakContents.removeAll()
        }
    }
}
