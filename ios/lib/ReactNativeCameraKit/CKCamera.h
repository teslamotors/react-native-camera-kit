//
//  CKCamera.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 31/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif


typedef void (^CaptureBlock)(NSDictionary *imageObject);
typedef void (^CallbackBlock)(BOOL success);

typedef NS_ENUM(NSInteger, CKCameraFlashMode) {
    CKCameraFlashModeAuto,
    CKCameraFlashModeOn,
    CKCameraFlashModeOff
};

@interface RCTConvert(CKCameraFlashMode)

+ (CKCameraFlashMode)CKCameraFlashMode:(id)json;

@end


typedef NS_ENUM(NSInteger, CKCameraFocushMode) {
    CKCameraFocushModeOn,
    CKCameraFocushModeOff,
};

@interface RCTConvert(CKCameraFocushMode)

+ (CKCameraFocushMode)CKCameraFocushMode:(id)json;

@end

typedef NS_ENUM(NSInteger, CKCameraZoomMode) {
    CKCameraZoomModeOn,
    CKCameraZoomModeOff,
};

@interface RCTConvert(CKCameraZoomMode)

+ (CKCameraZoomMode)CKCameraZoomMode:(id)json;

@end


@interface CKCamera : UIView

@property (nonatomic, readonly) AVCaptureDeviceInput *videoDeviceInput;


// api
- (void)snapStillImage:(BOOL)shouldSaveToCameraRoll success:(CaptureBlock)block;
- (void)changeCamera:(CallbackBlock)block;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode callback:(CallbackBlock)block;
- (void)setRatio:(NSString*)ratioString;

@end
