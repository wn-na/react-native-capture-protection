#import "CaptureProtection.h"
#import <React/RCTEventEmitter.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
static int TAG_RECORD_PROTECTION_SCREEN = -1002;

@implementation CaptureProtection {
  NSString* SCREEN_IMAGE;
  bool hasRecordCapturedListener;
  enum CaptureProtectionStatus {
    INIT_RECORD_LISTENER,
    REMOVE_RECORD_LISTENER,
    RECORD_LISTENER_NOT_EXIST,
    RECORD_LISTENER_EXIST,
    RECORD_DETECTED_START,
    RECORD_DETECTED_END,
  };
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents {
  return @[@"CaptureProtectionListener"];
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
    [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_DETECTED_START)}];
  } else {
    [self removeRecordProtectionScreen];
    if (init != TRUE) {
      [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_DETECTED_END)}];
    }
  }
}

RCT_REMAP_METHOD(removeRecordCaptureProtecter,
  removeRecordCaptureProtecterResolver: (RCTPromiseResolveBlock)resolve
  removeRecordCaptureProtecterRejecter: (RCTPromiseRejectBlock)reject
) {
  @try {
    if (!hasRecordCapturedListener) {
      NSLog(@"[CaptureProtection] Call removeRecordCaptureProtecter but already remove");
      [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_NOT_EXIST)}];
      resolve(@(NO));
    } else {
      NSLog(@"[CaptureProtection] Call removeRecordCaptureProtecter");
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenCapturedDidChangeNotification object:nil];
        [self removeRecordProtectionScreen];
      });
      hasRecordCapturedListener = NO;
      [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(REMOVE_RECORD_LISTENER)}];
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
      [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(RECORD_LISTENER_EXIST)}];
      resolve(@(NO));
    } else {
      SCREEN_IMAGE = screen;
      NSLog(@"[CaptureProtection] Call addRecordCaptureProtecter");
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordEventDetected:) name:UIScreenCapturedDidChangeNotification object:nil];
        [self recordEventWithStatus:nil init:YES];
      });
      [self.bridge.eventDispatcher sendAppEventWithName:@"CaptureProtectionListener" body:@{@"status": @(INIT_RECORD_LISTENER)}];
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
