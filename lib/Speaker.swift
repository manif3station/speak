import AppKit
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
        let firstIsSamantha = $0.identifier == "com.apple.voice.compact.en-US.Samantha"
        let secondIsSamantha = $1.identifier == "com.apple.voice.compact.en-US.Samantha"
        if firstIsSamantha != secondIsSamantha {
            return firstIsSamantha
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

let voiceName = NSSpeechSynthesizer.VoiceName(rawValue: voice.identifier)
guard let synthesizer = NSSpeechSynthesizer(voice: voiceName) else {
    fputs("Cannot initialize macOS voice '\(voice.name)'.\n", stderr)
    exit(1)
}

guard synthesizer.startSpeaking(message) else {
    fputs("Cannot start macOS voice '\(voice.name)'.\n", stderr)
    exit(1)
}

let deadline = Date(timeIntervalSinceNow: max(30, Double(message.count) / 3))
while synthesizer.isSpeaking && Date() < deadline {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}

guard !synthesizer.isSpeaking else {
    fputs("Speech timed out using voice '\(voice.name)'.\n", stderr)
    exit(1)
}
