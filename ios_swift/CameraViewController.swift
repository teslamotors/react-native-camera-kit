//
//  CameraViewController.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

struct AspectRatio {
  let widthRatio: Int
  let heightRatio: Int
  
  init(widthRatio: Int, heightRatio: Int) {
    self.widthRatio = widthRatio
    self.heightRatio = heightRatio
  }
}

class CameraViewController : UIViewController, PhotoViewControllerDelegate {
  var cameraViewControllerDelegate: CameraViewControllerDelegate?
  
  var cameraManager: CameraSessionManager!
  var cameraOptions: [String: AnyObject]!
  let topBarHeight: CGFloat = 50
  var topBarButtonSize: CGSize!
  let bottomBarHeight: CGFloat = 115
  var flashButton: UIButton!
  let flashModes = ["Auto", "On", "Off"]
  var flashModeSelector: UISegmentedControl!
  var ratioField = UITextField()
  let aspectRatios: [String]
  var aspectRatio: AspectRatio!
  var ratioLayer = UIView()
  var infoLabel: UITextField!
  
  let flashColor = UIColor(colorLiteralRed: 0.95, green: 0.76, blue: 0.2, alpha: 1)
  
  let assetCollectionName: String!
  
  init(cameraOptions: [String: AnyObject]) {
    self.cameraOptions = cameraOptions
    self.aspectRatios = cameraOptions["aspectRatios"] as! [String]
    self.assetCollectionName = cameraOptions["collectionName"] as! String;
    super.init(nibName: nil, bundle: nil)
    
    self.aspectRatio = self.extractRatio(aspectRatios[0])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    self.setupCameraManager(.BackFacingCamera)
    
    let sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
    dispatch_async(sessionQueue) { () -> Void in
      self.cameraManager.captureSession.startRunning()
    }
    
    self.buildUi()
  }
  
  private func setupCameraManager(cameraType: CameraType) {
    self.cameraManager = CameraSessionManager(cameraType: cameraType)
    self.cameraManager.previewLayer.frame = CGRect(x: 0, y: topBarHeight, width: self.view.frame.size.width, height: self.view.frame.size.height - (topBarHeight + bottomBarHeight))
    self.view.layer.addSublayer(self.cameraManager.previewLayer)
    self.fitAspectRatio(aspectRatio)
  }
  
  private func buildUi() {
    topBarButtonSize = CGSizeMake(view.bounds.size.height * 0.04, view.bounds.size.height * 0.04)
    
    self.addToolbars()
    self.addShutterButton()
    self.addCloseButton()
    self.addFlashButton()
    self.addFlashModeSelector()
    self.addRatioSelector()
  }
  
  private func addToolbars() {
    let topBarView = UIView()
    topBarView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: topBarHeight)
    topBarView.backgroundColor = UIColor.blackColor()
    self.view.addSubview(topBarView)
    
