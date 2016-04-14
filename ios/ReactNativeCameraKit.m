//
//  RCTCameraKitManager.m
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTBridgeModule.h"
#import "AppDelegate.h"

@interface RCT_EXTERN_MODULE(ReactNativeCameraKit, NSObject)

RCT_EXTERN_METHOD(presentPhotoPicker:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)

@end
