//
//  MaskAnimationViewController.swift
//  sst
//
//  Created by NY on 2025/4/23.
//

import UIKit

class MaskAnimationViewController: UIViewController {
    
    // 目标视图（需要显示的内容）
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue // 可替换为 UIImageView 等
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // 添加目标视图
        view.addSubview(contentView)
        
        // 设置布局
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 200),
            contentView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // 设置遮罩并启动动画
        setupMaskAnimation()
    }
    
    private func setupMaskAnimation() {
        // 创建 CAShapeLayer 作为遮罩
        let maskLayer = CAShapeLayer()
        
        // 初始路径：宽度为 0（完全遮挡）
        let initialRect = CGRect(x: 0, y: 0, width: 0, height: contentView.bounds.height)
        maskLayer.path = CGPath(rect: initialRect, transform: nil)
        
        // 设置遮罩
        contentView.layer.mask = maskLayer
        
        // 创建动画：从宽度 0 到完整宽度
        let animation = CABasicAnimation(keyPath: "path")
        let finalRect = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
        animation.fromValue = maskLayer.path
        animation.toValue = CGPath(rect: finalRect, transform: nil)
        animation.duration = 1.0 // 动画持续时间
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // 缓动效果
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // 添加动画
        maskLayer.add(animation, forKey: "expandAnimation")
    }
}

