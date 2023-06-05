//
//  CKTypes.swift
//  ReactNativeCameraKit
//

import AVFoundation
import Foundation

// Dummy class used for RCTConvert
@objc class CKTypes: NSObject {}

@objc(CKCameraType)
public enum CameraType: Int {
    case back
    case front

    var avPosition: AVCaptureDevice.Position {
        switch self {
        case .back: return .back
        case .front: return .front
        }
    }
}

@objc(CKCameraFlashMode)
public enum FlashMode: Int {
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
}

@objc(CKCameraTorchMode)
public enum TorchMode: Int {
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
}

@objc(CKCameraFocusMode)
public enum FocusMode: Int {
    case on
    case off
}

@objc(CKCameraZoomMode)
public enum ZoomMode: Int {
    case on
    case off
}

// Temporary method to fill gap with ObjC
@objc public class EnumHelper: NSObject {
    @objc public static func cameraTypeToAVPosition(_ cameraType: CameraType) -> AVCaptureDevice.Position {
        return cameraType.avPosition
    }

    @objc public static func flashModeToAVFlashMode(_ flashMode: FlashMode) -> AVCaptureDevice.FlashMode {
        return flashMode.avFlashMode
    }

    @objc public static func torchModeToAVTorchMode(_ torchMode: TorchMode) -> AVCaptureDevice.TorchMode {
        return torchMode.avTorchMode
    }
}
