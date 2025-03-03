
#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTConvert.h>

@interface RCT_EXTERN_MODULE(CaptureProtection, RCTEventEmitter)

RCT_EXTERN_METHOD(setScreenRecordScreenWithImage:(NSDictionary*) screenImage resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(setScreenRecordScreenWithText:(NSString *)screenText textColor:(NSString *)textColor backgroundColor: (NSString *)backgroundColor resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(isScreenRecording:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(hasListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(getPreventStatus:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(addScreenshotListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(removeScreenshotListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(addScreenRecordListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(removeScreenRecordListener:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(allowBackground:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventBackground:(NSString *) backgroundColor resolver: (RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(allowScreenshot:(BOOL) removeScreenshotListener resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventScreenshot:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(allowScreenRecord:(BOOL*) removeScreenRecordListener resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)
RCT_EXTERN_METHOD(preventScreenRecord:(BOOL*) isImmediate resolver:(RCTPromiseResolveBlock) resolve rejecter:(RCTPromiseRejectBlock) reject)

@end
