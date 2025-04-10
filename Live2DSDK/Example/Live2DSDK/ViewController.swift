//
//  ViewController.swift
//  Live2DSDK
//
//  Created by NY on 03/06/2025.
//  Copyright (c) 2025 NY. All rights reserved.
//

import UIKit
import Live2DSDK
import GLKit

class ViewController: UIViewController {
    var count = 0
    
    lazy var tmpIV: UIImageView = {
        let iv = UIImageView(frame: CGRect(x: 10, y: 40, width: 100, height: 100))
        return iv
    }()
    
    // 定义 UISlider
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0 // 最小值
        slider.maximumValue = 1.0 // 最大值
        slider.value = 0.5        // 默认值
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        EAGLContext.setCurrent(EAGLContext(api: .openGLES2))
        self.view.addSubview(NYLDSDKManager.shared().stageVC.view)
        let w = (UIScreen.main.bounds.size.width - 45 )/2.0
        let btn = UIButton(frame: CGRect(x: 15, y: UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        btn.setTitle("Change Background", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .blue.withAlphaComponent(0.5)
        btn.addTarget(self, action: #selector(changeBackground), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let mbtn = UIButton(frame: CGRect(x: w + 30, y:  UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        mbtn.setTitle("Change Model", for: .normal)
        mbtn.setTitleColor(.white, for: .normal)
        mbtn.backgroundColor = .blue.withAlphaComponent(0.5)
        mbtn.addTarget(self, action: #selector(changeModel), for: .touchUpInside)
        self.view.addSubview(mbtn)
        
        self.view.addSubview(self.tmpIV)
        // 添加 UI 元素到视图
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        slider.frame = CGRect(x: 15, y: mbtn.frame.origin.y - 40, width: UIScreen.main.bounds.size.width - 30, height: 20)
    }
    // 滑动条值变化时的回调
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let value = sender.value
        
        // 在这里处理 value（范围 0 到 1）
        print("Slider value: \(value)")
        NYLDModelManager.shared().mouthOpenRate = value
    }
    
    @objc func changeModel() {
        NYLDModelManager.shared().nextScene()
    }
    @objc func changeBackground() {
        count += 1
        let nameIndex = count % 8
        let name = "0\(nameIndex)"
        NYLDSDKManager.shared().stageVC.changeBackground(withImageName: name)
        let filePath =  NYLDModelManager.shared().modelBundle.path(forResource: "0\(nameIndex)", ofType: "png", inDirectory: "Background") ?? ""
//        let filePath =  Bundle.main.path(forResource: "0\(nameIndex)", ofType: "png") ?? ""
        debugPrint("Background: \(filePath)")
        var image = UIImage(contentsOfFile: filePath)
        
        self.tmpIV.image = image
//        var texture:GLKTextureInfo
//        if let image = image, let cgimage = image.cgImage {
//            let outputImage:CIImage = CIImage(cgImage: cgimage)
//
//            let context:CIContext = CIContext.init(options: nil)
//            let pixelData = context.createCGImage(outputImage, from: outputImage.extent,
//                                                  format: kCIFormatARGB8,
//                                                  colorSpace: CGColorSpaceCreateDeviceRGB())!
//
//            do {
//                //失敗する。
//                texture = try GLKTextureLoader.texture(with: pixelData, options: nil)
//                debugPrint("texture:\(texture)")
//            } catch {
//                //ここに来る。
//                debugPrint("GLKTextureLoaderError:2\(error)")
//            }
////            GLKTextureLoader.texture(with: cgimage, options: [:])
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

