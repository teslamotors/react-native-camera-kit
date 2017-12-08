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

#if __has_include(<React/RCTRootView.h>)
#import <React/RCTRootView.h>
#else
#import "RCTRootView.h"
#endif

#if __has_include(<React/RCTRootViewDelegate.h>)
#import <React/RCTRootViewDelegate.h>
#else
#import "RCTRootViewDelegate.h"
#endif

@interface CKGalleryCustomCollectionViewCell () <RCTRootViewDelegate>
{
    RCTRootView *_componentRootView;
    UIImageView *_imageView;
    NSDictionary *_prevStyleDict;
}
@end

@implementation CKGalleryCustomCollectionViewCell


-(void) applyStyle:(NSDictionary*)styleDict {
    
    if (styleDict[CUSOM_BUTTON_COMPONENT]) {
        if (!_componentRootView) {
            _componentRootView = [[RCTRootView alloc] initWithBridge:self.bridge moduleName:styleDict[CUSOM_BUTTON_COMPONENT] initialProperties:nil];
            _componentRootView.delegate = self;
            _componentRootView.frame = self.bounds;
            _componentRootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _componentRootView.backgroundColor = [UIColor clearColor];
            [self addSubview:_componentRootView];
        } else {
            _componentRootView.frame = self.bounds;
        }
    }
    
    if (_componentRootView == nil) {
        id imageProps = styleDict[CUSOM_BUTTON_IMAGE];
        if (imageProps) {
            UIImage *image = [self getImage:imageProps];
            if (!_imageView) {
                _imageView = [[UIImageView alloc] initWithImage:image];
                _imageView.backgroundColor = [UIColor clearColor];
                _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _imageView.frame = self.bounds;
                _imageView.contentMode = UIViewContentModeCenter;
                [self addSubview:_imageView];
            } else {
                _imageView.frame = self.bounds;
                _imageView.image = image;
            }
        }
        
        id backgroundColorProps = styleDict[CUSOM_BUTTON_BACKGROUND_COLOR];
        if (backgroundColorProps) {
            UIColor *backgroundColor = [RCTConvert UIColor:backgroundColorProps];
            self.backgroundColor = backgroundColor;
        }
    }
    
    _prevStyleDict = styleDict;
}

-(UIImage*)getImage:(NSDictionary*)currentImageProps {
    //if it's the same image - don't load it again
    UIImage *image = nil;
    if (_prevStyleDict == nil) {
        image = [RCTConvert UIImage:currentImageProps];
    } else {
        NSDictionary *prevImageProps = _prevStyleDict[CUSOM_BUTTON_IMAGE];
        if (prevImageProps == nil || (prevImageProps != nil && ![prevImageProps isEqualToDictionary:currentImageProps])) {
            image = [RCTConvert UIImage:currentImageProps];
        } else if (_imageView != nil) {
            image = _imageView.image;
        }
    }
    return image;
}

#pragma - mark RCTRootViewDelegate methods

- (void)rootViewDidChangeIntrinsicSize:(RCTRootView *)rootView {
    if (rootView == _componentRootView) {
        [rootView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    }
}

@end
