//
//  CKGalleryCollectionViewCell.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SUPPORTED_FILE_TYPES                    @"supportedFileTypes"
#define UNSUPPORTED_OVERLAY_COLOR               @"unsupportedOverlayColor"
#define UNSUPPORTED_IMAGE                       @"unsupportedImage"
#define UNSUPPORTED_TEXT                        @"unsupportedText"
#define UNSUPPORTED_TEXT_COLOR                  @"unsupportedTextColor"


@interface CKGalleryCollectionViewCell : UICollectionViewCell

+(void)setSelectedImageIcon:(UIImage*)image;
+(void)setUnSlectedImageIcon:(UIImage*)image;
+(void)setSupported:(NSDictionary*)newSupported;
+(void)setImageStrokeColor:(UIColor*)strokeColor;

+(void)cleanStaticsVariables;

@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isSupported;
@property (nonatomic) BOOL disableSelectionIcons;

@end
