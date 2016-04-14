//
//  RCTCameraKitManager.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import ImagePickerSheetController

@objc(ReactNativeCameraKit)

class ReactNativeCameraKit: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CameraViewControllerDelegate {
  var defaultOptions: [String: AnyObject]
  var callback: RCTResponseSenderBlock? = nil
  
  override init() {
    defaultOptions = [String: AnyObject]()
    defaultOptions["takePhotoActionTitle"] = "Take a Photo"
    defaultOptions["pickPhotoActionTitle"] = "Gallery"
    defaultOptions["cancelActionTitle"] = "Cancel"
    defaultOptions["sendSelectedPhotosTitle"] = "Send %lu Photo"
    defaultOptions["aspectRatioInfoMessage"] = "Your images look best with 16:9 ratio"
    defaultOptions["aspectRatios"] = ["16:9", "1:1", "4:3", "3:2", "2:3", "3:4", "9:16"]
    defaultOptions["collectionName"] = "eCom"
    
    super.init()
  }
  
  
  func presentPhotoPicker(options: [String: AnyObject], callback: RCTResponseSenderBlock) -> Void {
    var computedOptions = [String: AnyObject]()
    self.callback = callback
    
    for (key, value) in defaultOptions {
      computedOptions[key] = value
    }
    for (key, value) in options {
      computedOptions[key] = value;
    }
    
    dispatch_async(dispatch_get_main_queue(), {
      let controller = ImagePickerSheetController(mediaType: .Image)
      
      let takePhotoAction = ImagePickerAction(
        title: computedOptions["takePhotoActionTitle"] as! String,
        handler: { _ in
          self.launchCamera(["aspectRatioInfoMessage": computedOptions["aspectRatioInfoMessage"]!, "aspectRatios": computedOptions["aspectRatios"]!, "collectionName": computedOptions["collectionName"]!])
        }
      )
      controller.addAction(takePhotoAction)
      
      let pickPhotoAction = ImagePickerAction(
        title: computedOptions["pickPhotoActionTitle"] as! String,
        secondaryTitle:  { NSString.localizedStringWithFormat(computedOptions["sendSelectedPhotosTitle"] as! String, $0) as String},
        handler: { _ in
          self.presentImagePickerController(.PhotoLibrary)
        },
        secondaryHandler: { _, numberOfPhotos in
          var selectedImages = [String]()
          for imageAsset in controller.selectedImageAssets {
            PHImageManager.defaultManager().requestImageDataForAsset(imageAsset,
              options: PHImageRequestOptions(),
              resultHandler: { (imageData, _, orientation, info) -> Void in
                selectedImages.append(imageData!.base64EncodedStringWithOptions([]))
                if (selectedImages.count == controller.selectedImageAssets.count) {
                  self.executeCallback(["images": selectedImages])
                }
            })
          }
      })
      controller.addAction(pickPhotoAction)
      
      let cancelAction = ImagePickerAction(
        title: computedOptions["cancelActionTitle"] as! String,
        style: .Cancel,
        handler: { _ in
          self.notifyAboutCancel()
        }
      )
      controller.addAction(cancelAction)
      
      self.presentViewControllerAnimated(controller)
    })
  }
  
  private func presentImagePickerController(source: UIImagePickerControllerSourceType) {
    dispatch_async(dispatch_get_main_queue(), {
      let controller = UIImagePickerController()
      controller.delegate = self
      var sourceType = source
      if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
        sourceType = .PhotoLibrary
      }
      controller.sourceType = sourceType
      
      controller.delegate = self
      self.presentViewControllerAnimated(controller)
    })
  }
  
  private func presentViewControllerAnimated(controller: UIViewController) {
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    delegate!.window.rootViewController!.presentViewController(controller, animated: true, completion: nil)
  }
  
  private func hideViewControler() {
    let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
    delegate!.window.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
  }
  
  private func executeCallback(result: [String: AnyObject]) {
    if (callback != nil) {
      callback!([result])
      callback = nil
    }
  }
  
  private func notifyAboutCancel() {
    executeCallback(["didCancel": true])
  }
  
  private func launchCamera(cameraOptions: [String: AnyObject]) {
    dispatch_async(dispatch_get_main_queue(), {
      let cameraViewController = CameraViewController(cameraOptions: cameraOptions)
      cameraViewController.cameraViewControllerDelegate = self
      
      let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
      delegate!.window.rootViewController!.presentViewController(cameraViewController, animated: true, completion: nil)
    })
  }
  
  // UIImagePickerControllerDelegate
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    notifyAboutCancel()
    hideViewControler()
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let mediaType = info[UIImagePickerControllerMediaType] as! NSString
    if !mediaType.isEqualToString(kUTTypeImage as String) {
      fatalError("Video is not supported")
    } else {
      let image = info[UIImagePickerControllerOriginalImage] as! UIImage
      let imageData = UIImageJPEGRepresentation(image, 1.0)!.base64EncodedStringWithOptions([])
      executeCallback(["images": [imageData]])
    }
    hideViewControler()
  }
  
  // CameraViewControllerDelegate
  
  func imageHasBeenTaken(controller: CameraViewController, imageData: String) {
    executeCallback(["images": [imageData]])
    hideViewControler()
  }
  
  func cameraViewControllerDidCancel(controller: CameraViewController) {
    hideViewControler()
  }
  
  func onError(controller: CameraViewController, error: String) {
    executeCallback(["error": [error]])
    hideViewControler()
  }
}
