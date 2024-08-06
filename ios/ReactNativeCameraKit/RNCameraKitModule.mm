#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import <React/RCTUIManagerUtils.h>
#import "RNCameraKitModule.h"
#ifdef RCT_NEW_ARCH_ENABLED
#import "CKCameraViewComponentView.h"
#endif // RCT_NEW_ARCH_ENABLED

#import "ReactNativeCameraKit-Swift.pre.h"

@implementation RNCameraKitModule

RCT_EXPORT_MODULE();

#ifdef RCT_NEW_ARCH_ENABLED
@synthesize viewRegistry_DEPRECATED = _viewRegistry_DEPRECATED;
#endif // RCT_NEW_ARCH_ENABLED
@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
  // It seems that due to how UIBlocks work with uiManager, we need to call the methods there
  // for the blocks to be dispatched before the batch is completed
  return RCTGetUIManagerQueue();
}

- (void)withCamera:(nonnull NSNumber*)viewRef block:(void (^)(CKCameraView *))block reject:(RCTPromiseRejectBlock)reject methodName:(NSString *)methodName
{
#ifdef RCT_NEW_ARCH_ENABLED
    [self.viewRegistry_DEPRECATED addUIBlock:^(RCTViewRegistry *viewRegistry) {
    CKCameraViewComponentView *componentView = [self.viewRegistry_DEPRECATED viewForReactTag:viewRef];
    CKCameraView *view = componentView.contentView;
        
#else
    [self.bridge.uiManager
     addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        CKCameraView *view = [uiManager viewForReactTag:viewRef];
#endif // RCT_NEW_ARCH_ENABLED
        if (view != nil) {
           block(view);
        } else {
            reject(methodName, [NSString stringWithFormat:@"Unknown reactTag: %@ in %@", viewRef, methodName], nil);
        }
    }];
}

RCT_EXPORT_METHOD(capture:(NSDictionary *)options tag:(nonnull NSNumber *)tag resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
    [self withCamera:tag block:^(CKCameraView *view) {
        [CKCameraManager captureWithCamera:view options:[NSDictionary new] resolve:resolve reject:reject];
    } reject:reject methodName:@"capture"];
}
 
 - (void)checkDeviceCameraAuthorizationStatus:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
        [CKCameraManager checkDeviceCameraAuthorizationStatus:resolve reject:reject];
}
 
 - (void)requestDeviceCameraAuthorization:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
        [CKCameraManager requestDeviceCameraAuthorization:resolve reject:reject];
}

 // Thanks to this guard, we won't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeCameraKitModuleSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
