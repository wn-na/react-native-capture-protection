#import "CaptureProtection.h"
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <UIKit/UIKit.h>
static int TAG_RECORD_PROTECTION_SCREEN = -1002;
static int TAG_SCREEN_PROTECTION = -1004;

@implementation CaptureProtection {
    bool hasListeners;
    bool hasScreenRecordObserver;
    bool hasScreenshotObserver;
    bool isPreventScreenRecord;
    bool isPreventScreenshot;
    bool isBundleObserver;
    enum CaptureProtectionStatus {
        INIT_RECORD_LISTENER,
        REMOVE_RECORD_LISTENER,
        RECORD_LISTENER_NOT_EXIST,
        RECORD_LISTENER_EXIST,
        RECORD_DETECTED_START,
        RECORD_DETECTED_END,
        CAPTURE_DETECTED,
        UNKNOWN
    };
    bool isBackgroundObserver;
    bool isPreventBackground;
    UITextField* secureTextField;
    UIViewController *protecterViewController;
    UIViewController *protecterScreenViewController;
    NSString* text;
    NSString* textColor;
    NSString* backgroundColor;
    NSString* backgroundScreenColor;
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
    if (hasListeners) {
        [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:CAPTURE_DETECTED]];
    }
}

- (UIColor *)colorFromHexString: (NSString *)hexString {
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }

    if (hexString.length != 6) {
        return [UIColor blackColor];
    }

    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];

    CGFloat red   = ((rgbValue >> 16) & 0xFF) / 255.0;
    CGFloat green = ((rgbValue >> 8) & 0xFF) / 255.0;
    CGFloat blue  = (rgbValue & 0xFF) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void)bundleObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:RCTBridgeWillReloadNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"RCTBridgeWillReloadNotification");
            if (self->secureTextField) {
                [self->secureTextField setSecureTextEntry:false];
            }
            [self removeScreenShotObserver];
            [self removeScreenRecordObserver];
            self->protecterViewController = nil;
            self->hasScreenRecordObserver = false;
            self->hasScreenshotObserver = false;
            self->isPreventScreenRecord = false;
            self->isPreventScreenshot = false;
        });
    }];
}

- (void)eventScreenRecordWithInit: (NSNotification *)notification init:(BOOL) init {
    bool isCaptured = [[[UIScreen mainScreen] valueForKey:@"isCaptured"] boolValue]; 
    if (isCaptured) {
        if (isPreventScreenRecord) {
            [self createRecordProtectionScreen];
        }
        if (hasListeners) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:RECORD_DETECTED_START]];
        }
    } else {
        [self removeRecordProtectionScreen];
        if (!init) {
            if (hasListeners) {
                [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:RECORD_DETECTED_END]];
            }
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
    [imageView setClipsToBounds:YES];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [protecterViewController.view addSubview:imageView];
    [protecterViewController.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)createRecordProtectionScreenWithText: (NSString *)text
                                   textColor: (NSString *)textColor
                             backgroundColor: (NSString *)backgroundColor {
    self->text = text;
    self->textColor = textColor;
    self->backgroundColor = backgroundColor;
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
    if (captureProtectScreenController != nil) {
        [captureProtectScreenController willMoveToParentViewController:nil];
        [captureProtectScreenController.view removeFromSuperview];
        [captureProtectScreenController removeFromParentViewController];
    }
    if(self->protecterViewController != nil) {
        [self->protecterViewController willMoveToParentViewController:nil];
        [self->protecterViewController.view removeFromSuperview];
        [self->protecterViewController removeFromParentViewController];
    }
    protecterViewController = [[UIViewController alloc] init];
    protecterViewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    [protecterViewController.view setBackgroundColor:[self colorFromHexString: self->backgroundColor]];
    
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [self colorFromHexString: self->textColor];
    label.userInteractionEnabled = NO;
    label.text = self->text;
    label.frame = window.frame;
    [protecterViewController.view addSubview:label];
}

- (void)createRecordProtectionScreen {
    dispatch_async(dispatch_get_main_queue(),
 ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
        if (captureProtectScreenController == nil) {
            if(self->protecterViewController != nil) {
                [self->protecterViewController willMoveToParentViewController:nil];
                [self->protecterViewController.view removeFromSuperview];
                [self->protecterViewController removeFromParentViewController];
            }
            
            if (self->text == nil) {
                self->text = @"record Detected";
            }
            if (self->textColor == nil) {
                self->textColor = @"#000000";
            }
            if (self->backgroundColor == nil) {
                self->backgroundColor = @"#ffffff";
            }
            [self createRecordProtectionScreenWithText:self->text textColor:self->textColor backgroundColor:self->backgroundColor];
            
            
            [window.rootViewController addChildViewController:self->protecterViewController];
            [window.rootViewController.view addSubview:self->protecterViewController.view];
            [window makeKeyAndVisible];
            [self->protecterViewController didMoveToParentViewController:window.rootViewController];
            
        }
    });
}

- (void)removeRecordProtectionScreen {
    dispatch_async(dispatch_get_main_queue(),
 ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
        if (captureProtectScreenController != nil) {
            [captureProtectScreenController willMoveToParentViewController:nil];
            [captureProtectScreenController.view removeFromSuperview];
            [captureProtectScreenController removeFromParentViewController];
        }
    });
}

