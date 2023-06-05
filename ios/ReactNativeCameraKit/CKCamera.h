#import <UIKit/UIKit.h>
@import AVFoundation;

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif


typedef void (^CaptureBlock)(NSDictionary *imageObject);
typedef void (^CallbackBlock)(BOOL success);

@interface CKCamera : UIView

@property (nonatomic, readonly) AVCaptureDeviceInput *videoDeviceInput;


// api
- (void)snapStillImage:(NSDictionary*)options success:(CaptureBlock)block onError:(void (^)(NSString*))onError;

- (void)setTorchMode:(AVCaptureTorchMode)torchMode;

+ (NSURL*)saveToTmpFolder:(NSData*)data;

@end
