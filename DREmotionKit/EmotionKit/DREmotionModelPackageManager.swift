//
//  DREmotionModelPackageManager.swift
//  doutu
//
//  Created by ZhangHang on 2017/12/3.
//  Copyright © 2017年 dourui. All rights reserved.
//

import Foundation

//import Alamofire
//import Zip
//import RxSwift

private struct DREmotionModelPackageDescription: Codable {

    let id: UInt
    let version: UInt
    let name: String
    let avatarPath: String
    let texturePaths: [String]
    let modelPath: String
    let avatarPaths: [String]
    let motionPaths: [String]
}

/// 表情模型（Live2D）包控制器
final class DREmotionModelPackageManager {
    
    /// 单例
    static let shared = DREmotionModelPackageManager()
    
    private let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let documentPackageRootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("emotionModelPackages")
    private lazy var embeddedPackageRootURL: URL = {
        guard
            let path = Bundle.main.path(forResource: "EmotionModel", ofType: "bundle"),
            let bundle = Bundle(path: path) else {
            fatalError("无法找到 EmotionModel Bundle")
        }
        return bundle.bundleURL
    }()
    

    private(set) var emotionModelPackages: [DREmotionModelPackage] = []
    
    func scanLocalPackages() {
        func scanPackage(fileURL: URL) -> [DREmotionModelPackage] {
            var packages = [DREmotionModelPackage]()

            do {
                for packageFolder in (try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: [.skipsHiddenFiles])) {
                    guard try packageFolder.resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory == true else { continue }
                    let descriptionJSONPath = packageFolder.appendingPathComponent("main.json")
                    let descriptionJSONData = try Data(contentsOf: descriptionJSONPath)
                    let packageDescription = try JSONDecoder().decode(DREmotionModelPackageDescription.self, from: descriptionJSONData)
                    let package = DREmotionModelPackage(
                        packageId: packageDescription.id,
                        version: packageDescription.version,
                        name: packageDescription.name,
                        rootURL: packageFolder,
                        avatarURL: packageFolder.appendingPathComponent(packageDescription.avatarPath),
                        modelURL: packageFolder.appendingPathComponent(packageDescription.modelPath),
                        textureURLs: packageDescription.texturePaths.map({packageFolder.appendingPathComponent($0)}),
                        avatarURLs: packageDescription.avatarPaths.map({packageFolder.appendingPathComponent($0)}),
                        motionURLs: packageDescription.motionPaths.map({packageFolder.appendingPathComponent($0)}))
                    packages.append(package)
                }
                return packages
            } catch let error {
                #if DEBUG
                print(error)
                #endif
                return packages
            }
        }

        emotionModelPackages = scanPackage(fileURL: documentPackageRootURL) + scanPackage(fileURL: embeddedPackageRootURL)
    }
    
//    func addPackage(zipPackageLocalPath: URL) throws {
//        let uuidString = UUID().uuidString
//        let finalFilePath = documentPackageRootURL.appendingPathComponent(uuidString)
//        do {
//            try Zip.unzipFile(zipPackageLocalPath, destination: finalFilePath, overwrite: true, password: nil)
//            try FileManager.default.removeItem(at: zipPackageLocalPath)
//            self.scanLocalPackages()
//        } catch let error {
//            throw error
//        }
//    }
    
    func removePackage(package: DREmotionModelPackage) throws {
        do {
            try FileManager.default.removeItem(at: package.rootURL)
            self.scanLocalPackages()
        } catch let error {
            throw error
        }
    }
//
//    func download(url: String, completinHandler: @escaping () -> Void) {
//        let zipFilePath = documentPackageRootURL.appendingPathComponent(UUID().uuidString + ".zip")
//        
//        Alamofire.download(url) {(url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
//            return (zipFilePath, [.removePreviousFile])
//            }.downloadProgress { (progress) in
//                print(progress)
//            }.response { [weak self] (_) in
//                do {
//                    try self?.addPackage(zipPackageLocalPath: zipFilePath)
//                } catch {
//                    #if DEBUG
//                    print(error)
//                    #endif
//                }
//        }
//    }
}
