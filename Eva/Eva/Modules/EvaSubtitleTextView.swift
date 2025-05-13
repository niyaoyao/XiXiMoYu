//
//  EvaSubtitleTextView.swift
//  Eva
//
//  Created by niyao on 5/13/25.
//

import Foundation
import UIKit

class EvaSubtitleTextView: UITextView {
    var originText: String = ""
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // 设置 UITextView 背景色为透明
        self.backgroundColor = .clear
        // 禁用交互和滚动
        self.isUserInteractionEnabled = true
        self.isScrollEnabled = true
        // 设置内边距
        self.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
    }
    
    func setSubtitle(_ text: String) {
        // 创建 NSAttributedString
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white, // 字体颜色：白色
            .backgroundColor: UIColor.black.withAlphaComponent(0.5), // 字体背景色：半透明黑色
            .font: UIFont.systemFont(ofSize: 20, weight: .medium) // 字体样式
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        self.attributedText = attributedString
        self.originText = text
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        // 确保有内容
        guard let attributedText = self.attributedText, attributedText.length > 0 else { return }
        
        // 创建一个指向最后一个字符的 NSRange
        let range = NSRange(location: attributedText.length - 1, length: 1)
        
        // 在主线程异步滚动以确保 UI 已更新
        DispatchQueue.main.async {
            self.scrollRangeToVisible(range)
        }
    }
}
