//
//  CKCameraManager.m
//  ReactNativeCameraKit
//

#import <AVFoundation/AVFoundation.h>

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
RCT_EXPORT_VIEW_PROPERTY(maxPhotoQualityPrioritization, CKMaxPhotoQualityPrioritization)
RCT_EXPORT_VIEW_PROPERTY(torchMode, CKTorchMode)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlay, NSString)
RCT_EXPORT_VIEW_PROPERTY(ratioOverlayColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, CKResizeMode)

RCT_EXPORT_VIEW_PROPERTY(scanBarcode, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onReadCode, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(showFrame, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scanThrottleDelay, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(laserColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(frameColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(barcodeFrameSize, NSDictionary)

RCT_EXPORT_VIEW_PROPERTY(onOrientationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCaptureButtonPressIn, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCaptureButtonPressOut, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onZoom, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(resetFocusTimeout, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(resetFocusWhenMotionDetected, BOOL)
RCT_EXPORT_VIEW_PROPERTY(focusMode, CKFocusMode)
RCT_EXPORT_VIEW_PROPERTY(zoomMode, CKZoomMode)
RCT_EXPORT_VIEW_PROPERTY(zoom, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(maxZoom, NSNumber)

@end
