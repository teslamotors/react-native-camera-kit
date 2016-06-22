//
//  CKGalleryCollectionViewCell.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKGalleryCollectionViewCell.h"

@interface CKGalleryCollectionViewCell ()

@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation CKGalleryCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    CGRect imageViewFrame = self.bounds;
    imageViewFrame.size.width *= 0.97;
    imageViewFrame.size.height *= 0.97;
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    self.imageView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.imageView];
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.isSelected = NO;
    
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

-(void)setIsSelected:(BOOL)isSelected {
    
    _isSelected = isSelected;
    if (_isSelected) {
        self.backgroundColor = [UIColor blueColor];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    
    
}

@end
