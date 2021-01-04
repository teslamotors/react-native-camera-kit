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
#import "CKMockPreview.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM( NSInteger, CKSetupResult ) {
    CKSetupResultSuccess,
    CKSetupResultCameraNotAuthorized,
    CKSetupResultSessionConfigurationFailed
};

@implementation RCTConvert(CKCameraTorchMode)

RCT_ENUM_CONVERTER(CKCameraTorchMode, (@{
                                         @"auto": @(AVCaptureTorchModeAuto),
                                         @"on": @(AVCaptureTorchModeOn),
                                         @"off": @(AVCaptureTorchModeOff)
                                         }), AVCaptureTorchModeAuto, integerValue)


@end

@implementation RCTConvert(CKCameraFlashMode)

RCT_ENUM_CONVERTER(CKCameraFlashMode, (@{
                                         @"auto": @(AVCaptureFlashModeAuto),
                                         @"on": @(AVCaptureFlashModeOn),
                                         @"off": @(AVCaptureFlashModeOff)
                                         }), AVCaptureFlashModeAuto, integerValue)

@end

@implementation RCTConvert(CKCameraFocusMode)

RCT_ENUM_CONVERTER(CKCameraFocusMode, (@{
                                          @"on": @(CKCameraFocusModeOn),
                                          @"off": @(CKCameraFocusModeOff)
                                          }), CKCameraFocusModeOn, integerValue)

@end

@implementation RCTConvert(CKCameraZoomMode)

RCT_ENUM_CONVERTER(CKCameraZoomMode, (@{
                                        @"on": @(CKCameraZoomModeOn),
                                        @"off": @(CKCameraZoomModeOff)
                                        }), CKCameraZoomModeOn, integerValue)

@end

@interface CKCamera () <AVCaptureMetadataOutputObjectsDelegate>


@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CKMockPreview *mockPreview;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) NSTimer *focusViewTimer;
@property (nonatomic, strong) CKCameraOverlayView *cameraOverlayView;

@property (nonatomic, strong) NSTimer *focusResetTimer;
@property (nonatomic) BOOL startFocusResetTimerAfterFocusing;
@property (nonatomic) NSInteger resetFocusTimeout;
@property (nonatomic) BOOL resetFocusWhenMotionDetected;
@property (nonatomic) BOOL tapToFocusEngaged;
@property (nonatomic) BOOL saveToCameraRoll;
@property (nonatomic) BOOL saveToCameraRollWithPhUrl;

// session management
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, readwrite) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) NSString *codeStringValue;


// utilities
@property (nonatomic) CKSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

// scanner options
@property (nonatomic, strong) NSDictionary *scannerOptions;
@property (nonatomic) BOOL showFrame;
@property (nonatomic) UIView *greenScanner;
@property (nonatomic, strong) RCTDirectEventBlock onReadCode;

@property (nonatomic) CGFloat frameOffset;
@property (nonatomic) CGFloat heightFrame;
@property (nonatomic, strong) UIColor *frameColor;
@property (nonatomic) UIView * dataReadingFrame;

// camera options
@property (nonatomic) AVCaptureTorchMode torchMode;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) CKCameraFocusMode focusMode;
@property (nonatomic) CKCameraZoomMode zoomMode;
@property (nonatomic, strong) NSString* ratioOverlay;
@property (nonatomic, strong) UIColor *ratioOverlayColor;

@property (nonatomic) BOOL isAddedOberver;

@end

@implementation CKCamera

#pragma mark - initializtion

- (void)dealloc
{
    [self removeObservers];
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
    [super removeReactSubview:subview];
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

        // Fit camera preview inside of viewport
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;

        // Communicate with the session and other session objects on this queue.
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );

        [self handleCameraPermission];

#if !(TARGET_IPHONE_SIMULATOR)
        [self setupCaptureSession];
#endif
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.layer addSublayer:self.previewLayer];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
#if (TARGET_IPHONE_SIMULATOR)
        // Create mock camera layer. When a photo is taken, we capture this layer and save it in place of a
        // hardware input.
        self.mockPreview = [[CKMockPreview alloc] initWithFrame:CGRectZero];
        [self addSubview:self.mockPreview];
