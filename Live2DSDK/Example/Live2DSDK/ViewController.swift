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
        
        
    }
    
    @IBAction func routeToLive2DPage(_ sender: Any) {
        let vc = Live2DSDK.NYLDRenderStageVC(nibName: nil, bundle: nil)
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

