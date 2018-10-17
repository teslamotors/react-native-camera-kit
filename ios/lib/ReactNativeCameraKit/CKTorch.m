//
//  CKTorch.m
//  ReactNativeCameraKit
//
//  Created by Shalom Yerushalmy on 16/10/2018.
//  Copyright © 2018 Wix. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CKTorch.h"

@implementation CKTorch

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(switchState:(BOOL *)newState)
{
    if ([AVCaptureDevice class]) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch]){
            [device lockForConfiguration:nil];
            
            if (newState) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
            
            [device unlockForConfiguration];
        }
    }
}

@end
