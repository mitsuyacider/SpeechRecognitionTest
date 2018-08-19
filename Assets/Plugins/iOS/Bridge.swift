import Foundation
import Speech

class Bridge : NSObject {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioEngine = AVAudioEngine()

    var timer: Timer?


    static func swiftMethod(_ message: String) {
        print("\(#function) is called with message: \(message)")
//        UnitySendMessage("Button", "callbackFromNative", "Message");
    }

    func swiftMethod2() {

        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:

                    if self.audioEngine.isRunning {
                        self.audioEngine.stop()
                        self.recognitionRequest?.endAudio()

                        guard let inputNode = self.audioEngine.inputNode else { fatalError("Audio engine has no input node") }
                        inputNode.removeTap(onBus: 0)

                        self.recognitionRequest = nil
                        self.recognitionTask?.cancel()
                        self.recognitionTask = nil
                    }

                    if (self.timer != nil && (self.timer?.isValid)!) {
                        self.timer?.invalidate()
                        self.timer = nil
                    }

                    self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.startRecording), userInfo: nil, repeats: false)

                    break
                case .notDetermined: break

                case .denied: break

                case .restricted: break

                }
            }
        }
    }

    public func startRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()

            guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
            inputNode.removeTap(onBus: 0)

            self.recognitionRequest = nil
            self.recognitionTask = nil
        }

        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch let error {
            print("an error happend on starting audio session", error)
        }

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
                isFinal = result.isFinal
//                self.analyzeText(text: result.bestTranscription.formattedString)
                self.notify2Unity(text: result.bestTranscription.formattedString)
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch let error {
          print("an error happend on starting audioEngine", error)
        }
    }

    public func stopRecognizing() {
        if self.audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()

            guard let inputNode = self.audioEngine.inputNode else { fatalError("Audio engine has no input node") }
            inputNode.removeTap(onBus: 0)

            self.recognitionRequest = nil
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        }

        if (self.timer != nil && (self.timer?.isValid)!) {
            self.timer?.invalidate()
            self.timer = nil
        }

        // NOTE: SFSpeechRecognizerが起動中は効果音が再生されない状態であるため、
        //       音声認識を終了する際はAVAudioSessoinのカテゴリを変更する必要がある
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
//            try audioSession.setMode(AVAudioSessionModeMeasurement)
//            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch let error {
            print(error)
        }

        UnitySendMessage("GameController", "callbackFromNative", "stopRecognizing")
    }

    func notify2Unity(text: String) {
        UnitySendMessage("GameController", "callbackFromNative", text)
    }
}

extension Bridge {
    func analyzeText(text: String) {
        // "en" = 英語
        // "ja" = 日本語
        let tagger = NSLinguisticTagger(tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "ja"), options: 0)

        tagger.string = text

        // NSLinguisticTagSchemeTokenType
        // Word, Punctuation, Whitespace, Otherで判別が可能。
        tagger.enumerateTags(in: NSRange(location: 0, length: (text as NSString).length), scheme: NSLinguisticTagSchemeTokenType, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange, sentenceRange, stop in

            let subString = (text as NSString).substring(with: tokenRange)
            print("\(subString) : \(tag)")
        }
    }
}
