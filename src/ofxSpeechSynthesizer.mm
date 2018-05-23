//
//  ofxSpeechSynthesizer.mm
//
//  Created by 石井通人 on 2018/05/22.
//

#import <AVFoundation/AVFoundation.h>
#include "ofxSpeechSynthesizer.h"

namespace {
    inline const char *to_cpp(NSString *str) {
        return str.UTF8String;
    }
    inline NSString *to_objc(const std::string &str) {
        return [NSString stringWithUTF8String:str.c_str()];
    }
    
    inline ofxSpeechUtterance to_cpp(AVSpeechUtterance *utterance) {
        ofxSpeechUtterance utter;
        utter.text = to_cpp(utterance.speechString);
        utter.language = to_cpp(utterance.voice.language);
        utter.voice = to_cpp(utterance.voice.name);

        utter.volume = utterance.volume;
        utter.rate = utterance.rate;
        utter.pitch = utterance.pitchMultiplier;
        utter.preUtteranceDelay = utterance.preUtteranceDelay;
        utter.postUtteranceDelay = utterance.postUtteranceDelay;
        return utter;
    }
}

@interface BBBSpeechSynthesizerDelegate : NSObject <AVSpeechSynthesizerDelegate> {
    ofxSpeechSynthesizerDelegate *impl;
}

- (void)setImpl:(ofxSpeechSynthesizerDelegate *)impl_;

@end

namespace bbb {
    using speech_utterance = ofx::SpeechUtterance;
    struct speech_synthesizer {
        speech_synthesizer()
        : synth(AVSpeechSynthesizer.alloc.init)
        { set_language(ofxSpeechSynthesizerLanguageCodes["English"]); }
        
        void speak(const std::string &text) const
        { speak(text, speech_utterance()); }
        void speak(const speech_utterance &utter) const
        { speak(utter.text, utter); }
        void speak(const std::string &text, const speech_utterance &utter) const {
            AVAudioSession *audio_session = [AVAudioSession sharedInstance];
            NSString *category = nil;
            NSString *mode = nil;
            if(audio_session) {
                category = audio_session.category;
                mode = audio_session.mode;
                [audio_session setCategory:AVAudioSessionCategoryPlayback error:nil];
                [audio_session setMode:AVAudioSessionModeDefault error:nil];
            }
            
            AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:to_objc(text)];
            if(utter.voice != "") {
                utterance.voice = get_voice(utter.voice);
            }
            if(utterance.voice == nil && utter.language != "") {
                utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:to_objc(ofxSpeechSynthesizerLanguageCodes[utter.language])];
            }
            if(utterance.voice == nil) utterance.voice = voice;
            
            utterance.volume = std::max(0.0f, std::min(utter.volume, 1.0f));
            utterance.rate = utter.rate;
            utterance.pitchMultiplier = utter.pitch;
            utterance.preUtteranceDelay = utter.preUtteranceDelay;
            utterance.postUtteranceDelay = utter.postUtteranceDelay;
            
            [synth speakUtterance:utterance];
            if(audio_session) {
                [audio_session setCategory:category error:nil];
                [audio_session setMode:mode error:nil];
            }
        }
        
        bool pause(bool immediatly)
        { return [synth pauseSpeakingAtBoundary:immediatly ? AVSpeechBoundaryImmediate : AVSpeechBoundaryWord] ? true : false; };
        bool resume()
        { return [synth continueSpeaking] ? true : false; };
        bool stop(bool immediatly)
        { return [synth stopSpeakingAtBoundary:immediatly ? AVSpeechBoundaryImmediate : AVSpeechBoundaryWord] ? true : false; };
        
        bool set_language(const std::string &lang) {
            AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:to_objc(lang)];
            if(voice == nil) {
                ofLogWarning("ofxSpeechSynthesizer::setLanguage") << "voice of " << lang << " is not found";
                return false;
            }
            this->voice = voice;
            return true;
        }
        bool set_voice(const std::string &name) {
            voice = get_voice(name);
            return voice != nil;
        }
        void set_delegate(ofxSpeechSynthesizerDelegate *delegate) {
            if(!this->delegate) { this->delegate = BBBSpeechSynthesizerDelegate.alloc.init; };
            [this->delegate setImpl:delegate];
        }
        bool is_speaking() const { return synth.isSpeaking; };
        bool is_paused() const { return synth.isPaused; };

    private:
        AVSpeechSynthesizer *synth;
        AVSpeechSynthesisVoice *voice;
        BBBSpeechSynthesizerDelegate *delegate;
        
        AVSpeechSynthesisVoice *get_voice(const std::string &name) const {
            NSUInteger index = [AVSpeechSynthesisVoice.speechVoices indexOfObjectPassingTest:^BOOL(AVSpeechSynthesisVoice *voice, NSUInteger idx, BOOL * _Nonnull stop) {
                                return *stop = (voice.name.UTF8String == name);
                                }];
            if(index == NSNotFound) {
                ofLogWarning("ofxSpeechSynthesizer::setVoice") << "voice is named " << name << " is not found";
                return nil;
            }
            return AVSpeechSynthesisVoice.speechVoices[index];
        }
    };
};

