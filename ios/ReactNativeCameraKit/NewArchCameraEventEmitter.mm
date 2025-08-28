//
//  NewArchCameraEventEmitter.mm
//  ReactNativeCameraKit
//

#ifdef RCT_NEW_ARCH_ENABLED

#import "NewArchCameraEventEmitter.h"

#import "CKCameraViewComponentView.h"
#import "ReactNativeCameraKit-Swift.h"
#import <react/renderer/components/rncamerakit_specs/EventEmitters.h>

@interface NewArchCameraEventEmitter () {
    __weak CKCameraViewComponentView *_viewComponentView;
}
@end

@implementation NewArchCameraEventEmitter

- (instancetype)initWithCameraViewComponentView:(CKCameraViewComponentView *)viewComponentView {
    if (self = [super init]) {
        _viewComponentView = viewComponentView;
    }
    return self;
}

- (void)onReadCodeWithCodeStringValue:(NSString *)codeStringValue codeFormat:(NSString *)codeFormat {
    if ([_viewComponentView eventEmitter] != nullptr) {
        auto cameraEventEmitter = std::static_pointer_cast<const facebook::react::CKCameraEventEmitter>([_viewComponentView eventEmitter]);
        cameraEventEmitter->onReadCode({.codeStringValue = [codeStringValue UTF8String], .codeFormat = [codeFormat UTF8String]});
    }
}

- (void)onOrientationChangeWithOrientation:(NSInteger)orientation {
    if ([_viewComponentView eventEmitter] != nullptr) {
        auto cameraEventEmitter = std::static_pointer_cast<const facebook::react::CKCameraEventEmitter>([_viewComponentView eventEmitter]);
        cameraEventEmitter->onOrientationChange({.orientation = (int)orientation});
    }
}

- (void)onZoomWithZoom:(double)zoom {
    // log zoom
    NSLog(@"Zoom sent: %f", zoom);
    if ([_viewComponentView eventEmitter] != nullptr) {
        auto cameraEventEmitter = std::static_pointer_cast<const facebook::react::CKCameraEventEmitter>([_viewComponentView eventEmitter]);
        cameraEventEmitter->onZoom({.zoom = zoom});
    }
}

- (void)onCaptureButtonPressIn {
    if ([_viewComponentView eventEmitter] != nullptr) {
        auto cameraEventEmitter = std::static_pointer_cast<const facebook::react::CKCameraEventEmitter>([_viewComponentView eventEmitter]);
        cameraEventEmitter->onCaptureButtonPressIn({});
    }
}

- (void)onCaptureButtonPressOut {
    if ([_viewComponentView eventEmitter] != nullptr) {
        auto cameraEventEmitter = std::static_pointer_cast<const facebook::react::CKCameraEventEmitter>([_viewComponentView eventEmitter]);
        cameraEventEmitter->onCaptureButtonPressOut({});
    }
}

@end

#endif // RCT_NEW_ARCH_ENABLED