#endif
        
        UIView *focusView = [[UIView alloc] initWithFrame:CGRectZero];
        focusView.backgroundColor = [UIColor clearColor];
        focusView.layer.borderColor = [UIColor yellowColor].CGColor;
        focusView.layer.borderWidth = 1;
        focusView.hidden = YES;
        self.focusView = focusView;

        [self addSubview:self.focusView];

        // defaults
        self.zoomMode = CKCameraZoomModeOn;
        self.flashMode = CKCameraFlashModeAuto;
        self.focusMode = CKCameraFocusModeOn;
    }

    return self;
}

-(void)setTorchMode:(AVCaptureTorchMode)torchMode callback:(CallbackBlock)block {
    _torchMode = torchMode;
    if (self.videoDeviceInput && [self.videoDeviceInput.device isTorchModeSupported:torchMode] && self.videoDeviceInput.device.hasTorch) {
        NSError* err = nil;
        if ( [self.videoDeviceInput.device lockForConfiguration:&err] ) {
            [self.videoDeviceInput.device setTorchMode:torchMode];
            [self.videoDeviceInput.device unlockForConfiguration];
        }
    }
    if (block) {
        block(self.videoDeviceInput.device.torchMode == torchMode);
    }
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
        } else {
            NSLog(@"Could not lock device for configuration: %@", error);
        }
    }
}

- (void)setFocusMode:(CKCameraFocusMode)focusMode {
    _focusMode = focusMode;
    if (self.focusMode == CKCameraFocusModeOn) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposeTap:)];
        [self addGestureRecognizer:tapGesture];
    } else {
        NSArray *gestures = [self gestureRecognizers];
        for (id object in gestures) {
            if ([object class] == UITapGestureRecognizer.class) {
                [self removeGestureRecognizer:object];
            }
        }
    }
}

- (void)setZoomMode:(CKCameraZoomMode)zoomMode {
    _zoomMode = zoomMode;
    if (zoomMode == CKCameraZoomModeOn) {
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchToZoomRecognizer:)];
        [self addGestureRecognizer:pinchGesture];
    } else {
        NSArray *gestures = [self gestureRecognizers];
        for (id object in gestures) {
            if ([object class] == UIPinchGestureRecognizer.class) {
                [self removeGestureRecognizer:object];
            }
        }
    }
}

- (void)setRatio:(NSString*)ratio {
    if (ratio && ![ratio isEqualToString:@""]) {
        self.ratioOverlay = ratio;
    }
}

-(void)setupCaptureSession {
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

        AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
        if ([self.session canAddOutput:output]) {
            self.metadataOutput = output;
            [self.session addOutput:self.metadataOutput];
            [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [self.metadataOutput setMetadataObjectTypes:[self.metadataOutput availableMetadataObjectTypes]];
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
    
    self.previewLayer.frame = self.bounds;

#if TARGET_IPHONE_SIMULATOR
    self.mockPreview.frame = self.bounds;
    return;
#endif

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
                if (self.showFrame) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addFrameForScanner];
                    });
                }
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

-(void)setRatioOverlay:(NSString *)ratioOverlay {
    _ratioOverlay = ratioOverlay;
    [self.cameraOverlayView setRatio:self.ratioOverlay];
}

-(void)setOverlayRatioView {
    if (self.ratioOverlay) {
        [self.cameraOverlayView removeFromSuperview];
        self.cameraOverlayView = [[CKCameraOverlayView alloc] initWithFrame:self.bounds ratioString:self.ratioOverlay overlayColor:self.ratioOverlayColor];
        [self addSubview:self.cameraOverlayView];
    }
}


#pragma mark -


+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;

    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }

    return captureDevice;
}


#pragma mark - actions



- (void)snapStillImage:(NSDictionary*)options success:(CaptureBlock)onSuccess onError:(void (^)(NSString*))onError {
    
    #if TARGET_IPHONE_SIMULATOR
    [self capturePreviewLayer:options success:onSuccess onError:onError];
    return;
    #endif
    
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];

        UIImageOrientation imageOrientation = UIImageOrientationUp;
        switch([UIDevice currentDevice].orientation) {
            default:
            case UIDeviceOrientationPortrait:
                connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                imageOrientation = UIImageOrientationUp;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                imageOrientation = UIImageOrientationDown;
                break;
            case UIDeviceOrientationLandscapeLeft:
                imageOrientation = UIImageOrientationRight;
                connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                imageOrientation = UIImageOrientationRightMirrored;
                break;
        }

        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if (!imageDataSampleBuffer) {
                NSLog(@"Could not capture still image: %@", error);
                onError(@"Could not capture still image");
                return;
            }

            // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            [self writeCapturedImageData:imageData onSuccess:onSuccess onError:onError];
            [self resetFocus];
        }];
    });
}

