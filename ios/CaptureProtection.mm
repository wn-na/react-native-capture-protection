#import "CaptureProtection.h"
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
static int TAG_RECORD_PROTECTION_SCREEN = -1002;

@implementation CaptureProtection {
    bool hasRecordCapturedListener;
    UITextField* preventCaptureScreen;
    enum CaptureProtectionStatus {
        INIT_RECORD_LISTENER,
        REMOVE_RECORD_LISTENER,
        RECORD_LISTENER_NOT_EXIST,
        RECORD_LISTENER_EXIST,
        RECORD_DETECTED_START,
        RECORD_DETECTED_END,
    };
    UIViewController *recordProtecterViewController;
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
    return @[@"CaptureProtectionListener"];
}

- (NSError *)convertNSError: (NSException *)exception {
    return [NSError errorWithDomain:exception.name code:0 userInfo:@{
        NSUnderlyingErrorKey: exception,
        NSDebugDescriptionErrorKey: exception.userInfo ?: @{ },
        NSLocalizedFailureReasonErrorKey: (exception.reason ?: @"unknown_reason")
    }];
}


- (void)createRecordProtectionScreenWithImage: (UIImage *)image {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    recordProtecterViewController = [[UIViewController alloc] init];
    recordProtecterViewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = window.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [recordProtecterViewController.view addSubview:imageView];
    [recordProtecterViewController.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)createRecordProtectionScreenWithText: (NSString *)text {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    recordProtecterViewController = [[UIViewController alloc] init];
    recordProtecterViewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    [recordProtecterViewController.view setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.userInteractionEnabled = NO;
    label.text = text;
    label.frame = window.frame;
    [recordProtecterViewController.view addSubview:label];
}

- (void)createRecordProtectionScreen {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
    if (captureProtectScreenController == nil) {
        if(recordProtecterViewController == nil) {
            [self createRecordProtectionScreenWithText:@"record Detected"];
        }
        
        [window.rootViewController addChildViewController:recordProtecterViewController];
        [window.rootViewController.view addSubview:recordProtecterViewController.view];
        [window makeKeyAndVisible];
        [recordProtecterViewController didMoveToParentViewController:window.rootViewController];
    }
}

- (void)removeRecordProtectionScreen {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
    if (captureProtectScreenController != nil) {
         [captureProtectScreenController willMoveToParentViewController:nil];
         [captureProtectScreenController.view removeFromSuperview];
         [captureProtectScreenController removeFromParentViewController];
    }
}

- (void)recordEventDetected: (NSNotification *)notification {
    [self recordEventWithStatus:notification init:NO];
}

- (void)recordEventWithStatus: (NSNotification *)notification init: (Boolean)init {
    bool isCaptured = [[[UIScreen mainScreen] valueForKey:@"isCaptured"] boolValue];
    NSLog(@"[CaptureProtection] Call recordEventWithStatus %d", isCaptured == true);
    if (isCaptured) {
        [self createRecordProtectionScreen];
        [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_DETECTED_START)}];
    } else {
        [self removeRecordProtectionScreen];
        if (init != YES) {
            [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_DETECTED_END)}];
        }
    }
}

- (void)preventScreenshot: (Boolean)isStart resolve: (RCTPromiseResolveBlock)resolve {
    NSLog(@"[CaptureProtection] Call preventScreenshot with %@", (isStart ? @"YES" : @"NO"));
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->preventCaptureScreen == nil) {
            self->preventCaptureScreen = [[UITextField alloc] init];
            self->preventCaptureScreen.userInteractionEnabled = false;
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            [window addSubview:self->preventCaptureScreen];
            [window.layer.superlayer addSublayer:self->preventCaptureScreen.layer];
            [self->preventCaptureScreen.layer.sublayers.firstObject addSublayer:window.layer];
        }
        [self->preventCaptureScreen setSecureTextEntry:isStart];
        resolve(@(isStart ? self->preventCaptureScreen.isSecureTextEntry : !self->preventCaptureScreen.isSecureTextEntry));
    });
}



RCT_REMAP_METHOD(setRecordProtectionScreenWithImage,
    imageObj: (NSDictionary*) imageObj
    setRecordProtectionScreenWithImageResolver: (RCTPromiseResolveBlock)resolve
    setRecordProtectionScreenWithImageRejecter: (RCTPromiseRejectBlock)reject
) {
    @try {
        UIImage *image = [RCTConvert UIImage:imageObj];
        NSLog(@"[CaptureProtection] Call setRecordProtectionScreenWithImage");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createRecordProtectionScreenWithImage:image];
        });
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"setRecordProtectionScreenWithImage", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};


