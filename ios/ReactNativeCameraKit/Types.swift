//
//  Types.swift
//  ReactNativeCameraKit
//

import AVFoundation
import Foundation

// Dummy class used for RCTConvert
@objc(CKType) class Types: NSObject {}

@objc(CKCameraType)
public enum CameraType: Int, CustomStringConvertible {
    case back
    case front

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        }
    }

    public var description: String {
        switch self {
        case .back: return "back"
        case .front: return "front"
        }
    }
}

@objc(CKFlashMode)
public enum FlashMode: Int, CustomStringConvertible {
    case on
    case off
    case auto

    var avFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }

    public var description: String {
        switch self {
        case .on: return "on"
        case .off: return "off"
        case .auto: return "auto"
        }
    }
}

@objc(CKTorchMode)
public enum TorchMode: Int, CustomStringConvertible {
    case on
    case off

    init(from string: String) {
        switch string {
        case "on": self = .on
        default: self = .off
        }
    }

    var avTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .on: return .on
        case .off: return .off
        }
    }

    public var description: String {
        switch self {
        case .on: return "on"
        case .off: return "off"
        }
    }
}

@objc(CKFocusMode)
public enum FocusMode: Int, CustomStringConvertible {
    case on
    case off

    public var description: String {
        switch self {
        case .on: return "on"
        case .off: return "off"
        }
    }
}

@objc(CKZoomMode)
public enum ZoomMode: Int, CustomStringConvertible {
    case on
    case off

    public var description: String {
        switch self {
        case .on: return "on"
        case .off: return "off"
        }
    }
}

@objc(CKSetupResult)
enum SetupResult: Int {
    case notStarted
    case success
    case cameraNotAuthorized
    case sessionConfigurationFailed
}

enum Orientation: Int {
    case portrait = 0 // ⬆️
    case landscapeLeft = 1 // ⬅️
    case portraitUpsideDown = 2 // ⬇️
    case landscapeRight = 3 // ➡️

    init?(from orientation: UIDeviceOrientation) {
        switch orientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeLeft
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }

    init?(from orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait: self = .portrait
        case .landscapeLeft: self = .landscapeLeft
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }

    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        }
    }
}

extension AVCaptureDevice.FocusMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .autoFocus: return "autofocus"
        case .continuousAutoFocus: return "continuousAutoFocus"
        case .locked: return "locked"
        @unknown default: return "unknown"
        }
    }
}
