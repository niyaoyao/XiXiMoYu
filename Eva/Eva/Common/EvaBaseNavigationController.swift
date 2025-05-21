//
//  EvaBaseNavigationController.swift
//  Eva
//
//  Created by niyao on 4/25/25.
//

import UIKit

class EvaBaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let popGesture = self.interactivePopGestureRecognizer {
            popGesture.delegate = self
        }
    }
}

extension EvaBaseNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
}
