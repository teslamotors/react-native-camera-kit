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

//
//-(void)iterateAllAlbums:(AlbumsNamesBlock)block {
//
//
//}


-(void)initAlbums {
    
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    PHFetchOptions *albumsOptions = [[PHFetchOptions alloc] init];
    albumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    
    self.allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    self.topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
}


//-(void)getAlbumsName:(PHFetchResult*)albums block:(AlbumsNamesBlock)block {
//
//    NSMutableDictionary *albumsInfo = [[NSMutableDictionary alloc] init];
//    NSInteger albumsCount = [albums count];
//
//    if (albumsCount == 0) {
//        block(nil);
//    }
//
//    [albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
//
//
//        //        NSMutableDictionary *albumInfoDict = [[NSMutableDictionary alloc] init];
//        if (collection.estimatedAssetCount != NSNotFound) {
//            albumsInfo[collection.localizedTitle] = @{@"name": collection.localizedTitle};
//        }
//
//        if (idx == albumsCount-1) {
//            if (block) {
//                block(albumsInfo);
//            }
//        }
//
//    }];
//
//}


-(void)getAllAlbumsNameAndThumbnails:(AlbumsBlock)block {
    
    PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
    cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
    cropToSquare.synchronous = YES;
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
    
    NSMutableDictionary *albumsDict = [[NSMutableDictionary alloc] init];
    
    NSInteger smartAlbumsCount = self.smartAlbums.count;
    
    
    NSLog(@"### smartAlbums");
    
    
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
                    
                    albumsDict[albumName] = albumInfo;
                    
                    [[PHImageManager defaultManager]
                     requestImageForAsset:thumbnail
                     targetSize:retinaSquare
                     contentMode:PHImageContentModeAspectFit
                     options:cropToSquare
                     resultHandler:^(UIImage *result, NSDictionary *info) {
                         
                         NSLog(@"albumName:%@", albumName);
                         if (!albumInfo[@"image"]) {
                             
                             albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
                         }
                         
                         if (idx == smartAlbumsCount-1) {
                             
                             NSLog(@"%@", albumsDict );
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
        
        NSLog(@"### topLevelUserCollections");
        
        
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
                
                albumsDict[albumName] = albumInfo;
                
                
                //                __block BOOL isInvokeBlock = NO;
                
                [[PHImageManager defaultManager]
                 requestImageForAsset:thumbnail
                 targetSize:retinaSquare
                 contentMode:PHImageContentModeAspectFit
                 options:cropToSquare
                 resultHandler:^(UIImage *result, NSDictionary *info) {
                     
                     if (!albumInfo[@"image"]) {
                         NSLog(@"albumName:%@", albumName);
                         albumInfo[@"image"] = [UIImageJPEGRepresentation(result, 1.0) base64Encoding];
                     }
                     
                     if (idx == topLevelAlbumsCount-1) {
                         
                         if (block) {
                             
                             NSLog(@"cool");
                             block(albumsDict);
                         }
                     }
                 }];
            }
        }];
        
    });
    
    
    
}

//-(NSDictionary*)dictionaryForCollection:(PHAssetCollection*)collection semaphore:(dispatch_semaphore_t)sem albumsDict:(NSDictionary) {
//
//}


RCT_EXPORT_METHOD(getAllAlbumsNamesAndThumbnails:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    
    
}


RCT_EXPORT_METHOD(getAllAlbumsName:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    
    [self getAllAlbumsNameAndThumbnails:^(NSDictionary *albums) {
        if (resolve) {
            
//            NSArray *arr = [NSArray arrayWithObject:albums];
            NSDictionary *ans = @{[NSString stringWithFormat:@"albums"]: albums};
            resolve(ans);
        }
    }];
    
    //    //    NSMutableDictionary *albumsInfo = [[NSMutableDictionary alloc] init];
    //    PHFetchResult *userAlbums = [self getAllAlbums:PHAssetCollectionTypeAlbum];
    //
    //    [self getAlbumsName:userAlbums block:^(NSDictionary *albumsNames) {
    //        PHFetchResult *userSmartAlbums = [self getAllAlbums:PHAssetCollectionTypeSmartAlbum];
    //
    //        if (userSmartAlbums.count == 0) {
    //            if(resolve) {
    //                resolve(albumsNames);
    //                return;
    //            }
    //        }
    //
    //        [self getAlbumsName:userSmartAlbums block:^(NSDictionary *smartAlbumsNames) {
    //
    //            NSMutableDictionary *userAlbumsFull = [NSMutableDictionary dictionaryWithDictionary:albumsNames];
    //            [userAlbumsFull addEntriesFromDictionary:smartAlbumsNames];
    //
    //            if(resolve) {
    //                resolve(userAlbumsFull);
    //            }
    //        }];
    //    }];
    //
    //    //    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
    //    //
    //    //        NSMutableDictionary *albumInfoDict = [[NSMutableDictionary alloc] init];
    //    //        albumInfoDict[@"albumName"] = collection.localizedTitle;
    //    //        [albumsInfo addObject:albumInfoDict];
    //    //
    //    //        if (idx == albumsCount-1) {
    //    //            if (resolve) {
    //    //                resolve(albumsInfo);
    //    //            }
    //    //        }
    //    //
    //    //    }];
}

