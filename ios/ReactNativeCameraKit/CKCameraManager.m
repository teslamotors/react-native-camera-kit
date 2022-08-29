#import "CKCameraManager.h"
#import "CKCamera.h"


@interface CKCameraManager ()

@property (nonatomic, strong) CKCamera *camera;

@end

@implementation CKCameraManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    self.camera = [CKCamera new];
    return self.camera;
}

RCT_EXPORT_VIEW_PROPERTY(cameraType, CKCameraType)
RCT_EXPORT_VIEW_PROPERTY(flashMode, CKCameraFlashMode)
RCT_EXPORT_VIEW_PROPERTY(torchMode, CKCameraTorchMode)
RCT_EXPORT_VIEW_PROPERTY(focusMode, CKCameraFocusMode)
RCT_EXPORT_VIEW_PROPERTY(zoomMode, CKCameraZoomMode)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlay, NSString)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlayColor, UIColor)

RCT_EXPORT_VIEW_PROPERTY(onReadCode, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onOrientationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showFrame, BOOL)
RCT_EXPORT_VIEW_PROPERTY(laserColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(frameColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(resetFocusTimeout, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(resetFocusWhenMotionDetected, BOOL)

RCT_EXPORT_METHOD(capture:(NSDictionary*)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {

    [self.camera snapStillImage:options success:^(NSDictionary *imageObject) {
        resolve(imageObject);
    } onError:^(NSString* error) {
        reject(@"capture_error", error, nil);
    }];
}

RCT_EXPORT_METHOD(checkDeviceCameraAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {


    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        resolve(@YES);
    } else if(authStatus == AVAuthorizationStatusNotDetermined) {
        resolve(@(-1));
    } else {
        resolve(@NO);
    }
}

RCT_EXPORT_METHOD(requestDeviceCameraAuthorization:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
    __block NSString *mediaType = AVMediaTypeVideo;

    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (resolve) {
            resolve(@(granted));
        }
    }];
}

@end