- (void)capturePreviewLayer:(NSDictionary*)options success:(CaptureBlock)onSuccess onError:(void (^)(NSString*))onError
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.mockPreview != nil) {
            UIImage *previewSnapshot = [self.mockPreview snapshotWithTimestamp:YES]; // Generate snapshot from main UI thread
            dispatch_async( self.sessionQueue, ^{ // write image async
                [self writeCapturedImageData:UIImagePNGRepresentation(previewSnapshot) onSuccess:onSuccess onError:onError];
            });
        } else {
            onError(@"Simulator image could not be captured from preview layer");
        }
    });
}

- (void)writeCapturedImageData:(NSData *)imageData onSuccess:(CaptureBlock)onSuccess onError:(void (^)(NSString*))onError {
    NSMutableDictionary *imageInfoDict = [[NSMutableDictionary alloc] init];

    NSNumber *length = [NSNumber numberWithInteger:imageData.length];
    if (length) {
        imageInfoDict[@"size"] = length;
    }

    if (self.saveToCameraRoll) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status != PHAuthorizationStatusAuthorized) {
                onError(@"Photo library permission is not authorized.");
                return;
            }
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                // To preserve the metadata, we create an asset from the JPEG NSData representation.
                // Note that creating an asset from a UIImage discards the metadata.
                // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Could not save to camera roll");
                    onError(@"Photo library asset creation failed");
                    return;
                }

                // Get local identifier
                PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:self.fetchOptions];
                PHAsset *firstAsset = [fetchResult firstObject];
                NSString *localIdentifier = firstAsset.localIdentifier;

                if (localIdentifier) {
                    imageInfoDict[@"id"] = localIdentifier;
                }

                // 'ph://' is a rnc/cameraroll URL scheme for loading PHAssets by localIdentifier
                // which are loaded via RNCAssetsLibraryRequestHandler module that conforms to RCTURLRequestHandler
                if (self.saveToCameraRollWithPhUrl) {
                    imageInfoDict[@"uri"] = [NSString stringWithFormat:@"ph://%@", localIdentifier];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        onSuccess(imageInfoDict);
                    });
                } else {
                    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
                    [options setNetworkAccessAllowed:YES];
                    [firstAsset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                        imageInfoDict[@"uri"] = contentEditingInput.fullSizeImageURL.absoluteString;

                        dispatch_async(dispatch_get_main_queue(), ^{
                            onSuccess(imageInfoDict);
                        });
                    }];
                }


            }];
        }];
    } else {
        NSURL *temporaryFileURL = [CKCamera saveToTmpFolder:imageData];
        if (temporaryFileURL) {
            imageInfoDict[@"uri"] = temporaryFileURL.description;
            imageInfoDict[@"name"] = temporaryFileURL.lastPathComponent;
        }

        onSuccess(imageInfoDict);
    }

}

