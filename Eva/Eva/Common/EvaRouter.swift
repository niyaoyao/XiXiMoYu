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
        
        guard let window = UIApplication.shared.delegate?.window else { return }
        
    }
    
    @objc static func showHomePage()  {
        let aiChat = AIChatViewController()
        let homeNav = EvaBaseNavigationController(rootViewController: aiChat)
        guard let window = UIApplication.shared.delegate?.window as? UIWindow else { return }
        window.rootViewController = homeNav
        window.makeKeyAndVisible()
    }
}
