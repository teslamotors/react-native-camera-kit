//
//  CameraEventEmitter.swift
//  ReactNativeCameraKit
//

@objc public protocol CameraEventEmitter {
    @objc func onReadCode(codeStringValue: String, codeFormat: String)
    @objc func onOrientationChange(orientation: Int)
    @objc func onZoom(zoom: Double)

    @objc func onCaptureButtonPressIn()
    @objc func onCaptureButtonPressOut()
}

class OldArchCameraEventEmitter: CameraEventEmitter {
    var onReadCodeProp: RCTDirectEventBlock?
    var onOrientationChangeProp: RCTDirectEventBlock?
    var onZoomProp: RCTDirectEventBlock?
    var onCaptureButtonPressInProp: RCTDirectEventBlock?
    var onCaptureButtonPressOutProp: RCTDirectEventBlock?
    
    init(onReadCodeProp: RCTDirectEventBlock?,
         onOrientationChangeProp: RCTDirectEventBlock?,
         onZoomProp: RCTDirectEventBlock?,
         onCaptureButtonPressInProp: RCTDirectEventBlock?,
         onCaptureButtonPressOutProp: RCTDirectEventBlock?) {
        self.onReadCodeProp = onReadCodeProp
        self.onOrientationChangeProp = onOrientationChangeProp
        self.onZoomProp = onZoomProp
        self.onCaptureButtonPressInProp = onCaptureButtonPressInProp
        self.onCaptureButtonPressOutProp = onCaptureButtonPressOutProp
    }
    
    func onReadCode(codeStringValue: String, codeFormat: String) {
        onReadCodeProp?(["codeStringValue": codeStringValue, "codeFormat": codeFormat])
    }
    
    func onOrientationChange(orientation: Int) {
        onOrientationChangeProp?(["orientation": orientation])
    }
    
    func onZoom(zoom: Double) {
        print("onZoom")
        print(onZoomProp.debugDescription)
        onZoomProp?(["zoom": zoom])
    }
    
    func onCaptureButtonPressIn() {
        onCaptureButtonPressInProp?(nil)
    }
    
    func onCaptureButtonPressOut() {
        onCaptureButtonPressOutProp?(nil)
    }
}