    let bottomBarView = UIView()
    bottomBarView.frame = CGRect(x: 0, y: self.view.frame.size.height - bottomBarHeight, width: self.view.frame.size.width, height: bottomBarHeight)
    bottomBarView.backgroundColor = UIColor.blackColor()
    self.view.addSubview(bottomBarView)
  }
  
  private func addShutterButton() {
    let shutterButtonSize = CGSizeMake(self.view.bounds.size.width * 0.23, self.view.bounds.size.width * 0.23)
    
    let image = UIImage(named: "ShutterIcon") as UIImage?
    let button = UIButton(type: UIButtonType.Custom) as UIButton
    button.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: shutterButtonSize)
    button.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - shutterButtonSize.height / 2 - 5)
    button.setImage(image, forState: .Normal)
    
    button.addTarget(self, action: "onTakePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    
    self.view.addSubview(button)
  }
  
  private func addCloseButton() {
    let image = UIImage(named: "CloseIcon") as UIImage?
    let closeButton = UIButton(type: UIButtonType.Custom) as UIButton
    closeButton.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: topBarButtonSize)
    closeButton.center = CGPointMake(topBarButtonSize.width / 2, topBarHeight / 2)
    closeButton.setImage(image, forState: .Normal)
    
    closeButton.addTarget(self, action: "onClose:", forControlEvents: UIControlEvents.TouchUpInside)
    
    self.view.addSubview(closeButton)
  }
  
  func addFlashButton() {
    let image = UIImage(named: "FlashAutoIcon") as UIImage?
    flashButton = UIButton(type: UIButtonType.Custom) as UIButton
    flashButton.frame = CGRect(origin: CGPoint(x: self.view.bounds.size.width - topBarButtonSize.width, y: 0), size: topBarButtonSize)
    flashButton.center = CGPointMake(self.view.bounds.size.width - topBarButtonSize.width / 2, topBarHeight / 2)
    flashButton.setImage(image, forState: .Normal)
    
    flashButton.addTarget(self, action: "onFlashChange:", forControlEvents: UIControlEvents.TouchUpInside)
    
    self.view.addSubview(flashButton)
  }
  
  func addFlashModeSelector() {
    let controlWidth = 0.6 * self.view.bounds.size.width
    flashModeSelector = UISegmentedControl(items: flashModes)
    flashModeSelector.selectedSegmentIndex = 0
    flashModeSelector.frame = CGRectMake((self.view.bounds.size.width - controlWidth) / 2, 0, controlWidth, topBarHeight)
    flashModeSelector.backgroundColor = UIColor.clearColor()
    flashModeSelector.tintColor = UIColor.clearColor()
    
    flashModeSelector.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState.Normal)
    flashModeSelector.setTitleTextAttributes([NSForegroundColorAttributeName: flashColor], forState: UIControlState.Selected)
    
    flashModeSelector.addTarget(self, action: "changeFlashMode:", forControlEvents: .ValueChanged)
  }
  
  func addRatioSelector() {
    let ratioPicker = UIPickerView()
    ratioPicker.showsSelectionIndicator = true
    ratioPicker.delegate = self
    ratioPicker.dataSource = self
    
    let toolBar = UIToolbar()
    toolBar.barStyle = UIBarStyle.Default
    toolBar.tintColor = UIColor.blackColor()
    toolBar.translucent = true
    toolBar.sizeToFit()
    let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "onRatioSelected:")
    toolBar.setItems([doneButton], animated: false)
    toolBar.userInteractionEnabled = true
    
    let fieldHeight: CGFloat = 40
    
    ratioField.tintColor = UIColor.clearColor()
    ratioField.inputView = ratioPicker
    ratioField.inputAccessoryView = toolBar
    ratioField.text = aspectRatios[0]
    ratioField.frame = CGRectMake(self.view.frame.size.width * 0.85, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width * 0.15, fieldHeight)
    ratioField.textAlignment = NSTextAlignment.Right
    ratioField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
    ratioField.textColor = flashColor
    self.view.addSubview(ratioField)
    self.view.addSubview(ratioLayer)
    
    infoLabel = UITextField()
    infoLabel.text = cameraOptions["aspectRatioInfoMessage"] as! String
    infoLabel.adjustsFontSizeToFitWidth = true
    infoLabel.textColor = UIColor.whiteColor()
    infoLabel.textAlignment = NSTextAlignment.Left
    infoLabel.frame = CGRectMake(0, self.view.frame.size.height - bottomBarHeight, self.view.frame.size.width * 0.75, fieldHeight)
    infoLabel.inputView = ratioPicker
    infoLabel.inputAccessoryView = toolBar
    self.view.addSubview(infoLabel)
  }
  
  private func fitAspectRatio(aspectRatio: AspectRatio) {
    let previewLayerExcess = CropHelper.cropRectangleToFitRatio(self.cameraManager.previewLayer.frame.width, originalRectangleHeight: self.cameraManager.previewLayer.frame.height, widthRatio: aspectRatio.widthRatio, heightRatio: aspectRatio.heightRatio)
    
    let backgroundColor = UIColor(white: 0, alpha: 0.5)
    
    self.ratioLayer.removeFromSuperview()
    self.ratioLayer = UIView(frame: CGRect(origin: self.cameraManager.previewLayer.frame.origin, size: self.cameraManager.previewLayer.frame.size))
    self.view.addSubview(self.ratioLayer)
    
    if (previewLayerExcess.verticalExcess != 0.0) {
      let topExcess = UIView()
      topExcess.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.cameraManager.previewLayer.frame.width, height: previewLayerExcess.verticalExcess / 2))
      topExcess.backgroundColor = backgroundColor
      self.ratioLayer.addSubview(topExcess)
      
      let bottomExcess = UIView()
      bottomExcess.frame = CGRect(x: self.cameraManager.previewLayer.frame.origin.x, y: self.cameraManager.previewLayer.frame.height - previewLayerExcess.verticalExcess / 2, width: self.cameraManager.previewLayer.frame.width, height: previewLayerExcess.verticalExcess / 2)
      bottomExcess.backgroundColor = backgroundColor
      self.ratioLayer.addSubview(bottomExcess)
    } else {
      let leftExcess = UIView()
      leftExcess.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: previewLayerExcess.horizontalExcess / 2, height: self.cameraManager.previewLayer.frame.height))
      leftExcess.backgroundColor = backgroundColor
      self.ratioLayer.addSubview(leftExcess)
      
      let rightExcess = UIView()
      rightExcess.frame = CGRect(x: self.cameraManager.previewLayer.frame.origin.x + self.cameraManager.previewLayer.frame.width - previewLayerExcess.horizontalExcess / 2, y: 0, width: previewLayerExcess.horizontalExcess / 2, height: self.cameraManager.previewLayer.frame.height)
      rightExcess.backgroundColor = backgroundColor
      self.ratioLayer.addSubview(rightExcess)
    }
  }
  
  func onFlashChange(sender: UIButton) {
    sender.selected = !sender.selected
    if sender.selected {
      flashButton.setImage(UIImage(named: "FlashAutoIcon") as UIImage?, forState: .Normal)
      self.view.addSubview(flashModeSelector)
    } else {
      flashModeSelector.removeFromSuperview()
      setFlashIcon()
    }
  }
  
  func onRatioSelected(sender: UIButton) {
    self.ratioField.resignFirstResponder()
    self.infoLabel.resignFirstResponder()
  }
  
  func changeFlashMode(_: UISegmentedControl) {
    setFlashIcon()
    flashButton.selected = false
    flashModeSelector.removeFromSuperview()
  }
  
  private func setFlashIcon() {
    switch flashModeSelector.selectedSegmentIndex {
    case 1:
      cameraManager.changeFlashMode(.On)
      flashButton.setImage(UIImage(named: "FlashOnIcon") as UIImage?, forState: .Normal)
      break
    case 2:
      cameraManager.changeFlashMode(.Off)
      flashButton.setImage(UIImage(named: "FlashOffIcon") as UIImage?, forState: .Normal)
      break
    default:
      cameraManager.changeFlashMode(.Auto)
      flashButton.setImage(UIImage(named: "FlashAutoIcon") as UIImage?, forState: .Normal)
      break
    }
  }
  
  func onTakePhoto(sender: UIButton) {
    self.cameraManager.captureStillImage({ (image: UIImage) -> Void in
      let croppedImage = self.cropImage(image)
      self.showPhotoViewController(croppedImage)
    })
  }
  
  func onClose(sender: UIButton) {
    self.cameraManager.stopSession()
    //dismissViewControllerAnimated(true, completion: nil)
    if let delegate = self.cameraViewControllerDelegate {
      delegate.cameraViewControllerDidCancel(self)
    }
  }
  
  func showPhotoViewController(image: UIImage) {
    let photoViewController = PhotoViewController(image: image)
    photoViewController.delegate = self
    photoViewController.view.bounds = self.view.bounds
    self.addChildViewController(photoViewController)
    self.view.addSubview(photoViewController.view)
    photoViewController.didMoveToParentViewController(self)
  }
  
  func hidePhotoViewController(controller: PhotoViewController) {
    controller.willMoveToParentViewController(nil)
    controller.view.removeFromSuperview()
    controller.removeFromParentViewController()
  }
  
  //PhotoViewControllerDelegate
  
  func retakePhoto(controller: PhotoViewController) {
    self.hidePhotoViewController(controller)
  }
  
  func usePhoto(controller: PhotoViewController, photo: UIImage) {
    dismissViewControllerAnimated(true, completion: nil)
    let imageData = UIImageJPEGRepresentation(photo, 1.0)
    let base64 = imageData!.base64EncodedStringWithOptions([])
    
    var assetCollection: PHAssetCollection?
    var assetCollectionPlaceholder: PHObjectPlaceholder?
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", self.assetCollectionName)
    let collection : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
    if let _: AnyObject = collection.firstObject {
      assetCollection = collection.firstObject as? PHAssetCollection
      savePhoto(base64, photo: photo, assetCollection: assetCollection!)
    } else {
      PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.assetCollectionName)
        assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
          if (success) {
            let collectionFetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([assetCollectionPlaceholder!.localIdentifier], options: nil)
            assetCollection = collectionFetchResult.firstObject as? PHAssetCollection
            self.savePhoto(base64, photo: photo, assetCollection: assetCollection!)
          }
      })
    }
  }
  
  private func savePhoto(imageData: String, photo: UIImage, assetCollection: PHAssetCollection) {
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
      let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(photo)
      let assetPlaceholder = assetRequest.placeholderForCreatedAsset
      let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection)
      albumChangeRequest!.addAssets([assetPlaceholder!])
      }, completionHandler: { (success, error) -> Void in
        self.cameraManager.stopSession()
        if let delegate = self.cameraViewControllerDelegate {
          if success {
            delegate.imageHasBeenTaken(self, imageData: imageData)
          } else {
            delegate.onError(self, error: (error?.localizedDescription)!)
          }
        }
    })
  }
  
  
  func cropImage(image: UIImage) -> UIImage {
    let barPart: CGFloat = (topBarHeight + bottomBarHeight) / self.view.bounds.size.height
    return CropHelper.cropImage(image, widthRatio: aspectRatio.widthRatio, heightRatio: aspectRatio.heightRatio, verticalPartToCrop: barPart)
  }
  
  func extractRatio(ratioString: String) -> AspectRatio {
    let ratios = ratioString.characters.split{$0 == ":"}.map(String.init)
    return AspectRatio(widthRatio: Int(ratios[0])!, heightRatio: Int(ratios[1])!)
  }
}

extension CameraViewController: UIPickerViewDataSource {
  func numberOfComponentsInPickerView(colorPicker: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return aspectRatios.count
  }
}

extension CameraViewController: UIPickerViewDelegate {
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return aspectRatios[row]
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    ratioField.text = aspectRatios[row]
    self.aspectRatio = self.extractRatio(aspectRatios[row])
    self.fitAspectRatio(self.aspectRatio)
  }
}
