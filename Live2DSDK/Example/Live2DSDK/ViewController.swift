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
        
        self.navigationController?.pushViewController(NYLDSDKManager.shared().stageVC, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

