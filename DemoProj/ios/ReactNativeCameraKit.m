#import "RCTBridgeModule.h"
#import "AppDelegate.h"


@interface RCT_EXTERN_MODULE(ReactNativeCameraKit, NSObject)

RCT_EXTERN_METHOD(presentPhotoPicker:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)

@end
