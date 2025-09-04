//
//  CameraManager.swift
//  ReactNativeCameraKit
//

import AVFoundation
import Foundation
import React

/*
 * Class managing the communication between React Native and the native implementation
 */
@objc(CKCameraManager) public class CameraManager: RCTViewManager {
    override public static func requiresMainQueueSetup() -> Bool {
        return true
    }

    override public func view() -> UIView! {
        return CameraView()
    }

    @objc public static func capture(camera: CameraView,
                       options: NSDictionary,
                       resolve: @escaping RCTPromiseResolveBlock,
                       reject: @escaping RCTPromiseRejectBlock) {
        camera.capture(onSuccess: { resolve($0) },
                    onError: { reject("capture_error", $0, nil) })
    }

    @objc public static func checkDeviceCameraAuthorizationStatus(_ resolve: @escaping RCTPromiseResolveBlock,
                                                    reject: @escaping RCTPromiseRejectBlock) {
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 14.0, *) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: resolve(true)
            case .notDetermined: resolve(-1)
            default: resolve(false)
            }
        } else {
            resolve(false)
        }
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: resolve(true)
            case .notDetermined: resolve(-1)
            default: resolve(false)
        }
        #endif
    }

    @objc public static func requestDeviceCameraAuthorization(_ resolve: @escaping RCTPromiseResolveBlock,
                                                reject: @escaping RCTPromiseRejectBlock) {
        #if targetEnvironment(macCatalyst)
        if #available(macCatalyst 14.0, *) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { resolve($0) })
        } else {
            resolve(false)
        }
        #else
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { resolve($0) })
        #endif
    }
}
