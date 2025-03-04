//
//  DREmotionPoseAlgorithm.swift
//  DREmotionKit
//
//  Created by niyao on 11/1/17.
//  Copyright © 2017 dourui. All rights reserved.
//

import Foundation

class Point {
    public var x: Double!
    public var y: Double!
    
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }
    
    init(withDictionary dictionary: Dictionary<String, Double>) {
        x = dictionary["x"]
        y = dictionary["y"]
    }
}

extension DREmotionModelRender {
    fileprivate func setFaceAngele(_ landmarks: Array<Dictionary<String, Double>>) {
        let  r_m = 0.4
        let r_n = 0.5
        
        let leftE: Dictionary<String, Double> = landmarks[36]
        let rightE: Dictionary<String, Double> = landmarks[45]
        let noseT: Dictionary<String, Double> = landmarks[30]
        let mouthL: Dictionary<String, Double> = landmarks[48]
        let mouthR: Dictionary<String, Double> = landmarks[54]
        
        let leftEye: Point = Point(withDictionary: leftE)
        let rightEye: Point = Point(withDictionary: rightE)
        let noseTip: Point = Point(withDictionary: noseT)
        let mouthLeft: Point = Point(withDictionary: mouthL)
        let mouthRight: Point = Point(withDictionary: mouthR)
        
        let noseBase: Point = Point(x: (leftEye.x + rightEye.x) / 2.0, y: (leftEye.y + rightEye.y) / 2.0)
        let mouth: Point = Point(x: (mouthLeft.x + mouthRight.x) / 2.0, y: (mouthLeft.y + mouthRight.y) / 2.0)
        
        let n: Point = Point(x: Int(mouth.x + (noseBase.x - mouth.x) * r_m),
                             y: Int(mouth.y + (noseBase.y - mouth.y) * r_m))
        
        let thetaC = (noseBase.y - n.y) * (noseTip.y - n.y)
        let thetaB = (noseBase.x - n.x) * (noseTip.x - n.x)
        let thetaA = Double(thetaB + thetaC)
        let theta: Double = acos(thetaA / hypot(noseTip.x - n.x, noseTip.y - n.y) / hypot(noseBase.x - n.x, noseBase.y - n.y))
        
        let tau: Double = atan2(Double(n.y - noseTip.y), Double(n.x - noseTip.x))
        
        let m1E = (noseTip.y - n.y) * (noseTip.y - n.y)
        let m1D = (noseBase.y - mouth.y) * (noseBase.y - mouth.y)
        let m1C = (noseBase.x - mouth.x) * (noseBase.x - mouth.x)
        let m1B = (noseTip.x - n.x) * (noseTip.x - n.x)
        let m1A = Double(m1B + m1E)
        let m1: Double = m1A / (m1C + m1D)
        
        let m2: Double = cos(theta) * cos(theta)
        
        let a: Double = r_n * r_n * (1 - m2)
        let b: Double = m1 - r_n * r_n + 2 * m2 * r_n * r_n
        let c: Double = -(m2 * r_n * r_n)
        
        
        let deltaA = sqrt(b * b - 4 * a * c)
        let deltaB = sqrt((deltaA - b) / (2 * a))
        let delta: Double = acos(deltaB)
        
        var fn: Array<Double> = [Double]()
        fn.append(sin(delta) * cos(tau))
        fn.append(sin(delta) * sin(tau))
        fn.append(-cos(delta))
        
        var sfn: Array<Double> = [Double]()
        let alpha: Double = Double.pi / 12.0
        sfn.append(0)
        sfn.append(sin(alpha))
        sfn.append(-cos(alpha))
        
        var w: Double!
        var x: Double!
        var y: Double!
        var z: Double!
        
        let angleA = sfn[0] * fn[0]
        let angleB = sfn[1] * fn[1]
        let angleC = sfn[2] * fn[2]
        
        let angleD = sfn[0] * sfn[0]
        let angleE = sfn[1] * sfn[1]
        let angleF = sfn[2] * sfn[2]
        
        let angleG = fn[0] * fn[0]
        let angleH = fn[1] * fn[1]
        let angleI = fn[2] * fn[2]
        let angleJ = (angleA + angleB + angleC) / sqrt(angleD + angleE + angleF) / sqrt(angleG + angleH + angleI)
        let angle: Double = acos(angleJ)
        w = cos(0.5  *  angle)
        x = sfn[1] * fn[2] - sfn[2] * fn[1]
        y = sfn[2] * fn[0] - sfn[0] * fn[2]
        z = sfn[0] * fn[1] - sfn[1] * fn[0]
        let xx = x * x
        let yy = y * y
        let zz = z * z
        let l: Double = sqrt(xx + yy + zz)
        x = sin(0.5 * angle) * x / l
        y = sin(0.5 * angle) * y / l
        z = sin(0.5 * angle) * z / l
        
        
        var yaw: Double!
        var pitch: Double!
        var roll: Double!
        let wx = w * x
        let yz = y * z
        let wy = w * y
        let zx = z * x
        let wz = w * z
        let xy = x * y
        
        roll = atan2(2 * (wx + yz), 1 - 2 * (xx + yy))
        pitch = asin(2 * (wy - zx))
        yaw = atan2(2 * (wz + xy), 1 - 2 * (yy + zz))
        
        //        if(yaw < Math.PI / 18) {
        if(sfn[0] < 0.1 && sfn[1] < 0.1) {
            roll = 1.5 * atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x)
        }
        yaw = yaw * 180 / Double.pi
        pitch = -pitch * 180 / Double.pi
        roll = roll * 180 / Double.pi
        
