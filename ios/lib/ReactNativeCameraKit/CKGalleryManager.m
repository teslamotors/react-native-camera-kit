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

typedef void (^AlbumsBlock)(NSDictionary *albums);

@interface CKGalleryManager ()

@property (nonatomic, strong) PHFetchResult *allPhotos;
@property (nonatomic, strong) PHFetchResult *smartAlbums;
@property (nonatomic, strong) PHFetchResult *topLevelUserCollections;

@end


@implementation CKGalleryManager


RCT_EXPORT_MODULE();


-(instancetype)init {
    self = [super init];
    
    [self initAlbums];
    
    return self;
}


-(void)initAlbums {
    
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchOptions *albumsOptions = [[PHFetchOptions alloc] init];
    albumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    
    self.allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    self.topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
}


-(void)extractCollection:(id)collection
     imageRequestOptions:(PHImageRequestOptions*)options
           thumbnailSize:(CGSize)thumbnailSize
                   block:(AlbumsBlock)block {
    
    NSInteger collectionCount = ([collection isKindOfClass:[PHAssetCollection class]]) ? [PHAsset fetchAssetsInAssetCollection:collection options:nil].count : ((PHFetchResult*)collection).count;
    
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
    
    NSMutableDictionary *albumsDict = [[NSMutableDictionary alloc] init];
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
                albumsDict[albumName] = album;
            }
            
            if (idx == collectionCount-1) {
                if (block) {
                    block(albumsDict);
                }
            }
        }];
    }];
}


RCT_EXPORT_METHOD(getAlbumsWithThumbnails:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    imageRequestOptions.synchronous = YES;
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
    
    NSMutableDictionary *albumsDict = [[NSMutableDictionary alloc] init];
    
    [self extractCollectionsDetails:self.topLevelUserCollections
                imageRequestOptions:imageRequestOptions
                      thumbnailSize:retinaSquare
                              block:^(NSDictionary *albums) {
                                  
                                  if (albums) {
                                      [albumsDict addEntriesFromDictionary:albums];
                                  }
                                  
                                  [self extractCollection:self.allPhotos imageRequestOptions:imageRequestOptions thumbnailSize:retinaSquare block:^(NSDictionary *album) {
                                      
                                      if (album) {
                                          albumsDict[album[@"albumName"]] = album;
                                      }
                                      
                                      if (resolve) {
                                          NSDictionary *ans = @{[NSString stringWithFormat:@"albums"]: albumsDict};
                                          resolve(ans);
                                      }
                                  }];
                              }];
}



@end
