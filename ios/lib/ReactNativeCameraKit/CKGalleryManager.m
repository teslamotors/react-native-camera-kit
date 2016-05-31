//
//  CKGallery.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import "CKGalleryManager.h"
#import <Photos/Photos.h>
#import "RCTConvert.h"


@implementation CKGallery : NSObject


//+(void)getAllAlbumsName:(RCTPromiseResolveBlock)resolve
//                 reject:(RCTPromiseRejectBlock)reject {
//    
//    NSMutableArray *albumsNames = [[NSMutableArray alloc] init];
//    
//    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
//    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
//    
//    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
//    
//    NSInteger albumsCount = [userAlbums count];
//    
//    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
//        [albumsNames addObject:collection.localizedTitle];
//        if (idx == albumsCount-1) {
//            if (resolve) {
//                resolve(@{@"albumsNames": albumsNames});
//            }
//        }
//    }];
//    
//    
//}


@end

@implementation CKGalleryManager

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(getAllAlbumsName:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{

    NSMutableArray *albumsNames = [[NSMutableArray alloc] init];
    
    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
    
    NSInteger albumsCount = [userAlbums count];
    
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        [albumsNames addObject:collection.localizedTitle];
        if (idx == albumsCount-1) {
            if (resolve) {
                resolve(albumsNames);
            }
        }
    }];
}

@end
