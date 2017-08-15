//
//  CKGalleryCollectionViewCell.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif



#import "CKGalleryCollectionViewCell.h"
#import "SelectionGesture.h"
#import "GalleryData.h"

#define BADGE_MARGIN            5
#define BADGE_COLOR             0x00ADF5
#define IMAGE_OVERLAY_ALPHA     0.5

#define SELECTION_SELECTED_IMAGE        @"selectedImage"
#define SELECTION_UNSELECTED_IMAGE      @"unselectedImage"
#define SELECTION_IMAGE_POSITION        @"imagePosition"
#define SELECTION_OVERLAY_COLOR         @"overlayColor"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]



static UIImage *selectedImageIcon = nil;
static UIImage *unSelectedImageIcon = nil;
static NSDictionary *supported = nil;
static UIColor *imageStrokeColor = nil;
static NSDictionary *selection = nil;
static NSString *imagePosition = nil;
static UIColor *selectionOverlayColor = nil;
static UIColor *remoteDownloadIndicatorColor = nil;
static NSString *remoteDownloadIndicatorType = REMOTE_DOWNLOAD_INDICATOR_TYPE_SPINNER;



@interface CKGalleryCollectionViewCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIImageView *badgeImageView;
@property (nonatomic, strong) UIView *imageOveray;
@property (nonatomic, strong) UIView *unsupportedView;
@property (nonatomic, strong) SelectionGesture *gesture;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIProgressView *progressView;

@end


@implementation CKGalleryCollectionViewCell


+(void)setSelectedImageIcon:(UIImage*)image {
    if (image) selectedImageIcon = image;
}


+(void)setUnSlectedImageIcon:(UIImage*)image {
    if (image) unSelectedImageIcon = image;
}

+(void)setSupported:(NSDictionary*)newSupported {
    if (newSupported) supported = newSupported;
}

+(void)setImageStrokeColor:(UIColor*)strokeColor {
    if (strokeColor) imageStrokeColor = strokeColor;
}

+(void)setSelection:(NSDictionary*)selectionDict {
    if (selectionDict) selection = selectionDict;
}


+(void)cleanStaticsVariables {
    selectedImageIcon = nil;
    unSelectedImageIcon = nil;
    supported = nil;
    imageStrokeColor = nil;
    selection = nil;
    imagePosition = nil;
    selectionOverlayColor = nil;
    remoteDownloadIndicatorColor = nil;
}

+(void)setRemoteDownloadIndicatorColor:(UIColor*)color {
    if (color) remoteDownloadIndicatorColor = color;
}

+(void)setRemoteDownloadIndicatorType:(NSString*)type {
    if (type) remoteDownloadIndicatorType = type;
}

-(UIActivityIndicatorView*)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinner.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [_spinner startAnimating];
        if (remoteDownloadIndicatorColor) {
            [_spinner setColor:remoteDownloadIndicatorColor];
        }
        
    }
    return _spinner;
}

-(UIProgressView*)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(0, 0, self.bounds.size.width*0.8, self.bounds.size.height*0.15);
        _progressView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)*1.8);
        _progressView.progress = 0;
        if (remoteDownloadIndicatorColor) {
            _progressView.tintColor = remoteDownloadIndicatorColor;
        }
    }
    return _progressView;
}




-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    CGRect imageViewFrame = self.bounds;
    
    if(imageStrokeColor) {
        imageViewFrame.size.height -= 2;
        imageViewFrame.size.width -= 2;
        self.backgroundColor = imageStrokeColor;
    }
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    
    [self addSubview:self.imageView];
    
    self.imageOveray = [[UIView alloc] initWithFrame:self.imageView.bounds];
    self.imageOveray.opaque = NO;
    self.imageOveray.backgroundColor = [UIColor clearColor];
    
    [self.imageView addSubview:self.imageOveray];
    
    self.badgeImageView = [[UIImageView alloc] init];
    [self addSubview:self.badgeImageView];
    
    self.isSupported = YES;
    
    
    self.gesture = [[SelectionGesture alloc] initWithTarget:self action:@selector(handleGesture:)];
    [self addGestureRecognizer:self.gesture];
    self.gesture.cancelsTouchesInView = NO;
    self.gesture.delegate = self;
    
    [self applyStyleOnInit];
    
    return self;
}

