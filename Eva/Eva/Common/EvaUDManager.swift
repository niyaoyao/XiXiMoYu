//
//  EvaUDManager.swift
//  Eva
//
//  Created by NY on 2025/5/14.
//

import Foundation

class EvaUserDefaultManager {
    static var aiKeys: [String] {
        get {
            if let array = UserDefaults.standard.array(forKey: #function) as? [String] {
                return array
            } else {
                return []
            }
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: #function)
        }
    }
}
