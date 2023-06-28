//
//  CKTypes+RCTConvert.m
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

RCT_ENUM_CONVERTER(CKFlashMode, (@{
    @"on": @(CKFlashModeOn),
    @"off": @(CKFlashModeOff),
    @"auto": @(CKFlashModeAuto)
}), CKFlashModeAuto, integerValue)

RCT_ENUM_CONVERTER(CKTorchMode, (@{
    @"on": @(CKTorchModeOn),
    @"off": @(CKTorchModeOff)
}), CKTorchModeOn, integerValue)

RCT_ENUM_CONVERTER(CKFocusMode, (@{
    @"on": @(CKFocusModeOn),
    @"off": @(CKFocusModeOff)
}), CKFocusModeOn, integerValue)

RCT_ENUM_CONVERTER(CKZoomMode, (@{
    @"on": @(CKZoomModeOn),
    @"off": @(CKZoomModeOff)
}), CKZoomModeOn, integerValue)

@end
