//
//  PhotoViewControllerDelegate.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

protocol PhotoViewControllerDelegate : NSObjectProtocol {
  func retakePhoto(controller: PhotoViewController)
  func usePhoto(controller: PhotoViewController, photo: UIImage)
}
