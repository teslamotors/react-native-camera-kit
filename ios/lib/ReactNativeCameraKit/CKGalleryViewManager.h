//
//  CKGalleryViewManager.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTViewManager.h>
#import <React/RCTConvert.h>
#else
#import "RCTViewManager.h"
#import "RCTConvert.h"
#endif



@interface CKGalleryViewManager : RCTViewManager

+(NSMutableDictionary*)infoForAsset:(PHAsset*)asset imageRequestOptions:(PHImageRequestOptions*)imageRequestOptions;


@end
