//
//  AIChatViewController.swift
//  Eva
//
//  Created by niyao on 4/27/25.
//

import UIKit
import SnapKit
import Live2DSDK
import GLKit

import AVFoundation // TTS
import Speech     // STT // STT
import AVFAudio

import Combine

// 顶级响应结构体
struct ChatCompletionError: Codable {
    let message: String?
    let code: Int?
    enum CodingKeys: String, CodingKey {
        case message, code
    }
}

struct ChatCompletionResponse: Codable {
    let error: ChatCompletionError?
    let id: String?
    let provider: String?
    let model: String?
    let object: String?
    let created: Int?
    let choices: [Choice]?
    let usage: Usage?
    let user_id: String?
    enum CodingKeys: String, CodingKey {
        case id, provider, model, object, created, choices, usage, error, user_id
    }
}

// Choice 结构体
struct Choice: Codable {
    let logprobs: Logprobs?
    let finishReason: String?
    let nativeFinishReason: String?
    let index: Int?
    let message: Message?
    let refusal: String?
    let reasoning: String?
    
    enum CodingKeys: String, CodingKey {
        case logprobs
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case index, message, refusal, reasoning
    }
}

// Logprobs 结构体（处理 null）
struct Logprobs: Codable {
    let value: Bool? // JSON 中为 null，设为可选类型
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(Bool.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// Message 结构体
struct Message: Codable {
    let role: String
    let content: String
}

// Usage 结构体
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
class AIChatViewController: EvaBaseViewController {
    let btnSize = CGSize(width: 35, height: 35)
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var amplitudes: [Float] = []
    private var keyboardObserver: KeyboardObserver =  KeyboardObserver()
    private var cancellables = Set<AnyCancellable>()
    
    lazy var modelBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage( UIImage(named: "menu_model"), for: .normal)
        btn.addActionHandler {
        }
        return btn
    }()
    
    lazy var backgroundBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_background"), for: .normal)
        return btn
    }()
    
    lazy var controlBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_control"), for: .normal)
        return btn
    }()
    
    lazy var settingsBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_settings"), for: .normal)
        return btn
    }()
    
    lazy var speakBtn: UIButton = {
        let speakButton = UIButton(frame: .zero)// Speak Button
        speakButton.setTitle("Speak", for: .normal)
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
        textView.text = "Hi,welcome! Let’s start the AI ​​journey together~"
        return textView
    }()
    
    lazy var inputWrapper: UIView = {
        let v = UIView(frame: .zero)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(settingsBtn)
        view.addSubview(controlBtn)
        view.addSubview(backgroundBtn)
        view.addSubview(modelBtn)
        
        settingsBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-kBottomSafeHeight-160)
            make.right.equalTo(view).offset(-15)
            make.size.equalTo(btnSize)
        }
        
        controlBtn.snp.makeConstraints { make in
            make.bottom.equalTo(settingsBtn.snp.top).offset(-25)
            make.right.equalTo(settingsBtn)
            make.size.equalTo(btnSize)
        }
        
        backgroundBtn.snp.makeConstraints { make in
            make.bottom.equalTo(controlBtn.snp.top).offset(-25)
            make.right.equalTo(controlBtn)
            make.size.equalTo(btnSize)
        }
        
        modelBtn.snp.makeConstraints { make in
            make.bottom.equalTo(backgroundBtn.snp.top).offset(-25)
            make.right.equalTo(backgroundBtn)
            make.size.equalTo(btnSize)
        }
    }

}

// MARK: - TTS
extension AIChatViewController {
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
        stopAmplitudeAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let `self` = self else { return }
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
//                NYLDModelManager.shared().mouthOpenRate = amplitude * 20
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
//        NYLDModelManager.shared().mouthOpenRate = 0.0
        
        freshAIAnswerTextView(text: "", shouldHide: true)
    }
    
    func freshAIAnswerTextView(text: String, shouldHide: Bool) {
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            
        }
        
    }
    
    func startAISpeak(answer: String) {
        setupAmplitudeAudioEngine()
        let text = answer
        if text.isEmpty || text.count <= 0 { return }
        freshAIAnswerTextView(text: text, shouldHide: false)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 中文语音
        utterance.rate = 0.5 // 语速（0.1 - 1.0）
        utterance.pitchMultiplier = 1.0 // 音调（0.5 - 2.0）
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
    func aiRequest(prompt: String, model:String = "deepseek/deepseek-r1-zero:free", completion: ((String?)->())?) {
        let key = "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"
        let headers: [String: String] = ["Authorization" : "Bearer \(key)"]
        let body: [String: Any] = [
            "model" : model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
        NetworkClient.shared.post(url: url, headers: headers, body: body) { result in
            print(result)
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ChatCompletionResponse.self, from: data)
                    if let error = response.error {
                        print("USPictureSearchIntent error: \(error.message)")
                    } else {
                        print("ID: \(response.id)")
                        print("Provider: \(response.provider)")
                        if let firstChoice = response.choices?.first {
                            print("USPictureSearchIntent Assistant response: \(firstChoice.message?.content)")
                            DispatchQueue.main.async {
                                completion?(firstChoice.message?.content)
                            }
                        }
                    }
//                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    print("USPictureSearchIntent ID: \(responseDict)")
//                    print("USPictureSearchIntent Provider: \(responseDict)")
//
                } catch  {
                    debugPrint("USPictureSearchIntent log request 错误: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("USPictureSearchIntent error: \(error)")
                
            }
        }
    }
    
    // TTS: 文字转语音
    @objc private func speakText() {
        self.endEditing()
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.count <= 0 { return }
        self.startAISpeak(answer: text)
//        aiAnswerTV.text = "AI 正在思考中，请稍等..."
//        aiAnswerTV.isHidden = false
//        aiRequest(prompt: text) { [weak self] answer in
//            guard let `self` = self else { return }
//            guard let answer = answer else { return }
//            self.startAISpeak(answer: answer)
//        }
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
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
extension AIChatViewController: AVSpeechSynthesizerDelegate {
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
