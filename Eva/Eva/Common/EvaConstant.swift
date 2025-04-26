//
//  EvaConstant.swift
//  Eva
//
//  Created by niyao on 4/25/25.
//

import Foundation
import UIKit

var isIPhoneX: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
        && (max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) >= 375
                && max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) >= 812)
}

/// 状态栏高度
let kStatusBarHeight: CGFloat = (isIPhoneX == true ? 44 : 20)
/// 导航栏高度
let kNavigationBarHeight = (kStatusBarHeight + 44)
/// 自定义 TabBar 高度
let kTabBarHeight: CGFloat = (isIPhoneX == true ? (49 + 34) : 49)
/// 自定义 TabBar 高度
let kBottomSafeHeight: CGFloat = (isIPhoneX == true ?  34 : 0)

let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width

enum WeStudyResponseStatus {
    case initialized
    case loading
    case failed
    case success
    case noData
}

enum WeStudyResponseError: Error {
    case requestFailed
    case decodingError
}
