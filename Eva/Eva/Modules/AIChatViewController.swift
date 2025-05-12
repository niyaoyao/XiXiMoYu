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

enum EvaModelChangeType {
    case avatar, background
}

class EvaThreadSafeContentsManager {
    // 共享数组
    private var waitToSpeakContents: [String] = []
    
    // 并发队列，启用 barrier
    private let queue = DispatchQueue(label: "com.example.subtitleManager", attributes: .concurrent)
    
    // 写操作：添加内容
    func appendContent(_ content: String) {
        queue.async(flags: .barrier) {
            self.waitToSpeakContents.append(content)
        }
    }
    
    // 写操作：移除内容
    func removeFirstContent() -> String? {
        var result: String?
        queue.sync(flags: .barrier) {
            result = self.waitToSpeakContents.isEmpty ? nil : self.waitToSpeakContents.removeFirst()
        }
        return result
    }
    
    // 读操作：获取所有内容
    func getAllContents() -> [String] {
        var result: [String] = []
        queue.sync {
            result = self.waitToSpeakContents
        }
        return result
    }
    
    func getAllContentsString() -> String {
        return getAllContents().joined(separator: "")
    }
    
    // 读操作：获取内容数量
    func getContentCount() -> Int {
        var count = 0
        queue.sync {
            count = self.waitToSpeakContents.count
        }
        return count
    }
    
    // 新增：移除所有内容
    func removeAllContents() {
        queue.async(flags: .barrier) {
            self.waitToSpeakContents.removeAll()
        }
    }
}

class AIChatViewController: EvaBaseViewController {
    let btnSize = CGSize(width: 35, height: 35)
    let bottomH = 100.0
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var amplitudes: [Float] = []
    private var keyboardObserver: KeyboardObserver =  KeyboardObserver()
    private var cancellables = Set<AnyCancellable>()
    var collectionDatas:[String] = []
    var modelChangeType:EvaModelChangeType = .avatar
    var selectedModelIndex:IndexPath?
    var selectedBackgroundIndex:IndexPath?
    lazy var collectionView: UICollectionView = {
        let width = 80.0
        let y = UIScreen.main.bounds.size.height - kBottomSafeHeight - bottomH - 4.0 * btnSize.height - 3 * 25.0 - width
        
        let frame = CGRect(x: 0.0, y: y, width: UIScreen.main.bounds.width, height: width)
        let padding = (frame.width - 80)/2.0
        let layout = NYScaleCenterItemCollectionFlowLayout(width:width, height: frame.size.height, padding: padding)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = true
        collectionView.clipsToBounds = false
        collectionView.register(NYScaleCenterCollectionCell.self, forCellWithReuseIdentifier: NYScaleCenterCollectionCell.identifier)
        collectionView.alpha = 0.0
        
        return collectionView
    }()
    
    lazy var modelBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage( UIImage(named: "menu_model"), for: .normal)
        let layer = btn.layer
                
