//
//  UIInterfaceOrientation+Convert.swift
//  ReactNativeCameraKit
//

import UIKit
import AVFoundation

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation {
        get {
            switch self {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .unknown: return .portrait
            @unknown default: return .portrait
            }
        }
    }
}
