//
//  AppDelegate.swift
//  Eva
//
//  Created by niyao on 4/18/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = ViewController(nibName: nil, bundle: nil)
        self.window?.makeKeyAndVisible()
        
        return true
    }


}