-(void)applyStyleOnInit {
    id selectedImageIconProp = selection[SELECTION_SELECTED_IMAGE];
    if(selectedImageIconProp) {
        selectedImageIcon = [RCTConvert UIImage:selectedImageIconProp];
    }
    
    id unselectedImageIconProp = selection[SELECTION_UNSELECTED_IMAGE];
    if(unselectedImageIconProp) {
        unSelectedImageIcon = [RCTConvert UIImage:unselectedImageIconProp];
    }
    
    id overlayColorProp = selection[SELECTION_OVERLAY_COLOR];
    if(overlayColorProp) {
        selectionOverlayColor = [RCTConvert UIColor:overlayColorProp];
    }
    
}

-(CGRect)frameforImagePosition:(NSString*)position image:(UIImage*)image {
    CGRect badgeRect;
    
    if ([position isEqualToString:@"top-right"]) {
        badgeRect= CGRectMake(self.imageView.bounds.size.width - (image.size.width + BADGE_MARGIN), BADGE_MARGIN, image.size.width, image.size.height);
    }
    else if ([position isEqualToString:@"top-left"]) {
        badgeRect= CGRectMake(BADGE_MARGIN, BADGE_MARGIN, image.size.width, image.size.height);
    }
    else if ([position isEqualToString:@"bottom-right"]) {
        badgeRect= CGRectMake(self.imageView.bounds.size.width - (image.size.width + BADGE_MARGIN), self.imageView.bounds.size.height - (image.size.height + BADGE_MARGIN), image.size.width, image.size.height);
    }
    else if ([position isEqualToString:@"bottom-left"]) {
        badgeRect= CGRectMake(BADGE_MARGIN, self.imageView.bounds.size.height - (image.size.height + BADGE_MARGIN), image.size.width, image.size.height);
    }
    else if ([position isEqualToString:@"center"]) {
        badgeRect = CGRectMake((self.imageView.bounds.size.width - image.size.width) * 0.5, (self.imageView.bounds.size.height - image.size.height) * 0.5, image.size.width, image.size.height);
    }
    else {
        badgeRect = CGRectZero;
    }
    
    return badgeRect;
    
}

-(void)updateBadgeImageViewFrame {
    id imagePositionProp = selection[SELECTION_IMAGE_POSITION];
    if(!imagePositionProp) imagePositionProp = @"top-right"; // defualt
    CGRect badgeRect = [self frameforImagePosition:imagePositionProp image:self.badgeImageView.image];
    if (!CGRectIsEmpty(badgeRect)) {
        self.badgeImageView.frame = badgeRect;
    };
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.isSelected = NO;
    _isDownloading = NO;
    self.isSupported = YES;
    self.gesture.enabled = YES;
    
    [self.unsupportedView removeFromSuperview];
    self.unsupportedView = nil;
    
    [_spinner removeFromSuperview];
    _spinner = nil;
    
    [_progressView removeFromSuperview];
    _progressView = nil;
}


- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