-(void)changeCamera:(CallbackBlock)block
{
#if TARGET_IPHONE_SIMULATOR
    dispatch_async( dispatch_get_main_queue(), ^{
        [self.mockPreview randomize];
    });
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

        [self removeObservers];
        [self.session beginConfiguration];

        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        [self.session removeInput:self.videoDeviceInput];

        if ( [self.session canAddInput:videoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];

            [CKCamera setFlashMode:self.flashMode forDevice:videoDevice];

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
        [self addObservers];

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

    if (error) {
        NSLog(@"Error occured while writing image data to a temporary file: %@", error);
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
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewLayer captureDevicePointOfInterestForPoint:touchPoint];

    // Engage manual focus
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];

    // Disengage manual focus once focusing finishing (if focusTimeout > 0)
    // See [self observeValueForKeyPath]
    self.startFocusResetTimerAfterFocusing = YES;

    self.tapToFocusEngaged = YES;

    // Animate focus rectangle
    CGFloat halfDiagonal = 73;
    CGFloat halfDiagonalAnimation = halfDiagonal*2;

    CGRect focusViewFrame = CGRectMake(touchPoint.x - (halfDiagonal/2),
                                       touchPoint.y - (halfDiagonal/2),
                                       halfDiagonal,
                                       halfDiagonal);

    self.focusView.alpha = 0;
    self.focusView.hidden = NO;
    self.focusView.frame = CGRectMake(touchPoint.x - (halfDiagonalAnimation/2),
                                      touchPoint.y - (halfDiagonalAnimation/2),
                                      halfDiagonalAnimation,
                                      halfDiagonalAnimation);

    [UIView animateWithDuration:0.2 animations:^{
        self.focusView.frame = focusViewFrame;
        self.focusView.alpha = 1;
    } completion:^(BOOL finished) {
        self.focusView.alpha = 1;
        self.focusView.frame = focusViewFrame;
    }];
}

- (void)resetFocus
{
    if (self.focusResetTimer) {
        [self.focusResetTimer invalidate];
        self.focusResetTimer = nil;
    }

    // Resetting focus to continuous focus, so not interested in resetting anymore
    self.startFocusResetTimerAfterFocusing = NO;

    // Avoid showing reset-focus animation after each photo capture
    if (!self.tapToFocusEngaged) {
        return;
    }

    self.tapToFocusEngaged = NO;

    // 1. Reset actual camera focus
    CGPoint deviceCenter = CGPointMake(0.5, 0.5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:deviceCenter monitorSubjectAreaChange:NO];

    // 2. Create animation to indicate the new focus location
    CGPoint layerCenter = [(AVCaptureVideoPreviewLayer *)self.previewLayer pointForCaptureDevicePointOfInterest:deviceCenter];

    CGFloat halfDiagonal = 123;
    CGFloat halfDiagonalAnimation = halfDiagonal*2;

    CGRect focusViewFrame = CGRectMake(layerCenter.x - (halfDiagonal/2), layerCenter.y - (halfDiagonal/2), halfDiagonal, halfDiagonal);
    CGRect focusViewFrameForAnimation = CGRectMake(layerCenter.x - (halfDiagonalAnimation/2), layerCenter.y - (halfDiagonalAnimation/2), halfDiagonalAnimation, halfDiagonalAnimation);

    self.focusView.alpha = 0;
    self.focusView.hidden = NO;
    self.focusView.frame = focusViewFrameForAnimation;

    [UIView animateWithDuration:0.2 animations:^{
        self.focusView.frame = focusViewFrame;
        self.focusView.alpha = 1;
    } completion:^(BOOL finished) {
        self.focusView.alpha = 1;
        self.focusView.frame = focusViewFrame;

        if (self.focusViewTimer) {
            [self.focusViewTimer invalidate];
        }
        self.focusViewTimer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer *timer) {
            [UIView animateWithDuration:0.2 animations:^{
                self.focusView.alpha = 0;
            } completion:^(BOOL finished) {
                self.focusView.frame = CGRectZero;
                self.focusView.hidden = YES;
            }];
        }];
    }];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if (![device lockForConfiguration:&error]) {
            NSLog(@"Unable to device.lockForConfiguration() %@", error);
            return;
        }

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

        device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange && self.resetFocusWhenMotionDetected;
        [device unlockForConfiguration];
    });
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


+ (CGRect)cropRectForSize:(CGRect)frame overlayObject:(CKOverlayObject*)overlayObject {

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

+ (CGSize)cropImageToPreviewSize:(UIImage*)image size:(CGSize)previewSize {

    float imageToPreviewWidthScale = image.size.width/previewSize.width;
    float imageToPreviewHeightScale = image.size.width/previewSize.width;

    return CGSizeMake(previewSize.width*imageToPreviewWidthScale, previewSize.height*imageToPreviewHeightScale);
}

#pragma mark - Frame for Scanner Settings

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.sessionRunning && self.dataReadingFrame) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startAnimatingScanner:self.dataReadingFrame];
        });
    }
}

