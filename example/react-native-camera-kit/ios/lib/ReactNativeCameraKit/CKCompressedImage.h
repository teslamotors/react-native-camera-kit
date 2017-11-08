//
//  CKCompressedImage.h
//  ReactNativeCameraKit
//
//  Created by Sergey Ilyevsky on 15/05/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CKCompressedImage : NSObject

- (instancetype)initWithImage:(UIImage *)image imageQuality:(NSString*)imageQuality;

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSData *data;

@end
