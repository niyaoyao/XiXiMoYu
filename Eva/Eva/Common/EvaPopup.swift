//
//  EvaPopup.swift
//  Eva
//
//  Created by niyao on 4/30/25.
//

import UIKit

class EvaPopup: NSObject {
    static let shared = EvaPopup()
    var popupShowView: UIView?
    var from: CGRect?
    var to: CGRect?
    var isShowing: Bool = false
    
    lazy var btn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = .black.withAlphaComponent(0.5)
        btn.addActionHandler { [weak self] in
            self?.hide()
        }
        return btn
    }()
    
    func show(view: UIView, in container: UIView, from: CGRect? = nil, to: CGRect? = nil) {
        if isShowing {
            return
        }
        self.popupShowView = view
        if let from = from {
            self.from = from
        } else {
            self.from = container.bounds
        }
        
        if let to = to {
            self.to = to
        } else {
            self.to = container.bounds
        }
        
        container.addSubview(btn)
        btn.frame = container.bounds
        
        container.addSubview(view)
        view.frame = self.from
        view.alpha = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            view.alpha = 1
            view.frame = self?.to
        } completion: { [weak self] _ in
            self?.isShowing = true
        }

    }
    
    func hide() {
        popupShowView?.removeFromSuperview()
        popupShowView = nil
        isShowing = false
    }
    
    static func show(view: UIView) {
        guard let window = UIWindow.current() else { return }
        guard let container = window.rootViewController.view else { return }
        EvaPopup.shared.show(view: view, in: container)
    }
    
    static func hide() {
        EvaPopup.shared.hide()
    }
}
