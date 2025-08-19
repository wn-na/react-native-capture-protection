#import <Foundation/Foundation.h>
#ifdef RCT_NEW_ARCH_ENABLED
#import "generated/CaptureProtectionSpec/CaptureProtectionSpec.h"

@interface CaptureProtection : NSObject <NativeCaptureProtectionSpec>
#else
#import <React/RCTBridgeModule.h>

@interface CaptureProtection : NSObject <RCTBridgeModule>
#endif

@end
