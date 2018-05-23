#include "ofxiOS.h"
#include "ofxSpeechSynthesizer.h"

class ofApp : public ofxiOSApp {
    ofxSpeechSynthesizer synth;
public:
    void setup() {
        synth.setup("Arthur");
        synth.printAvailableLanguages();
        synth.printAvailableVoices();
    }
    void update() {}
    void draw() {}
    void exit() {}
    
    void touchDown(ofTouchEventArgs & touch) {
        if(synth.isSpeaking()) synth.stop(true);
        auto &&text = "Hello world";
        synth.speak(text);
//        ofx::SpeechUtterance utter;
//        utter.text = "Hello world";
//        utter.voice = "Kyoko";
//        utter.pitch = 2.0f;
//        utter.volume = 1.0f;
//        utter.rate = 0.5f;
//        synth.speak(utter);
    }
    void touchMoved(ofTouchEventArgs & touch) {}
    void touchUp(ofTouchEventArgs & touch) {}
    void touchDoubleTap(ofTouchEventArgs & touch) {}
    void touchCancelled(ofTouchEventArgs & touch) {}
    
    void lostFocus() {}
    void gotFocus() {}
    void gotMemoryWarning() {}
    void deviceOrientationChanged(int newOrientation) {}
};

int main() {
    //  here are the most commonly used iOS window settings.
    //------------------------------------------------------
    ofiOSWindowSettings settings;
    settings.enableRetina = false; // enables retina resolution if the device supports it.
    settings.enableDepth = false; // enables depth buffer for 3d drawing.
    settings.enableAntiAliasing = false; // enables anti-aliasing which smooths out graphics on the screen.
    settings.numOfAntiAliasingSamples = 0; // number of samples used for anti-aliasing.
    settings.enableHardwareOrientation = false; // enables native view orientation.
    settings.enableHardwareOrientationAnimation = false; // enables native orientation changes to be animated.
    settings.glesVersion = OFXIOS_RENDERER_ES1; // type of renderer to use, ES1, ES2, ES3
    settings.windowMode = OF_FULLSCREEN;
    ofCreateWindow(settings);
    
    return ofRunApp(new ofApp);
}
