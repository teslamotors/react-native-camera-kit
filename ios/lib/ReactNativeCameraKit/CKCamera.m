//
//  CKCamera.m
//  ReactNativeCameraKit
//
//  Created by Ran Greenberg on 31/05/2016.
//  Copyright © 2016 Wix. All rights reserved.
//

@import Foundation;
@import Photos;
#import "CKCamera.h"
#import "UIView+React.h"
#import "RCTConvert.h"


static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM( NSInteger, CKSetupResult ) {
    CKSetupResultSuccess,
    CKSetupResultCameraNotAuthorized,
    CKSetupResultSessionConfigurationFailed
};

@interface CKCamera () <AVCaptureFileOutputRecordingDelegate>


@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, readwrite) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) CKSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;


@end

@implementation CKCamera

#pragma mark - initializtion

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self){
        // Create the AVCaptureSession.
        self.session = [[AVCaptureSession alloc] init];
        
        // Communicate with the session and other session objects on this queue.
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
        
        [self handleCameraPermission];
        [self setupCaptionSession];
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.layer addSublayer:self.previewLayer];
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
    }
    
    return self;
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
        
        if ( ! videoDeviceInput ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            [CKCamera setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        }
        else {
            NSLog( @"Could not add video device input to the session" );
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
            NSLog( @"Could not add movie file output to the session" );
            self.setupResult = CKSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ( [self.session canAddOutput:stillImageOutput] ) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else {
            NSLog( @"Could not add still image output to the session" );
            self.setupResult = CKSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );
}

-(void)handleCameraPermission {
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
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
    
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case CKSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                //                [self addObservers];
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
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}


#pragma mark - actions



- (void)snapStillImage:(BOOL)shouldSaveToCameraRoll success:(CaptureBlock)block {
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = self.previewLayer.connection.videoOrientation;
        
        // Flash set to Auto for Still Capture.
//        [CKCamera setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if ( status == PHAuthorizationStatusAuthorized ) {

                        
                        NSURL *temporaryFileURL = [self saveToTmpFolder:imageData];
                        
                        if (shouldSaveToCameraRoll) {
                            
                            [self saveImageToCameraRoll:imageData temporaryFileURL:temporaryFileURL];
                        }
                        
                        if (block) {
                            block(temporaryFileURL.description);
                        }
                    }
                }];
            }
            else {
                NSLog( @"Could not capture still image: %@", error );
            }
        }];
    } );
}


-(void)changeCamera:(CallbackBlock)block
{
    
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
            
            [CKCamera setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
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



-(void)saveImageToCameraRoll:(NSData*)imageData temporaryFileURL:(NSURL*)temporaryFileURL{
    // To preserve the metadata, we create an asset from the JPEG NSData representation.
    // Note that creating an asset from a UIImage discards the metadata.
    // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
    // In iOS 8, we save the image to a temporary file and use +[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:].
    if ( [PHAssetCreationRequest class] ) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
        } completionHandler:^( BOOL success, NSError *error ) {
            if ( ! success ) {
                NSLog( @"Error occurred while saving image to photo library: %@", error );
            }
        }];
    }
    else {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            NSError *error = nil;
            if ( error ) {
                NSLog( @"Error occured while writing image data to a temporary file: %@", error );
            }
            else {
                [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
            }
        } completionHandler:^( BOOL success, NSError *error ) {
            if ( ! success ) {
                NSLog( @"Error occurred while saving image to photo library: %@", error );
            }
        }];
    }
}


-(NSURL*)saveToTmpFolder:(NSData*)data {
    NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
    NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
    
    NSError *error = nil;
    [data writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
    
    if ( error ) {
        NSLog( @"Error occured while writing image data to a temporary file: %@", error );
    }
    else {
        NSLog(@"YOU ROCK!");
    }
    
    return temporaryFileURL;
    
}


#pragma mark - observers


- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewLayer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewLayer.opacity = 1.0;
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


@end
