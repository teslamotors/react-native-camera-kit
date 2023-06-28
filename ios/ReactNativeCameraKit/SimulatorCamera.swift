//
//  SimulatorCamera.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit

import os.signpost

/*
 * Fake camera implementation to be used on simulator
 */
class SimulatorCamera: CameraProtocol {
    var previewView: UIView { mockPreview }

    var onReadCode: RCTDirectEventBlock?

    private var fakeFocusFinishedTimer: Timer?

    // Create mock camera layer. When a photo is taken, we capture this layer and save it in place of a hardware input.
    private let mockPreview = SimulatorPreviewView(frame: .zero)

    // MARK: - Public

    func setup() {}
    func cameraRemovedFromSuperview() {}

    func update(zoomVelocity: CGFloat) {
        DispatchQueue.main.async {
            self.mockPreview.zoomVelocityLabel.text = "Zoom Velocity: \(zoomVelocity)"
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
                                 onReadCode: RCTDirectEventBlock?) {}
    func update(scannerFrameSize: CGRect?) {}

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data) -> (),
                        onError: @escaping (_ message: String) -> ()) {
        onWillCapture()

        DispatchQueue.main.async {
            // Generate snapshot from main UI thread
            let previewSnapshot = self.mockPreview.snapshot(withTimestamp: true)

            // Then switch to background thread
            DispatchQueue.global(qos: .default).async {
                if let imageData = previewSnapshot?.jpegData(compressionQuality: 0.85) {
                    onSuccess(imageData)
                } else {
                    onError("Failed to convert snapshot to JPEG data")
                }
            }
        }
    }
}
