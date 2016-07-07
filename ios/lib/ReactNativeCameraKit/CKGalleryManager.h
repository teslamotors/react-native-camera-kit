//
//  CKGallery.h
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 30/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"

typedef void (^CallbackGalleryBlock)(BOOL success, NSString *encodeImage);
typedef void (^CallbackGalleryAuthorizationStatus)(BOOL isAuthorized);

@interface CKGalleryManager : NSObject <RCTBridgeModule>


+(void)deviceGalleryAuthorizationStatus:(CallbackGalleryAuthorizationStatus)callback;


@end
