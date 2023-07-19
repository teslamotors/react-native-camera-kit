//
//  SimulatorCamera.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit

/*
 * Fake camera implementation to be used on simulator
 */
class SimulatorCamera: CameraProtocol {
    private var onOrientationChange: RCTDirectEventBlock?
    private var onZoom: RCTDirectEventBlock?
    private var videoDeviceZoomFactor: Double = 1.0
    private var videoDeviceMaxAvailableVideoZoomFactor: Double = 150.0
    private var wideAngleZoomFactor: Double = 2.0
    private var zoom: Double?
    private var maxZoom: Double?

    var previewView: UIView { mockPreview }

    private var fakeFocusFinishedTimer: Timer?

    // Create mock camera layer. When a photo is taken, we capture this layer and save it in place of a hardware input.
    private let mockPreview = SimulatorPreviewView(frame: .zero)

    // MARK: - Public

    func setup(cameraType: CameraType, supportedBarcodeType: [AVMetadataObject.ObjectType]) {
        DispatchQueue.main.async {
            self.mockPreview.cameraTypeLabel.text = "Camera type: \(cameraType)"
        }
        
        // Listen to orientation changes
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: UIDevice.current,
                                               queue: nil,
                                               using: { [weak self] notification in self?.orientationChanged(notification: notification) })


    }
    
    private func orientationChanged(notification: Notification) {
        guard let device = notification.object as? UIDevice,
              let orientation = Orientation(from: device.orientation) else {
            return
        }

        self.onOrientationChange?(["orientation": orientation.rawValue])
    }
    
    func cameraRemovedFromSuperview() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)

    }

    func update(onOrientationChange: RCTDirectEventBlock?) {
        self.onOrientationChange = onOrientationChange
    }
    
    func update(onZoom: RCTDirectEventBlock?) {
        self.onZoom = onZoom
    }
    
    func setVideoDevice(zoomFactor: Double) {
        self.videoDeviceZoomFactor = zoomFactor
        self.mockPreview.zoomLabel.text = "Zoom: \(zoomFactor)"
    }
    
    private var zoomStartedAt: Double = 1.0
    func zoomPinchStart() {
        DispatchQueue.main.async {
            self.zoomStartedAt = self.videoDeviceZoomFactor
            self.mockPreview.zoomLabel.text = "Zoom start"
        }
    }
    
    func zoomPinchChange(pinchScale: CGFloat) {
        guard !pinchScale.isNaN else { return }
        
        DispatchQueue.main.async {
            let desiredZoomFactor = self.zoomStartedAt * pinchScale
            var maxZoomFactor = self.videoDeviceMaxAvailableVideoZoomFactor
            if let maxZoom = self.maxZoom {
                maxZoomFactor = min(maxZoom, maxZoomFactor)
            }
            let zoomForDevice = max(1.0, min(desiredZoomFactor, maxZoomFactor))
            
            if zoomForDevice != self.videoDeviceZoomFactor {
                // Only trigger zoom changes if it's an uncontrolled component (zoom isn't manually set)
                // otherwise it's likely to cause issues inf. loops
                if self.zoom == nil {
                    self.setVideoDevice(zoomFactor: zoomForDevice)
                }
                self.onZoom?(["zoom": zoomForDevice])
            }
        }
    }

    func focus(at: CGPoint, focusBehavior: FocusBehavior) {
        DispatchQueue.main.async {
            self.mockPreview.focusAtLabel.text = "Focus at: (\(Int(at.x)), \(Int(at.y))), focusMode: \(focusBehavior.avFocusMode)"
        }

        // Fake focus finish after a second
        fakeFocusFinishedTimer?.invalidate()
        if case let .customFocus(_, _, focusFinished) = focusBehavior {
            fakeFocusFinishedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                focusFinished()
            }
        }
    }

    func update(torchMode: TorchMode) {
        DispatchQueue.main.async {
            self.mockPreview.torchModeLabel.text = "Torch mode: \(torchMode)"
        }
    }

    func update(flashMode: FlashMode) {
        DispatchQueue.main.async {
            self.mockPreview.flashModeLabel.text = "Flash mode: \(flashMode)"
        }
    }

    func update(cameraType: CameraType) {
        DispatchQueue.main.async {
            self.mockPreview.cameraTypeLabel.text = "Camera type: \(cameraType)"

            self.mockPreview.randomize()
        }
    }
    
    func update(maxZoom: Double?) {
        self.maxZoom = maxZoom
    }
    
    func update(zoom: Double?) {
        self.zoom = zoom
        
        DispatchQueue.main.async {
            var zoomOrDefault = zoom ?? 0
            // -1 will reset to zoom default (which is not 1 on modern cameras)
            if zoomOrDefault == 0 {
                zoomOrDefault = self.wideAngleZoomFactor
            }

            var maxZoomFactor = self.videoDeviceMaxAvailableVideoZoomFactor
            if let maxZoom = self.maxZoom {
                maxZoomFactor = min(maxZoom, maxZoomFactor)
            }
            let zoomForDevice = max(1.0, min(zoomOrDefault, maxZoomFactor))
            self.setVideoDevice(zoomFactor: zoomForDevice)
            
            // If they wanted to reset, tell them what the default zoom turned out to be
            // regardless if it's controlled
            if self.zoom == nil || zoom == 0 {
                self.onZoom?(["zoom": zoomForDevice])
            }
        }
    }
    

    func isBarcodeScannerEnabled(_ isEnabled: Bool,
                                 supportedBarcodeType: [AVMetadataObject.ObjectType],
                                 onBarcodeRead: ((_ barcode: String) -> Void)?) {}
    func update(scannerFrameSize: CGRect?) {}

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data, _ thumbnailData: Data?) -> (),
                        onError: @escaping (_ message: String) -> ()) {
        onWillCapture()

        DispatchQueue.main.async {
            // Generate snapshot from main UI thread
            let previewSnapshot = self.mockPreview.snapshot(withTimestamp: true)

            // Then switch to background thread
            DispatchQueue.global(qos: .default).async {
                if let imageData = previewSnapshot?.jpegData(compressionQuality: 0.85) {
                    onSuccess(imageData, nil)
                } else {
                    onError("Failed to convert snapshot to JPEG data")
                }
            }
        }
    }
}
