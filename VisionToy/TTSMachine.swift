//
//  TTSMachine.swift
//  VisionToy
//
//  Created by Pedro Vasconcelos on 02/03/2018.
//  Copyright © 2018 Pedro Vasconcelos. All rights reserved.
//

import Foundation
import Speech


/// A simple text to speech service that accepts a String to convert to speech and ignores repeated Strings in consecutive requests.
class TTSMachine {
    
    // MARK: - Properties
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastUtteranceText: String?
}

// MARK: - Public

extension TTSMachine {
    /// Produces speech from the given text, unless it is the same as the text provided in the previous request.
    func speak(text: String?) {
        guard text != lastUtteranceText else { return }
        
        // Update lastUtteranceText with new text, even if new text is nil.
        lastUtteranceText = text
        
        // Ensure new text is not nil before executing new request.
        guard let utteranceText = text else { return }
        
        speechSynthesizer.stopSpeaking(at: .word)
        let utterance = AVSpeechUtterance(string: utteranceText)
        speechSynthesizer.speak(utterance)
    }
    
    /// Stops speech and clears memory of previous requests.
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .word)
        lastUtteranceText = nil
    }
}