        // 启用阴影
        layer.shadowOpacity = 0.35 // 对应 rgba 的透明度 (0.3)
        layer.shadowColor = UIColor("#333333").cgColor
        layer.shadowOffset = CGSize(width: 0, height: 6) // 对应 offset-x: 0px, offset-y: 11px
        layer.shadowRadius = 12
        btn.addActionHandler { [weak self] in
            self?.modelChangeType = .avatar
            self?.collectionDatas = NYLDModelManager.modelAvatarPaths() ?? []
            self?.collectionView.reloadData()
            self?.endEditing()
            self?.showCollectionView(selectedIndex: self?.selectedModelIndex)
        }
        return btn
    }()
    
    lazy var backgroundBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_background"), for: .normal)
        let layer = btn.layer
                
        // 启用阴影
        layer.shadowOpacity = 0.35 // 对应 rgba 的透明度 (0.3)
        layer.shadowColor = UIColor("#333333").cgColor // 对应 rgba(255, 89, 0)
        layer.shadowOffset = CGSize(width: 0, height: 6) // 对应 offset-x: 0px, offset-y: 11px
        layer.shadowRadius = 12
        btn.addActionHandler { [weak self] in
            self?.modelChangeType = .background
            do {
                self?.collectionDatas = try NYLDModelManager.backgroundDirFilePaths()
                self?.collectionView.reloadData()
            } catch {
                debugPrint("Error: \(error)")
            }
            self?.endEditing()
            self?.showCollectionView(selectedIndex: self?.selectedBackgroundIndex)
        }
        return btn
    }()
    
    lazy var controlBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_control"), for: .normal)
        let layer = btn.layer
                
        // 启用阴影
        layer.shadowOpacity = 0.35 // 对应 rgba 的透明度 (0.3)
        layer.shadowColor = UIColor("#333333").cgColor // 对应 rgba(255, 89, 0)
        layer.shadowOffset = CGSize(width: 0, height: 6) // 对应 offset-x: 0px, offset-y: 11px
        layer.shadowRadius = 12
        return btn
    }()
    
    lazy var settingsBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "menu_settings"), for: .normal)
        let layer = btn.layer
                
        // 启用阴影
        layer.shadowOpacity = 0.35 // 对应 rgba 的透明度 (0.3)
        layer.shadowColor = UIColor("#333333").cgColor // 对应 rgba(255, 89, 0)
        layer.shadowOffset = CGSize(width: 0, height: 6) // 对应 offset-x: 0px, offset-y: 11px
        layer.shadowRadius = 12
        
        btn.addActionHandler { [weak self] in
            self?.endEditing()
            let vc = EvaSettingViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return btn
    }()
    
    lazy var speakBtn: UIButton = {
        let speakButton = UIButton(frame: .zero)// Speak Button
        speakButton.setTitle("Send", for: .normal)
        speakButton.setTitle("Waiting", for: .disabled)
        speakButton.addTarget(self, action: #selector(speakText), for: .touchUpInside)
        let layer = speakButton.layer
                
        // 启用阴影
        layer.shadowOpacity = 1 // 对应 rgba 的透明度 (0.3)
        layer.shadowColor = UIColor("#333333").cgColor // 对应 rgba(255, 89, 0)
        layer.shadowOffset = CGSize(width: 0, height: 0) // 对应 offset-x: 0px, offset-y: 11px
        layer.shadowRadius = 12
        return speakButton
    }()
    
    lazy var textView : UITextView = {
        // TextView 用于显示和输入文字
        let textView = UITextView(frame: .zero)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 16)
        textView.text = "I'm fired now. I'm so sad and frustrated. Please help me go through it."
        return textView
    }()
    
    lazy var inputWrapper: UIView = {
        let v = UIView(frame: .zero)
        v.addSubview(inputBackground)
        inputBackground.snp.makeConstraints({ $0.edges.equalTo(v) })
        return v
    }()
    
    lazy var inputBackground: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = .white
        v.alpha = 0.0
        return v
    }()
    
    var inputWrapperEndRect = CGRect()
    var startTime: TimeInterval?
    
    lazy var modelBackgroudBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.addActionHandler { [weak self] in
            self?.endEditing()
        }
        return btn
    }()
    
    var contentsManager: EvaThreadSafeContentsManager = EvaThreadSafeContentsManager()
    var isSpeaking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Permission Guide Page
        requestPermissions()
        setupAudioSession()
        keyboardObserver.keyboardHeightPublisher
           .sink { [weak self] keyRect in
               guard let `self` = self else { return }

               
               var rect = self.inputWrapperEndRect
               let keyboardH =  keyRect.size.height
               var alpha = 0.0
               if keyRect.origin.y >= UIScreen.main.bounds.height {
                   rect = self.inputWrapperEndRect
                   alpha = 0.0
               } else {
                   rect.origin.y =  UIScreen.main.bounds.height - keyboardH - self.inputWrapperEndRect.height
                   alpha = 1.0
               }
               UIView.animate(withDuration: 0.3) {
                   self.inputWrapper.frame = rect
                   self.inputBackground.alpha = alpha
               } completion: { success in

               }
           }.store(in: &cancellables)
        setupUI()
        
    }
    
    func setupUI() {
        self.view.addSubview(NYLDSDKManager.shared().stageVC.view)
        NYLDSDKManager.shared().stageVC.didEndTouchActionHandler = { [weak self] in
            self?.endEditing()
        }
        view.addSubview(modelBackgroudBtn)
        view.addSubview(settingsBtn)
        view.addSubview(controlBtn)
        view.addSubview(backgroundBtn)
        view.addSubview(modelBtn)
        
        settingsBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view).offset(-kBottomSafeHeight-bottomH)
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
        
        // tts
        let th = 50.0
        let sbtnw = 80.0
        view.addSubview(inputWrapper)
        let inputY = UIScreen.main.bounds.height - kBottomSafeHeight - bottomH//(bottomH - th)/2.0 - th
        inputWrapper.frame = CGRect(x: 0, y: inputY, width: UIScreen.main.bounds.size.width, height: th + 20)
        inputWrapperEndRect = inputWrapper.frame
        inputWrapper.addSubview(self.textView)
        inputWrapper.addSubview(speakBtn)
        textView.frame = CGRect(x: 15, y: 10, width: UIScreen.main.bounds.size.width - 30 - sbtnw - 10, height: th)
        speakBtn.frame = CGRect(x: textView.frame.maxX + 10.0, y: textView.frame.origin.y, width: sbtnw, height: th)
        
        view.addSubview(collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        NYLDSDKManager.resume()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NYLDSDKManager.suspend()
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
            print("OpenRouter buffer:\(buffer) Thread.current: \(Thread.current)")
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
            print("OpenRouter AI Request batchAmplitudes: \(batchAmplitudes.last) Thread.current:\(Thread.current)")
            if let amplitude = batchAmplitudes.last {
                NYLDModelManager.shared().mouthOpenRate = amplitude * 20
                print("OpenRouter AI Request Mouth: \(NYLDModelManager.shared().mouthOpenRate)")
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
        NYLDModelManager.shared().mouthOpenRate = 0.0
        freshAIAnswerTextView(text: "", shouldHide: true)
        isSpeaking = false
    }
    
    func freshAIAnswerTextView(text: String, shouldHide: Bool) {
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            
        }
        
    }
    
    func startAISpeak(answer: String) {
        let text = answer
        if text.isEmpty || text.count <= 0 { return }
        requestAI(userContent: text)
    }
    
    func startTTS(content: String) {
        if self.isSpeaking {
            return
        }
        print("OpenRouter AI Request Start TTS: \(content)")
        self.isSpeaking = true
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 中文语音
        utterance.rate = 0.5 // 语速（0.1 - 1.0）
        utterance.pitchMultiplier = 1.0 // 音调（0.5 - 2.0）
        
        self.synthesizer.stopSpeaking(at: .immediate)
        self.synthesizer.speak(utterance)
        
    }
    
    // TTS: 文字转语音
    @objc private func speakText() {
        self.endEditing()
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.count <= 0 { return }
        self.startAISpeak(answer: text)
        
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
        self.hideCollectionView()
    }
    // 提示用户前往设置
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "权限错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "前往设置", style: .default) { _ in
            openAppSettings()
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
        print("OpenRouter AI Request characterRange: \(characterRange)")
        
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("OpenRouter 语音合成完成")
        let ttsContent = contentsManager.getAllContentsString()
        let ttsContents = contentsManager.getAllContents()
        print("OpenRouter ttsContent: \(ttsContent)")
        print("OpenRouter ttsContent: \(ttsContents)")
        self.isSpeaking = false
        if ttsContents.count > 0 {
            self.startTTS(content: ttsContent)
            contentsManager.removeAllContents()
        } else {
            stopAmplitudeAudioEngine()
        }
    }
}



