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

+(NSMutableDictionary*)infoForAsset:(PHAsset*)asset
                imageRequestOptions:(PHImageRequestOptions*)imageRequestOptions
                       imageQuality:(NSString*)imageQuality;


@end
