//
//  CKCameraManager.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKCameraManager.h"
#import "CKCamera.h"

@implementation CKCameraManager

RCT_EXPORT_MODULE()


- (UIView *)view {
    return [CKCamera new];
}


@end
