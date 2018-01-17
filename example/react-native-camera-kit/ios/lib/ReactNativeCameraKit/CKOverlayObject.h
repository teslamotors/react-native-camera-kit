//
//  CKOverlayObject.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 17/07/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CKOverlayObject : NSObject


@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) float ratio;

-(instancetype)initWithString:(NSString*)str;


@end
