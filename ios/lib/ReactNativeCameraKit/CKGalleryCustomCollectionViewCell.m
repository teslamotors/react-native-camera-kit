//
//  CKGalleryCustomCellCollectionViewCell.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 28/02/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import "CKGalleryCustomCollectionViewCell.h"

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif



@implementation CKGalleryCustomCollectionViewCell

//-(instancetype)initWithFrame:(CGRect)frame {
//
//    self = [super initWithFrame:frame];
//    if (self) {

//    }
//    
//    return self;
//}


-(void) applyStyle:(NSDictionary*)styleDict {
    
    id imageProp = styleDict[CUSOM_BUTTON_IMAGE];
    if (imageProp) {
        UIImage *image = [RCTConvert UIImage:imageProp];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = self.bounds;
        imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
    }
    
    id backgroundColorProps = styleDict[CUSOM_BUTTON_BACKGROUND_COLOR];
    if (backgroundColorProps) {
        UIColor *backgroundColor = [RCTConvert UIColor:backgroundColorProps];
        self.backgroundColor = backgroundColor;
    }
    
}



@end
