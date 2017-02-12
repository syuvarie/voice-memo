//
//  ViewController.swift
//  voice memo
//
//  Created by 奥田紘士 on 2017/02/12.
//  Copyright © 2017年 奥田紘士. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController,SFSpeechRecognizerDelegate {
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP,en-US"))!
    
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    var recognitionTask: SFSpeechRecognitionTask?
    
    let audioEngine = AVAudioEngine()
    
    @IBOutlet var recordButton : UIButton!

    @IBOutlet var textView : UITextView!
    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //レコードボタンが使えるか使えないか初期値は偽
         recordButton.isEnabled = false
    }
    
    //音声取得認証
    override public func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("音声認識へのアクセスが拒否されています", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("この端末で音声認識はできません。", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("音声認識はまだ許可されていません。", for: .disabled)
                }
            }
        }
    }
    
    
    func startText (){
        textView.text = "適当にしゃべってねー"
    }
    
    func helloRco(){
        switch  textView.text {
        case "こんにちは":
            textView.text = "こんにちは、今日はいい天気ですね！"
        default:
            break
        }
    
    }
    
    func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("開始", for: [])
            }
        }
        
        
        
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        
        
        try audioEngine.start()
        
        self.startText()
        //textView.textColor = UIColor.red
        //textView.text = "しゃべってほしいとか思ってないんだからねっ！"
    }

    
        // 音声認識の可否が変更したときに呼ばれるdelegate
        func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
            if available {
                recordButton.isEnabled = true
                recordButton.setTitle("音声認識スタート", for: [])
            } else {
                recordButton.isEnabled = false
                recordButton.setTitle("音声認識ストップ", for: .disabled)
            }
        }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

