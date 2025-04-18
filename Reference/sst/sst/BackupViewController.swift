//
//  BackupViewController.swift
//  sst
//
//  Created by NY on 2025/4/16.
//

import UIKit

import AVFoundation // TTS
import Speech     // STT

class BackupViewController: UIViewController {
    // UI 元素
    private let textView = UITextView()
    private let recordButton = UIButton(type: .system)
    private let speakButton = UIButton(type: .system)
    
    // STT
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) // 中文示例
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestPermissions()
    }
    
    // 设置 UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // TextView 用于显示和输入文字
        textView.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 200)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.font = .systemFont(ofSize: 16)
        view.addSubview(textView)
        
        // Record Button
        recordButton.setTitle("开始录音", for: .normal)
        recordButton.frame = CGRect(x: 20, y: textView.frame.maxY + 20, width: 100, height: 40)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        view.addSubview(recordButton)
        
        // Speak Button
        speakButton.setTitle("朗读文字", for: .normal)
        speakButton.frame = CGRect(x: recordButton.frame.maxX + 20, y: textView.frame.maxY + 20, width: 100, height: 40)
        speakButton.addTarget(self, action: #selector(speakText), for: .touchUpInside)
        view.addSubview(speakButton)
    }
    
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
    
    // STT: 录音并转文字
    @objc private func toggleRecording() {
        self.view.endEditing(true)
        if audioEngine.isRunning {
            stopRecording()
            recordButton.setTitle("开始录音", for: .normal)
        } else {
            startRecording()
            recordButton.setTitle("停止录音", for: .normal)
        }
    }
    
    private func startRecording() {
        // 重置任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true // 实时返回结果
        
        // 配置音频输入
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 开始音频引擎
        audioEngine.prepare()
        try? audioEngine.start()
        
        // 开始语音识别
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
                self.recordButton.setTitle("开始录音", for: .normal)
            }
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // TTS: 文字转语音
    @objc private func speakText() {
//        self.view.endEditing(true)
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }
        
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
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
