//
//  CKCamera.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 31/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

typedef void (^CaptureBlock)(NSString *imagePath);
typedef void (^CallbackBlock)(BOOL success);


@interface CKCamera : UIView

@property (nonatomic, readonly) AVCaptureDeviceInput *videoDeviceInput;


// api
- (void)snapStillImage:(BOOL)shouldSaveToCameraRoll success:(CaptureBlock)block;
- (void)changeCamera:(CallbackBlock)block;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode callback:(CallbackBlock)block;

@end