// MARK: - UICollectionViewDataSource
extension AIChatViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NYScaleCenterCollectionCell.identifier, for: indexPath) as? NYScaleCenterCollectionCell else {
            return UICollectionViewCell()
        }
        cell.update(title: collectionDatas[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension AIChatViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.hideCollectionView()
        switch modelChangeType {
        case .avatar:
            selectedModelIndex = indexPath
            NYLDModelManager.shared().changeScene(indexPath.item)
        case .background:
            selectedBackgroundIndex = indexPath
            let path = collectionDatas[indexPath.item]
            NYLDSDKManager.shared().stageVC.changeBackground(withImagePath: path)
        }
    }
}

extension AIChatViewController {
    private func scrollToMiddleItem(selectedIndex: IndexPath?) {
        guard !collectionDatas.isEmpty else { return }
            
        // 计算中间 item 的索引
        let middleIndex = collectionDatas.count / 2
        var indexPath = IndexPath(item: middleIndex, section: 0)
        
        if let selected = selectedIndex {
            indexPath = selected
        }
        
        // 滚动到中间 item，水平居中
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    func showCollectionView(selectedIndex: IndexPath?) {
        scrollToMiddleItem(selectedIndex: selectedIndex)
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.collectionView.alpha = 1.0
        }
    }
    
