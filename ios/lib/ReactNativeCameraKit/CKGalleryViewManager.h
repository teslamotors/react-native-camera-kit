//
//  CKGalleryViewManager.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 20/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <UIKit/UIKit.h>


@import AVFoundation;
#import "RCTViewManager.h"
#import "RCTConvert.h"



@interface CKGalleryViewManager : RCTViewManager

+(NSMutableDictionary*)infoForAsset:(PHAsset*)asset imageRequestOptions:(PHImageRequestOptions*)imageRequestOptions;


@end
