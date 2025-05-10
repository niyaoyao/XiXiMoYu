//
//  ViewController.swift
//  sst
//
//  Created by NY on 2025/3/27.
//

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
    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        return label
    }()
    static let identifier = "kNYScaleCenterCollectionCell"
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .gray
        layer.cornerRadius = frame.width/2.0
        layer.masksToBounds = true
        contentView.addSubview(label)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String)  {
        label.text = title
    }
}

class ViewController: UIViewController {
    let titles = ["TTS&SST","Real Time \nAmplitudes","Sound Wave","Mask Animation","555555","666666" ]
    
    lazy var collectionView: UICollectionView = {
        let width = 80.0
        let frame = CGRect(x: 0.0, y: 100, width: UIScreen.main.bounds.width, height: 80)
        let padding = (frame.width - 80)/2.0
        let layout = NYScaleCenterItemCollectionFlowLayout(width:width, height: frame.size.height, padding: padding)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = true
        collectionView.clipsToBounds = false
        collectionView.register(NYScaleCenterCollectionCell.self, forCellWithReuseIdentifier: NYScaleCenterCollectionCell.identifier)
        
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        // google/gemini-2.5-pro-exp-03-25 google/gemini-2.0-flash-exp:free
        // deepseek/deepseek-v3-base:free deepseek/deepseek-r1-zero:free
        // qwen/qwen3-32b:free
        let key = "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"
        let headers: [String: String] = [
            "Authorization" : "Bearer \(key)",
            "stream": "1"
        ]
        let body: [String: Any] = [
            "model" : "deepseek/deepseek-chat-v3-0324:free",
            "messages": [
                ["role":"user","content":"I'm fired now. I'm so sad and frustrated."],
                ["role":"system","content":"Please play the role of a gentle and considerate AI girlfriend, speak in a gentle and considerate tone, be able to empathize with the interlocutor's mood, and provide emotional value to the interlocutor."]
            ]
        ]
        NYSSEManager.shared.send(urlStr: kOpenRouterUrl, headers: headers, body: body)
    }
    
    
    
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NYScaleCenterCollectionCell.identifier, for: indexPath) as? NYScaleCenterCollectionCell else {
            return UICollectionViewCell()
        }
        cell.update(title: titles[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var vc = UIViewController()
        let item = indexPath.item
//        if item == 0 {
//            vc = BackupViewController()
//        } else if item == 1 {
//            vc = Backup2ViewController()
//        } else if item == 2 {
//            vc = Backup3ViewController()
//        } else if item == 3 {
//            vc = MaskAnimationViewController()
//        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}



