//
//  CKCameraManager.swift
//  ReactNativeCameraKit
//

import AVFoundation
import Foundation

@objc(CKCameraManager) public class CKCameraManager: RCTViewManager {
    var camera: CKCamera!

    override public static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override public func view() -> UIView! {
        camera = CKCamera()

        return camera
    }

    @objc func capture(_ options: NSDictionary,
                       resolve: @escaping RCTPromiseResolveBlock,
                       reject: @escaping RCTPromiseRejectBlock) {
        camera.snapStillImage(options as! [String: Any],
                              success: { resolve($0) },
                              onError: { reject("capture_error", $0, nil) })
    }

    @objc func setTorchMode(_ modeString: String) {
        let mode = TorchMode(from: modeString)
        camera.setTorchMode(mode.avTorchMode)
    }

    @objc func checkDeviceCameraAuthorizationStatus(_ resolve: @escaping RCTPromiseResolveBlock,
                                                    reject: @escaping RCTPromiseRejectBlock) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: resolve(true)
        case .notDetermined: resolve(-1)
        default: resolve(false)
        }
    }

    @objc func requestDeviceCameraAuthorization(_ resolve: @escaping RCTPromiseResolveBlock,
                                                reject: @escaping RCTPromiseRejectBlock) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { resolve($0) })
    }
}
