//
//  GalleryData.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/06/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;

@interface GalleryData : NSObject

-(instancetype)initWithFetchResults:(PHFetchResult*)fetchResults selectedImagesIds:(NSArray*)selectedImagesIds;

@property (nonatomic, strong, readonly) NSArray *data;



@end
