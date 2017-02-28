//
//  CKGalleryCustomCellCollectionViewCell.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 28/02/2017.
//  Copyright © 2017 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CUSOM_BUTTON_IMAGE                      @"image"
#define CUSOM_BUTTON_BACKGROUND_COLOR           @"backgroundColor"

@interface CKGalleryCustomCollectionViewCell : UICollectionViewCell

-(void) applyStyle:(NSDictionary*)styleDict;


@end