- (void)setScannerOptions:(NSDictionary *)scannerOptions {
    if (scannerOptions[offsetForScannerFrame]) {
        self.frameOffset = [scannerOptions[offsetForScannerFrame] floatValue];
    }
    if (scannerOptions[heightForScannerFrame]) {
        self.heightFrame = [scannerOptions[heightForScannerFrame] floatValue];
    }
    if (scannerOptions[colorForFrame]) {
        UIColor *acolor = [RCTConvert UIColor:scannerOptions[colorForFrame]];
        self.frameColor = (acolor) ? acolor : [UIColor whiteColor];
    }
}

- (void)addFrameForScanner {
    CGFloat frameWidth = self.bounds.size.width - 2 * self.frameOffset;
    if (!self.dataReadingFrame) {
        self.dataReadingFrame = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameWidth, self.heightFrame)]; //
        self.dataReadingFrame.center = self.center;
        self.dataReadingFrame.backgroundColor = [UIColor clearColor];
        [self createCustomFramesForView:self.dataReadingFrame];
        [self addSubview:self.dataReadingFrame];


        [self startAnimatingScanner:self.dataReadingFrame];

        [self addVisualEffects:self.dataReadingFrame.frame];

        CGRect visibleRect = [self.previewLayer metadataOutputRectOfInterestForRect:self.dataReadingFrame.frame];
        self.metadataOutput.rectOfInterest = visibleRect;
    }
}

- (void)createCustomFramesForView:(UIView *)frameView {
    CGFloat cornerSize = 20.f;
    CGFloat cornerWidth = 2.f;
    for (int i = 0; i < 8; i++) {
        CGFloat x = 0.0;
        CGFloat y = 0.0;
        CGFloat width = 0.0;
        CGFloat height = 0.0;
        switch (i) {
            case 0:
                x = 0; y = 0; width = cornerWidth; height = cornerSize;
                break;
            case 1:
                x = 0; y = 0; width = cornerSize; height = cornerWidth;
                break;
            case 2:
                x = CGRectGetWidth(frameView.bounds) - cornerSize; y = 0; width = cornerSize; height = cornerWidth;
                break;
            case 3:
                x = CGRectGetWidth(frameView.bounds) - cornerWidth; y = 0; width = cornerWidth; height = cornerSize;
                break;
            case 4:
                x = CGRectGetWidth(frameView.bounds) - cornerWidth;
                y = CGRectGetHeight(frameView.bounds) - cornerSize; width = cornerWidth; height = cornerSize;
                break;
            case 5:
                x = CGRectGetWidth(frameView.bounds) - cornerSize;
                y = CGRectGetHeight(frameView.bounds) - cornerWidth; width = cornerSize; height = cornerWidth;
                break;
            case 6:
                x = 0; y = CGRectGetHeight(frameView.bounds) - cornerWidth; width = cornerSize; height = cornerWidth;
                break;
            case 7:
                x = 0; y = CGRectGetHeight(frameView.bounds) - cornerSize; width = cornerWidth; height = cornerSize;
                break;
        }
        UIView * cornerView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        cornerView.backgroundColor = self.frameColor;
        [frameView addSubview:cornerView];

    }
}

- (void)addVisualEffects:(CGRect)inputRect {
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, inputRect.origin.y)];
    topView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.4];
    [self addSubview:topView];

    UIView *leftSideView = [[UIView alloc] initWithFrame:CGRectMake(0, inputRect.origin.y, self.frameOffset, self.heightFrame)]; //paddingForScanner scannerHeight
    leftSideView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.4];
    [self addSubview:leftSideView];

    UIView *rightSideView = [[UIView alloc] initWithFrame:CGRectMake(inputRect.size.width + self.frameOffset, inputRect.origin.y, self.frameOffset, self.heightFrame)];
    rightSideView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.4];
    [self addSubview:rightSideView];

    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, inputRect.origin.y + self.heightFrame, self.frame.size.width,
                                                                  self.frame.size.height - inputRect.origin.y - self.heightFrame)];
    bottomView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.4];
    [self addSubview:bottomView];

}

