//
//  CKCameraManager.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKCameraManager.h"
#import "CKCamera.h"


@implementation RCTConvert(CustomSegmentedSelectedLineAlign)

RCT_ENUM_CONVERTER(CKCameraFlashMode, (@{
                                         @"auto": @(AVCaptureFlashModeAuto),
                                         @"on": @(AVCaptureFlashModeOn),
                                         @"off": @(AVCaptureFlashModeOff)
                                         }), AVCaptureFlashModeAuto, integerValue)

@end



@interface CKCameraManager ()

@property (nonatomic, strong) CKCamera *camera;

@end

@implementation CKCameraManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    self.camera = [CKCamera new];
    return self.camera;
}


RCT_EXPORT_METHOD(capture:(BOOL)shouldSaveToCameraRoll
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [self.camera snapStillImage:shouldSaveToCameraRoll success:^(NSString *imagePath) {
        if (imagePath) {
            if (resolve) {
                resolve(imagePath);
            }
        }
    }];
}

RCT_EXPORT_METHOD(changeCamera:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [self.camera changeCamera:^(BOOL success) {
        if (success) {
            if (resolve) {
                resolve([NSNumber numberWithBool:success]);
            }
        }
    }];
}

RCT_EXPORT_METHOD(setFlashMode:(CKCameraFlashMode)flashMode
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [self.camera setFlashMode:flashMode callback:^(BOOL success) {
        if (resolve) {
            resolve([NSNumber numberWithBool:success]);
        }
    }];
}


@end
