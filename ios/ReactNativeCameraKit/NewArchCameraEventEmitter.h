//
//  NewArchCameraEventEmitter.h
//  ReactNativeCameraKit
//

#ifdef RCT_NEW_ARCH_ENABLED

@class CKCameraViewComponentView;
@protocol CameraEventEmitter;

/* This unfortunately needs to be in ObjectiveC since it's using C++ implementation */
@interface NewArchCameraEventEmitter : NSObject <CameraEventEmitter>

- (instancetype)initWithCameraViewComponentView:(CKCameraViewComponentView *)viewComponentView;

@end

#endif // RCT_NEW_ARCH_ENABLED