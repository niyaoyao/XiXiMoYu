//
//  Backup3ViewController.swift
//  sst
//
//  Created by NY on 2025/4/17.
//

import UIKit
import AVFoundation

// 波形视图
class WaveformView: UIView {
    var amplitudes: [Float] = [] // 振幅数据
    var playbackProgress: Float = 0.0 { // 播放进度（0.0 到 1.0）
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        guard !amplitudes.isEmpty else { return }
        
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let maxAmplitude = amplitudes.max() ?? 1.0
        
        // 计算可见样本数
        let sampleCount = amplitudes.count
        let step = width / CGFloat(sampleCount)
        
        // 绘制波形
        for index in 0..<sampleCount {
            let amplitude = amplitudes[index]
            let x = CGFloat(index) * step
            let normalized = min(amplitude / maxAmplitude, 1.0)
            let y = midY - CGFloat(normalized) * midY
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: midY))
            }
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 绘制波形线
        UIColor.blue.setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // 绘制进度指示线
//        let progressX = width * CGFloat(playbackProgress)
//        let progressPath = UIBezierPath()
//        progressPath.move(to: CGPoint(x: progressX, y: 0))
//        progressPath.addLine(to: CGPoint(x: progressX, y: height))
//        UIColor.red.setStroke()
//        progressPath.lineWidth = 1
//        progressPath.stroke()
    }
}

// 振幅提取器
class AudioAmplitudeExtractor {
    func extractAmplitudes(from url: URL, batchSize: Int = 1024) -> [Float]? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            print("无法加载音频文件")
            return nil
        }
        
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("无法创建 PCM 缓冲区")
            return nil
        }
        
        do {
            try audioFile.read(into: buffer)
        } catch {
            print("读取音频数据失败: \(error)")
            return nil
        }
        
        guard let floatChannelData = buffer.floatChannelData else {
            print("无法获取样本数据")
            return nil
        }
        
        let frameLength = Int(buffer.frameLength)
        let samples = floatChannelData[0] // 假设单声道
        
        var amplitudes: [Float] = []
        for i in stride(from: 0, to: frameLength, by: batchSize) {
            let end = min(i + batchSize, frameLength)
            var sum: Float = 0
            let count = end - i
            
            for j in i..<end {
                sum += abs(samples[j])
            }
            
            let averageAmplitude = count > 0 ? sum / Float(count) : 0
            amplitudes.append(averageAmplitude)
        }
        
        return amplitudes
    }
}

// 主视图控制器
class Backup3ViewController: UIViewController, AVAudioPlayerDelegate {
    
    private var audioPlayer: AVAudioPlayer?
    private var waveformView: WaveformView!
    private var playButton: UIButton!
    private var displayLink: CADisplayLink?
    private var amplitudes: [Float] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAudio()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 波形视图
        waveformView = WaveformView()
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformView)
        
        // 播放按钮
        playButton = UIButton(type: .system)
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playButton)
        
        // 约束
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 150),
            
            playButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 20),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func loadAudio() {
        // 替换为你的 WAV 文件路径
        guard let wavURL = Bundle.main.url(forResource: "sample", withExtension: "wav") else {
            print("找不到 WAV 文件")
            return
        }
        
        // 提取振幅
        let extractor = AudioAmplitudeExtractor()
        if let extractedAmplitudes = extractor.extractAmplitudes(from: wavURL, batchSize: 1024) {
            amplitudes = extractedAmplitudes
            waveformView.amplitudes = amplitudes
            print("振幅数据（前 10 个）: \(amplitudes.prefix(10))")
        }
        
        // 初始化播放器
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: wavURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch {
            print("无法初始化音频播放器: \(error)")
        }
    }
    
    @objc private func togglePlay() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.pause()
            stopDisplayLink()
            playButton.setTitle("Play", for: .normal)
        } else {
            audioPlayer?.play()
            startDisplayLink()
            playButton.setTitle("Pause", for: .normal)
        }
    }
    
    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveform))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateWaveform() {
        guard let player = audioPlayer, player.isPlaying else { return }
        let currentTime = player.currentTime
        let duration = player.duration
        let progress = Float(currentTime / duration)
        waveformView.playbackProgress = progress
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopDisplayLink()
        playButton.setTitle("Play", for: .normal)
        waveformView.playbackProgress = 0.0
    }
}

