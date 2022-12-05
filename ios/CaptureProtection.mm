#import "CaptureProtection.h"
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
static int TAG_RECORD_PROTECTION_SCREEN = -1002;

@implementation CaptureProtection {
    bool hasRecordCapturedListener;
    NSString* SCREEN_IMAGE;
    UITextField* preventCaptureScreen;
    enum CaptureProtectionStatus {
        INIT_RECORD_LISTENER,
        REMOVE_RECORD_LISTENER,
        RECORD_LISTENER_NOT_EXIST,
        RECORD_LISTENER_EXIST,
        RECORD_DETECTED_START,
        RECORD_DETECTED_END,
    };
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

- (void)createRecordProtectionScreen {
  UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
  UIViewController *captureProtectScreenController = (UIViewController *)[[window viewWithTag:TAG_RECORD_PROTECTION_SCREEN] nextResponder];
  if (captureProtectScreenController == nil) {
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view.tag = TAG_RECORD_PROTECTION_SCREEN;
    [viewController.view setBackgroundColor:[UIColor whiteColor]];
    
    UIImageView *imageView =  [[UIImageView alloc] initWithImage:[UIImage imageNamed:SCREEN_IMAGE]];
    imageView.frame = window.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [viewController.view addSubview:imageView];
    [viewController.view setBackgroundColor:[UIColor whiteColor]];
    
    
    [window.rootViewController addChildViewController:viewController];
    [window.rootViewController.view addSubview:viewController.view];
    [window makeKeyAndVisible];
    [viewController didMoveToParentViewController:window.rootViewController];
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
    if (init != TRUE) {
      [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_DETECTED_END)}];
    }
  }
}

- (void)preventScreenshot: (Boolean)isStart {
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
    });
}

RCT_REMAP_METHOD(startPreventScreenshot,
    startPreventScreenshotResolver: (RCTPromiseResolveBlock)resolve
    startPreventScreenshotRejecter: (RCTPromiseRejectBlock)reject
) {
    NSLog(@"[CaptureProtection] Call startPreventScreenshot");
    @try {
        [self preventScreenshot:true];
        resolve(@(preventCaptureScreen.isSecureTextEntry));
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
        [self preventScreenshot:false];
        resolve(@(preventCaptureScreen.isSecureTextEntry));
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

RCT_REMAP_METHOD(removeRecordCaptureProtecter,
  removeRecordCaptureProtecterResolver: (RCTPromiseResolveBlock)resolve
  removeRecordCaptureProtecterRejecter: (RCTPromiseRejectBlock)reject
) {
  @try {
    if (!hasRecordCapturedListener) {
      NSLog(@"[CaptureProtection] Call removeRecordCaptureProtecter but already remove");
      [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_NOT_EXIST)}];
      resolve(@(NO));
    } else {
      NSLog(@"[CaptureProtection] Call removeRecordCaptureProtecter");
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
    NSError *error = [NSError errorWithDomain:e.name code:0 userInfo:@{
        NSUnderlyingErrorKey: e,
        NSDebugDescriptionErrorKey: e.userInfo ?: @{ },
        NSLocalizedFailureReasonErrorKey: (e.reason ?: @"unknown_reason")
    }];
    reject(@"removeRecordCaptureProtecter", e.reason ?: @"unknown_message", error);
  }
};

RCT_REMAP_METHOD(addRecordCaptureProtecter,
  screen: (NSString*) screen
  addRecordCaptureProtecterResolver: (RCTPromiseResolveBlock)resolve
  addRecordCaptureProtecterRejecter: (RCTPromiseRejectBlock)reject
) {
  @try {
    if (hasRecordCapturedListener) {
      NSLog(@"[CaptureProtection] Call addRecordCaptureProtecter but already init");
      [self sendEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_EXIST)}];
      resolve(@(NO));
    } else {
      SCREEN_IMAGE = screen;
      NSLog(@"[CaptureProtection] Call addRecordCaptureProtecter");
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
    NSError *error = [NSError errorWithDomain:e.name code:0 userInfo:@{
        NSUnderlyingErrorKey: e,
        NSDebugDescriptionErrorKey: e.userInfo ?: @{ },
        NSLocalizedFailureReasonErrorKey: (e.reason ?: @"unknown_reason")
    }];
    reject(@"addRecordCaptureProtecter", e.reason ?: @"unknown_message", error);
  }
};

RCT_REMAP_METHOD(hasRecordCapturedListener,
  hasRecordCapturedListenerResolver: (RCTPromiseResolveBlock)resolve
  hasRecordCapturedListenerRejector: (RCTPromiseRejectBlock)reject
) {
  resolve(@(hasRecordCapturedListener));
}

RCT_REMAP_METHOD(isCaptured,
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
