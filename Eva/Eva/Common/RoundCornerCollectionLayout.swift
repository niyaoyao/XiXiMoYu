//
//  File.swift
//  Eva
//
//  Created by niyao on 5/6/25.
//

import Foundation
import UIKit


protocol RoundCornerCollectionDelegateLayout: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout: RoundCornerCollectionLayout, configModelForSection: NSInteger) -> RoundCornerCollectionDecorateModel?
}

final class RoundCornerCollectionLayout: UICollectionViewFlowLayout {
    lazy fileprivate var decorationViewAttrs: [RoundCornerCollectionDecorateAttribute] = {
        Array()
    }()
    
    override func prepare() {
        super.prepare()
        self.register(RoundCornerCollectionDecorateView.self, forDecorationViewOfKind: String(describing: RoundCornerCollectionDecorateView.self))
        self.decorationViewAttrs.removeAll()
        if let sections = self.collectionView?.numberOfSections {
            if sections > 0 {
                for sectionIndex in 0..<sections {
                    if let rows = self.collectionView?.numberOfItems(inSection: sectionIndex) {
                        if rows > 0 {
                            var firstFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                            if let firstAttribute = self.layoutAttributesForItem(at: IndexPath(row: 0, section: sectionIndex)) {
                                firstFrame = firstAttribute.frame
                            }
                            
                            if let headerAtt = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: sectionIndex)) {
                                if headerAtt.frame.size.width > 0 && headerAtt.frame.size.height > 0 {
                                    firstFrame = headerAtt.frame
                                }
                            }
                            
                            var lastFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                            if let lastAtt = self.layoutAttributesForItem(at: IndexPath(row: rows - 1, section: sectionIndex)) {
                                lastFrame = lastAtt.frame
                            }
                            let decorateViewAtt = RoundCornerCollectionDecorateAttribute(forDecorationViewOfKind: String(describing: RoundCornerCollectionDecorateView.self), with: IndexPath(row: 0, section: sectionIndex))
                            var decorateViewInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                            if let delegate = self.collectionView?.delegate as? RoundCornerCollectionDelegateLayout {
                                if let configModel = (delegate.collectionView(self.collectionView!, layout: self, configModelForSection: sectionIndex)) {
                                    decorateViewAtt.configModel = configModel
                                    decorateViewInset = configModel.borderEdgeInsets
                                }
                            }
                            
                            var decorateViewFrame = firstFrame.union(lastFrame)
                            if decorateViewFrame != CGRect(x: 0, y: 0, width: 0, height: 0) {
                                decorateViewFrame.origin.x = decorateViewInset.left
//                                decorateViewFrame.origin.y = decorateViewInset.top
                                decorateViewFrame.size.width = (kScreenWidth - decorateViewInset.left - decorateViewInset.right)
                                decorateViewFrame.size.height -= (decorateViewInset.top + decorateViewInset.bottom)
                            }
                            decorateViewAtt.frame = decorateViewFrame
                            decorateViewAtt.zIndex = -1
                            self.decorationViewAttrs.append(decorateViewAtt)
                        }
                    }else {
                        continue
                    }
                }
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if let atts = super.layoutAttributesForElements(in: rect) {
            return atts + self.decorationViewAttrs
        }else {
            return nil
        }
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == String(describing: RoundCornerCollectionDecorateAttribute.self) {
            return self.decorationViewAttrs[indexPath.section]
        }else {
            return nil
        }
    }
}

final class RoundCornerCollectionDecorateView: UICollectionReusableView {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attrubutes = layoutAttributes as? RoundCornerCollectionDecorateAttribute {
            if let config = attrubutes.configModel {
                self.layer.backgroundColor = config.backgroundColor.cgColor
                self.layer.cornerRadius = CGFloat(config.cornerRadius)
            }
        }
    }
}

final fileprivate class RoundCornerCollectionDecorateAttribute: UICollectionViewLayoutAttributes {
    fileprivate var configModel: RoundCornerCollectionDecorateModel?
}

struct RoundCornerCollectionDecorateModel {
    // section边框自定义缩进 默认(0, 16.f, 16.f, 16.f)
    var borderEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)
    // section背景色  默认白色
    var backgroundColor: UIColor = .white
    // 圆角 默认8pt
    var cornerRadius: Float = 8.0
    init(borderEdgeInsets: UIEdgeInsets, backgroundColor: UIColor, cornerRadius: Float) {
        self.borderEdgeInsets = borderEdgeInsets
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
}
