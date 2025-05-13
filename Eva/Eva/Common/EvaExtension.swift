//
//  EvaExtension.swift
//  Eva
//
//  Created by niyao on 4/25/25.
//

import Foundation
import UIKit
import Combine

extension UIColor {
    
    convenience init(_ hex: String) {
        self.init(hex: hex, alpha: 1)
    }
    convenience init(hex: String, alpha: CGFloat = 1) {
        let hex = (hex as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.scanLocation = 1
        } else if hex.hasPrefix("0x") || hex.hasPrefix("0X"){
            scanner.scanLocation = 2
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}


extension UIViewController {
    
    class func current() -> UIViewController? {
        return getTopViewController(with: UIWindow.current()?.rootViewController)
    }
    
    class func getTopViewController(with viewController: UIViewController?) -> UIViewController? {
        if let presentVC = viewController?.presentedViewController, !presentVC.isBeingDismissed{
            return getTopViewController(with: presentVC)
        }else if let tabVC = viewController as? UITabBarController {
            return getTopViewController(with: tabVC.selectedViewController)
        }else if let navVC = viewController as? UINavigationController {
            return getTopViewController(with: navVC.topViewController)
        }else if let vc = viewController?.children.last {
            return getTopViewController(with: vc)
        }else {
            return viewController
        }
    }

}


extension UIWindow {
    
    static func current() -> UIWindow?{
        if let window = UIApplication.shared.delegate?.window {
            return window
        }
        if #available(iOS 13.0, *) {
            if let window = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first {
                return window
            }
        }
        return nil
    }
}

extension UIView {
    func addSubviews(_ views: [UIView]) {
        for view in views {
            self.addSubview(view)
        }
    }
}


extension NSString {
    @objc public func validPhoneNo() -> Bool {
        let regex = "^1[3-9]\\d{9}$"
        let mobileTest = NSPredicate(format: "SELF MATCHES %@", regex)
        return mobileTest.evaluate(with: self)
    }
}

import Combine

extension UITextField {
    var textDidChangePublisher: AnyPublisher<String, Never> {
        let publisher = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { notification in
                return (notification.object as? UITextField)?.text ?? ""
            }
            .eraseToAnyPublisher()
        return publisher
    }
}

// MARK: UIButton
import UIKit
import ObjectiveC

private var actionHandlerKey: Void?

extension UIButton {
    
    private var tapActionHandler: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &actionHandlerKey) as? (() -> Void)
        }
        set {
            objc_setAssociatedObject(self, &actionHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addActionHandler(_ handler: (() -> Void)?) {
        tapActionHandler = handler
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        tapActionHandler?()
    }
}

extension UIButton {
    var tapPublisher: AnyPublisher<Void, Never> {
        let publisher = ControlEventPublisher(control: self, events: .touchUpInside)
        return publisher.eraseToAnyPublisher()
    }
}

private struct ControlEventPublisher: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let control: UIControl
    private let events: UIControl.Event
    
    init(control: UIControl, events: UIControl.Event) {
        self.control = control
        self.events = events
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscription = ControlEventSubscription(subscriber: subscriber, control: control, events: events)
        subscriber.receive(subscription: subscription)
    }
    
    private class ControlEventSubscription<S: Subscriber>: Subscription where S.Input == Void {
        private var subscriber: S?
        private weak var control: UIControl?
        private let events: UIControl.Event
        
        init(subscriber: S, control: UIControl, events: UIControl.Event) {
            self.subscriber = subscriber
            self.control = control
            self.events = events
            
            control.addTarget(self, action: #selector(eventHandler), for: events)
        }
        
        @objc private func eventHandler() {
            _ = subscriber?.receive(())
        }
        
        func request(_ demand: Subscribers.Demand) {
            // No action needed for Void
        }
        
        func cancel() {
            control?.removeTarget(self, action: #selector(eventHandler), for: events)
            subscriber = nil
        }
    }
}

extension UIImage {
    static func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage? {
        // Begin image context
        let renderer = UIGraphicsImageRenderer(size: size)
        let renderedImage = renderer.image { context in
            // Draw original image
            UIImage().draw(in: CGRect(origin: .zero, size: size))
            
            // Set the fill color
            context.cgContext.setBlendMode(.sourceIn)
            context.cgContext.setFillColor(color.cgColor)
            
            // Fill the image with the color
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fill(rect)
        }
        
        return renderedImage
    }
}



extension UIImageView {
    private struct AssociatedKeys {
        static var tapAction = "tapAction"
    }
    
    private var tapAction: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.tapAction) as? (() -> Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.tapAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addTapGesture(action: @escaping () -> Void) {
        // 确保用户交互是开启的
        isUserInteractionEnabled = true
        
        // 保存闭包
        tapAction = action
        
        // 创建手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        tapAction?()
    }
}


extension Date {
    static func createTimeStr(date: Date = Date()) -> String {
        // 创建 NSDateFormatter 实例
        let dateFormatter = DateFormatter()

        // 设置日期格式
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // 设置时区为 "Asia/Shanghai"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        // 设置本地化标识符为 "zh_CN"
        dateFormatter.locale = Locale(identifier: "zh_CN")

        // 获取当前日期字符串
        let currentDateStr = dateFormatter.string(from: date)

        // 将结果赋值给 createTimeStr
        let createTimeStr = currentDateStr
        return createTimeStr
    }
    
    static func durationString(from dateString: String) -> String {
        // 1. 创建日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        dateFormatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        // 2. 解析指定时间的字符串
        let pastDate = dateFormatter.date(from: dateString)

        // 3. 获取当前时间
        let currentDate = Date()

        // 4. 计算时间差
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: pastDate ?? Date(), to: currentDate)

        // 5. 将时间差格式化为 "HH:mm:ss" 字符串
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0

        let durationString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        return durationString
    }
    
    // 函数：将秒数转换为 "HH:mm:ss" 格式的字符串
    static func formatSeconds(_ totalSeconds: Int) -> String {
        // 计算小时、分钟和秒
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        // 格式化为 "HH:mm:ss" 字符串
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

}

extension String {
    func substring(with nsrange: NSRange) -> String? {
        // 验证 NSRange 是否有效
        guard nsrange.location != NSNotFound,
              nsrange.location >= 0,
              nsrange.location + nsrange.length <= self.utf16.count else {
            return nil
        }
        
        // 将 NSRange 转换为 Range<String.Index>
        guard let range = Range(nsrange, in: self) else {
            return nil
        }
        
        // 提取子字符串
        return String(self[range])
    }
}
