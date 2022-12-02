
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNCaptureProtectionSpec.h"

@interface CaptureProtection : NSObject <NativeCaptureProtectionSpec>
- (void)recordEventDetected: (NSNotification*)notification;
- (void)recordEventWithStatus: (NSNotification *)notification init: (Boolean)init;
- (void)createRecordProtectionScreen;
- (void)removeRecordProtectionScreen;
#else
#import <React/RCTBridgeModule.h>

@interface CaptureProtection : NSObject <RCTBridgeModule>
#endif

@end
