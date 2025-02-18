//
//  DRVideoExtension.swift
//  doutu
//
//  Created by niyao on 12/21/17.
//  Copyright © 2017 dourui. All rights reserved.
//

import Foundation
import AVKit
import MobileCoreServices

private let kVideoGIFQueue = DispatchQueue(label:"group.dourui.doutu.video.gif.queue", attributes: .concurrent)
private let kVideoGIFURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("doutu_avatar.gif")

private let timeInterval = 600
private let tolerance = 0.01

extension DRMovieRecorder {
    
    /// 调用该方法获得视频第一帧缩略图
    ///
    /// - Parameter completion: 回调函数
    public class func videoThumbImage(_ videoURL: URL, completion: @escaping (_ image: UIImage, _ imageFileURL: URL) -> ()) {
        let asset : AVURLAsset = AVURLAsset(url: videoURL)
        let generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let thumbTime = CMTime(seconds: 0, preferredTimescale: 60)
        generator.apertureMode = .encodedPixels
        let generatorHandler : AVAssetImageGeneratorCompletionHandler = { ( requestedTime, image,  actualTime, result, error) in
            if result == .succeeded {
                let thumbImage = UIImage(cgImage: image!)
                let url = DRMovieRecorder.videoThumbURL()
                
                do {
                    try UIImagePNGRepresentation(thumbImage)?.write(to: url)
                    DispatchQueue.main.async {
                        completion(thumbImage, url)
                    }
                } catch {
                    print("\(error)")
                }
            }
        }
        
        generator.generateCGImagesAsynchronously(forTimes: [thumbTime as NSValue],
                                                 completionHandler: generatorHandler)
    }
    
    public class func createGIF(_ videoURL: URL, frameCount: Int, delay: Float, loopCount: Int, completion: @escaping ((_ url: URL?, _ error: Error?) -> ())) {
        let fileProperties = [
            kCGImagePropertyGIFDictionary : [kCGImagePropertyGIFLoopCount : loopCount]
        ]
        let frameProperties = [
            kCGImagePropertyGIFDictionary : [kCGImagePropertyGIFDelayTime : delay],
            kCGImagePropertyColorModel : kCGImagePropertyColorModelRGB
            ] as [CFString : Any]
        
        let asset: AVURLAsset = AVURLAsset(url: videoURL)
        let videoLength: Float = Float(asset.duration.value) / Float(asset.duration.timescale)
        let increment: Float = videoLength / Float(frameCount)
        var timePoints: Array<CMTime> = []
        for i in 0...frameCount {
            let seconds: Double = Double(increment) * Double(i)
            let time: CMTime = CMTime(seconds: Double(seconds), preferredTimescale: CMTimeScale(timeInterval))
            timePoints.append(time)
        }
        
        kVideoGIFQueue.async {
            let fileURL = kVideoGIFURL
            let destination: CGImageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeGIF, frameCount, nil)!
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            
            let generator : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            let toleranceTime = CMTime(seconds: tolerance, preferredTimescale: CMTimeScale(timeInterval))
            generator.requestedTimeToleranceAfter = toleranceTime
            generator.requestedTimeToleranceBefore = toleranceTime
            
            var previousImageRefCopy: CGImage?
            for time: CMTime in timePoints {
                var imageRef: CGImage?
                do {
                    try imageRef = generator.copyCGImage(at: time, actualTime: nil)
                    let rect = CGRect(x: 0, y: 0, width: (imageRef?.width)!, height: (imageRef?.width)!)
                    imageRef = tailorCGImage(imageRef!, rect: rect )
                    if imageRef != nil {
                        previousImageRefCopy = imageRef?.copy()
                    } else if previousImageRefCopy != nil {
                        imageRef = previousImageRefCopy
                    } else {
                        print("previousImageRefCopy && image nil")
                        return
                    }
                    CGImageDestinationAddImage(destination, imageRef!, frameProperties as CFDictionary)
                    
                } catch {
                    print("failed to copy image")
                }
            } // for end
            
