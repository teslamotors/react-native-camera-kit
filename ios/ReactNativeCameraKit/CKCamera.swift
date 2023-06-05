//
//  CKCamera.swift
//  ReactNativeCameraKit
//

import AVFoundation
import UIKit

class CKCamera1: UIView, AVCaptureMetadataOutputObjectsDelegate {
    let label = UILabel()

    private var cameraType: CameraType?
    private var flashMode: FlashMode?
    private var torchMode: TorchMode?
    private var focusMode: FocusMode?
    private var zoomMode: ZoomMode?
    private var ratioOverlay: String?
    private var ratioOverlayColor: UIColor?

    // Barcode
    private var onReadCode: RCTDirectEventBlock?
    private var showFrame: Bool?
    private var laserColor: UIColor?
    private var frameColor: UIColor?

    private var onOrientationChange: RCTDirectEventBlock?

    private var resetFocusTimeout: Int?
    private var resetFocusWhenMotionDetected: Bool?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.text = "Hello world"
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        addSubview(label)

        backgroundColor = .red
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func snapStillImage(_ options: [String: Any], success: (_ imageObject: [String: Any]) -> (), onError:(_ error: String) -> ()) {
        success(["uri":"SUCCESS!", "name":"OHOH!"])
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
    }

    // MARK: Objective C setter

    @objc func setCameraType(_ cameraType: CameraType) {
        self.cameraType = cameraType
    }

    @objc func setFlashMode(_ flashMode: FlashMode) {
        onReadCode?(["codeStringValue":"SUCCESS!", "name":"OHOH!"])
        
        self.flashMode = flashMode
    }

    @objc func setTorchMode(_ torchMode: TorchMode) {
        if torchMode == .off {
            backgroundColor = .red
        } else {
            backgroundColor = .green
        }

        self.torchMode = torchMode
    }

    @objc func setFocusMode(_ focusMode: FocusMode) {
        self.focusMode = focusMode
    }

    @objc func setZoomMode(_ zoomMode: ZoomMode) {
        self.zoomMode = zoomMode
    }

    @objc func setRatioOverlayColor(_ ratioOverlayColor: UIColor) {
        self.ratioOverlayColor = ratioOverlayColor
    }

    @objc func setRatioOverlay(_ ratioOverlay: String) {
        self.ratioOverlay = ratioOverlay
    }

    @objc func setOnReadCode(_ onReadCode: @escaping RCTDirectEventBlock) {
        self.onReadCode = onReadCode
    }

    @objc func setShowFrame(_ showFrame: Bool) {
        self.showFrame = showFrame
    }

    @objc func setLaserColor(_ laserColor: UIColor) {
        self.laserColor = laserColor
    }

    @objc func setFrameColor(_ frameColor: UIColor) {
        self.frameColor = frameColor
    }

    @objc func setOnOrientationChange(_ onOrientationChange: @escaping RCTDirectEventBlock) {
        self.onOrientationChange = onOrientationChange
    }

    @objc func setResetFocusTimeout(_ resetFocusTimeout: Int) {
        self.resetFocusTimeout = resetFocusTimeout
    }

    @objc func setResetFocusWhenMotionDetected(_ resetFocusWhenMotionDetected: Bool) {
        self.resetFocusWhenMotionDetected = resetFocusWhenMotionDetected
    }
}
