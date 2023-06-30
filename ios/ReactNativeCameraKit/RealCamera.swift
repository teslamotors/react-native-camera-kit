//
//  RealCamera.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit

import os.signpost

/*
 * Real camera implementation that uses AVFoundation
 */
class RealCamera: NSObject, CameraProtocol, AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
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

    private var cameraType: CameraType = .back
    private var flashMode: FlashMode = .auto
    private var torchMode: TorchMode = .off
    private var resetFocus: (() -> Void)?
    private var focusFinished: (() -> Void)?
    private var onBarcodeRead: ((_ barcode: String) -> Void)?
    private var scannerFrameSize: CGRect? = nil

    // KVO observation
    private var adjustingFocusObservation: NSKeyValueObservation?

    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureDelegate]()

    // MARK: - Lifecycle

    override init() {
        // No-op
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cameraRemovedFromSuperview() {
        sessionQueue.async {
            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "stopRunning")
            }

            if self.setupResult == .success {
                print("------- stop running \(Thread.current)")
                self.session.stopRunning()
                self.removeObservers()
            }

            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "stopRunning")
            }
        }
    }

    deinit {
        print("------- deinit RealCamera \(Thread.current)")
        removeObservers()
    }

    // MARK: - Public

    func setup(cameraType: CameraType, supportedBarcodeType: [AVMetadataObject.ObjectType]) {
        self.cameraType = cameraType

        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: log, name: "setup")
        }

        print("setup \(Thread.current)")

        DispatchQueue.main.async {
            self.cameraPreview.session = self.session
            self.cameraPreview.previewLayer.videoGravity = .resizeAspectFill
        }

        // Setup the capture session.
        // In general, it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        sessionQueue.async {
            if #available(iOS 12.0, *) {
                os_signpost(.event, log: log, name: "Processing", "setupCaptureSession")
            }

            self.setupResult = self.setupCaptureSession(supportedBarcodeType: supportedBarcodeType)

            self.addObservers()

            if self.setupResult == .success {
                print("---- startRunning")
                if #available(iOS 12.0, *) {
                    os_signpost(.event, log: log, name: "Processing", "startRunning")
                }
                self.session.startRunning()
                if #available(iOS 12.0, *) {
                    os_signpost(.event, log: log, name: "Processing", "finished startRunning")
                }

                // We need to reapply the configuration after starting the camera
                self.update(torchMode: self.torchMode)
            }

            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "setup")
            }
        }
    }

    func update(zoomVelocity: CGFloat) {
        guard !zoomVelocity.isNaN else { return }

        sessionQueue.async {
            let pinchVelocityDividerFactor: CGFloat = 20.0
            self.videoDeviceInput?.device.incrementZoomFactor(atan(zoomVelocity / pinchVelocityDividerFactor))
        }
    }

    func focus(at touchPoint: CGPoint, focusBehavior: FocusBehavior) {
        DispatchQueue.main.async {
            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "focusat")
            }

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

                if #available(iOS 12.0, *) {
                    os_signpost(.end, log: log, name: "focusat")
                }
            }
        }
    }

    func update(torchMode: TorchMode) {
        self.torchMode = torchMode

        sessionQueue.asyncAfter(deadline: .now() + 0.1) {
            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "torchMode")
            }

            if (self.videoDeviceInput?.device.torchMode != torchMode.avTorchMode) {
                print("update torchMode from from \(self.videoDeviceInput?.device.torchMode.rawValue) to \(torchMode.avTorchMode.rawValue)")
                self.videoDeviceInput?.device.setTorchMode(torchMode.avTorchMode)
            }

            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "torchMode")
            }
        }
    }

    func update(flashMode: FlashMode) {
        self.flashMode = flashMode
    }

    func update(cameraType: CameraType) {
        self.cameraType = cameraType

        if #available(iOS 12.0, *) {
            os_signpost(.event, log: log, name: "update cameraType")
        }

        sessionQueue.async {
            if self.videoDeviceInput?.device.position == cameraType.avPosition {
                return
            }

            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "cameraType")
            }

            // Avoid chaining device inputs when camera input is denied by the user, since both front and rear vido input devices will be nil
            guard self.setupResult == .success,
                  let currentViewDeviceInput = self.videoDeviceInput,
                  let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraType.avPosition),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            self.removeObservers()
            self.session.beginConfiguration()

            // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
            self.session.removeInput(currentViewDeviceInput)

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                // If it fails, put back current camera
                self.session.addInput(currentViewDeviceInput)
            }

            self.session.commitConfiguration()
            self.addObservers()

            // We need to reapply the configuration after reloading the camera
            self.update(torchMode: self.torchMode)

            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "cameraType")
            }
        }
    }

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data) -> Void,
                        onError: @escaping (_ message: String) -> Void) {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        DispatchQueue.main.async {
            let videoPreviewLayerOrientation = self.cameraPreview.previewLayer.connection?.videoOrientation

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
                    onCaptureSuccess: { uniqueID, imageData in
                        self.inProgressPhotoCaptureDelegates[uniqueID] = nil
                        onSuccess(imageData)
                    },
                    onCaptureError: { uniqueID, errorMessage in
                        self.inProgressPhotoCaptureDelegates[uniqueID] = nil
                        onError(errorMessage)
                    })

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
            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "isBarcodeScannerEnabled")
            }

            print("--------- isBarcodeScannerEnabled")

            let newTypes: [AVMetadataObject.ObjectType]
            if isEnabled && onBarcodeRead != nil {
                let availableTypes = self.metadataOutput.availableMetadataObjectTypes
                newTypes = supportedBarcodeType.filter { type in availableTypes.contains(type) }
            } else {
                newTypes = []
            }

            if self.metadataOutput.metadataObjectTypes != newTypes {
                if #available(iOS 12.0, *) {
                    os_signpost(.event, log: log, name: "update metadataObjectTypes")
                }

                self.metadataOutput.metadataObjectTypes = newTypes

                // Setting metadataObjectTypes reloads the camera, we need to reapply the configuration
                self.update(torchMode: self.torchMode)
            }

            if #available(iOS 12.0, *) {
                os_signpost(.end, log: log, name: "isBarcodeScannerEnabled")
            }
        }
    }

    func update(scannerFrameSize: CGRect?) {
        guard self.scannerFrameSize != scannerFrameSize else { return }

        self.scannerFrameSize = scannerFrameSize

        self.sessionQueue.async {
            if #available(iOS 12.0, *) {
                os_signpost(.begin, log: log, name: "scannerFrameSize")
            }

            if !self.session.isRunning {
                print("setting rectOfInterest while session not running wouldn't work")
                if #available(iOS 12.0, *) {
                    os_signpost(.end, log: log, name: "scannerFrameSize")
                }
                return
            }

            DispatchQueue.main.async {
                let visibleRect = scannerFrameSize != nil && scannerFrameSize != .zero ? self.cameraPreview.previewLayer.metadataOutputRectConverted(fromLayerRect: scannerFrameSize!) : nil

                self.sessionQueue.async {
                    if (self.metadataOutput.rectOfInterest == visibleRect) {
                        if #available(iOS 12.0, *) {
                            os_signpost(.end, log: log, name: "scannerFrameSize")
                        }
                        return
                    }

                    print("------ update scannerFrameSize from \(self.metadataOutput.rectOfInterest) to \(visibleRect ?? CGRect(x: 0, y: 0, width: 1, height: 1))")

                    if #available(iOS 12.0, *) {
                        os_signpost(.event, log: log, name: "update scannerFrameSize")
                    }
                    self.metadataOutput.rectOfInterest = visibleRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
                    // We need to reapply the configuration after touching the metadataOutput
                    self.update(torchMode: self.torchMode)

                    if #available(iOS 12.0, *) {
                        os_signpost(.end, log: log, name: "scannerFrameSize")
                    }
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

        print("----------- \(codeStringValue)")

        onBarcodeRead?(codeStringValue)
    }

    // MARK: - Private

    private func setupCaptureSession(supportedBarcodeType: [AVMetadataObject.ObjectType]) -> SetupResult {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraType.avPosition),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return .sessionConfigurationFailed
        }

        session.beginConfiguration()

        session.sessionPreset = .photo

        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
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

        self.refreshPreviewVideoOrientation()

        return .success
    }

    private func refreshPreviewVideoOrientation() {
        DispatchQueue.main.async {
            guard let orientation = Orientation(from: UIApplication.shared.statusBarOrientation)?.avVideoOrientation else { return }

            self.cameraPreview.previewLayer.connection?.videoOrientation = orientation
        }
    }

    // MARK: Private observers

    private func addObservers() {
        guard adjustingFocusObservation == nil else { return }

        NotificationCenter.default.addObserver(forName: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil,
                                               queue: nil,
                                               using: { [weak self] _ in self?.refreshPreviewVideoOrientation() })

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
