//
//  ScaleCollectionCell.swift
//  Eva
//
//  Created by niyao on 5/6/25.
//

import Foundation
import UIKit

class NYScaleCenterItemCollectionFlowLayout: UICollectionViewFlowLayout {
    init(width: CGFloat, height: CGFloat, padding: CGFloat) {
        super.init()
        itemSize = CGSize(width: width, height: height)
        scrollDirection = .horizontal
        minimumLineSpacing = 0.0
        minimumInteritemSpacing = 0.0
        sectionInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let collectionViewLayoutAttribuites: [UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect) ?? []
        guard let collectionView = self.collectionView else {
            return collectionViewLayoutAttribuites
        }
        let centerX = collectionView.contentOffset.x + collectionView.bounds.size.width/2.0
        let visableRect = CGRect(x: collectionView.contentOffset.x,
                                 y: collectionView.contentOffset.y,
                                 width: collectionView.frame.size.width,
                                 height: collectionView.frame.size.height)
        for attribuite in collectionViewLayoutAttribuites {
            if !visableRect.intersects(attribuite.frame) {
                continue
            }
            
            let cellCenterX = attribuite.center.x
            let distance = abs(cellCenterX - centerX)
            let scale: CGFloat = 1/(1 + distance * 0.004)
            attribuite.transform3D = CATransform3DMakeScale(scale, scale, scale)
        }
        
        return collectionViewLayoutAttribuites
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return CGPoint.zero }
        let lastRect = CGRect(x: proposedContentOffset.x, y: proposedContentOffset.y, width: collectionView.frame.width, height: collectionView.frame.height)
        let centerX = proposedContentOffset.x + collectionView.frame.width * 0.5
        guard let layoutAttributesForElements =  self.layoutAttributesForElements(in: lastRect) else { return CGPoint.zero }
        let attributes: [UICollectionViewLayoutAttributes] = layoutAttributesForElements
        var adjustOffsetX = CGFloat(MAXFLOAT)
        var tempOffsetX : CGFloat = 0.0
        for attribute in attributes {
            tempOffsetX = attribute.center.x - centerX
            if abs(tempOffsetX) < abs(adjustOffsetX) {
                adjustOffsetX = tempOffsetX
            }
        }
        return CGPoint(x: proposedContentOffset.x + adjustOffsetX, y: proposedContentOffset.y)
    }
}

class NYScaleCenterCollectionCell: UICollectionViewCell {
    
    lazy var imageView: UIImageView = {
        let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    static let identifier = "kNYScaleCenterCollectionCell"
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .gray
        layer.cornerRadius = frame.width/2.0
        layer.masksToBounds = true
        layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 3
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String)  {
        imageView.image = UIImage(contentsOfFile: title)
    }
}
