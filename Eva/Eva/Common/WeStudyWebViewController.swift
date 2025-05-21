//
//  WeStudyWebViewController.swift
//  WeStudy
//
//  Created by zyb on 8/31/24.
//

import UIKit
import WebKit

class EvaWebViewController: EvaBaseViewController {
    let webConfiguration:WKWebViewConfiguration = WKWebViewConfiguration()
    lazy var webView: WKWebView = {
        let wb = WKWebView(frame: CGRect(), configuration: self.webConfiguration)
        wb.navigationDelegate = self
        return wb
    }()
    var url:String! = ""
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    init(url: String) {
        super.init()
        self.url = url
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.webView)
        self.webView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        let request = URLRequest(url: URL(string: self.url)!)
        self.webView.load(request)
        
        
    }

}

extension EvaWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}
