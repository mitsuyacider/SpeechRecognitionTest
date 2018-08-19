#import <Foundation/Foundation.h>
#import "SpeechTest-Swift.h"
// Required

extern "C" {
    Bridge *bridgeInstance = [[Bridge alloc ] init];

    void _ex_startRecognizing() {
        // You can access Swift classes directly here.
        if (bridgeInstance) {
            [bridgeInstance swiftMethod2];
        }
    }

    void _ex_stopRecognizing() {
        if (bridgeInstance) {
            [bridgeInstance stopRecognizing];
        }
    }
}
