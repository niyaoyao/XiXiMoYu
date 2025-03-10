//
//  ViewController.swift
//  Live2DSDK
//
//  Created by NY on 03/06/2025.
//  Copyright (c) 2025 NY. All rights reserved.
//

import UIKit
import Live2DSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the bundle for the Live2DSDK framework
        guard let bundle = loadLive2DModelsBundle() else { return }
        if let imagePath = bundle.path(forResource: "back_class_normal", ofType: "png") {
            
            // 3. Load the image
            if let image = UIImage(contentsOfFile: imagePath) {
                
                // 4. Create UIImageView to display the image
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x: 0, y: 200, width: 200, height: 200) // Adjust size as needed
                imageView.contentMode = .scaleAspectFit
                
                // 5. Add to view
                view.addSubview(imageView)
            } else {
                print("Failed to load image")
            }
        } else {
            print("Image file not found in bundle")
        }
        
        
    }
    
    @IBAction func routeToLive2DPage(_ sender: Any) {
        let vc = Live2DSDK.ViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func loadLive2DModelsBundle() -> Bundle? {
        let url = Bundle.main.url(forResource: "Frameworks/Live2DSDK", withExtension: "framework")
        
        
        guard let url = url, let bundlePath = Bundle.init(url: url)?.path(forResource: "Live2DModels", ofType: "bundle"),
              let bundle = Bundle(path: bundlePath) else {
            print("Live2DModels.bundle not found in main bundle")
            let resources = Bundle.main.paths(forResourcesOfType: "bundle", inDirectory: nil)
            print("All bundles in main bundle: \(resources)")
            return nil
        }
        return bundle
    }
}

