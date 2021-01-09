#import <UIKit/UIKit.h>
@import AVFoundation;

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif


typedef void (^CaptureBlock)(NSDictionary *imageObject);
typedef void (^CallbackBlock)(BOOL success);

typedef NS_ENUM(NSInteger, CKCameraType) {
    CKCameraTypeBack,
    CKCameraTypeFront,
};

@interface RCTConvert(CKCameraType)

+ (CKCameraType)CKCameraType:(id)json;

@end

typedef NS_ENUM(NSInteger, CKCameraFlashMode) {
    CKCameraFlashModeAuto,
    CKCameraFlashModeOn,
    CKCameraFlashModeOff
};

@interface RCTConvert(CKCameraFlashMode)

+ (CKCameraFlashMode)CKCameraFlashMode:(id)json;

@end

typedef NS_ENUM(NSInteger, CKCameraTorchMode) {
    CKCameraTorchModeOn,
    CKCameraTorchModeOff
};

@interface RCTConvert(CKCameraTorchMode)

+ (CKCameraTorchMode)CKCameraTorchMode:(id)json;

@end

typedef NS_ENUM(NSInteger, CKCameraFocusMode) {
    CKCameraFocusModeOn,
    CKCameraFocusModeOff,
};

@interface RCTConvert(CKCameraFocusMode)

+ (CKCameraFocusMode)CKCameraFocusMode:(id)json;

@end

typedef NS_ENUM(NSInteger, CKCameraZoomMode) {
    CKCameraZoomModeOn,
    CKCameraZoomModeOff,
};

@interface RCTConvert(CKCameraZoomMode)

+ (CKCameraZoomMode)CKCameraZoomMode:(id)json;

@end


@interface CKCamera : UIView

@property (nonatomic, readonly) AVCaptureDeviceInput *videoDeviceInput;


// api
- (void)snapStillImage:(NSDictionary*)options success:(CaptureBlock)block onError:(void (^)(NSString*))onError;

+ (NSURL*)saveToTmpFolder:(NSData*)data;

@end