-(void)setIsSupported:(BOOL)isSupported {
    _isSupported = isSupported;
    
    if (!_isSupported) {
        if (supported) {
            
            UIImageView *imageView;
            UILabel *unsupportedLabel;
            
            self.unsupportedView = [[UIView alloc] initWithFrame:self.bounds];
            
            UIColor *overlayColor = supported[UNSUPPORTED_OVERLAY_COLOR];
            if (overlayColor) {
                self.unsupportedView.backgroundColor = overlayColor;
            }
            
            UIImage *unsupportedImage = supported[UNSUPPORTED_IMAGE];
            if (unsupportedImage) {
                CGRect imageViewFrame = self.unsupportedView.bounds;
                imageViewFrame.size.height  = self.unsupportedView.bounds.size.height/4*2;
                imageViewFrame.origin.y = self.unsupportedView.bounds.size.height/4 - (imageViewFrame.size.height/6);
                
                imageView = [[UIImageView alloc] initWithImage:unsupportedImage];
                imageView.frame = imageViewFrame;
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                [self.unsupportedView addSubview:imageView];
            }
            
            
            NSString *unsupportedText = supported[UNSUPPORTED_TEXT];
            if (unsupportedText) {
                CGRect labelFrame = self.unsupportedView.bounds;
                labelFrame.size.height /= 4;
                labelFrame.origin.y = self.unsupportedView.center.y - labelFrame.size.height/2;
                if (imageView) {
                    labelFrame.origin.y = self.unsupportedView.bounds.size.height - labelFrame.size.height - (labelFrame.size.height/2);
                }
                unsupportedLabel = [[UILabel alloc] initWithFrame:labelFrame];
                unsupportedLabel.text = unsupportedText;
                unsupportedLabel.textAlignment = NSTextAlignmentCenter;
                
                UIColor *unsupportedTextColor = supported[UNSUPPORTED_TEXT_COLOR];
                if (unsupportedTextColor) {
                    unsupportedLabel.textColor = unsupportedTextColor;
                }
                
                [self.unsupportedView addSubview:unsupportedLabel];
            }
            
            [self addSubview:self.unsupportedView];
            [self.badgeImageView removeFromSuperview];
            self.gesture.enabled = NO;
        }
    }
    
    else {
        [self.unsupportedView removeFromSuperview];
        self.unsupportedView = nil;
        [self addSubview:self.badgeImageView];
        self.gesture.enabled = YES;
        
    }
}


-(void)setIsSelected:(BOOL)isSelected {
    
    _isSelected = isSelected;
    
    if (self.disableSelectionIcons) return;
    
    if (_isSelected) {
        self.imageOveray.backgroundColor = selectionOverlayColor ? selectionOverlayColor : [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        
        if (selectedImageIcon) {
            double frameDuration = 1.0/2.0; // 4 = number of keyframes
            self.badgeImageView.image = selectedImageIcon;
            [self updateBadgeImageViewFrame];
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
        self.imageOveray.backgroundColor = [UIColor clearColor];
        if (unSelectedImageIcon) {
            self.badgeImageView.image = unSelectedImageIcon;
            [self updateBadgeImageViewFrame];
        }
        else {
            self.badgeImageView.image = nil;
        }
    }
}

-(void)setIsDownloading:(BOOL)isDownloading {
    _isDownloading = isDownloading;
    [self updateRemoteDownload];
}

-(void)setDownloadingProgress:(CGFloat)downloadingProgress {
    _downloadingProgress = downloadingProgress;
    self.progressView.progress = downloadingProgress;
    
    [self updateRemoteDownload];
}

-(void)updateRemoteDownload {
    if (self.isDownloading) {
        if ([remoteDownloadIndicatorType isEqualToString:REMOTE_DOWNLOAD_INDICATOR_TYPE_SPINNER]) {
            [self addSubview:self.spinner];
        }
        else if ([remoteDownloadIndicatorType isEqualToString:REMOTE_DOWNLOAD_INDICATOR_TYPE_PROGRESS_BAR]) {
            if (![self.progressView isDescendantOfView:self]) {
                [self addSubview:self.progressView];
            }
        }
    }
    
    else {
        [self removeRemoteDownloadIndicator];
    }
}

-(void)removeRemoteDownloadIndicator {
    [_spinner removeFromSuperview];
    _spinner = nil;
    
    [_progressView removeFromSuperview];
    _progressView = nil;
}


-(void)handleGesture:(UIGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(0.9, 0.9);
            
        } completion:^(BOOL finished) {
            
        }];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
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
