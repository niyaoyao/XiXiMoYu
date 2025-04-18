//
//  ViewController.swift
//  Live2DSDK
//
//  Created by NY on 03/06/2025.
//  Copyright (c) 2025 NY. All rights reserved.
//

import UIKit
import Live2DSDK
import GLKit

import AVFoundation // TTS
import Speech     // STT

import AVFoundation // TTS
import Speech     // STT
import UIKit
import AVFAudio

class ViewController: UIViewController {
    var count = 0
        
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var amplitudes: [Float] = []
    
    // 定义 UISlider
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0 // 最小值
        slider.maximumValue = 1.0 // 最大值
        slider.value = 0.5        // 默认值
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    lazy var speakBtn: UIButton = {
        let speakButton = UIButton(frame: .zero)// Speak Button
        speakButton.setTitle("朗读文字", for: .normal)
        speakButton.addTarget(self, action: #selector(speakText), for: .touchUpInside)
        return speakButton
    }()
    
    lazy var textView : UITextView = {
        // TextView 用于显示和输入文字
        let textView = UITextView(frame: .zero)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 16)
        textView.text = "和我一起开始 AI 之旅吧～"
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestPermissions()
        setupAudioSession()
    }
    
    func setupUI() {
        EAGLContext.setCurrent(EAGLContext(api: .openGLES2))
        self.view.addSubview(NYLDSDKManager.shared().stageVC.view)
        let w = (UIScreen.main.bounds.size.width - 45 )/2.0
        let btn = UIButton(frame: CGRect(x: 15, y: UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        btn.setTitle("Change Background", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .blue.withAlphaComponent(0.5)
        btn.addTarget(self, action: #selector(changeBackground), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let mbtn = UIButton(frame: CGRect(x: w + 30, y:  UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        mbtn.setTitle("Change Model", for: .normal)
        mbtn.setTitleColor(.white, for: .normal)
        mbtn.backgroundColor = .blue.withAlphaComponent(0.5)
        mbtn.addTarget(self, action: #selector(changeModel), for: .touchUpInside)
        self.view.addSubview(mbtn)
        
        // 添加 UI 元素到视图
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        let sh = 30.0
        slider.frame = CGRect(x: 15, y: mbtn.frame.origin.y - sh - 10, width: UIScreen.main.bounds.size.width - 30, height: sh)
        
        // tts
        let th = 40.0
        let sbtnw = 80.0
        view.addSubview(self.textView)
        view.addSubview(speakBtn)
        textView.frame = CGRect(x: slider.frame.origin.x, y: slider.frame.origin.y - 10.0 - th, width: UIScreen.main.bounds.size.width - 30 - sbtnw - 10, height: th)
        speakBtn.frame = CGRect(x: textView.frame.maxX + 10.0, y: textView.frame.origin.y, width: sbtnw, height: th)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    // 滑动条值变化时的回调
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let value = sender.value
        
        // 在这里处理 value（范围 0 到 1）
        print("Slider value: \(value)")
        NYLDModelManager.shared().mouthOpenRate = value
    }
    
    @objc func changeModel() {
        NYLDModelManager.shared().nextScene()
    }
    @objc func changeBackground() {
        count += 1
        let nameIndex = count % 9
        let name = "0\(nameIndex)"
        NYLDSDKManager.shared().stageVC.changeBackground(withImageName: name)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - TTS
extension ViewController {
    // 请求权限
    private func requestPermissions() {
       // 麦克风权限
       AVAudioSession.sharedInstance().requestRecordPermission { granted in
           DispatchQueue.main.async {
               if !granted {
                   self.showAlert(message: "请在设置中启用麦克风权限")
               }
           }
       }
       
       // 语音识别权限
       SFSpeechRecognizer.requestAuthorization { status in
           DispatchQueue.main.async {
               if status != .authorized {
                   self.showAlert(message: "请在设置中启用语音识别权限")
               }
           }
       }
    }

    private func setupAudioSession() {
        synthesizer.delegate = self
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        do {
           try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
           try audioSession.setActive(true)
        } catch {
           print("音频会话配置失败: \(error)")
        }
    }

    private func setupAmplitudeAudioEngine() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            guard let floatChannelData = buffer.floatChannelData else { return }
            let frameLength = Int(buffer.frameLength)
            let samples = floatChannelData[0]
            
            let batchSize = 64
            var batchAmplitudes: [Float] = []
            
            for i in stride(from: 0, to: frameLength, by: batchSize) {
                let end = min(i + batchSize, frameLength)
                var sum: Float = 0
                let count = end - i
                
                for j in i..<end {
                    sum += abs(samples[j])
                }
                
                let averageAmplitude = count > 0 ? sum / Float(count) : 0
                batchAmplitudes.append(averageAmplitude)
            }
            
            self.amplitudes.append(contentsOf: batchAmplitudes)
            print("实时振幅（最新）: \(batchAmplitudes.last ?? 0)")
            if let amplitude = batchAmplitudes.last {
                NYLDModelManager.shared().mouthOpenRate = amplitude * 10
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("音频引擎启动失败: \(error)")
        }
    }
    
    func stopAmplitudeAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    // TTS: 文字转语音
    @objc private func speakText() {
        setupAmplitudeAudioEngine()
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.count <= 0 { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN") // 中文语音
        utterance.rate = 0.5 // 语速（0.1 - 1.0）
        utterance.pitchMultiplier = 1.0 // 音调（0.5 - 2.0）
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
    // 提示用户前往设置
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "权限错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "前往设置", style: .default) { _ in
//            if let url = URL(string: UIApplication.UIApplicationOpenSettingsURLString) {
//                UIApplication.shared.open(url)
//            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        print("characterRange: \(characterRange)")
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("语音合成完成，振幅数据（前 10 个）: \(amplitudes)")
        stopAmplitudeAudioEngine()
    }
}
