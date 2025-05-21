//
//  EvaporatingImageLayerView.swift
//  tts
//
//  Created by NY on 2025/5/19.
//

import Foundation
import UIKit

class EvaporatingImageLayerView: UIView {
    private let originalImage: UIImage
    /// 粒子大小
    private var gridSize: Int = 2
    private var particleLayers: [CALayer] = []

    init(frame: CGRect, image: UIImage, gridSize: Int = 6) {
        self.originalImage = image
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.gridSize = gridSize
        generateParticleLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化蒸汽粒子
    private func generateParticleLayers() {
        guard let cgImage = originalImage.cgImage else { return }

        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        let scaleX = bounds.width / CGFloat(imageWidth)
        let scaleY = bounds.height / CGFloat(imageHeight)

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return }

        for y in stride(from: 0, to: imageHeight, by: gridSize) {
            for x in stride(from: 0, to: imageWidth, by: gridSize) {
                let index = ((imageWidth * y) + x) * 4
                if index + 3 >= CFDataGetLength(data) { continue }

                let r = ptr[index]
                let g = ptr[index + 1]
                let b = ptr[index + 2]
                let a = ptr[index + 3]
                if a == 0 { continue }

                let color = UIColor(red: CGFloat(r)/255.0,
                                    green: CGFloat(g)/255.0,
                                    blue: CGFloat(b)/255.0,
                                    alpha: CGFloat(a)/255.0)

                let particle = CALayer()
                let px = CGFloat(x) * scaleX
                let py = CGFloat(y) * scaleY
                let pSize = CGSize(width: CGFloat(gridSize) * scaleX,
                                   height: CGFloat(gridSize) * scaleY)

                particle.frame = CGRect(origin: CGPoint(x: px, y: py), size: pSize)
                particle.backgroundColor = color.cgColor
                particle.cornerRadius = pSize.width / 2
                self.layer.addSublayer(particle)
                self.particleLayers.append(particle)
            }
        }
    }

    /// 开始蒸发动画
    func startEvaporateAnimation(duration: TimeInterval = 2.0, delay: Double = 0.0,
                                 minX: CGFloat = -50.0, maxX: CGFloat = 50.0,
                                 minY: CGFloat = -150.0, maxY: CGFloat = 30.0,
                                 minScale: CGFloat = 0.5, maxScale: CGFloat = 2.5) {
        for particle in particleLayers {
            let moveX = CGFloat.random(in: minX...maxX)
            let moveY = CGFloat.random(in: minY...maxY)
            let scale = CGFloat.random(in: minScale...maxScale)

            // 位移动画
            let move = CAKeyframeAnimation(keyPath: "position")
            move.values = [
                particle.position,
                CGPoint(x: particle.position.x + moveX * 0.5,
                        y: particle.position.y + moveY * 0.5),
                CGPoint(x: particle.position.x + moveX,
                        y: particle.position.y + moveY)
            ]
            move.keyTimes = [0, 0.5, 1]
            move.timingFunction = CAMediaTimingFunction(name: .easeOut)

            // 缩放动画
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 1.0
            scaleAnim.toValue = scale

            // 透明度动画
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0

            // 动画组
            let group = CAAnimationGroup()
            group.animations = [move, scaleAnim, fade]
            group.duration = duration
            group.beginTime = CACurrentMediaTime() + delay
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false

            particle.add(group, forKey: nil)
        }

        // 最后淡出整个图层视图
        UIView.animate(withDuration: duration + 0.5, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}
