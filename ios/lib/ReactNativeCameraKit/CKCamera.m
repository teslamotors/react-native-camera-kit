//
//  CKCamera.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 31/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

@import Foundation;
@import Photos;

#if __has_include(<React/RCTBridge.h>)
#import <React/UIView+React.h>
#import <React/RCTConvert.h>
#else
#import "UIView+React.h"
#import "RCTConvert.h"
#endif


#import "CKCamera.h"
#import "CKCameraOverlayView.h"
#import "CKGalleryManager.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM( NSInteger, CKSetupResult ) {
    CKSetupResultSuccess,
    CKSetupResultCameraNotAuthorized,
    CKSetupResultSessionConfigurationFailed
};

@implementation RCTConvert(CKCameraFlashMode)

RCT_ENUM_CONVERTER(CKCameraFlashMode, (@{
                                         @"auto": @(AVCaptureFlashModeAuto),
                                         @"on": @(AVCaptureFlashModeOn),
                                         @"off": @(AVCaptureFlashModeOff)
                                         }), AVCaptureFlashModeAuto, integerValue)

@end

@implementation RCTConvert(CKCameraFocushMode)

RCT_ENUM_CONVERTER(CKCameraFocushMode, (@{
                                          @"on": @(CKCameraFocushModeOn),
                                          @"off": @(CKCameraFocushModeOff)
                                          }), CKCameraFocushModeOn, integerValue)

@end

@implementation RCTConvert(CKCameraZoomMode)

RCT_ENUM_CONVERTER(CKCameraZoomMode, (@{
                                        @"on": @(CKCameraZoomModeOn),
                                        @"off": @(CKCameraZoomModeOff)
                                        }), CKCameraZoomModeOn, integerValue)

@end



#define CAMERA_OPTION_FLASH_MODE                    @"flashMode"
#define CAMERA_OPTION_FOCUS_MODE                    @"focusMode"
#define CAMERA_OPTION_ZOOM_MODE                     @"zoomMode"
#define CAMERA_OPTION_CAMERA_RATIO_OVERLAY          @"ratioOverlay"
#define CAMERA_OPTION_CAMERA_RATIO_OVERLAY_COLOR    @"ratioOverlayColor"
#define CAMERA_OPTION_ON_READ_QR_CODE               @"onReadQRCode"
#define TIMER_FOCUS_TIME_SECONDS            5

@interface CKCamera () <AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate>


@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSDictionary *cameraOptions;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) NSTimer *focusViewTimer;
@property (nonatomic, strong) CKCameraOverlayView *cameraOverlayView;

// session management
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, readwrite) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) NSString *qrcodeStringValue;


// utilities
@property (nonatomic) CKSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

// cameraOptions props
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) CKCameraFocushMode focusMode;
@property (nonatomic) CKCameraZoomMode zoomMode;
@property (nonatomic, strong) NSString* ratioOverlayString;
@property (nonatomic, strong) UIColor *ratioOverlayColor;
@property (nonatomic, strong) RCTDirectEventBlock onReadQRCode;

@property (nonatomic) BOOL isAddedOberver;

@end

@implementation CKCamera

#pragma mark - initializtion

- (void)dealloc
{
    [self removeObservers];
    //NSLog(@"dealloc");
}

-(PHFetchOptions *)fetchOptions {
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d && creationDate <= %@",PHAssetMediaTypeImage, [NSDate date]];
    // iOS 9+
    if ([fetchOptions respondsToSelector:@selector(fetchLimit)]) {
        fetchOptions.fetchLimit = 1;
    }
    
    return fetchOptions;
}

- (void)removeReactSubview:(UIView *)subview
{
    [subview removeFromSuperview];
}