            if !CGImageDestinationFinalize(destination) {
                print("Failed CGImageDestinationFinalize")

                let error: Error = NSError(domain: "CGImageDestinationFinalize", code: 10001, userInfo: [NSLocalizedDescriptionKey: "Failed CGImageDestinationFinalize"])
                completion(nil, error)
                return
            }
            
            completion(fileURL, nil)
        }
        
    }
    
    class func tailorCGImage(_ image: CGImage, rect: CGRect) -> CGImage {
        let cgImage: CGImage = image
        let subImageRef: CGImage = cgImage.cropping(to: rect)!//CGImageCreateWithImageInRect(self.cgImage!, rect)!
        let smallBounds: CGRect = CGRect(x: 0, y: 0,
                                         width: subImageRef.width, //CGImageGetWidth(subImageRef),
            height: subImageRef.height) //CGImageGetHeight(subImageRef));
        
        UIGraphicsBeginImageContext(smallBounds.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        //        CGContextDrawImage(context, smallBounds, subImageRef);
        context.draw(subImageRef, in: smallBounds)
//        let smallImage: UIImage = UIImage(cgImage: subImageRef)
        UIGraphicsEndImageContext();
        
        return subImageRef
    }
}

extension DRMovieRecorder {
    class public func videoComposition(audioURL: URL,
                                       backgroundMusicURL: URL? = nil,
                                       tempURL: URL,
                                       outputURL: URL,
                                       originAudioVolume: Float = 1.0,
                                       backgroundMusicVolume: Float = 0.1,
                                       completion: (() -> ())?) {
        let startTime: CMTime = kCMTimeZero
        let composition: AVMutableComposition = AVMutableComposition()
        
        // Video
        let videoAsset: AVURLAsset = AVURLAsset(url: tempURL)
        let videoTimeRange: CMTimeRange = CMTimeRange(start: startTime, duration: videoAsset.duration)
        let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let videoAssetTrack: AVAssetTrack = videoAsset.tracks(withMediaType: .video).first!
        
        // Audio
        let audioAsset: AVURLAsset = AVURLAsset(url: audioURL)
        let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let audioAssetTrack: AVAssetTrack = audioAsset.tracks(withMediaType: .audio).first!
        
        // Audio Mix
        var audioMixParams: [AVMutableAudioMixInputParameters] = []
        let originAudioMixInputParameters = AVMutableAudioMixInputParameters()
        originAudioMixInputParameters.trackID = audioTrack.trackID
        originAudioMixInputParameters.setVolume(originAudioVolume, at: kCMTimeZero)
        audioMixParams.append(originAudioMixInputParameters)
        
        do {
            try videoTrack.insertTimeRange(videoTimeRange, of: videoAssetTrack, at: startTime)
            try audioTrack.insertTimeRange(videoTimeRange, of: audioAssetTrack, at: startTime)
            
            // BGM
            if backgroundMusicURL != nil {
                let bgmAsset: AVURLAsset = AVURLAsset(url: backgroundMusicURL!)
                // AVMutableCompositionTrack
                let bgmTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
                let bgmAssetTrack: AVAssetTrack = bgmAsset.tracks(withMediaType: .audio).first!
                try bgmTrack.insertTimeRange(videoTimeRange, of: bgmAssetTrack, at: startTime)
                
                let bgmAudioMixInputParameters = AVMutableAudioMixInputParameters()
                bgmAudioMixInputParameters.trackID = bgmTrack.trackID
                bgmAudioMixInputParameters.setVolume(backgroundMusicVolume, at: kCMTimeZero)
                audioMixParams.append(bgmAudioMixInputParameters)
            }
            
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = audioMixParams
            
            let assetExport: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
            assetExport.outputFileType = .mp4
            assetExport.outputURL = outputURL
            assetExport.shouldOptimizeForNetworkUse = true
            assetExport.audioMix = audioMix
            assetExport.exportAsynchronously {
                completion?()
            }
        } catch {
            DebugLog("\(error)")
        }
    }
}
