//
//  CKCameraManager.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKCameraManager.h"
#import "CKCamera.h"


@interface CKCameraManager ()

@property (nonatomic, strong) CKCamera *camera;

@end

@implementation CKCameraManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    self.camera = [CKCamera new];
    return self.camera;
}

RCT_EXPORT_VIEW_PROPERTY(cameraOptions, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(onReadCode, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(scannerOptions, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(showFrame, BOOL)
RCT_EXPORT_VIEW_PROPERTY(resetFocusTimeout, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(resetFocusWhenMotionDetected, BOOL)

RCT_EXPORT_METHOD(checkDeviceCameraAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {

    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        resolve(@YES);
    } else if(authStatus == AVAuthorizationStatusNotDetermined) {
        resolve(@(-1));
    } else {
        resolve(@NO);
    }
}

RCT_EXPORT_METHOD(requestDeviceCameraAuthorization:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    __block NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (resolve) {
            resolve(@(granted));
        }
    }];
}


RCT_EXPORT_METHOD(capture:(BOOL)shouldSaveToCameraRoll
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [self.camera snapStillImage:shouldSaveToCameraRoll success:^(NSDictionary *imageObject) {
        if (imageObject) {
            if (resolve) {
                resolve(imageObject);
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

RCT_EXPORT_METHOD(setTorchMode:(CKCameraTorchMode)torchMode
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [self.camera setTorchMode:torchMode callback:^(BOOL success) {
        if (resolve) {
            resolve([NSNumber numberWithBool:success]);
        }
    }];
}


@end
