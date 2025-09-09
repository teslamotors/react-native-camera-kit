#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <NativeCameraKitSpec/NativeCameraKitSpec.h>
#else
#import <React/RCTBridge.h>
#endif

@interface RNCameraKitModule : NSObject
#ifdef RCT_NEW_ARCH_ENABLED
<NativeCameraKitModuleSpec>
#else
<RCTBridgeModule>
#endif

@end
