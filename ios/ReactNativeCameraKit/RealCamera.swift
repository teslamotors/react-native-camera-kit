//
//  RealCamera.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit
import CoreMotion

/*
 * Real camera implementation that uses AVFoundation
 */
class RealCamera: NSObject, CameraProtocol, AVCaptureMetadataOutputObjectsDelegate {
    var previewView: UIView { cameraPreview }

    private let cameraPreview = RealPreviewView(frame: .zero)
    private let session = AVCaptureSession()
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")

    // utilities
    private var setupResult: SetupResult = .notStarted
    private var isSessionRunning: Bool = false
    private var backgroundRecordingId: UIBackgroundTaskIdentifier = .invalid

    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let metadataOutput = AVCaptureMetadataOutput()

    private var flashMode: FlashMode = .auto
    private var torchMode: TorchMode = .off
    private var resetFocus: (() -> Void)?
    private var focusFinished: (() -> Void)?
    private var onBarcodeRead: ((_ barcode: String) -> Void)?
    private var scannerFrameSize: CGRect? = nil
    private var onOrientationChange: RCTDirectEventBlock?
    
    private var deviceOrientation = UIInterfaceOrientation.unknown
    private var motionManager: CMMotionManager?

    // KVO observation
    private var adjustingFocusObservation: NSKeyValueObservation?

