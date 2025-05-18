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
        speakButton.setTitle("问我", for: .normal)
        speakButton.setTitle("思考中", for: .disabled)
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
        textView.text = "好无聊啊，给我讲个笑话吧？"//"I'm fired now. I'm so sad and frustrated. Please help me go through it."
        textView.delegate = self
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
        v.backgroundColor = .black.withAlphaComponent(0.5)
        v.alpha = 0.0
        return v
    }()
    
    lazy var inputPlaceholer: UILabel = {
        let lab = UILabel(frame: .zero)
        lab.font = .systemFont(ofSize: 16)
        lab.text = "Type message here..."
        lab.textColor = UIColor("#dddddd")
        return lab
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
    var currentSpeakingString = ""
    var currentAIKey = ""
    
    lazy var subtitleTextView: EvaSubtitleTextView = {
        let tv = EvaSubtitleTextView(frame: .zero)
        tv.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return tv
    }()
    
    lazy var copyBtn: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UIImage(named: "tts_copy"), for: .normal)
        btn.isHidden = true
        btn.addActionHandler { [weak self] in
            UIPasteboard.general.string = self?.subtitleTextView.originText
        }
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Permission Guide Page
        refreshAPIKeys()
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
        let sbtnw = 60.0
        view.addSubview(inputWrapper)
        let inputY = UIScreen.main.bounds.height - kBottomSafeHeight - bottomH//(bottomH - th)/2.0 - th
        inputWrapper.frame = CGRect(x: 0, y: inputY, width: UIScreen.main.bounds.size.width, height: th + 20)
        inputWrapperEndRect = inputWrapper.frame
        inputWrapper.addSubview(self.textView)
        inputWrapper.addSubview(inputPlaceholer)
        inputWrapper.addSubview(speakBtn)
        textView.frame = CGRect(x: 15, y: 10, width: UIScreen.main.bounds.size.width - 30 - sbtnw - 10, height: th)
        speakBtn.frame = CGRect(x: textView.frame.maxX + 10.0, y: textView.frame.origin.y, width: sbtnw, height: th)
        inputPlaceholer.frame = textView.frame
        inputPlaceholer.isHidden = true
        view.addSubview(collectionView)
        
        // 设置 UITextView 的初始 frame
        let h = 150.0
        let width = UIScreen.main.bounds.size.width - btnSize.width - 15 - 15
        subtitleTextView.frame = CGRect(x: 0, y: inputY - h, width: width, height: h)
        view.addSubview(subtitleTextView)
        let w = 25.0
        view.addSubview(copyBtn)
        copyBtn.frame = CGRect(x: subtitleTextView.frame.maxX - w - 20, y: subtitleTextView.frame.maxY - w, width: w, height: w)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshAPIKeys()
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
           // print("音频会话配置失败: \(error)")
        }
    }

    private func setupAmplitudeAudioEngine() {
        stopAmplitudeAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            // print("OpenRouter buffer:\(buffer) Thread.current: \(Thread.current)")
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
            // print("OpenRouter AI Request batchAmplitudes: \(batchAmplitudes.last) Thread.current:\(Thread.current)")
            if let amplitude = batchAmplitudes.last {
                NYLDModelManager.shared().mouthOpenRate = amplitude * 20
                // print("OpenRouter AI Request Mouth: \(NYLDModelManager.shared().mouthOpenRate)")
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            // print("音频引擎启动失败: \(error)")
        }
    }
    
    func stopAmplitudeAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        NYLDModelManager.shared().mouthOpenRate = 0.0
        freshAIAnswerTextView(text: "", shouldHide: true)
        setIsSpeaking(false)
        currentSpeakingString = ""
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
        setupAmplitudeAudioEngine()
        // print("OpenRouter AI Request Start TTS: \(content)")
        setIsSpeaking(true)
        currentSpeakingString = content
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-Hant-TW") // 中文语音 zh-Hant-TW "en-US" zh-Hans
        utterance.rate = 0.5 // 语速（0.1 - 1.0）
        utterance.pitchMultiplier = 1.0 // 音调（0.5 - 2.0）
        
        self.synthesizer.stopSpeaking(at: .immediate)
        self.synthesizer.speak(utterance)
        
    }
    
    
    // TTS: 文字转语音
    @objc private func speakText() {
        self.endEditing()
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleTextView.setSubtitle("")
        
        if text.isEmpty || text.count <= 0 {
            self.startTTS(content: "请先输入您想要询问的问题")
            return
        }
        self.startTTS(content: "好的，让我想想如何回答你的问题")
        self.startAISpeak(answer: text)
        textView.text = ""
        inputPlaceholer.isHidden = false
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
        // 设置示例字幕
        let content = currentSpeakingString.substring(with: characterRange) ?? ""
        copyBtn.isHidden = false
        subtitleTextView.setSubtitle("\(subtitleTextView.originText)\(content)")
        setIsSpeaking(true)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        setIsSpeaking()
        let ttsContent = contentsManager.getAllContentsString()
        let ttsContents = contentsManager.getAllContents()
        
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
        var key = ""
        if let decrypted = EvaUserDefaultManager.aiKeys.first {
            key = decrypted
        }
        
        if key == "" {
            refreshAPIKeys()
            stopAmplitudeAudioEngine()
            setSpeakBtn(enabled: true)
            self.startTTS(content: "抱歉，网络出问题了，请重试")
            return
        }
        let headers: [String: String] = [
            "Authorization" : "Bearer \(key)",
            "Content-Type": "application/json"
        ]
        let model =  "qwen/qwen3-32b:free" //"google/gemini-2.0-flash-exp:free"//"qwen/qwen3-32b:free" // "deepseek/deepseek-v3-base:free"

        let body: [String: Any] = [
            "model" : model,
            "messages": [
                ["role":"user", "content": "\(userContent) 请直接提供最终答案，不要包含推理过程，不超过500字"],
//                ["role":"system", "content": "请扮演一位温柔体贴的AI女友，用温柔体贴的语气说话，能够体会对话者的心情，并为对话者提供情感价值。"]
            ],
            "stream": true
        ]
        
        NYSSEManager.shared.messageHandler = { [weak self] type, data in
            self?.handleMessage(type: type, data: data)
        }
        self.startTime = Date().timeIntervalSince1970
        speakBtn.isEnabled = false
        currentAIKey = key
        contentsManager.removeAllContents()
        NYSSEManager.shared.send(urlStr: kOpenRouterUrl, headers: headers, body: body)
    }
    
    func handleMessage(type: NYSSEMessageHandleType, data: [String: Any]?) {
        if let data = data, let content = data["content"] as? String, type == .message {
            print("OpenRouter isSpeaking: \(isSpeaking)")
//            print("OpenRouter reasoning: \(data["reasoning"])")
            print("OpenRouter Content: \(content)")
            setSpeakBtn(enabled: false)
            if (content == "." ||  content == "，" ||  content == "。" ||  content == "？" ||  content == "！") && !self.isSpeaking  {
                DispatchQueue.main.async { [weak self] in
                    self?.copyBtn.isHidden = true
                }
                let ttsContent = contentsManager.getAllContentsString()
                self.startTTS(content: ttsContent)
                contentsManager.removeAllContents()
            }
            contentsManager.appendContent(content)
            
            print("OpenRouter contentsManager.getAllContentsString(): \(contentsManager.getAllContentsString())")
        } else if type == .close {
                // print("OpenRouter Cost: \(Date().timeIntervalSince1970 - (self.startTime ?? TimeInterval()))")
        } else if type == .error {
            stopAmplitudeAudioEngine()
            setSpeakBtn(enabled: true)
            if let data = data, let errorCode = data["code"] as? Int, let msg = data["msg"] {
                
                switch errorCode {
                case 401:
                    var invalidKeys = EvaUserDefaultManager.invalidAIKeys
                    if !invalidKeys.contains(currentAIKey) {
                        invalidKeys.append(currentAIKey)
                    }
                    EvaUserDefaultManager.invalidAIKeys = invalidKeys
                    let arrayA = EvaUserDefaultManager.aiKeys
                    let arrayB = EvaUserDefaultManager.invalidAIKeys
                    EvaUserDefaultManager.aiKeys = arrayA.filter { !arrayB.contains($0) }
                    print("EvaAI Keys: \(EvaUserDefaultManager.aiKeys)")
                default:
                    print("code: \(errorCode)")
                    print("msg: \(msg)")
                }
            }
            self.startTTS(content: "抱歉，网络出问题了，请重试")
        } else if type == .done {
            setSpeakBtn(enabled: true)
        } else if type == .comment {
            subtitleTextView.setSubtitle("")
            setSpeakBtn(enabled: false)
        }
            
    }
    
    
    func setIsSpeaking(_ isSpeaking: Bool = false) {
        self.isSpeaking = isSpeaking
        self.setSpeakBtn(enabled: !isSpeaking)
    }
    
    func setSpeakBtn(enabled: Bool) {
        DispatchQueue.main.async {
            self.speakBtn.isEnabled = enabled
        }
    }
    
    func generateRandomIntMod3(range: ClosedRange<Int> = 0...100) -> Int {
        // 生成随机整数
        let randomInt = Int.random(in: range)
        // 对 3 取余
        let result = randomInt
        return result
    }

}

extension AIChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        inputPlaceholer.isHidden = textView.text.count > 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        inputPlaceholer.isHidden = textView.text.count > 0
        subtitleTextView.setSubtitle("")
    }
}

extension AIChatViewController {
    func refreshAPIKeys() {
        guard let url = URL(string: "https://cyberpi.tech/web-player/musics/config.json") else { return
        }
        NetworkClient.shared.post(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(EvaConfigResponse.self, from: data)
                    if let error = response.error {
                        print("USPictureSearchIntent error: \(error.message)")
                    } else {
                        if let data = response.data, let keys = data.keys as? [String] {
                            let arrayA = keys.map({ AESCryptor.decryptString($0) ?? "" }).filter({ $0 != "" })
                            let arrayB = EvaUserDefaultManager.invalidAIKeys
                            EvaUserDefaultManager.aiKeys = arrayA.filter { !arrayB.contains($0) }
                            print("EvaAI Keys:\(EvaUserDefaultManager.aiKeys)")
                        }
                    }
                    
                } catch  {
                    debugPrint("USPictureSearchIntent log request 错误: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("USPictureSearchIntent error: \(error)")
    
            }
        }
        
    }
}