- (void)removeFromSuperview
{
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == CKSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );
    [super removeFromSuperview];
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self){
        // Create the AVCaptureSession.
        self.session = [[AVCaptureSession alloc] init];
        
        // Communicate with the session and other session objects on this queue.
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
        
        [self handleCameraPermission];
        
#if !(TARGET_IPHONE_SIMULATOR)
        [self setupCaptionSession];
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.layer addSublayer:self.previewLayer];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
#endif
        
        UIView *focusView = [[UIView alloc] initWithFrame:CGRectZero];
        focusView.backgroundColor = [UIColor clearColor];
        focusView.layer.borderColor = [UIColor yellowColor].CGColor;
        focusView.layer.borderWidth = 1;
        focusView.hidden = YES;
        self.focusView = focusView;
        
        [self addSubview:self.focusView];
        
        // defualts
        self.zoomMode = CKCameraZoomModeOn;
        self.flashMode = CKCameraFlashModeAuto;
        self.focusMode = CKCameraFocushModeOn;
    }
    
    return self;
}


-(void)setCameraOptions:(NSDictionary *)cameraOptions {
    _cameraOptions = cameraOptions;
    
    // CAMERA_OPTION_FLASH_MODE
    id flashMode = self.cameraOptions[CAMERA_OPTION_FLASH_MODE];
    if (flashMode) {
        self.flashMode = [RCTConvert CKCameraFlashMode:flashMode];
    }
    
    // CAMERA_OPTION_FOCUS_MODE
    id focusMode = self.cameraOptions[CAMERA_OPTION_FOCUS_MODE];
    if (focusMode) {
        self.focusMode = [RCTConvert CKCameraFocushMode:focusMode];
        
        if (self.focusMode == CKCameraFocushModeOn) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposeTap:)];
            [self addGestureRecognizer:tapGesture];
        }
    }
    
    // CAMERA_OPTION_FOCUS_MODE
    id zoomMode = self.cameraOptions[CAMERA_OPTION_ZOOM_MODE];
    if (zoomMode) {
        self.zoomMode = [RCTConvert CKCameraZoomMode:zoomMode];
        
        if (self.zoomMode == CKCameraZoomModeOn) {
            UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchToZoomRecognizer:)];
            [self addGestureRecognizer:pinchGesture];
        }
    }
    
    // CAMERA_OPTION_CAMERA_RATIO_OVERLAY_COLOR
    id ratioOverlayColor = self.cameraOptions[CAMERA_OPTION_CAMERA_RATIO_OVERLAY_COLOR];
    if (ratioOverlayColor) {
        self.ratioOverlayColor = [RCTConvert UIColor:ratioOverlayColor];
    }
    
    // CAMERA_OPTION_CAMERA_RATIO_OVERLAY
    id ratioOverlay = self.cameraOptions[CAMERA_OPTION_CAMERA_RATIO_OVERLAY];
    if (ratioOverlay) {
        self.ratioOverlayString = [RCTConvert NSString:ratioOverlay];
        [self setRatio:self.ratioOverlayString];
    }
    //
    //    // CAMERA_OPTION_CAMERA_RATIO_OVERLAY
    //    id onReadQRCode = self.cameraOptions[CAMERA_OPTION_ON_READ_QR_CODE];
    //    if (onReadQRCode) {
    //        self.onReadQRCode = onReadQRCode;
    //    }
}


-(void)setupCaptionSession {
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult != CKSetupResultSuccess ) {
            return;
        }
        
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [CKCamera deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            [CKCamera setFlashMode:self.flashMode forDevice:self.videoDeviceInput.device];
        }
        else {
            self.setupResult = CKSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ( [self.session canAddOutput:movieFileOutput] ) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( connection.isVideoStabilizationSupported ) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        else {
            self.setupResult = CKSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ( [self.session canAddOutput:stillImageOutput] ) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else {
            self.setupResult = CKSetupResultSessionConfigurationFailed;
        }
        if (self.onReadQRCode) {//TODO check if qrcode mode is on
            self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
            [self.session addOutput:self.metadataOutput];
            [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [self.metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeQRCode]];
        }
        
        
        [self.session commitConfiguration];
    } );
}

-(void)handleCameraPermission {
    
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = CKSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = CKSetupResultCameraNotAuthorized;
            break;
        }
    }
}