RCT_REMAP_METHOD(setRecordProtectionScreenWithText,
    warningText: (NSString *)warningText
    setRecordProtectionScreenWithImageResolvers: (RCTPromiseResolveBlock)resolve
    setRecordProtectionScreenWithImageRejecters: (RCTPromiseRejectBlock)reject
) {
    @try {
        NSLog(@"[CaptureProtection] Call setRecordProtectionScreenWithImage");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createRecordProtectionScreenWithText:warningText];
        });
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"setRecordProtectionScreenWithImage", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};



RCT_REMAP_METHOD(startPreventScreenshot,
    startPreventScreenshotResolver: (RCTPromiseResolveBlock)resolve
    startPreventScreenshotRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call startPreventScreenshot");
    @try {
        [self preventScreenshot:true resolve:resolve];
    }
    @catch (NSException *e) {
        reject(@"startPreventScreenshot", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(stopPreventScreenshot,
    stopPreventScreenshotResolver: (RCTPromiseResolveBlock)resolve
    stopPreventScreenshotRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call stopPreventScreenshot");
    @try {
        [self preventScreenshot:false resolve:resolve];
    }
    @catch (NSException *e) {
        reject(@"stopPreventScreenshot", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

RCT_REMAP_METHOD(isPreventScreenshot,
    isPreventScreenshotResolver: (RCTPromiseResolveBlock)resolve
    isPreventScreenshotRejector: (RCTPromiseRejectBlock)reject
) {
    if (preventCaptureScreen != nil) {
        resolve(@(preventCaptureScreen.isSecureTextEntry));
    } else {
        resolve(@(NO));
    }
}

RCT_REMAP_METHOD(stopPreventRecording,
    stopPreventRecordingResolver: (RCTPromiseResolveBlock)resolve
    stopPreventRecordingRejecter: (RCTPromiseRejectBlock)reject
) {
    @try {
        if (!hasRecordCapturedListener) {
            NSLog(@"[CaptureProtection] Call stopPreventRecording but already remove");
            [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_NOT_EXIST)}];
            resolve(@(NO));
        } else {
            NSLog(@"[CaptureProtection] Call stopPreventRecording");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenCapturedDidChangeNotification object:nil];
                [self removeRecordProtectionScreen];
            });
            hasRecordCapturedListener = NO;
            [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(REMOVE_RECORD_LISTENER)}];
            resolve(@(TRUE));
        }
    }
    @catch (NSException *e) {
        reject(@"stopPreventRecording", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

RCT_REMAP_METHOD(startPreventRecording,
    startPreventRecordingResolvers: (RCTPromiseResolveBlock)resolve
    startPreventRecordingRejecters: (RCTPromiseRejectBlock)reject
) {
    @try {
        if (hasRecordCapturedListener) {
            NSLog(@"[CaptureProtection] Call startPreventRecording but already init");
            [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_EXIST)}];
            resolve(@(NO));
        } else {
            NSLog(@"[CaptureProtection] Call startPreventRecording");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordEventDetected:) name:UIScreenCapturedDidChangeNotification object:nil];
                [self recordEventWithStatus:nil init:YES];
            });
            [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(INIT_RECORD_LISTENER)}];
            hasRecordCapturedListener = YES;
            resolve(@(YES));
        }
    }
    @catch (NSException *e) {
        reject(@"startPreventRecording", e.reason ?: @"unknown_message", [self convertNSError:e]);  
    }
};

RCT_REMAP_METHOD(hasRecordEventListener,
    hasRecordCapturedListenerResolver: (RCTPromiseResolveBlock)resolve
    hasRecordCapturedListenerRejector: (RCTPromiseRejectBlock)reject
) {
    resolve(@(hasRecordCapturedListener));
}

RCT_REMAP_METHOD(isRecording,
    isCapturedCapturedResolver: (RCTPromiseResolveBlock)resolve
    isCapturedCapturedRejector: (RCTPromiseRejectBlock)reject
) {
    resolve(@([[[UIScreen mainScreen] valueForKey:@"isCaptured"] boolValue]));
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeCaptureProtectionSpecJSI>(params);
}
#endif

@end
