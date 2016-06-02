//
//  CKCameraManager.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

@import AVFoundation;
#import "RCTViewManager.h"
#import "RCTConvert.h"

typedef NS_ENUM(NSInteger, CKCameraFlashMode) {
    CKCameraFlashModeAuto,
    CKCameraFlashModeOn,
    CKCameraFlashModeOff
};

@interface RCTConvert(CKCameraFlashMode)

+ (CKCameraFlashMode)CKCameraFlashMode:(id)json;

@end

@interface CKCameraManager : RCTViewManager




@end