-(void)reactSetFrame:(CGRect)frame {
    [super reactSetFrame:frame];
    
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    
    self.previewLayer.frame = self.bounds;
    
    
    
    [self setOverlayRatioView];
    
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case CKSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case CKSetupResultCameraNotAuthorized:
            {
                //                dispatch_async( dispatch_get_main_queue(), ^{
                //                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                //                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                //                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                //                    [alertController addAction:cancelAction];
                //                    // Provide quick access to Settings.
                //                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                //                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                //                    }];
                //                    [alertController addAction:settingsAction];
                //                    [self presentViewController:alertController animated:YES completion:nil];
                //                } );
                break;
            }
            case CKSetupResultSessionConfigurationFailed:
            {
                //                dispatch_async( dispatch_get_main_queue(), ^{
                //                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                //                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                //                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                //                    [alertController addAction:cancelAction];
                //                    [self presentViewController:alertController animated:YES completion:nil];
                //                } );
                break;
            }
        }
    } );
}

-(void)setRatioOverlayString:(NSString *)ratioOverlayString {
    _ratioOverlayString = ratioOverlayString;
    [self.cameraOverlayView setRatio:self.ratioOverlayString];
}

-(void)setOverlayRatioView {
    if (self.ratioOverlayString) {
        [self.cameraOverlayView removeFromSuperview];
        self.cameraOverlayView = [[CKCameraOverlayView alloc] initWithFrame:self.bounds ratioString:self.ratioOverlayString overlayColor:self.ratioOverlayColor];
        [self addSubview:self.cameraOverlayView];
    }
}


#pragma mark -


-(void)startFocusViewTimer {
    [self stopFocusViewTimer];
    
    self.focusViewTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_FOCUS_TIME_SECONDS target:self selector:@selector(dismissFocusView) userInfo:nil repeats:NO];
}

-(void)stopFocusViewTimer {
    if (self.focusViewTimer) {
        [self.focusViewTimer invalidate];
        self.focusViewTimer = nil;
    }
}

-(void)dismissFocusView {
    
    [self stopFocusViewTimer];
    
    [UIView animateWithDuration:0.8 animations:^{
        self.focusView.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.focusView.frame = CGRectZero;
        self.focusView.hidden = YES;
        self.focusView.alpha = 1;
    }];
}


+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
        
    }
    
    return captureDevice;
}


- (void)setFlashMode:(AVCaptureFlashMode)flashMode callback:(CallbackBlock)block {
    _flashMode = flashMode;
    [CKCamera setFlashMode:flashMode forDevice:self.videoDeviceInput.device];
    if (block) {
        block(self.videoDeviceInput.device.flashMode == flashMode);
    }
}