@implementation BBBSpeechSynthesizerDelegate

- (void)setImpl:(ofxSpeechSynthesizerDelegate *)impl_ {
    impl = impl_;
};

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance {
     // pause
    if(impl) impl->didPause(to_cpp(utterance));
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    // start
    if(impl) impl->didStart(to_cpp(utterance));
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    // finish
    if(impl) impl->didFinish(to_cpp(utterance));
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    // did stop
    if(impl) impl->didCancel(to_cpp(utterance));
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance {
    // resume from pause
    if(impl) impl->didContinue(to_cpp(utterance));
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance {
    if(impl) impl->willSpeakRange(to_cpp(utterance), characterRange.location, characterRange.length);
}

@end


namespace ofx {
    float SpeechUtterance::defaultRate()
    { return AVSpeechUtteranceDefaultSpeechRate; }
    float SpeechUtterance::minimumRate()
    { return AVSpeechUtteranceMinimumSpeechRate; }
    float SpeechUtterance::maximumRate()
    { return AVSpeechUtteranceMaximumSpeechRate; }

    SpeechSynthesizer::SpeechSynthesizer() {
        impl = std::make_shared<bbb::speech_synthesizer>();
    }
    
    void SpeechSynthesizer::setup(const std::string &lang_or_voice) {
        if(!impl->set_language(ofxSpeechSynthesizerLanguageCodes[lang_or_voice])) impl->set_voice(lang_or_voice);
    };
    void SpeechSynthesizer::speak(const std::string &text) const
    { impl->speak(text); };
    void SpeechSynthesizer::speak(const std::string &text, const SpeechUtterance &utterance) const
    { impl->speak(text, utterance); };
    void SpeechSynthesizer::speak(const SpeechUtterance &utterance) const
    { impl->speak(utterance); };

    bool SpeechSynthesizer::pause(bool immediatly)
    { return impl->pause(immediatly); };
    bool SpeechSynthesizer::resume()
    { return impl->resume(); };
    bool SpeechSynthesizer::stop(bool immediatly)
    { return impl->stop(immediatly); };

    bool SpeechSynthesizer::setLanguage(const std::string &lang)
    { return impl->set_language(ofxSpeechSynthesizerLanguageCodes[lang]); };
    bool SpeechSynthesizer::setVoice(const std::string &name)
    { return impl->set_voice(name); };

    void SpeechSynthesizer::printAvailableLanguages() {
        std::ostringstream os("");
        for(const auto &pair : ofxSpeechSynthesizerLanguageCodes) {
            os << "\n  " << pair.first << "\n";
        }
        ofLogNotice("ofxSpeechSynthesizerLanguageCodes:") << os.str();
    }
    void SpeechSynthesizer::printAvailableVoices()
    {
        std::ostringstream os("");
        for(AVSpeechSynthesisVoice *voice in AVSpeechSynthesisVoice.speechVoices) {
            os << "\n  " << to_cpp(voice.name) << " [" << to_cpp(voice.language) << "]";
        }
        ofLogNotice("ofxSpeechSynthesizer::availableVoices") << os.str();
    };
    
    bool SpeechSynthesizer::isSpeaking() const
    { return impl->is_speaking(); };
    bool SpeechSynthesizer::isPaused() const
    { return impl->is_paused(); };
}

std::map<std::string, std::string> ofxSpeechSynthesizerLanguageCodes = {
    {"Arabic", "ar-SA"},
    {"Czech", "cs-CZ"},
    {"Danish", "da-DK"},
    {"German", "de-DE"},
    {"Greek", "el-GR"},
    {"English", "en-US"},
    {"English US", "en-US"},
    {"English AU", "en-AU"},
    {"English GB", "en-GB"},
    {"English IE", "en-IE"},
    {"English ZA", "en-ZA"},
    {"Spanish", "es-ES"},
    {"Spanish ES", "es-ES"},
    {"Spanish MX", "es-MX"},
    {"Finnish", "fi-FI"},
    {"French", "fr-FR"},
    {"French FR", "fr-FR"},
    {"French CA", "fr-CA"},
    {"Hindi", "hi-IN"},
    {"Hungarian", "hu-HU"},
    {"Indonesian", "id-ID"},
    {"Italian", "it-IT"},
    {"Japanese", "ja-JP"},
    {"Korean", "ko-KR"},
    {"Norwegian", "nl-NL"},
    {"Dutch", "nl-BE"},
    {"Norwegian", "no-NO"},
    {"Polish", "pl-PL"},
    {"Portuguese", "pt-PT"},
    {"Portuguese BR", "pt-BR"},
    {"Portuguese PT", "pt-PT"},
    {"Romanian", "ro-RO"},
    {"Russian", "ru-RU"},
    {"Slovak", "sk-SK"},
    {"Swedish", "sv-SE"},
    {"Thai", "th-TH"},
    {"Turkish", "tr-TR"},
    {"Chinese", "zh-CN"},
    {"Chinese CN", "zh-CN"},
    {"Chinese HK", "zh-HK"},
    {"Chinese TW", "zh-TW"}
};