    func hideCollectionView() {
        UIView.animate(withDuration: 0.35) { [weak self] in
            self?.collectionView.alpha = 0.0
        }
    }
}

extension AIChatViewController {
    func requestAI(userContent: String) {
        // google/gemini-2.5-pro-exp-03-25 google/gemini-2.0-flash-exp:free
        // deepseek/deepseek-v3-base:free deepseek/deepseek-r1-zero:free
        // qwen/qwen3-32b:free
        let key = "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"
        let headers: [String: String] = [
            "Authorization" : "Bearer \(key)",
            "Content-Type": "application/json"
        ]
        let model =  "qwen/qwen3-32b:free" //"google/gemini-2.0-flash-exp:free"//"qwen/qwen3-32b:free" // "deepseek/deepseek-v3-base:free"

        let body: [String: Any] = [
            "model" : model,
            "messages": [
                ["role":"user", "content": userContent],
                ["role":"system", "content": "Please play the role of a gentle and considerate AI girlfriend, speak in a gentle and considerate tone, be able to empathize with the interlocutor's mood, and provide emotional value to the interlocutor. Not more than 300 words"]
            ],
            "stream": true
        ]
        
        NYSSEManager.shared.messageHandler = { [weak self] type, data in
            self?.handleMessage(type: type, data: data)
        }
        self.startTime = Date().timeIntervalSince1970
        speakBtn.isEnabled = false
        
        contentsManager.removeAllContents()
        NYSSEManager.shared.send(urlStr: kOpenRouterUrl, headers: headers, body: body)
    }
    
    func handleMessage(type: NYSSEMessageHandleType, data: [String: Any]?) {
        if let data = data, let content = data["content"] as? String, type == .message {
            print("OpenRouter Content: \(content)")
            
            if (content == "." ||  content == "。") && !self.isSpeaking  {
                let ttsContent = contentsManager.getAllContentsString()
                self.startTTS(content: ttsContent)
                contentsManager.removeAllContents()
            } else {
                contentsManager.appendContent(content)
            }
            
        } else if type == .close {
                print("OpenRouter Cost: \(Date().timeIntervalSince1970 - (self.startTime ?? TimeInterval()))")
                setSpeakBtn(enabled: true)
            } else if type == .error {
                self.startTTS(content: "Sorry, something is wrong. Please try a again.")
                setSpeakBtn(enabled: true)
            } else if type == .done {
                
            }
            
        }
    
    
    func setSpeakBtn(enabled: Bool) {
        DispatchQueue.main.async {
            self.speakBtn.isEnabled = enabled
        }
    }
}
