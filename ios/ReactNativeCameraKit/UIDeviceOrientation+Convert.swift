//
//  UIDeviceOrientation+Convert.swift
//  ReactNativeCameraKit
//

import UIKit
import AVFoundation

// Device orientation counter-rotate interface when in landscapeLeft/Right so it appears level
// (note how landscapeLeft sets landscapeRight)
extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        get {
            switch self {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .faceUp, .faceDown, .unknown: return nil
            @unknown default: return nil
            }
        }
    }
}