    // Keep delegate objects in memory to avoid collecting them before photo capturing finishes
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureDelegate]()

    // MARK: - Lifecycle

    override init() {
        super.init()
        
        // In addition to using accelerometer to determine REAL orientation
        // we also listen to UI orientation changes (UIDevice does not report rotation if orientation lock is on, so photos aren't rotated correctly)
        // When UIDevice reports rotation to the left, UI is rotated right to compensate, but that means we need to re-rotate left to make camera appear correctly (see self.uiOrientationChanged)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: UIDevice.current,
                                               queue: nil,
                                               using: { [weak self] notification in self?.uiOrientationChanged(notification: notification) })
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cameraRemovedFromSuperview() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.removeObservers()
            }
        }
        
        motionManager?.stopAccelerometerUpdates()
        
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
        
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Public
    
    func initializeMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.2
        motionManager?.gyroUpdateInterval = 0.2
        motionManager?.startAccelerometerUpdates(to: (OperationQueue.current)!, withHandler: {
            (accelerometerData, error) -> Void in
            if error != nil {
                print("\(error!)")
            }
            guard let acceleration = accelerometerData?.acceleration else {
                print("no acceleration data")
                return
            }
            var orientationNew: UIInterfaceOrientation
            if acceleration.x >= 0.75 {
                orientationNew = .landscapeLeft
            } else if acceleration.x <= -0.75 {
                orientationNew = .landscapeRight
            } else if acceleration.y <= -0.75 {
                orientationNew = .portrait
            } else if acceleration.y >= 0.75 {
                orientationNew = .portraitUpsideDown
            } else {
                // Device is not clearly pointing in either direction
                // (e.g. it's flat on the table, so stick with the same orientation)
                return
            }
            
            if orientationNew == self.deviceOrientation {
                return
            }
            self.deviceOrientation = orientationNew
            self.onOrientationChange?(["orientation": Orientation.init(from: orientationNew)!.rawValue])
        })
    }
    
    func setup(cameraType: CameraType, supportedBarcodeType: [AVMetadataObject.ObjectType]) {
        DispatchQueue.main.async {
            self.cameraPreview.session = self.session
            self.cameraPreview.previewLayer.videoGravity = .resizeAspect
            var interfaceOrientation: UIInterfaceOrientation
            if #available(iOS 13.0, *) {
                interfaceOrientation = self.previewView.window!.windowScene!.interfaceOrientation
            } else {
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            }
            let orientation = self.counterRotatedCaptureVideoOrientationFrom(deviceOrientation: interfaceOrientation)
            self.cameraPreview.previewLayer.connection?.videoOrientation = orientation!
        }
        
        self.initializeMotionManager()

        // Setup the capture session.
        // In general, it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        sessionQueue.async {
            self.setupResult = self.setupCaptureSession(cameraType: cameraType, supportedBarcodeType: supportedBarcodeType)

            self.addObservers()

            if self.setupResult == .success {
                self.session.startRunning()

                // We need to reapply the configuration after starting the camera
                self.update(torchMode: self.torchMode)
            }
        }
    }

    func update(pinchVelocity: CGFloat, pinchScale: CGFloat) {
        guard !pinchScale.isNaN else { return }
        
        sessionQueue.async {
            let pinchVelocityDividerFactor: Float = 10.0
            let incrementZoomFactor = CGFloat(atan2f(Float(pinchVelocity), pinchVelocityDividerFactor))
            self.videoDeviceInput?.device.incrementZoomFactor(incrementZoomFactor)
        }
    }

    func focus(at touchPoint: CGPoint, focusBehavior: FocusBehavior) {
        DispatchQueue.main.async {
            let devicePoint = self.cameraPreview.previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)

            self.sessionQueue.async {
                if case let .customFocus(_, resetFocus, focusFinished) = focusBehavior {
                    self.resetFocus = resetFocus
                    self.focusFinished = focusFinished
                } else {
                    self.resetFocus = nil
                    self.focusFinished = nil
                }

                self.videoDeviceInput?.device.focusWithMode(focusBehavior.avFocusMode,
                                                            exposeWithMode: focusBehavior.exposureMode,
                                                            atDevicePoint: devicePoint,
                                                            isSubjectAreaChangeMonitoringEnabled: focusBehavior.isSubjectAreaChangeMonitoringEnabled)
            }
        }
    }
    
    func update(onOrientationChange: RCTDirectEventBlock?) {
        self.onOrientationChange = onOrientationChange
    }
    
    func update(torchMode: TorchMode) {
        self.torchMode = torchMode

        sessionQueue.asyncAfter(deadline: .now() + 0.1) {
            if (self.videoDeviceInput?.device.torchMode != torchMode.avTorchMode) {
                self.videoDeviceInput?.device.setTorchMode(torchMode.avTorchMode)
            }
        }
    }

    func update(flashMode: FlashMode) {
        self.flashMode = flashMode
    }

    func update(cameraType: CameraType) {
        sessionQueue.async {
            if self.videoDeviceInput?.device.position == cameraType.avPosition {
                return
            }

            // Avoid chaining device inputs when camera input is denied by the user, since both front and rear vido input devices will be nil
            guard self.setupResult == .success,
                  let currentViewDeviceInput = self.videoDeviceInput,
                  let videoDevice = self.getBestDevice(for: cameraType),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            self.removeObservers()
            self.session.beginConfiguration()

            // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
            self.session.removeInput(currentViewDeviceInput)

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                videoDevice.videoZoomFactor = self.wideAngleZoomFactor(for: videoDevice)
                self.videoDeviceInput = videoDeviceInput
            } else {
                // If it fails, put back current camera
                self.session.addInput(currentViewDeviceInput)
            }

            self.session.commitConfiguration()
            self.addObservers()

            // We need to reapply the configuration after reloading the camera
            self.update(torchMode: self.torchMode)
        }
    }

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data, _ thumbnailData: Data?) -> Void,
                        onError: @escaping (_ message: String) -> Void) {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        DispatchQueue.main.async {
            let videoPreviewLayerOrientation = self.counterRotatedCaptureVideoOrientationFrom(deviceOrientation: self.deviceOrientation) ?? self.cameraPreview.previewLayer.connection?.videoOrientation

            self.sessionQueue.async {
                if let photoOutputConnection = self.photoOutput.connection(with: .video), let videoPreviewLayerOrientation {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
                }

                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                settings.isAutoStillImageStabilizationEnabled = true

                if self.videoDeviceInput?.device.isFlashAvailable == true {
                    settings.flashMode = self.flashMode.avFlashMode
                }

                let photoCaptureDelegate = PhotoCaptureDelegate(
                    with: settings,
                    onWillCapture: onWillCapture,
                    onCaptureSuccess: { uniqueID, imageData, thumbnailData in
                        self.inProgressPhotoCaptureDelegates[uniqueID] = nil
                        
                        onSuccess(imageData, thumbnailData)
                    },
                    onCaptureError: { uniqueID, errorMessage in
                        self.inProgressPhotoCaptureDelegates[uniqueID] = nil
                        onError(errorMessage)
                    }
                )

                self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
                self.photoOutput.capturePhoto(with: settings, delegate: photoCaptureDelegate)
            }
        }
    }

    func isBarcodeScannerEnabled(_ isEnabled: Bool,
                                 supportedBarcodeType: [AVMetadataObject.ObjectType],
                                 onBarcodeRead: ((_ barcode: String) -> Void)?) {
        self.onBarcodeRead = onBarcodeRead

        sessionQueue.async {
            let newTypes: [AVMetadataObject.ObjectType]
            if isEnabled && onBarcodeRead != nil {
                let availableTypes = self.metadataOutput.availableMetadataObjectTypes
                newTypes = supportedBarcodeType.filter { type in availableTypes.contains(type) }
            } else {
                newTypes = []
            }

            if self.metadataOutput.metadataObjectTypes != newTypes {
                self.metadataOutput.metadataObjectTypes = newTypes

                // Setting metadataObjectTypes reloads the camera, we need to reapply the configuration
                self.update(torchMode: self.torchMode)
            }
        }
    }

    func update(scannerFrameSize: CGRect?) {
        guard self.scannerFrameSize != scannerFrameSize else { return }

        self.scannerFrameSize = scannerFrameSize

        self.sessionQueue.async {
            if !self.session.isRunning {
                return
            }

            DispatchQueue.main.async {
                let visibleRect = scannerFrameSize != nil && scannerFrameSize != .zero ? self.cameraPreview.previewLayer.metadataOutputRectConverted(fromLayerRect: scannerFrameSize!) : nil

                self.sessionQueue.async {
                    if (self.metadataOutput.rectOfInterest == visibleRect) {
                        return
                    }

                    self.metadataOutput.rectOfInterest = visibleRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
                    // We need to reapply the configuration after touching the metadataOutput
                    self.update(torchMode: self.torchMode)
                }
            }
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Try to retrieve the barcode from the metadata extracted
        guard let machineReadableCodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let codeStringValue = machineReadableCodeObject.stringValue else {
            return
        }

        onBarcodeRead?(codeStringValue)
    }

    // MARK: - Private

    private func counterRotatedCaptureVideoOrientationFrom(deviceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
        switch(deviceOrientation) {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .unknown: break
        @unknown default: break
        }
        return nil
    }

    private func uiOrientationChanged(notification: Notification) {
        guard let device = notification.object as? UIDevice else {
            return
        }
        
        // Counter-rotate video when in landscapeLeft/Right UI so it appears level
        // (note how landscapeLeft sets landscapeRight)
        switch(device.orientation) {
        case .unknown: break
        case .portrait:
            self.cameraPreview.previewLayer.connection?.videoOrientation = .portrait
            print("ui portrait")
        case .portraitUpsideDown:
            self.cameraPreview.previewLayer.connection?.videoOrientation = .portraitUpsideDown
            print("ui upside down")
        case .landscapeLeft:
            self.cameraPreview.previewLayer.connection?.videoOrientation = .landscapeRight
            print("ui landscapeLeft")
        case .landscapeRight:
            self.cameraPreview.previewLayer.connection?.videoOrientation = .landscapeLeft
            print("ui landscapeRight")
        case .faceUp: break
        case .faceDown: break
        @unknown default: break
        }
    }
    
    private func getBestDevice(for cameraType: CameraType) -> AVCaptureDevice? {
        if #available(iOS 13.0, *) {
            if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: cameraType.avPosition) {
                return device
            }
        }
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: cameraType.avPosition) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraType.avPosition) {
            return device
        }
        return nil
    }

    private func setupCaptureSession(cameraType: CameraType,
                                     supportedBarcodeType: [AVMetadataObject.ObjectType]) -> SetupResult {
        guard let videoDevice = self.getBestDevice(for: cameraType),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return .sessionConfigurationFailed
        }

        session.beginConfiguration()

        session.sessionPreset = .photo

        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            videoDevice.videoZoomFactor = wideAngleZoomFactor(for: videoDevice)
            self.videoDeviceInput = videoDeviceInput
        } else {
            return .sessionConfigurationFailed
        }


        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            return .sessionConfigurationFailed
        }

        if self.session.canAddOutput(metadataOutput) {
            self.session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            let availableTypes = self.metadataOutput.availableMetadataObjectTypes
            let filteredTypes = supportedBarcodeType.filter { type in availableTypes.contains(type) }
            metadataOutput.metadataObjectTypes = filteredTypes
        }

        session.commitConfiguration()

        return .success
    }

    private func wideAngleZoomFactor(for videoDevice: AVCaptureDevice) -> CGFloat {
        // Devices that have multiple physical cameras are binded behind one virtual camera input. The zoom factor defines what physical camera it actually uses
        // Find the 'normal' zoom factor, which on the physical camera defaults to the wide angle
        if #available(iOS 13.0, *) {
            if let indexOfWideAngle = videoDevice.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }) {
                // .virtualDeviceSwitchOverVideoZoomFactors has the .constituentDevices zoom factor which borders the NEXT device
                // so we grab the one PRIOR to the wide angle to get the wide angle's zoom factor
                return videoDevice.virtualDeviceSwitchOverVideoZoomFactors[indexOfWideAngle - 1].doubleValue
            }
        }

        return 1.0
    }

    // MARK: Private observers

    private func addObservers() {
        guard adjustingFocusObservation == nil else { return }

        adjustingFocusObservation = videoDeviceInput?.device.observe(\.isAdjustingFocus,
                                                                      options: .new,
                                                                      changeHandler: { [weak self] device, change in
            guard let self, let isFocusing = change.newValue else { return }

            self.isAdjustingFocus(isFocusing: isFocusing)
        })

        NotificationCenter.default.addObserver(forName: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput?.device,
                                               queue: nil,
                                               using: { [weak self] notification in self?.subjectAreaDidChange(notification: notification) })
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError,
                                               object: session,
                                               queue: nil,
                                               using: { [weak self] notification in self?.sessionRuntimeError(notification: notification) })
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted,
                                               object: session,
                                               queue: nil,
                                               using: { [weak self] notification in self?.sessionWasInterrupted(notification: notification) })

    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)

        adjustingFocusObservation?.invalidate()
        adjustingFocusObservation = nil
    }

    private func isAdjustingFocus(isFocusing: Bool) {
        if !isFocusing {
            focusFinished?()
        }
    }

    private func subjectAreaDidChange(notification: Notification) {
        resetFocus?()
    }

    private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }

        print("Capture session runtime error: \(error)")

        // Automatically try to restart the session running if media services were reset and the last start running succeeded.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
        // Otherwise, enable the user to try to resume the session running.
        // FIXME: Missing showResumeButton
    }

    private func sessionWasInterrupted(notification: Notification) {
        // In some scenarios we want to enable the user to resume the session running.
        // For example, if music playback is initiated via control center while using AVCam,
        // then the user can let AVCam resume the session running, which will stop music playback.
        // Note that stopping music playback in control center will not automatically resume the session running.
        // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
        var showResumeButton = false

        if let reasonValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonValue) {
            print("Capture session was interrupted with reason \(reason)")

            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            }
        }

        // FIXME: Missing use of showResumeButton
    }
}
