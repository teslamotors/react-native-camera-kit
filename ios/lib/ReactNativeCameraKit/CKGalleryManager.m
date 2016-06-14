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
//    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    self.topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
}



-(void)getAllAlbumsNameAndThumbnails:(AlbumsBlock)block {
    
    PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
    cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
    cropToSquare.synchronous = YES;
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
    
    NSMutableDictionary *albumsDict = [[NSMutableDictionary alloc] init];
    
    NSInteger smartAlbumsCount = self.smartAlbums.count;
    
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (smartAlbumsCount) {
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            
            [self.smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSInteger collectionCount = [PHAsset fetchAssetsInAssetCollection:collection options:nil].count;
                
                if (collectionCount > 0){
                    
                    NSString *albumName = collection.localizedTitle;
                    albumName = [NSString stringWithFormat:@"%@", albumName];
                    
                    PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
                    PHAsset *thumbnail = [fetchResult firstObject];
                    
                    NSMutableDictionary *albumInfo = [[NSMutableDictionary alloc] init];
                    albumInfo[@"albumName"] = albumName;
                    albumInfo[@"imagesCount"] = [NSNumber numberWithInteger:collectionCount];
                    
                    albumsDict[albumName] = albumInfo;
                    
                    [[PHImageManager defaultManager]
                     requestImageForAsset:thumbnail
                     targetSize:retinaSquare
                     contentMode:PHImageContentModeAspectFit
                     options:cropToSquare
                     resultHandler:^(UIImage *result, NSDictionary *info) {
                         
                         if (!albumInfo[@"image"]) {
                             
                             albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
                         }
                         
                         if (idx == smartAlbumsCount-1) {
                             
                             dispatch_semaphore_signal(sem);
                             
                         }
                         
                     }];
                }
                else if (idx == smartAlbumsCount-1) {
                    dispatch_semaphore_signal(sem);
                }
                
            }];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        }
        
        
        
        NSInteger topLevelAlbumsCount = self.topLevelUserCollections.count;
        
        [self.topLevelUserCollections enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger collectionCount = [PHAsset fetchAssetsInAssetCollection:collection options:nil].count;
            
            if (collectionCount > 0){
                
                NSString *albumName = collection.localizedTitle;
                albumName = [NSString stringWithFormat:@"%@", albumName];
                
                PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
                PHAsset *thumbnail = [fetchResult firstObject];
                
                NSMutableDictionary *albumInfo = [[NSMutableDictionary alloc] init];
                albumInfo[@"albumName"] = [NSString stringWithFormat:@"%@", albumName];
                albumInfo[@"imagesCount"] = [NSNumber numberWithInteger:collectionCount];
                
                albumsDict[albumName] = albumInfo;
                
                
                //                __block BOOL isInvokeBlock = NO;
                
                [[PHImageManager defaultManager]
                 requestImageForAsset:thumbnail
                 targetSize:retinaSquare
                 contentMode:PHImageContentModeAspectFit
                 options:cropToSquare
                 resultHandler:^(UIImage *result, NSDictionary *info) {
                     
                     if (!albumInfo[@"image"]) {
                         albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
                     }
                     
                     if (idx == topLevelAlbumsCount-1) {
                         
//                         if (block) {
//                             
//                             block(albumsDict);
//                         }
                     }
                 }];
            }
        }];
        
        NSInteger allPhotosCount = self.allPhotos.count;
        
//        NSInteger collectionCount = [PHAsset fetchAssetsInAssetCollection:collection options:nil].count;
        
        if (allPhotosCount > 0){
            
            NSString *albumName = @"All Photos";
            albumName = [NSString stringWithFormat:@"%@", albumName];
            
//            PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:self.allPhotos options:nil];
            PHAsset *thumbnail = [self.allPhotos firstObject];
            
            NSMutableDictionary *albumInfo = [[NSMutableDictionary alloc] init];
            albumInfo[@"albumName"] = [NSString stringWithFormat:@"%@", albumName];
            albumInfo[@"imagesCount"] = [NSNumber numberWithInteger:allPhotosCount];
            
            albumsDict[albumName] = albumInfo;
            
            
            //                __block BOOL isInvokeBlock = NO;
            
            [[PHImageManager defaultManager]
             requestImageForAsset:thumbnail
             targetSize:retinaSquare
             contentMode:PHImageContentModeAspectFit
             options:cropToSquare
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 
                 if (!albumInfo[@"image"]) {
                     albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
                 }
                 
//                 if (idx == topLevelAlbumsCount-1) {
                 
                     if (block) {
                         
                         block(albumsDict);
                     }
//                 }
             }];
        }
        
    });
}


-(void)getThumbnial:(PHFetchResult*)albums
          albumName:(NSString*)albumName
       cropToSquare:(PHImageRequestOptions*)cropToSquare
       retinaSquare:(CGSize)retinaSquare block:(CallbackGalleryBlock)block {
    
    [albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        if ([albumName isEqualToString:collection.localizedTitle]) {
            *stop = YES;
            
            PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
            PHAsset *asset = [fetchResult firstObject];
            
            CGFloat cropSideLength = MIN(asset.pixelWidth, asset.pixelHeight);
            CGRect square = CGRectMake(0, 0, cropSideLength, cropSideLength);
            CGRect cropRect = CGRectApplyAffineTransform(square,
                                                         CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
                                                                                    1.0 / asset.pixelHeight));
            
            
            // make sure resolve call only once
            __block BOOL isInvokeResolve = NO;
            
            [[PHImageManager defaultManager]
             requestImageForAsset:asset
             targetSize:retinaSquare
             contentMode:PHImageContentModeAspectFit
             options:cropToSquare
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 
                 
                 NSData *imageData = [UIImagePNGRepresentation(result) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                 
                 
                 if (!imageData) {
                     imageData = UIImagePNGRepresentation(result);
                     
                     if (!imageData) {
                         CGDataProviderRef provider = CGImageGetDataProvider(result.CGImage);
                         imageData = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
                     }
                 }
                 
                 
                 NSString *encodedString = [imageData base64Encoding];
                 
                 
                 //                 NSString *encodedString = [data base64Encoding];
                 
                 
                 
                 if (block && !isInvokeResolve) {
                     isInvokeResolve = YES;
                     block(YES, encodedString);
                 }
                 
             }];
        }
        else {
            if (block) {
                block(NO, nil);
            }
        }
    }];
}



RCT_EXPORT_METHOD(getAlbumsWithThumbnails:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    
    [self getAllAlbumsNameAndThumbnails:^(NSDictionary *albums) {
        if (resolve) {
            
            NSDictionary *ans = @{[NSString stringWithFormat:@"albums"]: albums};
            resolve(ans);
        }
    }];
}


RCT_EXPORT_METHOD(getImagesForAlbumName:(NSInteger)numberOfImages
                  albumName:(NSString*)albumName
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    //    [self.imageManager requestImageForAsset:asset
    //                                 targetSize:AssetGridThumbnailSize
    //                                contentMode:PHImageContentModeAspectFill
    //                                    options:nil
    //                              resultHandler:^(UIImage *result, NSDictionary *info) {
    //                                  // Set the cell's thumbnail image if it's still showing the same asset.
    //                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
    //                                      cell.thumbnailImage = result;
    //                                  }
    //                              }];
    
}




@end