+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else {
            //NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

- (void)setRatio:(NSString*)ratioString {
    if (ratioString && ![ratioString isEqualToString:@""]) {
        self.ratioOverlayString = ratioString;
    }
}


#pragma mark - actions



- (void)snapStillImage:(BOOL)shouldSaveToCameraRoll success:(CaptureBlock)block {
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = self.previewLayer.connection.videoOrientation;
        
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *capturedImage = [UIImage imageWithData:imageData];
                capturedImage = [CKCamera rotateImage:capturedImage];
                
                CGSize previewScaleSize = [CKCamera cropImageToPreviewSize:capturedImage size:self.previewLayer.bounds.size];
                CGRect rectToCrop = CGRectMake((capturedImage.size.width-previewScaleSize.width)*0.5, (capturedImage.size.height-previewScaleSize.height)*0.5, previewScaleSize.width, previewScaleSize.height);
                
                if (self.ratioOverlayString) {
                    
                    rectToCrop = [CKCamera cropRectForSize:rectToCrop overlayObject:self.cameraOverlayView.overlayObject];
                }
                
                CGImageRef imageRef = CGImageCreateWithImageInRect(capturedImage.CGImage, rectToCrop);
                capturedImage = [UIImage imageWithCGImage:imageRef scale:capturedImage.scale orientation:UIImageOrientationUp];
                imageData = UIImageJPEGRepresentation(capturedImage, 0.85f);
                
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if ( status == PHAuthorizationStatusAuthorized ) {
                        
                        NSMutableDictionary *imageInfoDict = [[NSMutableDictionary alloc] init];
                        
                        NSURL *temporaryFileURL = [CKCamera saveToTmpFolder:imageData];
                        if (temporaryFileURL) {
                            imageInfoDict[@"uri"] = temporaryFileURL.description;
                            imageInfoDict[@"name"] = temporaryFileURL.lastPathComponent;
                        }
                        imageInfoDict[@"size"] = [NSNumber numberWithInteger:imageData.length];
                        
                        if (shouldSaveToCameraRoll) {
                            NSData *compressedImageData = UIImageJPEGRepresentation(capturedImage, 1.0f);
                            
                            [CKGalleryManager saveImageToCameraRoll:compressedImageData temporaryFileURL:temporaryFileURL block:^(BOOL success) {
                                if (success) {
                                    NSString *localIdentifier = [CKGalleryManager getImageLocalIdentifierForFetchOptions:self.fetchOptions];
                                    if (localIdentifier) {
                                        imageInfoDict[@"id"] = localIdentifier;
                                    }
                                    
                                    if (block) {
                                        block(imageInfoDict);
                                    }
                                }
                                else {
                                    //NSLog( @"Could not save to camera roll");
                                }
                            }];
                        } else if (block) {
                            block(imageInfoDict);
                        }
                    }
                }];
                
                CGImageRelease(imageRef);
            }
            else {
                //NSLog( @"Could not capture still image: %@", error );
            }
        }];
    } );
}

+(UIImage*)rotateImage:(UIImage*)originalImage {
    
    if (originalImage.imageOrientation == UIImageOrientationUp || originalImage == nil)
        return originalImage;
    
    
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, originalImage.scale);
    
    [originalImage drawInRect:(CGRect){0, 0, originalImage.size}];
    UIImage *normalizedImage =  UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return normalizedImage;
}


-(void)changeCamera:(CallbackBlock)block
{
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"changeCamera isn't support on simulator");
    return;
#endif
    
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }
        
        AVCaptureDevice *videoDevice = [CKCamera deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [self.session beginConfiguration];
        
        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        [self.session removeInput:self.videoDeviceInput];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [CKCamera setFlashMode:self.flashMode forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        }
        else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        [self.session commitConfiguration];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            if (block) {
                block(YES);
            }
            
        } );
    } );
}

+(NSURL*)saveToTmpFolder:(NSData*)data {
    NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
    NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
    
    NSError *error = nil;
    [data writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
    
    if ( error ) {
        //NSLog( @"Error occured while writing image data to a temporary file: %@", error );
    }
    else {
        //NSLog(@"Image Saved - YOU ROCK!");
    }
    return temporaryFileURL;
}


-(void) handlePinchToZoomRecognizer:(UIPinchGestureRecognizer*)pinchRecognizer {
    if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        [self zoom:pinchRecognizer.velocity];
    }
}


- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewLayer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    CGFloat halfDiagonal = 80;
    CGFloat halfDiagonalAnimation = halfDiagonal*2;
    
    CGRect focusViewFrame = CGRectMake(touchPoint.x - (halfDiagonal/2), touchPoint.y - (halfDiagonal/2), halfDiagonal, halfDiagonal);
    CGRect focusViewFrameFoAnimation = CGRectMake(touchPoint.x - (halfDiagonalAnimation/2), touchPoint.y - (halfDiagonalAnimation/2), halfDiagonalAnimation, halfDiagonalAnimation);
    
    self.focusView.alpha = 0;
    self.focusView.hidden = NO;
    self.focusView.frame = focusViewFrameFoAnimation;
    
    
    [UIView animateWithDuration:0.2 animations:^{
        self.focusView.frame = focusViewFrame;
        self.focusView.alpha = 1;
        
    } completion:^(BOOL finished) {
        self.focusView.alpha = 1;
        self.focusView.frame = focusViewFrame;
        
    }];
    
    [self startFocusViewTimer];
}


- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            //NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}



- (void)zoom:(CGFloat)velocity {
    if (isnan(velocity)) {
        return;
    }
    const CGFloat pinchVelocityDividerFactor = 20.0f; // TODO: calibrate or make this component's property
    NSError *error = nil;
    AVCaptureDevice *device = [[self videoDeviceInput] device];
    if ([device lockForConfiguration:&error]) {
        CGFloat zoomFactor = device.videoZoomFactor + atan(velocity / pinchVelocityDividerFactor);
        if (zoomFactor > device.activeFormat.videoMaxZoomFactor) {
            zoomFactor = device.activeFormat.videoMaxZoomFactor;
        } else if (zoomFactor < 1) {
            zoomFactor = 1.0f;
        }
        device.videoZoomFactor = zoomFactor;
        [device unlockForConfiguration];
    } else {
        //NSLog(@"error: %@", error);
    }
}


+ (UIImage *)imageWithImage:(UIImage *)image scaledToRect:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


+(CGRect)cropRectForSize:(CGRect)frame overlayObject:(CKOverlayObject*)overlayObject {
    
    CGRect ans = CGRectZero;
    CGSize centerSize = CGSizeZero;
    
    if (overlayObject.width < overlayObject.height) {
        centerSize.width = frame.size.width;
        centerSize.height = frame.size.height * overlayObject.ratio;
        
        ans.origin.x = 0;
        ans.origin.y = (frame.size.height - centerSize.height)*0.5;
        
    }
    else if (overlayObject.width > overlayObject.height){
        centerSize.width = frame.size.width / overlayObject.ratio;
        centerSize.height = frame.size.height;
        
        ans.origin.x = (frame.size.width - centerSize.width)*0.5;
        ans.origin.y = 0;
        
    }
    else { // ratio is 1:1
        centerSize.width = frame.size.width;
        centerSize.height = frame.size.width;
        
        ans.origin.x = 0;
        ans.origin.y = (frame.size.height - centerSize.height)/2;
    }
    
    ans.size = centerSize;
    ans.origin.x += frame.origin.x;
    ans.origin.y += frame.origin.y;
    return ans;
}

+(CGSize)cropImageToPreviewSize:(UIImage*)image size:(CGSize)previewSize {
    
    CGRect ans = CGRectZero;
    CGSize centerSize = CGSizeZero;
    
    float imageToPreviewWidthScale = image.size.width/previewSize.width;
    float imageToPreviewHeightScale = image.size.width/previewSize.width;
    
    return CGSizeMake(previewSize.width*imageToPreviewWidthScale, previewSize.height*imageToPreviewHeightScale);
}


#pragma mark - observers


- (void)addObservers
{
    
    if (!self.isAddedOberver) {
        [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
        [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
        // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
        // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
        // interruption reasons.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
        self.isAddedOberver = YES;
    }
}


- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        //NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
    }
}


- (void)removeObservers
{
    if (self.isAddedOberver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
        [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
        self.isAddedOberver = NO;
    }
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    //NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else {
            }
        } );
    }
}


- (void)subjectAreaDidChange:(NSNotification *)notification
{
    //    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    //    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
    //        //NSLog(@"subjectAreaDidChange");
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.alpha = 0.0;
                [UIView animateWithDuration:0.35 animations:^{
                    self.alpha = 1.0;
                }];
            } );
        }
    }
    else if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        //        dispatch_async( dispatch_get_main_queue(), ^{
        //            // Only enable the ability to change camera if the device has more than one camera.
        //            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
        //            self.recordButton.enabled = isSessionRunning;
        //            self.stillButton.enabled = isSessionRunning;
        //        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    for(AVMetadataObject *metadataObject in metadataObjects)
    {
        if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject*)[self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            
            if (self.onReadQRCode && code.stringValue && ![code.stringValue isEqualToString:self.qrcodeStringValue]) {
                self.qrcodeStringValue = code.stringValue;
                self.onReadQRCode(@{@"qrcodeStringValue": code.stringValue});
            }
        }
    }
}



@end
