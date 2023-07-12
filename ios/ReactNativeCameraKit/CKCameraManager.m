//
//  CKCameraManager.m
//  ReactNativeCameraKit
//

@import AVFoundation;

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTViewManager.h>
#import <React/RCTConvert.h>
#else
#import "RCTViewManager.h"
#import "RCTConvert.h"
#endif

@interface RCT_EXTERN_MODULE(CKCameraManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(cameraType, CKCameraType)
RCT_EXPORT_VIEW_PROPERTY(flashMode, CKFlashMode)
RCT_EXPORT_VIEW_PROPERTY(torchMode, CKTorchMode)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlay, NSString)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlayColor, UIColor)

RCT_EXPORT_VIEW_PROPERTY(scanBarcode, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onReadCode, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showFrame, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scanThrottleDelay, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(laserColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(frameColor, UIColor)

RCT_EXPORT_VIEW_PROPERTY(onOrientationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(resetFocusTimeout, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(resetFocusWhenMotionDetected, BOOL)
RCT_EXPORT_VIEW_PROPERTY(focusMode, CKFocusMode)
RCT_EXPORT_VIEW_PROPERTY(zoomMode, CKZoomMode)

RCT_EXTERN_METHOD(capture:(NSDictionary*)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(checkDeviceCameraAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(requestDeviceCameraAuthorization:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)

@end
