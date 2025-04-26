//
//  EvaBaseViewController.swift
//  Eva
//
//  Created by niyao on 4/25/25.
//

import UIKit

class EvaBaseViewController: UIViewController {
    var statusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    var statusbarHidden: Bool {
        return false
    }
    
    var backButtonTapAction: (()->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        self.setBackButton()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.statusBarStyle
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return statusbarHidden
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        debugPrint("\(self) 销毁成功！")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @objc var isRootNavigationController: Bool {
        return self.navigationController?.topViewController == self && self.navigationController?.viewControllers.count == 1
    }
    
    @objc func backToPrevious() {
        guard let count = self.navigationController?.viewControllers.count else { return }
        if self.navigationController?.topViewController == self && count > 1 {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func goBack() {
        if backButtonTapAction != nil {
            self.backButtonTapAction?()
        }
        backToPrevious()
    }
    
    @objc func goBackRoot() {
        
        if backButtonTapAction != nil {
            self.backButtonTapAction?()
        }
        backToPrevious()
    }
    
    @objc func setBackButton() {
        setCustomLeftNavButton(image: UIImage(named: "back")) { [weak self] in
            self?.goBack()
        }
    }
    
    func setCustomRightNavButton(image: UIImage? = nil,
                                 tintColor: UIColor = UIColor(hex: "#333333"),
                                 title: String? = "",
                                 titleColor:UIColor = UIColor(hex: "#333333"),
                                 titleFont:UIFont = .systemFont(ofSize: 12),
                                 tapHandler: (() -> Void)? = nil) {
         let customButton = UIButton(type: .system)
         customButton.tintColor = tintColor
         customButton.setImage(image, for: .normal) // Set your image
         customButton.frame = CGRect(x: 0, y: 0, width: image?.size.width ?? 30.0, height: image?.size.height ?? 30.0)
     

         let text = title ?? ""
         if text.count > 0 {
             let imageSize = image?.size ?? CGSize.zero
             customButton.setTitle(title, for: .normal) // Set your title
             customButton.setTitleColor(titleColor, for: .normal) // Set title color
             let leftInset = imageSize.width > 0 ? 8.0 : 0.0
             customButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0) // Adjust title position
             customButton.titleLabel?.font = titleFont
             let font = UIFont.systemFont(ofSize: 17.0) // 替换成你的字体和大小
             let attributes: [NSAttributedString.Key: Any] = [.font: font]
             let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
             let textRect = text.boundingRect(with: maxSize,
                                              options: [.usesLineFragmentOrigin, .usesFontLeading],
                                              attributes: attributes,
                                              context: nil)
             let textWidth = textRect.width
             customButton.frame = CGRect(x: 0, y: 0, width: imageSize.width + textWidth + 8, height: 30)
         }// Adjust size as needed
         customButton.addActionHandler(tapHandler)
         // Create a UIBarButtonItem with the custom view
         let customBarButtonItem = UIBarButtonItem(customView: customButton)

         // Set the custom UIBarButtonItem as the right bar button item
         self.navigationItem.rightBarButtonItem = customBarButtonItem
     }
    
    func setCustomLeftNavButton(image: UIImage? = nil,
                                tintColor: UIColor = UIColor(hex: "#333333"),
                                title: String? = "",
                                titleColor:UIColor = UIColor(hex: "#333333"),
                                titleFont:UIFont = .systemFont(ofSize: 12),
                                tapHandler: (() -> Void)? = nil) {
        let customButton = UIButton(type: .system)
        customButton.tintColor = tintColor
        customButton.setImage(image, for: .normal) // Set your image
        customButton.frame = CGRect(x: 0, y: 0, width: image?.size.width ?? 32.0, height: image?.size.height ?? 44.0)
        if customButton.frame.size.height < 44.0 {
            customButton.frame = CGRect(x: 0, y: 0, width: customButton.frame.size.width, height: 44.0)
        }
        
        if customButton.frame.size.width < 44.0 {
            customButton.frame = CGRect(x: 0, y: 0, width: 44, height: customButton.frame.size.height)
        }
        

        let text = title ?? ""
        if text.count > 0 {
            let imageSize = image?.size ?? CGSize.zero
            customButton.setTitle(title, for: .normal) // Set your title
            customButton.setTitle(title, for: .highlighted) // Set your title
            customButton.setTitleColor(titleColor, for: .normal)
            customButton.setTitleColor(titleColor, for: .highlighted) // Set title color
            let leftInset = imageSize.width > 0 ? 8.0 : 0.0
            customButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0) // Adjust title position
            customButton.titleLabel?.font = titleFont
            let font = UIFont.systemFont(ofSize: 17.0) // 替换成你的字体和大小
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let textRect = text.boundingRect(with: maxSize,
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             attributes: attributes,
                                             context: nil)
            let textWidth = textRect.width
            customButton.frame = CGRect(x: 0, y: 0, width: imageSize.width + textWidth + 8, height: 30)
        } else {
            if let img = image {
                let size = img.size
                
                customButton.imageEdgeInsets = UIEdgeInsets(top: (44-size.height)/2.0, left: 0, bottom: (44-size.height)/2.0, right: 44-size.width)
            }
            
                    
        }
        customButton.addActionHandler(tapHandler)
        // Create a UIBarButtonItem with the custom view
        let customBarButtonItem = UIBarButtonItem(customView: customButton)

        // Set the custom UIBarButtonItem as the right bar button item
        self.navigationItem.leftBarButtonItem = customBarButtonItem
    }
}
