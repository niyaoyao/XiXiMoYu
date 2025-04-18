//
//  ViewController.swift
//  Live2DDemo
//
//  Created by niyao on 2/18/25.
//

import UIKit

class ViewController: UIViewController {

    private let render = DREmotionModelRender()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        self.view.addSubview(render.view)
        render.setModelViewFrame(self.view.bounds)
        render.modelScale = 1
        render.showBackgroundImage = true
        guard let model = DREmotionModelPackageManager.shared.emotionModelPackages[2] as? DREmotionModelPackage  else { return  }
        render.updateModel(model)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        render.setModelViewFrame(self.view.bounds)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render.enable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        render.disable()
    }
}

