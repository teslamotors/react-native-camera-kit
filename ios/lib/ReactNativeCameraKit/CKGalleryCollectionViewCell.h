//
//  CKGalleryCollectionViewCell.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CKGalleryCollectionViewCell : UICollectionViewCell

+(void)setSelectedImage:(UIImage*)image;
+(void)setUnSlectedImage:(UIImage*)image;


@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@property (nonatomic) BOOL isSelected;

@end
