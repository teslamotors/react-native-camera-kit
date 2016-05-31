//
//  CameraViewControllerDelegate.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

protocol CameraViewControllerDelegate : NSObjectProtocol {
  func imageHasBeenTaken(controller: CameraViewController, imageData: String)
  func cameraViewControllerDidCancel(controller: CameraViewController)
  func onError(controller: CameraViewController, error: String)
}
