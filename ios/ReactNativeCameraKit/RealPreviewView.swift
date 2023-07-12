//
//  RealPreviewView.swift
//  ReactNativeCameraKit
//

import AVFoundation

class RealPreviewView: UIView {
    // Use AVCaptureVideoPreviewLayer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    // Create an accessor for the right layer type
    var previewLayer: AVCaptureVideoPreviewLayer {
        // We can safely forcecast here, it can't change at runtime
        return layer as! AVCaptureVideoPreviewLayer
    }

    // Connect the layer to a capture session.
    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }
}
