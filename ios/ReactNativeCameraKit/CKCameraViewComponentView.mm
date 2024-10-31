#ifdef RCT_NEW_ARCH_ENABLED

#import "CKCameraViewComponentView.h"

#import <React/RCTBridge+Private.h>
#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <folly/dynamic.h>

#import <react/renderer/components/rncamerakit_specs/ComponentDescriptors.h>
#import <react/renderer/components/rncamerakit_specs/EventEmitters.h>
#import <react/renderer/components/rncamerakit_specs/Props.h>
#import <react/renderer/components/rncamerakit_specs/RCTComponentViewHelpers.h>

#import "ReactNativeCameraKit-Swift.pre.h"

using namespace facebook::react;

static id CKConvertFollyDynamicToId(const folly::dynamic &dyn)
{
  // I could imagine an implementation which avoids copies by wrapping the
  // dynamic in a derived class of NSDictionary.  We can do that if profiling
  // implies it will help.

  switch (dyn.type()) {
    case folly::dynamic::NULLT:
      return nil;
    case folly::dynamic::BOOL:
      return dyn.getBool() ? @YES : @NO;
    case folly::dynamic::INT64:
      return @(dyn.getInt());
    case folly::dynamic::DOUBLE:
      return @(dyn.getDouble());
    case folly::dynamic::STRING:
      return [[NSString alloc] initWithBytes:dyn.c_str() length:dyn.size() encoding:NSUTF8StringEncoding];
    case folly::dynamic::ARRAY: {
      NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:dyn.size()];
      for (const auto &elem : dyn) {
        id value = CKConvertFollyDynamicToId(elem);
        if (value) {
          [array addObject:value];
        }
      }
      return array;
    }
    case folly::dynamic::OBJECT: {
      NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:dyn.size()];
      for (const auto &elem : dyn.items()) {
        id key = CKConvertFollyDynamicToId(elem.first);
        id value = CKConvertFollyDynamicToId(elem.second);
        if (key && value) {
          dict[key] = value;
        }
      }
      return dict;
    }
  }
}

@interface CKCameraViewComponentView () <RCTCKCameraViewProtocol>
@end

@implementation CKCameraViewComponentView {
    CKCameraView *_view;
}

// Needed because of this: https://github.com/facebook/react-native/pull/37274
+ (void)load
{
  [super load];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const CKCameraProps>();
        _props = defaultProps;
        [self prepareView];
    }

    return self;
}

- (void)prepareView
{
    _view =  [[CKCameraView alloc] init];
    
    // just need to pass something, it won't really be used on fabric, but it's used to create events (it won't impact sending them)
    _view.reactTag = @-1;
    
    __weak __typeof__(self) weakSelf = self;

    [_view setOnReadCode:^(NSDictionary* event) {
        __typeof__(self) strongSelf = weakSelf;

        if (strongSelf != nullptr && strongSelf->_eventEmitter != nullptr) {
            std::string codeStringValue = [event valueForKey:@"codeStringValue"] == nil ? "" : std::string([[event valueForKey:@"codeStringValue"] UTF8String]);
            std::string codeFormat = [event valueForKey:@"codeFormat"] == nil ? "" : std::string([[event valueForKey:@"codeFormat"] UTF8String]);
            std::dynamic_pointer_cast<const facebook::react::CKCameraEventEmitter>(strongSelf->_eventEmitter)->onReadCode({.codeStringValue = codeStringValue, .codeFormat = codeFormat});
          }
    }];
    [_view setOnOrientationChange:^(NSDictionary* event) {
        __typeof__(self) strongSelf = weakSelf;

        if (strongSelf != nullptr && strongSelf->_eventEmitter != nullptr) {
            id orientation = [event valueForKey:@"orientation"] == nil ? 0 : [event valueForKey:@"orientation"];
            std::dynamic_pointer_cast<const facebook::react::CKCameraEventEmitter>(strongSelf->_eventEmitter)->onOrientationChange({.orientation = [orientation intValue]});
          }
    }];
    [_view setOnZoom:^(NSDictionary* event) {
        __typeof__(self) strongSelf = weakSelf;

        if (strongSelf != nullptr && strongSelf->_eventEmitter != nullptr) {
            id zoom = [event valueForKey:@"zoom"] == nil ? 0 : [event valueForKey:@"zoom"];
            std::dynamic_pointer_cast<const facebook::react::CKCameraEventEmitter>(strongSelf->_eventEmitter)->onZoom({.zoom = [zoom doubleValue]});
          }
    }];
    [_view setOnCaptureButtonPressIn:^(NSDictionary* event) {
        __typeof__(self) strongSelf = weakSelf;

        if (strongSelf != nullptr && strongSelf->_eventEmitter != nullptr) {
            std::dynamic_pointer_cast<const facebook::react::CKCameraEventEmitter>(strongSelf->_eventEmitter)->onCaptureButtonPressIn({});
          }
    }];
    [_view setOnCaptureButtonPressOut:^(NSDictionary* event) {
        __typeof__(self) strongSelf = weakSelf;

        if (strongSelf != nullptr && strongSelf->_eventEmitter != nullptr) {
            std::dynamic_pointer_cast<const facebook::react::CKCameraEventEmitter>(strongSelf->_eventEmitter)->onCaptureButtonPressOut({});
          }
    }];
    
    self.contentView = _view;
}

#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<CKCameraComponentDescriptor>();
}

