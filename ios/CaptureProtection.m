
#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTConvert.h>

@interface RCT_EXTERN_MODULE(CaptureProtection, RCTEventEmitter)
// ScreenShot
RCT_EXTERN_METHOD(allowScreenshot:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

RCT_EXTERN_METHOD(preventScreenshot:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
// Screen Record
RCT_EXTERN_METHOD(allowScreenRecord:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

RCT_EXTERN_METHOD(preventScreenRecord:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventScreenRecordWithText:(NSString *) text
                  textColor:(NSString *) textColor
                  backgroundColor: (NSString *) backgroundColor
                  resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventScreenRecordWithImage:(NSDictionary*) image
                  resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

// App Switcher
RCT_EXTERN_METHOD(allowAppSwitcher:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

RCT_EXTERN_METHOD(preventAppSwitcher:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventAppSwitcherWithText:(NSString *)text
                  textColor:(NSString *)textColor
                  backgroundColor: (NSString *)backgroundColor
                  resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventAppSwitcherWithImage:(NSDictionary*) image
                  resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

// Etc
RCT_EXTERN_METHOD(hasListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(protectionStatus:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(isScreenRecording:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
@end
