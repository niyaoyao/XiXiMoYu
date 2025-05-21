//
//  EvaSettingViewController.swift
//  Eva
//
//  Created by niyao on 5/6/25.
//

import UIKit

class EvaSettingViewController: EvaBaseViewController {
    lazy var listView: UICollectionView = {
        let layout = RoundCornerCollectionLayout()
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(hex: "#F7F7F7", alpha: 1)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        // Register cell and header view
        
        collectionView.register(EvaSettingsCommonCell.self, forCellWithReuseIdentifier: EvaSettingsCommonCell.reuseIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell.reuseIdentifier")
        
        return collectionView
    }()
    
    
    var basicSection: [EvaUserProfileListItemViewModel] {
        var version = EvaUserProfileListItemViewModel(type: .version)
        version.title = "产品版本"
        version.showBottomLine = true
        version.content = "V1.0.0"
        version.hideArrow = true
        var userProtocol = EvaUserProfileListItemViewModel(type: .userProtocol)
        userProtocol.title = "用户协议"
        userProtocol.showBottomLine = true
        var privacy = EvaUserProfileListItemViewModel(type: .privacy)
        privacy.title = "隐私政策"
        privacy.showBottomLine = true
        var icp = EvaUserProfileListItemViewModel(type: .icp)
        icp.title = "ICP备案号"
        icp.content = "鲁ICP备2025154436号-2A"
        icp.hideArrow = true
        
        return [version, userProtocol, privacy, icp]
    }
    
    var unregisterSection: [EvaUserProfileListItemViewModel] {
        var unregister = EvaUserProfileListItemViewModel(type: .about)
        unregister.title = "关于我们"
        
        return [unregister]
    }
    
    var viewModel: [[EvaUserProfileListItemViewModel]] = []
    
    lazy var logoutBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.backgroundColor = UIColor(hex: "#EDEDED", alpha: 1)
        btn.setTitle("退出登录", for: .normal)
        btn.setTitleColor(UIColor(hex: "#151D33", alpha: 1), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(logout), for: .touchUpInside)
        btn.layer.cornerRadius = 21
        btn.isHidden = true
        return btn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "账号设置"
        self.viewModel = [basicSection, unregisterSection]
        self.view.addSubview(listView)
        self.view.addSubview(logoutBtn)
        
        listView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        logoutBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 213, height: 42))
            make.bottom.equalTo(self.view).offset(-111)
            make.centerX.equalTo(self.view)
        }
    }
    
    @objc func logout() {
        print("Logout!!")
    }

}


extension EvaSettingViewController : UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.viewModel[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemVM = self.viewModel[indexPath.section][indexPath.item]
        if let commonCell: EvaSettingsCommonCell = collectionView.dequeueReusableCell(withReuseIdentifier: EvaSettingsCommonCell.reuseIdentifier, for: indexPath) as? EvaSettingsCommonCell {
            commonCell.update(vm: itemVM)
            return commonCell
        } else {
            return UICollectionViewCell()
        }
        
        
    }
}

extension EvaSettingViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemVM = self.viewModel[indexPath.section][indexPath.item]
        switch itemVM.type {
        case .userProtocol:
            let web = EvaWebViewController(url: "https://eva-ai-app.github.io/2025/05/22/TermsofUse/")
            self.navigationController?.pushViewController(web, animated: true)
        case .privacy:
            let web = EvaWebViewController(url: "https://eva-ai-app.github.io/2025/05/22/PrivacyPolicy/")
            self.navigationController?.pushViewController(web, animated: true)
        case .about:
            let web = EvaWebViewController(url: "https://cyberpi.tech")
            self.navigationController?.pushViewController(web, animated: true)
//        case .unregister:
//            let alert = UIAlertController(title: "注销账户", message: "注销后，个人信息都会删除，确定注销？", preferredStyle: .alert)
//            let ok = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
//                self?.unregisterAccount()
//            }
//            let cancel = UIAlertAction(title: "取消", style: .cancel)
//            alert.addAction(ok)
//            alert.addAction(cancel)
//            self.present(alert, animated: true)
        default:
            debugPrint("Unknown")
        }
    }
    
    func unregisterAccount()  {
        

    }
}

extension EvaSettingViewController : UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return EvaSettingsCommonCell.size
        
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
    }

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

}

extension EvaSettingViewController: RoundCornerCollectionDelegateLayout {
    func collectionView(_: UICollectionView, layout: RoundCornerCollectionLayout, configModelForSection: NSInteger) -> RoundCornerCollectionDecorateModel? {
        
        let configModel = RoundCornerCollectionDecorateModel(borderEdgeInsets: UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 15.0),
                                                             backgroundColor: .white,
                                                             cornerRadius: 8)
        return configModel
    }
}
