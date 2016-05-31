//
//  CameraSessionManager.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

import UIKit
import AVFoundation

enum CameraType {
  case FrontFacingCamera
  case BackFacingCamera
}

class CameraSessionManager: NSObject {
  var captureDevice: AVCaptureDevice!
  var previewLayer: AVCaptureVideoPreviewLayer!
  var captureSession: AVCaptureSession!
  var stillImageOutput: AVCaptureStillImageOutput!
  var flashMode: AVCaptureFlashMode = .Auto
  
  override init() {
    super.init()
    self.captureSession = AVCaptureSession()
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh
  }
  
  convenience init(cameraType: CameraType) {
    self.init()
    
    captureSession.beginConfiguration()
    initiateCaptureSessionForCamera(cameraType)
    addStillImageOutput()
    addVideoPreviewLayer()
    captureSession.commitConfiguration()
  }
  
  internal func addVideoPreviewLayer() {
    self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) as AVCaptureVideoPreviewLayer
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
  }
  
  internal func initiateCaptureSessionForCamera(cameraType: CameraType) {
    let devices = AVCaptureDevice.devices()
    
    for device in devices {
      if (device.hasMediaType(AVMediaTypeVideo)) {
        switch (cameraType) {
        case .FrontFacingCamera:
          if (device.position == AVCaptureDevicePosition.Front) {
            self.captureDevice = device as! AVCaptureDevice
          }
          break
        case .BackFacingCamera:
          if (device.position == AVCaptureDevicePosition.Back) {
            self.captureDevice = device as! AVCaptureDevice
          }
          break
        }
      }
    }
    
    do {
      let possibleCameraInput: AnyObject? = try AVCaptureDeviceInput(device: self.captureDevice)
      if let cameraInput = possibleCameraInput as? AVCaptureDeviceInput {
        if self.captureSession.canAddInput(cameraInput) {
          self.captureSession.addInput(cameraInput)
        }
      }
    } catch let error as NSError {
      print(error)
    }
  }
  
  func assignVideoOrienationForVideoConnection(videoConnection: AVCaptureConnection) {
    var newOrientation: AVCaptureVideoOrientation
    switch (UIDevice.currentDevice().orientation) {
    case .Portrait:
      newOrientation = AVCaptureVideoOrientation.Portrait
      break
    case .PortraitUpsideDown:
      newOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
      break
    case .LandscapeLeft:
      newOrientation = AVCaptureVideoOrientation.LandscapeRight
      break
    case .LandscapeRight:
      newOrientation = AVCaptureVideoOrientation.LandscapeLeft
      break
    default:
      newOrientation = AVCaptureVideoOrientation.Portrait
    }
    
    videoConnection.videoOrientation = newOrientation
  }
  
  func getOrientationAdaptedCaptureConnection() -> AVCaptureConnection?
  {
    var videoConnection: AVCaptureConnection? = nil
    for connection in self.stillImageOutput.connections {
      for port in connection.inputPorts! {
        if (port.mediaType == AVMediaTypeVideo) {
          videoConnection = connection as? AVCaptureConnection
          self.assignVideoOrienationForVideoConnection(videoConnection!)
          break
        }
      }
      if (videoConnection != nil) {
        break
      }
    }
    return videoConnection
  }
  
  internal func addStillImageOutput() {
    self.stillImageOutput = AVCaptureStillImageOutput()
    self.stillImageOutput.outputSettings = NSDictionary(objects: [AVVideoCodecJPEG], forKeys: [AVVideoCodecKey]) as! [NSObject : AnyObject]
    self.getOrientationAdaptedCaptureConnection()
    if self.captureSession.canAddOutput(self.stillImageOutput) {
      self.captureSession.addOutput(self.stillImageOutput)
    }
    
    do {
      if (captureDevice.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus)) {
        try captureDevice.lockForConfiguration()
        if captureDevice.isFlashModeSupported(self.flashMode) {
          captureDevice.flashMode = self.flashMode
        }
        if captureDevice.isFocusModeSupported(.ContinuousAutoFocus) {
          captureDevice.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
        }
        if captureDevice.isWhiteBalanceModeSupported(.ContinuousAutoWhiteBalance) {
          captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance
        }
        captureDevice.unlockForConfiguration()
      }
    } catch let error as NSError {
      print(error)
    }
  }
  
  internal func captureStillImage(completionHandler: ((UIImage) -> Void)!) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let videoConnection = self.getOrientationAdaptedCaptureConnection()
      if (videoConnection != nil) {
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler:
          { (imageSampleBuffer: CMSampleBuffer!, _) -> Void in
            let stillImageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
            let stillImage = UIImage(data: stillImageData)
            
            completionHandler(stillImage!)
        })
      }
    }
  }
  
  func changeFlashMode(mode: AVCaptureFlashMode) {
    do {
      if (captureDevice.hasFlash && captureDevice.isFlashModeSupported(mode) && captureDevice.flashMode != mode) {
        try captureDevice.lockForConfiguration()
        captureDevice.flashMode = mode
        self.flashMode = mode
        captureDevice.unlockForConfiguration()
      }
    } catch let error as NSError {
      print(error)
    }
  }
  
  func stopSession() {
    self.captureSession.stopRunning()
    
    for input in self.captureSession.inputs {
      self.captureSession.removeInput(input as! AVCaptureInput)
    }
    
    for output in self.captureSession.outputs {
      self.captureSession.removeOutput(output as! AVCaptureOutput)
    }
  }
}