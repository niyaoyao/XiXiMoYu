//
//  Backup2ViewController.swift
//  sst
//
//  Created by NY on 2025/4/16.
//

import UIKit

import AVFoundation // TTS
import Speech     // STT
import UIKit
import AVFAudio

class Backup2ViewController: UIViewController {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var amplitudes: [Float] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAudioSession()
        synthesizeAndCapture(text: "Hello, this is a test speech.")
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("音频会话配置失败: \(error)")
        }
    }
    
    private func setupAudioEngine() {
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
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("音频引擎启动失败: \(error)")
        }
    }
    
    private func synthesizeAndCapture(text: String) {
        setupAudioEngine()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioEngine.stop()
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension Backup2ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        print("characterRange: \(characterRange)")
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("语音合成完成，振幅数据（前 10 个）: \(amplitudes)")
        audioEngine.stop()
    }
}
