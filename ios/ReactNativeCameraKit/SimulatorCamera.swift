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
    
    func update(pinchVelocity: CGFloat, pinchScale: CGFloat) {
        DispatchQueue.main.async {
            self.mockPreview.zoomVelocityLabel.text = "Zoom Velocity: \(pinchVelocity)"
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
