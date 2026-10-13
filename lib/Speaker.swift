import AVFoundation
import Foundation

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: swift Speaker.swift <message>\n", stderr)
    exit(2)
}

let message = CommandLine.arguments.dropFirst().joined(separator: " ")
guard !message.isEmpty else {
    exit(0)
}

let englishVoices = AVSpeechSynthesisVoice.speechVoices()
    .filter { $0.language.hasPrefix("en") }
    .sorted {
        if $0.quality.rawValue != $1.quality.rawValue {
            return $0.quality.rawValue > $1.quality.rawValue
        }
        if ($0.language == "en-US") != ($1.language == "en-US") {
            return $0.language == "en-US"
        }
        return $0.name < $1.name
    }

guard let voice = englishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US") else {
    fputs("No English macOS speech voice is available.\n", stderr)
    exit(1)
}

let utterance = AVSpeechUtterance(string: message)
utterance.voice = voice
utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92

let synthesizer = AVSpeechSynthesizer()
synthesizer.speak(utterance)
while synthesizer.isSpeaking {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}