//RCT_EXPORT_METHOD(getThumbnailForAlbumName:(NSString*)albumName
//                  resolve:(RCTPromiseResolveBlock)resolve
//                  reject:(__unused RCTPromiseRejectBlock)reject)
//{
//
//    NSInteger retinaScale = [UIScreen mainScreen].scale;
//    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
//
//    PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
//    cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
//
//    PHFetchResult *userAlbums = [self getAllAlbums:PHAssetCollectionTypeAlbum]; // TODO ######################
//
//    [self getThumbnial:userAlbums albumName:albumName cropToSquare:cropToSquare retinaSquare:retinaSquare block:^(BOOL success, NSString *encodeImage) {
//
//        if (success) {
//            if (resolve) {
//                resolve(encodeImage);
//            }
//        }
//
//        else {
//            PHFetchResult *userSmartAlbums = [self getAllAlbums:PHAssetCollectionTypeSmartAlbum];
//            [self getThumbnial:userSmartAlbums albumName:albumName cropToSquare:cropToSquare retinaSquare:retinaSquare block:^(BOOL success, NSString *encodeImage) {
//                if (resolve) {
//                    resolve(encodeImage);
//                }
//            }];
//
//        }
//    }];
//
//    //    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
//    //
//    //        if ([albumName isEqualToString:collection.localizedTitle]) {
//    //
//    //            *stop = YES;
//    //
//    //            PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
//    //            PHAsset *asset = [fetchResult firstObject];
//    //
//    //            CGFloat cropSideLength = MIN(asset.pixelWidth, asset.pixelHeight);
//    //            CGRect square = CGRectMake(0, 0, cropSideLength, cropSideLength);
//    //            CGRect cropRect = CGRectApplyAffineTransform(square,
//    //                                                         CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
//    //                                                                                    1.0 / asset.pixelHeight));
//    //
//    //            // make sure resolve call only once
//    //            __block BOOL isInvokeResolve = NO;
//    //
//    //            [[PHImageManager defaultManager]
//    //             requestImageForAsset:asset
//    //             targetSize:retinaSquare
//    //             contentMode:PHImageContentModeAspectFit
//    //             options:cropToSquare
//    //             resultHandler:^(UIImage *result, NSDictionary *info) {
//    //
//    //                 NSData *imageData = UIImageJPEGRepresentation(result, 1.0);
//    //
//    //                 if (!imageData) {
//    //                     imageData = UIImagePNGRepresentation(result);
//    //                 }
//    //
//    //                 NSString *encodedString = [imageData base64Encoding];
//    //
//    //                 //                 CGDataProviderRef provider = CGImageGetDataProvider(result.CGImage);
//    //                 //                 NSData* data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
//    //                 //                 NSString *encodedString = [data base64Encoding];
//    //
//    //                 if (resolve && !isInvokeResolve) {
//    //                     isInvokeResolve = YES;
//    //                     resolve(encodedString);
//    //                 }
//    //             }];
//    //        }
//    //    }];
//}

-(void)getThumbnial:(PHFetchResult*)albums albumName:(NSString*)albumName cropToSquare:(PHImageRequestOptions*)cropToSquare retinaSquare:(CGSize)retinaSquare block:(CallbackGalleryBlock)block {
    [albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        if ([albumName isEqualToString:collection.localizedTitle]) {
            NSLog(@"collection.localizedTitle:%@", collection.localizedTitle);
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

@end
