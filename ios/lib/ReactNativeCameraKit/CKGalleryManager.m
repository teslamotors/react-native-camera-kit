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
#import "CKGalleryViewManager.h"

typedef void (^AlbumsBlock)(NSDictionary *albums);

@interface CKGalleryManager ()

@property (nonatomic, strong) PHFetchResult *allPhotos;
@property (nonatomic, strong) PHFetchResult *smartAlbums;
@property (nonatomic, strong) PHFetchResult *topLevelUserCollections;
@property (nonatomic, strong) PHFetchOptions *fetchOptions;

@end


@implementation CKGalleryManager


RCT_EXPORT_MODULE();


#pragma mark - lazy loading methods


-(PHFetchOptions*)fetchOptions {
    if (!_fetchOptions) {
        _fetchOptions = [[PHFetchOptions alloc] init];
        _fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    }
    return _fetchOptions;
}


-(PHFetchResult *)allPhotos {
    if (!_allPhotos) {
        _allPhotos = [PHAsset fetchAssetsWithOptions:self.fetchOptions];
    }
    return _allPhotos;
}


-(PHFetchResult *)topLevelUserCollections {
    if (!_topLevelUserCollections) {
        _topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    }
    return _topLevelUserCollections;
}


#pragma mark -


-(void)extractCollection:(id)collection
     imageRequestOptions:(PHImageRequestOptions*)options
           thumbnailSize:(CGSize)thumbnailSize
                   block:(AlbumsBlock)block {
    
    NSInteger collectionCount;
    if ([collection isKindOfClass:[PHAssetCollection class]]) {
        collectionCount = [PHAsset fetchAssetsInAssetCollection:collection options:nil].count;
    }
    else if ([collection isKindOfClass:[PHFetchResult class]]){
        collectionCount = ((PHFetchResult*)collection).count;
    }
    else {
        collectionCount = 0;
    }
    
    if (collectionCount > 0){
        
        NSString *albumName = ([collection isKindOfClass:[PHAssetCollection class]]) ? ((PHAssetCollection*)collection).localizedTitle : @"All photos";
        PHFetchResult *fetchResult = ([collection isKindOfClass:[PHAssetCollection class]]) ? [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil] : (PHAssetCollection*)collection;
        PHAsset *thumbnail = [fetchResult firstObject];
        
        NSMutableDictionary *albumInfo = [[NSMutableDictionary alloc] init];
        albumInfo[@"albumName"] = albumName;
        albumInfo[@"imagesCount"] = [NSNumber numberWithInteger:collectionCount];
        
        [[PHImageManager defaultManager]
         requestImageForAsset:thumbnail
         targetSize:thumbnailSize
         contentMode:PHImageContentModeAspectFit
         options:options
         resultHandler:^(UIImage *result, NSDictionary *info) {
             
             if (!albumInfo[@"image"]) {
                 albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
             }
             
             if (block) {
                 block(albumInfo);
             }
         }];
    }
    
    else {
        if (block) {
            block(nil);
        }
    }
}


-(void)extractCollectionsDetails:(PHFetchResult*)collections
             imageRequestOptions:(PHImageRequestOptions*)options
                   thumbnailSize:(CGSize)thumbnailSize
                           block:(AlbumsBlock)block {
    
    NSMutableArray *albumsArray = [[NSMutableArray alloc] init];
    NSInteger collectionCount = collections.count;
    
    if (collectionCount == 0) {
        if (block) {
            block(nil);
        }
    }
    
    [collections enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self extractCollection:collection imageRequestOptions:options thumbnailSize:thumbnailSize block:^(NSDictionary *album) {
            
            NSString *albumName = collection.localizedTitle;
            if (album) {
                [albumsArray addObject:album];
            }
            
            if (idx == collectionCount-1) {
                if (block) {
                    block(@{@"albums" : albumsArray});
                }
            }
        }];
    }];
}


RCT_EXPORT_METHOD(getAlbumsWithThumbnails:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    imageRequestOptions.synchronous = YES;
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
    
    __block NSMutableArray *albumsArray = [[NSMutableArray alloc] init];
    
    [self extractCollectionsDetails:self.topLevelUserCollections
                imageRequestOptions:imageRequestOptions
                      thumbnailSize:retinaSquare
                              block:^(NSDictionary *albums) {
                                  
                                  [self extractCollection:self.allPhotos imageRequestOptions:imageRequestOptions thumbnailSize:retinaSquare block:^(NSDictionary *allPhotosAlbum) {
                                      
                                      
                                      if (resolve) {
                                          NSMutableArray *albumsArrayAns = [[NSMutableArray alloc] init];;
                                          
                                          if(albums[@"albums"]) {
                                              [albumsArrayAns addObjectsFromArray:albums[@"albums"]];
                                          }
                                          if(allPhotosAlbum) {
                                              [albumsArrayAns insertObject:allPhotosAlbum atIndex:0];
                                          }
                                          
                                          if (!albumsArrayAns || albumsArrayAns.count == 0) {
                                              NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                                                          code:-100 userInfo:nil];
                                              
                                              reject(@"-100", @"no albnums", error);
                                          }
                                          else {
                                              if (resolve) {
                                                  NSDictionary *ans = @{@"albums":  albumsArrayAns };
                                                  resolve(ans);
                                              }
                                          }
                                      }
                                  }];
                              }];
}

RCT_EXPORT_METHOD(getImagesForIds:(NSArray*)imagesIdArray
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    
    NSMutableArray *assetsArray = [[NSMutableArray alloc] init];
    
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = YES;
    
    PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:imagesIdArray options:nil];
    
    for (PHAsset *asset in assets) {
        
        NSDictionary *assetInfoDict = [CKGalleryViewManager infoForAsset:asset imageRequestOptions:imageRequestOptions];
        
        [assetsArray addObject:@{@"uri": assetInfoDict[@"uri"],
                                 @"size": assetInfoDict[@"size"],
                                 @"name": assetInfoDict[@"name"]}];
        
    }
    
    if (resolve) {
        resolve(@{@"images": assetsArray});
    }
}


RCT_EXPORT_METHOD(checkDeviceGalleryAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    [CKGalleryManager deviceGalleryAuthorizationStatus:^(BOOL isAuthorized) {
        if (resolve) {
            resolve(@(isAuthorized));
        }
    }];
}


+(void)deviceGalleryAuthorizationStatus:(CallbackGalleryAuthorizationStatus)callback {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (callback) {
            switch (status) {
                case PHAuthorizationStatusAuthorized:
                    callback(true);
                    break;
                case PHAuthorizationStatusRestricted:
                    callback(false);
                    break;
                case PHAuthorizationStatusDenied:
                    callback(false);
                    break;
                default:
                    callback(false);
                    break;
            }
        }
    }];
}



@end