- (void)updateLayoutMetrics:(const facebook::react::LayoutMetrics &)layoutMetrics oldLayoutMetrics:(const facebook::react::LayoutMetrics &)oldLayoutMetrics
{
    [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];
    [_view updateSubviewsBounds:RCTCGRectFromRect(layoutMetrics.frame)];
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
    const auto &newProps = static_cast<const CKCameraProps &>(*props);
    NSMutableArray<NSString *> *changedProps = [NSMutableArray new];
    id cameraType = CKConvertFollyDynamicToId(newProps.cameraType);
    if (cameraType != nil && [cameraType isKindOfClass:NSString.class]) {
        _view.cameraType = [cameraType isEqualToString:@"back"] ? CKCameraTypeBack : CKCameraTypeFront;
        [changedProps addObject:@"cameraType"];
    }
    id resizeMode = CKConvertFollyDynamicToId(newProps.resizeMode);
    if (resizeMode != nil && [resizeMode isKindOfClass:NSString.class]) {
        _view.resizeMode = [resizeMode isEqualToString:@"contain"] ? CKResizeModeContain : CKResizeModeCover;
        [changedProps addObject:@"resizeMode"];
    }
    id flashMode = CKConvertFollyDynamicToId(newProps.flashMode);
    if (flashMode != nil && [flashMode isKindOfClass:NSString.class]) {
        _view.flashMode = [flashMode isEqualToString:@"auto"] ? CKFlashModeAuto :  [flashMode isEqualToString:@"on"] ? CKFlashModeOn : CKFlashModeOff;
        [changedProps addObject:@"flashMode"];
    }
    id torchMode = CKConvertFollyDynamicToId(newProps.torchMode);
    if (torchMode != nil && [torchMode isKindOfClass:NSString.class]) {
        _view.torchMode = [torchMode isEqualToString:@"on"] ? CKTorchModeOn : CKTorchModeOff;
        [changedProps addObject:@"torchMode"];
    }
    id ratioOverlay = CKConvertFollyDynamicToId(newProps.ratioOverlay);
    if (ratioOverlay != nil) {
        _view.ratioOverlay = ratioOverlay;
        [changedProps addObject:@"ratioOverlay"];
    }
    UIColor *ratioOverlayColor = RCTUIColorFromSharedColor(newProps.ratioOverlayColor);
    if (ratioOverlayColor != nil) {
        _view.ratioOverlayColor = ratioOverlayColor;
        [changedProps addObject:@"ratioOverlayColor"];
    }
    id scanBarcode = CKConvertFollyDynamicToId(newProps.scanBarcode);
    if (scanBarcode != nil) {
        _view.scanBarcode = scanBarcode;
        [changedProps addObject:@"scanBarcode"];
    }
    id showFrame = CKConvertFollyDynamicToId(newProps.showFrame);
    if (showFrame != nil) {
        _view.showFrame = showFrame;
        [changedProps addObject:@"showFrame"];
    }
    id scanThrottleDelay = CKConvertFollyDynamicToId(newProps.scanThrottleDelay);
    if (scanThrottleDelay != nil) {
        _view.scanThrottleDelay = [scanThrottleDelay intValue];
        [changedProps addObject:@"scanThrottleDelay"];
    }
    UIColor *frameColor = RCTUIColorFromSharedColor(newProps.frameColor);
    if (frameColor != nil) {
        _view.frameColor = frameColor;
        [changedProps addObject:@"frameColor"];
    }
    UIColor *laserColor = RCTUIColorFromSharedColor(newProps.laserColor);
    if (laserColor != nil) {
        _view.laserColor = laserColor;
        [changedProps addObject:@"laserColor"];
    }
    id resetFocusTimeout = CKConvertFollyDynamicToId(newProps.resetFocusTimeout);
    if (resetFocusTimeout != nil) {
        _view.resetFocusTimeout = [resetFocusTimeout intValue];
        [changedProps addObject:@"resetFocusTimeout"];
    }
    id resetFocusWhenMotionDetected = CKConvertFollyDynamicToId(newProps.resetFocusWhenMotionDetected);
    if (resetFocusWhenMotionDetected != nil) {
        _view.resetFocusWhenMotionDetected = resetFocusWhenMotionDetected;
        [changedProps addObject:@"resetFocusWhenMotionDetected"];
    }
    id focusMode = CKConvertFollyDynamicToId(newProps.focusMode);
    if (focusMode != nil) {
        _view.focusMode = [focusMode isEqualToString:@"on"] ? CKFocusModeOn : CKFocusModeOff;
        [changedProps addObject:@"focusMode"];
    }
    id zoomMode = CKConvertFollyDynamicToId(newProps.zoomMode);
    if (zoomMode != nil) {
        _view.zoomMode = [focusMode isEqualToString:@"on"] ? CKZoomModeOn : CKZoomModeOff;
        [changedProps addObject:@"zoomMode"];
    }
    id zoom = CKConvertFollyDynamicToId(newProps.zoom);
    if (zoom != nil) {
        _view.zoom = zoom;
        [changedProps addObject:@"zoom"];
    }
    id maxZoom = CKConvertFollyDynamicToId(newProps.maxZoom);
    if (maxZoom != nil) {
        _view.maxZoom = maxZoom;
        [changedProps addObject:@"maxZoom"];
    }
    
    [super updateProps:props oldProps:oldProps];
    [_view didSetProps:changedProps];
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];
    [self prepareView];
}

@end

Class<RCTComponentViewProtocol> CKCameraCls(void)
{
  return CKCameraViewComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
