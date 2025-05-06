//
//  EvaSettingsCommonCell.swift
//  Eva
//
//  Created by niyao on 5/6/25.
//

import Foundation
import UIKit

class EvaSettingsCommonCell: UICollectionViewCell {
    static let reuseIdentifier = "WeStudySettingsCommonCell"
    static let size: CGSize = CGSize(width: kScreenWidth - 24, height: 64.0)
    
    
    lazy var titLabel: UILabel = {
        let lab = UILabel(frame: .zero)
        lab.text = ""
        lab.textColor = UIColor(hex: "#020E22", alpha: 1)
        lab.font = .systemFont(ofSize: 16)
        return lab
    }()
    
    lazy var contentLabel: UILabel = {
        let lab = UILabel(frame: .zero)
        lab.text = ""
        lab.textColor = UIColor(hex: "#8A8A8A", alpha: 1)
        lab.font = .systemFont(ofSize: 14)
        return lab
    }()
    
    
    lazy var arrowIV: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "settings_common_arrow"))
        iv.contentMode = .center
        return iv
    }()
    
    lazy var lineV: UIView = {
        let l = UIView(frame: .zero)
        l.backgroundColor = UIColor(hex: "#DBDBDB", alpha: 1)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews([titLabel, contentLabel, arrowIV, lineV])

        
        titLabel.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.left.equalTo(contentView).offset(20)
        }
        
        arrowIV.snp.makeConstraints { make in
            make.right.equalTo(contentView).offset(-20)
            make.centerY.equalTo(contentView)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        contentLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowIV.snp.left)
            make.centerY.equalTo(contentView)
        }
        
        lineV.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(20)
            make.right.equalTo(contentView).offset(-20)
            make.bottom.equalTo(contentView)
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(vm: EvaUserProfileListItemViewModel) {
        titLabel.text = vm.title
        lineV.isHidden = !vm.showBottomLine
        contentLabel.text = vm.content
        arrowIV.isHidden = vm.hideArrow
        if vm.hideArrow {
            arrowIV.snp.updateConstraints { make in
                make.size.equalTo(CGSize())
            }
        }
    }
}
