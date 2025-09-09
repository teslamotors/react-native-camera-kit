#ifdef RCT_NEW_ARCH_ENABLED

#import "CKCameraViewComponentView.h"

#import <React/RCTBridge+Private.h>
#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <folly/dynamic.h>

#import <react/renderer/components/NativeCameraKitSpec/ComponentDescriptors.h>
#import <react/renderer/components/NativeCameraKitSpec/EventEmitters.h>
#import <react/renderer/components/NativeCameraKitSpec/Props.h>
#import <react/renderer/components/NativeCameraKitSpec/RCTComponentViewHelpers.h>

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
    const auto &oldViewProps = *std::static_pointer_cast<CKCameraProps const>(_props);
    const auto &newProps = *std::static_pointer_cast<CKCameraProps const>(props);

    NSMutableArray<NSString *> *changedProps = [NSMutableArray new];
    
    // Keep changedProps aligned with CameraView.swift didSetProps
    // Include event-related props so CameraView can update listeners/state
    [changedProps addObject:@"onOrientationChange"];
    [changedProps addObject:@"onZoom"];
    [changedProps addObject:@"onReadCode"];

    if (oldViewProps.cameraType != newProps.cameraType) {
        _view.cameraType = newProps.cameraType == "back" ? CKCameraTypeBack : CKCameraTypeFront;
        [changedProps addObject:@"cameraType"];
    }
    if (oldViewProps.resizeMode != newProps.resizeMode) {
        _view.resizeMode = newProps.resizeMode == "contain" ? CKResizeModeContain : CKResizeModeCover;
        [changedProps addObject:@"resizeMode"];
    }
    id flashMode = CKConvertFollyDynamicToId(newProps.flashMode);
    if (oldViewProps.flashMode != newProps.flashMode) {
        _view.flashMode = [flashMode isEqualToString:@"auto"] ? CKFlashModeAuto :  [flashMode isEqualToString:@"on"] ? CKFlashModeOn : CKFlashModeOff;
        [changedProps addObject:@"flashMode"];
    }
    if (oldViewProps.maxPhotoQualityPrioritization != newProps.maxPhotoQualityPrioritization) {
        if (newProps.maxPhotoQualityPrioritization == "balanced") {
            _view.maxPhotoQualityPrioritization = CKMaxPhotoQualityPrioritizationBalanced;
        } else if (newProps.maxPhotoQualityPrioritization == "quality") {
            _view.maxPhotoQualityPrioritization = CKMaxPhotoQualityPrioritizationQuality;
        } else {
            _view.maxPhotoQualityPrioritization = CKMaxPhotoQualityPrioritizationSpeed;
        }
        [changedProps addObject:@"maxPhotoQualityPrioritization"];
    }
    if (oldViewProps.torchMode != newProps.torchMode) {
        _view.torchMode = newProps.torchMode == "on" ? CKTorchModeOn : CKTorchModeOff;
        [changedProps addObject:@"torchMode"];
    }
    id ratioOverlay = CKConvertFollyDynamicToId(newProps.ratioOverlay);
    if (ratioOverlay != nil) {
        _view.ratioOverlay = ratioOverlay;
        [changedProps addObject:@"ratioOverlay"];
    }
    if (oldViewProps.ratioOverlayColor != newProps.ratioOverlayColor) {
        _view.ratioOverlayColor = RCTUIColorFromSharedColor(newProps.ratioOverlayColor);
        [changedProps addObject:@"ratioOverlayColor"];
    }
    if (_view.scanBarcode != newProps.scanBarcode) {
        _view.scanBarcode = newProps.scanBarcode;
        [changedProps addObject:@"scanBarcode"];
    }
    if (_view.showFrame != newProps.showFrame) {
        _view.showFrame = newProps.showFrame;
        [changedProps addObject:@"showFrame"];
    }
    if (newProps.scanThrottleDelay > -1) {
        _view.scanThrottleDelay = newProps.scanThrottleDelay;
        [changedProps addObject:@"scanThrottleDelay"];
    }
    if (oldViewProps.frameColor != newProps.frameColor) {
        _view.frameColor = RCTUIColorFromSharedColor(newProps.frameColor);
        [changedProps addObject:@"frameColor"];
    }
    if (oldViewProps.laserColor != newProps.laserColor) {
        UIColor *laserColor = RCTUIColorFromSharedColor(newProps.laserColor);
        _view.laserColor = laserColor;
        [changedProps addObject:@"laserColor"];
    }
    if (oldViewProps.resetFocusTimeout != newProps.resetFocusTimeout) {
        _view.resetFocusTimeout = newProps.resetFocusTimeout;
        [changedProps addObject:@"resetFocusTimeout"];
    }
    if (_view.resetFocusWhenMotionDetected != newProps.resetFocusWhenMotionDetected) {
        _view.resetFocusWhenMotionDetected = newProps.resetFocusWhenMotionDetected;
        [changedProps addObject:@"resetFocusWhenMotionDetected"];
    }
    if (oldViewProps.focusMode != newProps.focusMode) {
        id focusMode = CKConvertFollyDynamicToId(newProps.focusMode);
        _view.focusMode = [focusMode isEqualToString:@"on"] ? CKFocusModeOn : CKFocusModeOff;
        [changedProps addObject:@"focusMode"];
    }
    if (oldViewProps.zoomMode != newProps.zoomMode) {
        id zoomMode = CKConvertFollyDynamicToId(newProps.zoomMode);
        _view.zoomMode = [zoomMode isEqualToString:@"on"] ? CKZoomModeOn : CKZoomModeOff;
        [changedProps addObject:@"zoomMode"];
    }
    if (oldViewProps.zoom != newProps.zoom) {
        _view.zoom = newProps.zoom > -1 ? @(newProps.zoom) : nil;
        [changedProps addObject:@"zoom"];
    }
    if (oldViewProps.maxZoom != newProps.maxZoom) {
        _view.maxZoom = newProps.maxZoom > -1 ? @(newProps.maxZoom) : nil;
        [changedProps addObject:@"maxZoom"];
    }
    float barcodeWidth = newProps.barcodeFrameSize.width;
    float barcodeHeight = newProps.barcodeFrameSize.height;
    if (barcodeWidth != [_view.barcodeFrameSize[@"width"] floatValue] || barcodeHeight != [_view.barcodeFrameSize[@"height"] floatValue]) {
        _view.barcodeFrameSize = @{@"width": @(barcodeWidth), @"height": @(barcodeHeight)};
        [changedProps addObject:@"barcodeFrameSize"];
    }
    
    
    [super updateProps:props oldProps:oldProps];
    [_view didSetProps:changedProps];
}

+ (BOOL)shouldBeRecycled
{
    // Disable recycling as cameras are expensive to keep in memory and may cause unintended behaviors
    // (we need to reset the camera properly when recycling)
    // We can enable it later if find that the performance is needed
    return NO;
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