- (void) addBackgroundObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationWillResignActiveNotification
                                                      object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"UIApplicationWillResignActiveNotification");
            [self secureBackgroundView:true];
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationDidEnterBackgroundNotification
                                                      object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"UIApplicationDidEnterBackgroundNotification");
            [self secureBackgroundView:true];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationDidBecomeActiveNotification
                                                      object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"UIApplicationDidBecomeActiveNotification");
            [self secureBackgroundView:false];
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName: UIApplicationWillEnterForegroundNotification
                                                      object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"UIApplicationWillEnterForegroundNotification");
            [self secureBackgroundView:false];
        });
    }];
}

- (void)secureBackgroundView: (BOOL)show  {
    dispatch_async(dispatch_get_main_queue(),
 ^{
        if (self->protecterScreenViewController != nil) {
            [self->protecterScreenViewController willMoveToParentViewController:nil];
            [self->protecterScreenViewController.view removeFromSuperview];
            [self->protecterScreenViewController removeFromParentViewController];
        }
        if (!self->isPreventBackground) {
            return;
        }
        
        if (show) {
            UIViewController* viewController = [[UIViewController alloc] init];
            viewController.view.window.windowLevel = UIWindowLevelAlert;
            self->protecterScreenViewController = viewController;
            viewController.view.backgroundColor = UIColor.redColor;
            if (self->backgroundScreenColor == nil) {
                self->backgroundScreenColor = @"#ffffff";
            }
            viewController.view.backgroundColor = [self colorFromHexString: self->backgroundScreenColor];
            UIWindow *window = [[UIApplication sharedApplication] delegate].window;
            
            [window makeKeyAndVisible];
            
            [window.layer.superlayer addSublayer:viewController.view.layer];
            [viewController.view.layer.sublayers.firstObject addSublayer:viewController.view.window.layer];
        }
    
    });
}

- (void)secureScreenshotView: (BOOL)isSecure  {
    dispatch_async(dispatch_get_main_queue(),
 ^{
        if (self->isBundleObserver != true) {
            self->isBundleObserver = true;
            [self bundleObserver];
        }
        if (self->isBackgroundObserver != true) {
            self->isBackgroundObserver = true;
            [self addBackgroundObserver];
        }
        if (self->secureTextField == nil) {
            self->secureTextField = [[UITextField alloc] init];
            self->secureTextField.userInteractionEnabled = false;
            self->secureTextField.tag = TAG_SCREEN_PROTECTION;
            UIWindow *window = [[UIApplication sharedApplication] delegate].window;
            
            [window makeKeyAndVisible];
            
            [window.layer.superlayer addSublayer:self->secureTextField.layer];
            [self->secureTextField.layer.sublayers.firstObject addSublayer:window.layer];
            [self->secureTextField.layer.sublayers.lastObject addSublayer:window.layer];
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
    if (self->isBackgroundObserver != true) {
        self->isBackgroundObserver = true;
        [self addBackgroundObserver];
    }
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
- (void) startObserving {
    hasListeners = YES;
}

- (void) stopObserving {
    hasListeners = NO;
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
        reject(@"setScreenRecordScreenWithImage",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
    }
};

RCT_REMAP_METHOD(setScreenRecordScreenWithText,
                 screenText: (NSString *)screenText
                 textColor: (NSString *)textColor
                 backgroundColor: (NSString *)backgroundColor
                 setScreenRecordScreenWithTextResolvers: (RCTPromiseResolveBlock)resolve
                 setScreenRecordScreenWithTextRejecters: (RCTPromiseRejectBlock)reject
                 ) {
    NSLog(@"[CaptureProtection] Call setScreenRecordScreenWithText");
    @try {
        dispatch_async(dispatch_get_main_queue(),
 ^{
            [self createRecordProtectionScreenWithText:screenText textColor:textColor backgroundColor:backgroundColor];
        });
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"setScreenRecordScreenWithText",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
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
        reject(@"addScreenshotListener",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
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
        reject(@"addScreenRecordListener",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
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

RCT_REMAP_METHOD(allowBackground,
                 allowBackgroundResolver: (RCTPromiseResolveBlock)resolve
                 allowBackgroundRejecter: (RCTPromiseRejectBlock)reject
                 ) {
    isPreventBackground = NO;
};

RCT_REMAP_METHOD(preventBackground,
                 backgroundColor: (NSString *)backgroundColor
                 preventBackgroundResolver: (RCTPromiseResolveBlock)resolve
                 preventBackgroundRejecter: (RCTPromiseRejectBlock)reject
                 ) {
    isPreventBackground = YES; 
    self->backgroundScreenColor = backgroundColor;
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
        isPreventBackground = NO;
        isPreventScreenshot = NO;
        if (hasListeners) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:UNKNOWN]];
        }
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"allowScreenshot",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
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
        isPreventBackground = YES;
        isPreventScreenshot = YES;
        if (hasListeners) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:UNKNOWN]];
        }
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
        if (hasListeners) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:UNKNOWN]];
        }
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"allowScreenRecord",
               e.reason ?: @"unknown_message",
               [self convertNSError:e]);
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
        if (hasListeners) {
            [self sendEventWithName:@"CaptureProtectionListener" body:[self eventMessage:UNKNOWN]];
        }
        resolve(@(YES));
    }
    @catch (NSException *e) {
        reject(@"preventScreenRecord", e.reason ?: @"unknown_message", [self convertNSError:e]); 
    }
};

@end
