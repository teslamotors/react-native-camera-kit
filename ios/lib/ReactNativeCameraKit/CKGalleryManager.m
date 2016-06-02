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


@implementation CKGalleryManager

RCT_EXPORT_MODULE();



-(PHFetchResult*)getAllAlbums {
    
    PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
    userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
    
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
    
    return userAlbums;
}

RCT_EXPORT_METHOD(getAllAlbumsName:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
    
    NSMutableArray *albumsInfo = [[NSMutableArray alloc] init];
    PHFetchResult *userAlbums = [self getAllAlbums];
    
    NSInteger albumsCount = [userAlbums count];
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        NSMutableDictionary *albumInfoDict = [[NSMutableDictionary alloc] init];
        albumInfoDict[@"albumName"] = collection.localizedTitle;
        [albumsInfo addObject:albumInfoDict];
        
        PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:fetchOptions];
        PHAsset *asset = [fetchResult firstObject];
        
        
        
        if (idx == albumsCount-1) {
            if (resolve) {
                resolve(albumsInfo);
            }
        }
        
        
    }];
}

RCT_EXPORT_METHOD(getThumbnailForAlbumName:(NSString*)albumName
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100*retinaScale, 100*retinaScale);
    
    PHImageRequestOptions *cropToSquare = [[PHImageRequestOptions alloc] init];
    cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *userAlbums = [self getAllAlbums];
    
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
        
        if ([albumName isEqualToString:collection.localizedTitle]) {
            
            *stop = YES;
            
            PHFetchResult *fetchResult = [PHAsset fetchKeyAssetsInAssetCollection:collection options:fetchOptions];
            PHAsset *asset = [fetchResult firstObject];
            
            CGFloat cropSideLength = MIN(asset.pixelWidth, asset.pixelHeight);
            CGRect square = CGRectMake(0, 0, cropSideLength, cropSideLength);
            CGRect cropRect = CGRectApplyAffineTransform(square,
                                                         CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
                                                                                    1.0 / asset.pixelHeight));
            
            // make sure resolve call only once
            __block BOOL isInvokeResolve = NO;
            
            [[PHImageManager defaultManager]
             requestImageForAsset:(PHAsset *)asset
             targetSize:retinaSquare
             contentMode:PHImageContentModeAspectFit
             options:cropToSquare
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 NSData *imageData = UIImageJPEGRepresentation(result, 1.0);
                 NSString *encodedString = [imageData base64Encoding];
                 
                 if (resolve && !isInvokeResolve) {
                     isInvokeResolve = YES;
                     resolve(encodedString);
                 }
             }];
        }
    }];
}

@end
