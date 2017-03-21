//
//  CKGallery.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "RCTBridgeModule.h"
#import "CKCamera.h"

typedef void (^CallbackGalleryBlock)(BOOL success, NSString *encodeImage);
typedef void (^CallbackGalleryAuthorizationStatus)(BOOL isAuthorized);
typedef void (^SaveBlock)(BOOL success, NSString *localIdentifier);

@interface CKGalleryManager : NSObject <RCTBridgeModule>

+(void)deviceGalleryAuthorizationStatus:(CallbackGalleryAuthorizationStatus)callback;
+(void)saveImageToCameraRoll:(NSData*)imageData temporaryFileURL:(NSURL*)temporaryFileURL fetchOptions:(PHFetchOptions*)fetchOptions block:(SaveBlock)block;

@end
