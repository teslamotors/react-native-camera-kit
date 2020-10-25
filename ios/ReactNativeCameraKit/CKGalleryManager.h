#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif



#import "CKCamera.h"

typedef void (^CallbackGalleryBlock)(BOOL success, NSString *encodeImage);
typedef void (^CallbackGalleryAuthorizationStatus)(BOOL isAuthorized);
typedef void (^SaveBlock)(BOOL success);

@interface CKGalleryManager : NSObject <RCTBridgeModule>

+(void)deviceGalleryAuthorizationStatus:(CallbackGalleryAuthorizationStatus)callback;

@end
