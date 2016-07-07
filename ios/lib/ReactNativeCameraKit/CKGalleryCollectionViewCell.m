//
//  CKGalleryCollectionViewCell.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKGalleryCollectionViewCell.h"
#import "SelectionGesture.h"
#import "GalleryData.h"

#define BADGE_SIZE              22
#define BADGE_MARGIN            5
#define BADGE_COLOR             0x00ADF5
#define IMAGE_OVERLAY_ALPHA     0.5

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]



static UIImage *selectedImage = nil;
static UIImage *unSelectedImage = nil;


@interface CKGalleryCollectionViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIImageView *badgeImageView;
@property (nonatomic, strong) UIView *imageOveray;
//@property (strong, nonatomic) UILabel *badgeLabel;

@end


@implementation CKGalleryCollectionViewCell


+(void)setSelectedImage:(UIImage*)image {
    if (image) selectedImage = image;
}


+(void)setUnSlectedImage:(UIImage*)image {
    if (image) unSelectedImage = image;
}


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    CGRect imageViewFrame = self.bounds;
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    
    [self addSubview:self.imageView];
    
    self.imageOveray = [[UIView alloc] initWithFrame:self.imageView.bounds];
    self.imageOveray.backgroundColor = [UIColor whiteColor];
    self.imageOveray.alpha = 0;
    [self.imageView addSubview:self.imageOveray];
    
    CGRect badgeRect = CGRectMake(self.imageView.bounds.size.width - (BADGE_SIZE + BADGE_MARGIN), BADGE_MARGIN, BADGE_SIZE, BADGE_SIZE);
    self.badgeImageView = [[UIImageView alloc] initWithFrame:badgeRect];
    [self addSubview:self.badgeImageView];
    
    self.isSelected = NO;
    
    
    SelectionGesture *gesture = [[SelectionGesture alloc] initWithTarget:self action:@selector(handleGesture:)];
    [self addGestureRecognizer:gesture];
    gesture.cancelsTouchesInView = NO;
    gesture.delegate = self;
    
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
        self.imageOveray.alpha = IMAGE_OVERLAY_ALPHA;
        if (selectedImage) {
            
            double frameDuration = 1.0/2.0; // 4 = number of keyframes
            self.badgeImageView.image = selectedImage;
            self.badgeImageView.transform = CGAffineTransformMakeScale(0.5, 0.5);
            [UIView animateKeyframesWithDuration:0.2 delay:0 options:0 animations:^{
                
                
                [UIView addKeyframeWithRelativeStartTime:0*frameDuration relativeDuration:frameDuration animations:^{
                    self.badgeImageView.transform = CGAffineTransformIdentity;
                }];
                
            } completion:nil];
            
        }
        else {
            self.badgeImageView.backgroundColor = UIColorFromRGB(BADGE_COLOR);
        }
    }
    else {
        self.imageOveray.alpha = 0;
        if (unSelectedImage) {
            [UIView animateWithDuration:0.3 animations:^{
                self.badgeImageView.image = unSelectedImage;
            } completion:^(BOOL finished) {
                
            }];
            
        }
        else {
            self.badgeImageView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.7];
        }
    }
}


-(void)handleGesture:(UIGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(0.9, 0.9);
            
        } completion:^(BOOL finished) {
            
        }];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateChanged)
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


@end