        //        print("pitch: \(pitch)")
        //        print("roll: \(roll)")
        //        print("yaw: \(pitch)")
        
        self.setModelPose(.headAngleX, value: pitch)
        self.setModelPose(.headAngleY, value: roll)
        self.setModelPose(.headAngleZ, value: yaw)
        
        self.setModelPose(.bodyAngleX, value: pitch / 20.0)
        self.setModelPose(.bodyAngleY, value: roll / 20.0)
        self.setModelPose(.bodyAngleZ, value: yaw / 20.0)
        let time = Double(self.getUserTimeMSec())
        let breathValue = (cos(time) + 1.0) / 4.0
        self.setModelPose(.breath, value: breathValue)
        //        print("breathValue: \(breathValue)")
        //        let hair = cos(time) / 10.0
        //        self.setModelPose(.hairFront, value: hair)
        //        self.setModelPose(.hairBackLeft, value: hair)
    }
    
    fileprivate func setMouth(_ landmarks: Array<Dictionary<String, Double>>) {
        // Mouth
        let mouthMiddleDown: Dictionary<String, Double> = landmarks[66]
        let mouthMiddleTop: Dictionary<String, Double> = landmarks[62]
        let mouthMiddleTopOuter: Dictionary<String, Double> = landmarks[51]
        let mouthMD: Point = Point(withDictionary: mouthMiddleDown)
        let mouthMT: Point = Point(withDictionary: mouthMiddleTop)
        let mouthMTO: Point = Point(withDictionary: mouthMiddleTopOuter)
        
        let mouthA = abs(Double(mouthMD.y - mouthMT.y))
        let mouthB = abs(mouthMTO.y - mouthMT.y)
        let mouthC = abs(mouthMD.y - mouthMTO.y)
        var mouthEmotion: Double =  (mouthA / (mouthB + mouthC))
        
        //        print("mouthEmotion: \(mouthEmotion)\n")
        let mouthThresholdBottom = 0.25
        if mouthEmotion < mouthThresholdBottom {
            mouthEmotion = 0
        }
        
        let mouthThresholdTop = 0.55
        if mouthEmotion > mouthThresholdTop {
            mouthEmotion = 1
        }
        
        self.setModelPose(.mouthOpenY, value: mouthEmotion)
        
        let smile: Double = mouthEmotion < mouthThresholdBottom ? 0.5 : mouthEmotion
        self.setModelPose(.mouthForm, value: smile)
        let shy: Double = mouthEmotion
        self.setModelPose(.faceShy, value: shy)
    }
    
    fileprivate func setRightEye(_ landmarks: Array<Dictionary<String, Double>>) {
        let reyeThreshold = 0.24
        let reyeCloseThreshold = 0.215
        
        // Right eye (actually user left eye )
        let rightEyeMiddleDown: Dictionary<String, Double> = landmarks[46]
        let rightEyeMiddleTop: Dictionary<String, Double> = landmarks[44]
        let rightEyeLeftPoint: Dictionary<String, Double> = landmarks[42]
        let rightEyeRightPoint: Dictionary<String, Double> = landmarks[45]
        let rightEyeMD: Point = Point(withDictionary: rightEyeMiddleDown)
        let rightEyeMT: Point = Point(withDictionary: rightEyeMiddleTop)
        let rightEyeLP: Point = Point(withDictionary: rightEyeLeftPoint)
        let rightEyeRP: Point = Point(withDictionary: rightEyeRightPoint)
        var rightEyeEmotion: Double = Double(rightEyeMD.y - rightEyeMT.y) /
            (rightEyeLP.x - rightEyeRP.x)
        //        print("rightEyeEmotion: \(rightEyeEmotion)\n")
        rightEyeEmotion = abs(rightEyeEmotion)
        var rightEyeSmile = 0.0
        
        if rightEyeEmotion >= reyeThreshold {
            rightEyeEmotion = 2
        } else if rightEyeEmotion < reyeThreshold && rightEyeEmotion > reyeCloseThreshold {
            rightEyeEmotion = 0.35
            
            rightEyeSmile = 0.5
        } else {
            rightEyeSmile = 0.75
            rightEyeEmotion = 0
        }
        
        self.setModelPose(.eyeOpenRight, value: rightEyeEmotion)
        self.setModelPose(.eyeSmileRight, value: rightEyeSmile)
    }
    
    fileprivate func setLeftEye(_ landmarks: Array<Dictionary<String, Double>>) {
        let leyeThreshold = 0.24
        let leyeCloseThreshold = 0.215
        // Left eye (actually user right eye )
        let leftEyeMiddleDown: Dictionary<String, Double> = landmarks[41]
        let leftEyeMiddleTop: Dictionary<String, Double> = landmarks[37]
        let leftEyeLeftPoint: Dictionary<String, Double> = landmarks[39]
        let leftEyeRightPoint: Dictionary<String, Double> = landmarks[36]
        let leftEyeMD: Point = Point(withDictionary: leftEyeMiddleDown)
        let leftEyeMT: Point = Point(withDictionary: leftEyeMiddleTop)
        let leftEyeLP: Point = Point(withDictionary: leftEyeLeftPoint)
        let leftEyeRP: Point = Point(withDictionary: leftEyeRightPoint)
        var leftEyeEmotion: Double = Double(leftEyeMD.y - leftEyeMT.y) /
            (leftEyeLP.x - leftEyeRP.x)
        //        print("leftEyeEmotion: \(leftEyeEmotion)\n")
        
        leftEyeEmotion = abs(leftEyeEmotion)
        var leftEyeSmile = 0.0
        if leftEyeEmotion >= leyeThreshold {
            leftEyeEmotion = 2
        } else if leftEyeEmotion < leyeThreshold && leftEyeEmotion > leyeCloseThreshold {
            leftEyeEmotion = 0.35
            leftEyeSmile = 0.5
        } else {
            leftEyeEmotion = 0
            leftEyeSmile = 0.75
        }
        
        self.setModelPose(.eyeOpenLeft, value: leftEyeEmotion)
        self.setModelPose(.eyeSmileLeft, value: leftEyeSmile)
    }
    
    fileprivate func setBrow(_ landmarks: Array<Dictionary<String, Double>>) {
        let noseTop : Dictionary<String, Double> = landmarks[27]
        let noseBottom : Dictionary<String, Double> = landmarks[29]
        let noseTp: Point = Point(withDictionary: noseTop)
        let noseBtm: Point = Point(withDictionary: noseBottom)
        let browDenominator = abs(Double(noseTp.y - noseBtm.y))
        
        let rightBrow : Dictionary<String, Double> = landmarks[24]
        let rightBrowP: Point = Point(withDictionary: rightBrow)
        var rightBrowY = abs(Double(rightBrowP.y - noseTp.y)) / browDenominator
        rightBrowY /= 2.0
        //        print("rightBrowY: \(rightBrowY)")
        //        self.setModelPose(.browRightY, value: rightBrowY)
        //        self.setModelPose(.browRightX, value: 1)
        //        self.setModelPose(.browRightForm, value: 1)
        
        let leftBrow : Dictionary<String, Double> = landmarks[19]
        let leftBrowP: Point = Point(withDictionary: leftBrow)
        var leftBrowY = abs(Double(leftBrowP.y - noseTp.y)) / browDenominator
        leftBrowY /= 2.0
        //        print("leftBrowY:\(leftBrowY)")
        //        self.setModelPose(.browLeftY, value: leftBrowY)
        //        self.setModelPose(.browLeftX, value: 1)
        //        self.setModelPose(.browLeftForm, value: 1)
    }
    
    func estimateGaze(landmarks: Array<Dictionary<String, Double>>) {
        if landmarks.count > 0 {
            self.setFaceAngele(landmarks)
            self.setMouth(landmarks)
            self.setRightEye(landmarks)
            self.setLeftEye(landmarks)
            self.setBrow(landmarks)
        }
    }
    
    /// Set Right Eye (Actually User Left Eye )
    public func setRightEye(middleDownX: Double,
                            middleDownY: Double,
                            middleTopX: Double,
                            middleTopY: Double,
                            leftPointX: Double,
                            leftPointY: Double,
                            rightPointX: Double,
                            rightPointY: Double,
                            modelIndex: Int = 0) {
        let reyeThreshold = 0.24
        let reyeCloseThreshold = 0.215
        
        // Right eye (actually user left eye )
        let rightEyeMD: Point = Point(x: middleDownX, y: middleDownY)
        let rightEyeMT: Point = Point(x: middleTopX, y: middleTopY)
        let rightEyeLP: Point = Point(x: leftPointX, y: leftPointY)
        let rightEyeRP: Point = Point(x: rightPointX, y: rightPointY)
        var rightEyeEmotion: Double = Double(rightEyeMD.y - rightEyeMT.y) /
            (rightEyeLP.x - rightEyeRP.x)
        //        print("rightEyeEmotion: \(rightEyeEmotion)\n")
        rightEyeEmotion = abs(rightEyeEmotion)
        
        if rightEyeEmotion >= reyeThreshold {
            rightEyeEmotion = 2
        } else if rightEyeEmotion < reyeThreshold && rightEyeEmotion > reyeCloseThreshold {
            rightEyeEmotion = 0.35
        } else {
            rightEyeEmotion = 0
        }
        
        if modelIndex == 0 {
            self.setModelPose(.eyeOpenRight, value: rightEyeEmotion)
            self.setModelPose(.eyeOpenRight_3, value: rightEyeEmotion)
        } else if modelIndex == 1 {
            self.setSecondModelPose(.eyeOpenRight, value: rightEyeEmotion)
            self.setSecondModelPose(.eyeOpenRight_3, value: rightEyeEmotion)
        }
    }
    
    /// Set Left Eye (Actually User Right Eye )
    public func setLeftEye(middleDownX: Double,
                           middleDownY: Double,
                           middleTopX: Double,
                           middleTopY: Double,
                           leftPointX: Double,
                           leftPointY: Double,
                           rightPointX: Double,
                           rightPointY: Double,
                           modelIndex: Int = 0) {
        let leyeThreshold = 0.24
        let leyeCloseThreshold = 0.215
        // Left eye (actually user right eye )
        let leftEyeMD: Point = Point(x: middleDownX, y: middleDownY)
        let leftEyeMT: Point = Point(x: middleTopX, y: middleTopY)
        let leftEyeLP: Point = Point(x: leftPointX, y: leftPointY)
        let leftEyeRP: Point = Point(x: rightPointX, y: rightPointY)
        var leftEyeEmotion: Double = Double(leftEyeMD.y - leftEyeMT.y) /
            (leftEyeLP.x - leftEyeRP.x)
        //        print("leftEyeEmotion: \(leftEyeEmotion)\n")
        
        leftEyeEmotion = abs(leftEyeEmotion)
        if leftEyeEmotion >= leyeThreshold {
            leftEyeEmotion = 2
        } else if leftEyeEmotion < leyeThreshold && leftEyeEmotion > leyeCloseThreshold {
            leftEyeEmotion = 0.35
        } else {
            leftEyeEmotion = 0
        }
        
        if modelIndex == 0 {
            self.setModelPose(.eyeOpenLeft, value: leftEyeEmotion)
            self.setModelPose(.eyeOpenLeft_3, value: leftEyeEmotion)
        } else if modelIndex == 1 {
            self.setSecondModelPose(.eyeOpenLeft, value: leftEyeEmotion)
            self.setSecondModelPose(.eyeOpenLeft_3, value: leftEyeEmotion)
        }
    }
    
    class func rightEye(middleDownX: Double,
                         middleDownY: Double,
                         middleTopX: Double,
                         middleTopY: Double,
                         leftPointX: Double,
                         leftPointY: Double,
                         rightPointX: Double,
                         rightPointY: Double) -> Double {
        let reyeThreshold = 0.24
        let reyeCloseThreshold = 0.215
        
        // Right eye (actually user left eye )
        let rightEyeMD: Point = Point(x: middleDownX, y: middleDownY)
        let rightEyeMT: Point = Point(x: middleTopX, y: middleTopY)
        let rightEyeLP: Point = Point(x: leftPointX, y: leftPointY)
        let rightEyeRP: Point = Point(x: rightPointX, y: rightPointY)
        var rightEyeEmotion: Double = Double(rightEyeMD.y - rightEyeMT.y) /
            (rightEyeLP.x - rightEyeRP.x)
        //        print("rightEyeEmotion: \(rightEyeEmotion)\n")
        rightEyeEmotion = abs(rightEyeEmotion)
        
        if rightEyeEmotion >= reyeThreshold {
            rightEyeEmotion = 2
        } else if rightEyeEmotion < reyeThreshold && rightEyeEmotion > reyeCloseThreshold {
            rightEyeEmotion = 0.35
        } else {
            rightEyeEmotion = 0
        }
        return rightEyeEmotion
    }
    
    class func leftEye(middleDownX: Double,
                        middleDownY: Double,
                        middleTopX: Double,
                        middleTopY: Double,
                        leftPointX: Double,
                        leftPointY: Double,
                        rightPointX: Double,
                        rightPointY: Double) -> Double {
        let leyeThreshold = 0.24
        let leyeCloseThreshold = 0.215
        // Left eye (actually user right eye )
        let leftEyeMD: Point = Point(x: middleDownX, y: middleDownY)
        let leftEyeMT: Point = Point(x: middleTopX, y: middleTopY)
        let leftEyeLP: Point = Point(x: leftPointX, y: leftPointY)
        let leftEyeRP: Point = Point(x: rightPointX, y: rightPointY)
        var leftEyeEmotion: Double = Double(leftEyeMD.y - leftEyeMT.y) /
            (leftEyeLP.x - leftEyeRP.x)
        //        print("leftEyeEmotion: \(leftEyeEmotion)\n")
        
        leftEyeEmotion = abs(leftEyeEmotion)
        if leftEyeEmotion >= leyeThreshold {
            leftEyeEmotion = 2
        } else if leftEyeEmotion < leyeThreshold && leftEyeEmotion > leyeCloseThreshold {
            leftEyeEmotion = 0.35
        } else {
            leftEyeEmotion = 0
        }
        
        return leftEyeEmotion
    }
}
