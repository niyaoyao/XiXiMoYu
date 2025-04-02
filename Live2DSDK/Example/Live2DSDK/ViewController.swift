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
    let imageNames = ["bg0.jpg","bg1.jpg","bg2.jpg","bg3.jpg","bg4.jpg"]
    lazy var tmpIV: UIImageView = {
        let iv = UIImageView(frame: CGRect(x: 10, y: 40, width: 100, height: 100))
        return iv
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        EAGLContext.setCurrent(EAGLContext(api: .openGLES2))
        self.view.addSubview(NYLDSDKManager.shared().stageVC.view)
        let btn = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width - 220, y: UIScreen.main.bounds.size.height - 50 - 60, width: 200, height: 50))
        btn.setTitle("Change Background", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .blue.withAlphaComponent(0.5)
        btn.addTarget(self, action: #selector(changeBackground), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let mbtn = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width - 220, y:  UIScreen.main.bounds.size.height - 50 - 30 - 110, width: 200, height: 50))
        mbtn.setTitle("Change Model", for: .normal)
        mbtn.setTitleColor(.white, for: .normal)
        mbtn.backgroundColor = .blue.withAlphaComponent(0.5)
        mbtn.addTarget(self, action: #selector(changeModel), for: .touchUpInside)
        self.view.addSubview(mbtn)
        
        self.view.addSubview(self.tmpIV)
    }
    
    @objc func changeModel() {
        NYLDModelManager.shared().nextScene()
    }
    @objc func changeBackground() {
        count += 1
        let nameIndex = count % imageNames.count
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

