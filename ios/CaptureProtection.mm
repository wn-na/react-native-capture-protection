#import "CaptureProtection.h"
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
static int TAG_RECORD_PROTECTION_SCREEN = -1002;

@implementation CaptureProtection {
    bool hasScreenRecordObserver;
    bool hasScreenshotObserver;
    bool isPreventScreenRecord;
    bool isPreventScreenshot;
    enum CaptureProtectionStatus {
        INIT_RECORD_LISTENER,
        REMOVE_RECORD_LISTENER,
        RECORD_LISTENER_NOT_EXIST,
        RECORD_LISTENER_EXIST,
        RECORD_DETECTED_START,
        RECORD_DETECTED_END,
        CAPTURE_DETECTED
    };
    UITextField* secureTextField;
    UIViewController *protecterViewController;
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

- (NSDictionary *)eventMessage: (CaptureProtectionStatus)status {
    return @{
        @"status": @(status),
        @"isPrevent": @{
            @"screenshot": @(isPreventScreenshot), 
            @"record": @(isPreventScreenRecord)
        }
    };
}

// Observer Event
- (void)eventScreenshot: (NSNotification *)notification {
    [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:CAPTURE_DETECTED]];  
}

- (void)eventScreenRecordWithInit: (NSNotification *)notification init:(BOOL) init {
    bool isCaptured = [[[UIScreen mainScreen] valueForKey:@"isCaptured"] boolValue]; 
    if (isCaptured) {
        if (isPreventScreenRecord) {
            [self createRecordProtectionScreen];
        }
        [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:RECORD_DETECTED_START]];
    } else {
        [self removeRecordProtectionScreen];
        if (!init) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:RECORD_DETECTED_END]];
        }
    }
}

- (void)eventScreenRecord: (NSNotification *)notification {
    [self eventScreenRecordWithInit:notification init:NO];
}

- (void)setScreenRecordScreenWithImage: (UIImage *)image {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    protecterViewController = [[UIViewController alloc] init];
    protecterViewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = window.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [protecterViewController.view addSubview:imageView];
    [protecterViewController.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)createRecordProtectionScreenWithText: (NSString *)text {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    protecterViewController = [[UIViewController alloc] init];
    protecterViewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    [protecterViewController.view setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.userInteractionEnabled = NO;
    label.text = text;
    label.frame = window.frame;
    [protecterViewController.view addSubview:label];
}

- (void)createRecordProtectionScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
        if (captureProtectScreenController == nil) {
            if(self->protecterViewController == nil) {
                [self createRecordProtectionScreenWithText:@"record Detected"];
            }
            
            [window.rootViewController addChildViewController:self->protecterViewController];
            [window.rootViewController.view addSubview:self->protecterViewController.view];
            [window makeKeyAndVisible];
            [self->protecterViewController didMoveToParentViewController:window.rootViewController];
        }
    });
}

- (void)removeRecordProtectionScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
        if (captureProtectScreenController != nil) {
            [captureProtectScreenController willMoveToParentViewController:nil];
            [captureProtectScreenController.view removeFromSuperview];
            [captureProtectScreenController removeFromParentViewController];
        }
    });
}

- (void)secureScreenshotView: (BOOL)isSecure  { 
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->secureTextField == nil) {
            self->secureTextField = [[UITextField alloc] init];
            self->secureTextField.userInteractionEnabled = false;
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            [window.layer.superlayer addSublayer:self->secureTextField.layer];
            if (self->secureTextField.layer.sublayers.firstObject != nil) {
                [self->secureTextField.layer.sublayers.firstObject addSublayer:window.layer];
            }
        }
        [self->secureTextField setSecureTextEntry:isSecure];
    });
}

- (void) addScreenShotObserver {
    if (!hasScreenshotObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventScreenshot:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
        hasScreenshotObserver = YES;
    }
}

- (void) removeScreenShotObserver {
    if (hasScreenshotObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationUserDidTakeScreenshotNotification object:nil];
        hasScreenshotObserver = NO;
    }
}

- (void) addScreenRecordObserver { 
    if (!hasScreenRecordObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventScreenRecord:) name:UIScreenCapturedDidChangeNotification object:nil];
        hasScreenRecordObserver = YES;
    }
}

- (void) removeScreenRecordObserver { 
    if (hasScreenRecordObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenCapturedDidChangeNotification object:nil];
        hasScreenRecordObserver = NO;
    }
}

