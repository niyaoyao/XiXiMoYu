//
//  EvaUserProfileListItemViewModel.swift
//  Eva
//
//  Created by niyao on 5/6/25.
//

import Foundation
import UIKit
enum EvaUserProfileItemType {
    case vip
    case studyTime
    case analyseTime
    case myTarget
    case blockList
    case contactAssistance
    case username
    case gender
    case birth
    case slogan
    case identity
    case version
    case userProtocol
    case privacy
    case icp
    case unregister
}

struct EvaUserProfileListItemViewModel {
    var type:EvaUserProfileItemType = .vip
    var imageName: String = ""
    var title: String = ""
    var titleColor: UIColor?
    var content: String = ""
    var showBottomLine = false
    var hideArrow = false
    init(type: EvaUserProfileItemType) {
        self.type = type
    }
}
