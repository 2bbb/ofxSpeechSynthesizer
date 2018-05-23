//
//  ofxSpeechSynthesizer.h
//
//  Created by ISHII 2bit on 2018/05/22.
//

#ifndef ofxSpeechSynthesizer_h
#define ofxSpeechSynthesizer_h

#include <memory>
#include <string>
#include <map>

#include "ofLog.h"

namespace bbb {
    struct speech_synthesizer;
}

extern std::map<std::string, std::string> ofxSpeechSynthesizerLanguageCodes;

namespace ofx {
    struct SpeechUtterance {
        std::string text;
        std::string language;
        std::string voice;
        
        float volume{1.0f};
        float rate{defaultRate()};
        float pitch{1.0f};
        float preUtteranceDelay{0.0f};
        float postUtteranceDelay{0.0f};
        static float defaultRate();
        static float minimumRate();
        static float maximumRate();
    };
    
    struct SpeechSynthesizer {
        SpeechSynthesizer();
        
        void setup(const std::string &lang);
        
        void speak(const std::string &text) const;
        void speak(const std::string &text, const SpeechUtterance &utterance) const;
        void speak(const SpeechUtterance &utterance) const;
        bool pause(bool immediatly = false);
        bool resume();
        bool stop(bool immediatly = false);
        
        bool setLanguage(const std::string &lang);
        bool setVoice(const std::string &lang);
        static void printAvailableLanguages();
        static void printAvailableVoices();
        
        bool isSpeaking() const;
        bool isPaused() const;
    private:
        std::shared_ptr<bbb::speech_synthesizer> impl;
    };
    
    struct SpeechSynthesizerDelegate {
        virtual void didStart(SpeechUtterance utter) {};
        virtual void willSpeakRange(SpeechUtterance utter, std::size_t location, std::size_t length) {};
        virtual void didPause(SpeechUtterance utter) {};
        virtual void didContinue(SpeechUtterance utter) {};
        virtual void didCancel(SpeechUtterance utter) {};
        virtual void didFinish(SpeechUtterance utter) {};
    };
}

using ofxSpeechSynthesizer = ofx::SpeechSynthesizer;
using ofxSpeechSynthesizerDelegate = ofx::SpeechSynthesizerDelegate;
using ofxSpeechUtterance = ofx::SpeechUtterance;

#endif /* ofxSpeechSynthesizer_h */
