//
//  CKCameraOverlayView.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 17/07/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKOverlayObject.h"

@interface CKCameraOverlayView : UIView


@property (nonatomic, strong, readonly) UIView *centerView;
@property (nonatomic, strong, readonly) CKOverlayObject *overlayObject;



-(instancetype)initWithFrame:(CGRect)frame ratioString:(NSString*)ratioString overlayColor:(UIColor*)overlayColor;

-(void)setRatio:(NSString*)ratioString;



@end