RCT_REMAP_METHOD(setScreenRecordScreenWithImage,
    screenImage: (NSDictionary*) screenImage
    setScreenRecordScreenWithImageResolver: (RCTPromiseResolveBlock)resolve
    setScreenRecordScreenWithImageRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call setScreenRecordScreenWithImage");
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [RCTConvert UIImage:screenImage];
	        [self setScreenRecordScreenWithImage:image];
        });
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"setScreenRecordScreenWithImage", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(setScreenRecordScreenWithText,
    screenText: (NSString *)screenText
    setScreenRecordScreenWithTextResolvers: (RCTPromiseResolveBlock)resolve
    setScreenRecordScreenWithTextRejecters: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call setScreenRecordScreenWithText");
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createRecordProtectionScreenWithText:screenText];
        });
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"setScreenRecordScreenWithText", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(isScreenRecording,
    isScreenRecordingResolver: (RCTPromiseResolveBlock)resolve
    isScreenRecordingRejector: (RCTPromiseRejectBlock)reject
) {
    resolve(@([[[UIScreen mainScreen] valueForKey:@"isCaptured"] boolValue]));
}

RCT_REMAP_METHOD(hasListener,
    hasListenerResolver: (RCTPromiseResolveBlock)resolve
    hasListenerRejector: (RCTPromiseRejectBlock)reject
) {
    resolve(@{
        @"screenshot": @(hasScreenshotObserver), 
        @"record": @(hasScreenRecordObserver)
    });
}

RCT_REMAP_METHOD(getPreventStatus,
    getPreventStatusResolver: (RCTPromiseResolveBlock)resolve
    getPreventStatusRejector: (RCTPromiseRejectBlock)reject
) {
    resolve(@{
        @"screenshot": @(isPreventScreenshot), 
        @"record": @(isPreventScreenRecord)
    });
}

RCT_REMAP_METHOD(addScreenshotListener,
    addScreenshotListenerResolver: (RCTPromiseResolveBlock)resolve
    addScreenshotListenerRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call addScreenshotListener");
    @try {
        [self addScreenShotObserver];
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"addScreenshotListener", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(removeScreenshotListener,
    removeScreenshotListenerResolver: (RCTPromiseResolveBlock)resolve
    removeScreenshotListenerRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call removeScreenshotListener");
    @try { 
        [self removeScreenShotObserver];
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"removeScreenshotListener", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

RCT_REMAP_METHOD(addScreenRecordListener,
    addScreenRecordListenerResolver: (RCTPromiseResolveBlock)resolve
    addScreenRecordListenerRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call addScreenRecordListener");
    @try {
        [self addScreenRecordObserver];
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"addScreenRecordListener", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(removeScreenRecordListener,
    removeScreenRecordListenerResolver: (RCTPromiseResolveBlock)resolve
    removeScreenRecordListenerRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call removeScreenRecordListener");
    @try {
        [self removeScreenRecordObserver];
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"removeScreenRecordListener", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

RCT_REMAP_METHOD(allowScreenshot,
    removeScreenshotListener: (BOOL)removeScreenshotListener
    allowScreenshotResolver: (RCTPromiseResolveBlock)resolve
    allowScreenshotRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call allowScreenshot");
    @try {
        [self secureScreenshotView:false];
        if (removeScreenshotListener) {
            [self removeScreenShotObserver];
        }
        isPreventScreenshot = NO;
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"allowScreenshot", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(preventScreenshot,
    preventScreenshotResolver: (RCTPromiseResolveBlock)resolve
    preventScreenshotRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call preventScreenshot");
    @try { 
        [self secureScreenshotView:true];
        [self addScreenShotObserver];
        isPreventScreenshot = YES;
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"preventScreenshot", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

RCT_REMAP_METHOD(allowScreenRecord,
    removeScreenRecordListener: (BOOL)removeScreenRecordListener
    allowScreenRecordResolver: (RCTPromiseResolveBlock)resolve
    allowScreenRecordRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call allowScreenRecord");
    @try {
        [self removeRecordProtectionScreen];
        if (removeScreenRecordListener) {
            [self removeScreenRecordObserver];
        }
        isPreventScreenRecord = NO;
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"allowScreenRecord", e.reason ?: @"unknown_message", [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(preventScreenRecord,
    isImmediate: (BOOL)isImmediate
    preventScreenRecordResolver: (RCTPromiseResolveBlock)resolve
    preventScreenRecordRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call preventScreenRecord");
    @try { 
        [self addScreenRecordObserver];
        isPreventScreenRecord = YES;
        if (isImmediate) {
            [self eventScreenRecordWithInit:nil init:true];
        }
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"preventScreenRecord", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};
// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeCaptureProtectionSpecJSI>(params);
}
#endif

@end
