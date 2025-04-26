//
//  EvaRouter.swift
//  Eva
//
//  Created by niyao on 4/26/25.
//

import UIKit
let kEvaScheme = "eva://"
let loginPageUrl = "\(kEvaScheme)loginPage"
let mainTabUrl = "\(kEvaScheme)main"

class EvaRouter: NSObject {
    static let shared = EvaRouter()
    @objc static func openUrl(_ url: String, params: [String : Any] = [:]) {
        if url == loginPageUrl {
            showLoginView()
            
        } else if url == mainTabUrl {
            showHomePage()
        } else {
            
        }
    }
    
    @objc static func showLoginView() {
//        appdelegate().window.rootViewController =  WeStudyLoginViewController()
//        appdelegate().window.makeKeyAndVisible()
//        // TODO: Change to Swift
//        WSLocalUserDataManager.shared().userInfo?.isLoginLocal = false
//        WSLocalUserDataManager.shared().saveUserInfo()
    }
    
    @objc static func showHomePage()  {
//        let home =
//        appdelegate().window.rootViewController = tabvc
//        appdelegate().window.makeKeyAndVisible()
//        
    }
}