- (void)startAnimatingScanner:(UIView *)inputView {
    if (!self.greenScanner) {
        self.greenScanner = [[UIView alloc] initWithFrame:CGRectMake(2, 0, inputView.frame.size.width - 4, 2)];
        self.greenScanner.backgroundColor = [UIColor whiteColor];
    }
    if (self.greenScanner.frame.origin.y != 0) {
        [self.greenScanner setFrame:CGRectMake(2, 0, inputView.frame.size.width - 4, 2)];
    }
    [inputView addSubview:self.greenScanner];
    [UIView animateWithDuration:3 delay:0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) animations:^{
        CGFloat middleX = inputView.frame.size.width / 2;
        self.greenScanner.center = CGPointMake(middleX, inputView.frame.size.height - 1);
    } completion:^(BOOL finished) {}];
}

- (void)stopAnimatingScanner {
    [self.greenScanner removeFromSuperview];
}

//Observer actions

- (void)didEnterBackground:(NSNotification *)notification {
    [self stopAnimatingScanner];
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self startAnimatingScanner:self.dataReadingFrame];
}

#pragma mark - observers


- (void)addObservers
{

    if (!self.isAddedOberver) {
        [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
        [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];

        [self.videoDeviceInput.device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
        // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
        // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
        // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
        // interruption reasons.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
        //Observers for re-usage animation when app go to the background and back
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        self.isAddedOberver = YES;
    }
}

//UIApplicationDidEnterBackgroundNotification       NS_AVAILABLE_IOS(4_0);
//UIKIT_EXTERN NSNotificationName const UIApplicationWillEnterForegroundNotification

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
        [self.videoDeviceInput.device removeObserver:self forKeyPath:@"adjustingFocus"];
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
    [self resetFocus];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CapturingStillImageContext)
    {
        // Flash/dim preview to indicate shutter action
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        if ( isCapturingStillImage )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.alpha = 0.0;
                [UIView animateWithDuration:0.35 animations:^{
                    self.alpha = 1.0;
                }];
            });
        }
    }
    else if ([keyPath isEqualToString:@"adjustingFocus"])
    {
        // Note: oldKey is not available (value is always NO it seems) so we only check on newKey
        BOOL isFocusing = [change[NSKeyValueChangeNewKey] boolValue];
        if (self.startFocusResetTimerAfterFocusing == YES && !isFocusing && self.resetFocusTimeout > 0)
        {
            self.startFocusResetTimerAfterFocusing = NO;

            // Disengage manual focus after focusTimeout milliseconds
            NSTimeInterval focusTimeoutSeconds = self.resetFocusTimeout / 1000;
            self.focusResetTimer = [NSTimer scheduledTimerWithTimeInterval:focusTimeoutSeconds repeats:NO block:^(NSTimer *timer) {
                [self resetFocus];
            }];
        }
    }
    else if (context == SessionRunningContext)
    {
//        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
//
//        dispatch_async( dispatch_get_main_queue(), ^{
//            // Only enable the ability to change camera if the device has more than one camera.
//            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
//            self.recordButton.enabled = isSessionRunning;
//            self.stillButton.enabled = isSessionRunning;
//        } );
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {

    for(AVMetadataObject *metadataObject in metadataObjects)
    {
        if ([metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]] && [self isSupportedBarCodeType:metadataObject.type]) {

            AVMetadataMachineReadableCodeObject *code = (AVMetadataMachineReadableCodeObject*)[self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            if (self.onReadCode && code.stringValue && ![code.stringValue isEqualToString:self.codeStringValue]) {
                self.onReadCode(@{@"codeStringValue": code.stringValue});
                [self stopAnimatingScanner];
            }
        }
    }
}

- (BOOL)isSupportedBarCodeType:(NSString *)currentType {
    BOOL result = NO;
    NSArray *supportedBarcodeTypes = @[AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,
                                       AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code,
                                       AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode,
                                       AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeDataMatrixCode];
    for (NSString* object in supportedBarcodeTypes) {
        if ([currentType isEqualToString:object]) {
            result = YES;
        }
    }
    return result;
}

#pragma mark - String Constants For Scanner

const NSString *offsetForScannerFrame     = @"offsetFrame";
const NSString *heightForScannerFrame     = @"frameHeight";
const NSString *colorForFrame             = @"colorForFrame";
const NSString *isNeedMultipleScanBarcode = @"isNeedMultipleScanBarcode";


@end

