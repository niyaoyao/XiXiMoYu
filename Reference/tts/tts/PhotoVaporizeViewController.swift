//
//  PhotoVaporizeViewController.swift
//  tts
//
//  Created by NY on 2025/5/19.
//
import UIKit

class EvaporatingImageView: UIView {
    private var particleViews: [UIView] = []
    private var originalImage: UIImage
    private let gridSize: Int = 6  // 粒子大小（越小越细腻）

    init(frame: CGRect, image: UIImage) {
        self.originalImage = image
        super.init(frame: frame)
        self.backgroundColor = .clear
        generateParticles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func generateParticles() {
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

                let particle = UIView(frame: CGRect(x: CGFloat(x) * scaleX,
                                                    y: CGFloat(y) * scaleY,
                                                    width: CGFloat(gridSize) * scaleX,
                                                    height: CGFloat(gridSize) * scaleY))
                particle.backgroundColor = color
                particle.layer.cornerRadius = particle.frame.width / 2
                self.addSubview(particle)
                self.particleViews.append(particle)
            }
        }
    }

    func startEvaporateAnimation(duration: TimeInterval = 2.0, delay: Double = 0.0) {
        for particle in particleViews {
//            let delay = Double.random(in: 0...0.5)
            let randomX = CGFloat.random(in: -50...50)
            let randomY = CGFloat.random(in: -150...(-50))
            let scale = CGFloat.random(in: 0.5...1.5)

            UIView.animate(withDuration: duration,
                           delay: delay,
                           options: [.curveEaseOut],
                           animations: {
                particle.transform = CGAffineTransform(translationX: randomX, y: randomY)
                    .scaledBy(x: scale, y: scale)
                particle.alpha = 0
                particle.layer.cornerRadius = 0
            }, completion: { _ in
                particle.removeFromSuperview()
            })
        }

        // 可选：淡出整个 view
        UIView.animate(withDuration: duration + 0.5) {
            self.alpha = 0
        }
    }
}


// 使用示例
class PhotoVaporizeViewController: UIViewController {
    lazy var btn: UIButton = {
        let btn = UIButton(frame: .zero )
        btn.setTitleColor(.black, for: .normal)
        btn.setTitle("Start", for: .normal)
        btn.addTarget(self, action: #selector(startAnimation), for: .touchUpInside)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    lazy var animateImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "EvaApp"))
        iv.frame = CGRect(x: 50, y: 150, width: 300, height: 300)
        return iv
    }()
    
    var particleView: EvaporatingImageLayerView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        guard let image = UIImage(named: "EvaApp") else { return }
        particleView = EvaporatingImageLayerView(frame: CGRect(x: 50, y: 150, width: 300, height: 300), image: image)
        
        guard let imageView = particleView else { return  }
        view.addSubview(imageView)
        view.addSubview(animateImageView)
        view.addSubview(btn)
        btn.frame = CGRect(x: 10, y: imageView.frame.origin.y + imageView.frame.size.height + 10, width: 80, height: 50)
    }
    
    @objc func startAnimation() {
        animateImageView.isHidden = true
        guard let particleView = self.particleView else { return }
        particleView.startEvaporateAnimation()

    }
   
}

