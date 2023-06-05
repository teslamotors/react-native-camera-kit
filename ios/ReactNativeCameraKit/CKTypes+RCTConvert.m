//
//  CKCamera+RCTConvert.m
//  ReactNativeCameraKit
//

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTViewManager.h>
#import <React/RCTConvert.h>
#else
#import "RCTViewManager.h"
#import "RCTConvert.h"
#endif

#import "ReactNativeCameraKit-Swift.h"

@implementation RCTConvert (CKTypes)

RCT_ENUM_CONVERTER(CKCameraType, (@{
    @"back": @(CKCameraTypeBack),
    @"front": @(CKCameraTypeFront)
}), CKCameraTypeBack, integerValue)

RCT_ENUM_CONVERTER(CKCameraFlashMode, (@{
    @"on": @(CKCameraFlashModeOn),
    @"off": @(CKCameraFlashModeOff),
    @"auto": @(CKCameraFlashModeAuto)
}), CKCameraFlashModeAuto, integerValue)

RCT_ENUM_CONVERTER(CKCameraTorchMode, (@{
    @"on": @(CKCameraTorchModeOn),
    @"off": @(CKCameraTorchModeOff)
}), CKCameraTorchModeOn, integerValue)

RCT_ENUM_CONVERTER(CKCameraFocusMode, (@{
    @"on": @(CKCameraFocusModeOn),
    @"off": @(CKCameraFocusModeOff)
}), CKCameraFocusModeOn, integerValue)

RCT_ENUM_CONVERTER(CKCameraZoomMode, (@{
    @"on": @(CKCameraZoomModeOn),
    @"off": @(CKCameraZoomModeOff)
}), CKCameraZoomModeOn, integerValue)

@end
