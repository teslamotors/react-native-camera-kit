//
//  CKGalleryCollectionViewCell.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKGalleryCollectionViewCell.h"

#define BADGE_SIZE          22
#define BADGE_MARGIN        5


@interface CKGalleryCollectionViewCell ()


@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UILabel *badgeLabel;

@end


@implementation CKGalleryCollectionViewCell


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    CGRect imageViewFrame = self.bounds;

    self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    
    self.imageView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.imageView];
    self.badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.imageView.bounds.size.width - (BADGE_SIZE + BADGE_MARGIN), BADGE_MARGIN, BADGE_SIZE, BADGE_SIZE)];
    self.badgeLabel.layer.cornerRadius = self.badgeLabel.bounds.size.width/2;
    self.badgeLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
    self.badgeLabel.clipsToBounds = YES;

    [self.imageView addSubview:self.badgeLabel];
    
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
        self.badgeLabel.backgroundColor = [UIColor blueColor];
    }
    else {
        self.badgeLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
    }
}


@end
