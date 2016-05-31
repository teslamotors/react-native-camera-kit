//
//  PhotoViewController.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

class PhotoViewController: UIViewController {
  let image: UIImage
  var delegate: PhotoViewControllerDelegate?
  
  let topBarHeight: CGFloat = 50
  let bottomBarHeight: CGFloat = 50
  let buttonMargin: CGFloat = 10
  
  init(image: UIImage) {
    self.image = image
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    var imageViewWidth, imageViewHeight: CGFloat
    let imageView = UIImageView(image: self.image)
    if (image.size.width >= image.size.height) {
      imageViewWidth = self.view.frame.size.width
      imageViewHeight = imageViewWidth * image.size.height / image.size.width
    } else {
      imageViewHeight = self.view.frame.size.height - (topBarHeight + bottomBarHeight)
      imageViewWidth = imageViewHeight * image.size.width / image.size.height
    }
    imageView.frame = CGRectMake(self.view.frame.size.width / 2 - imageViewWidth / 2, self.view.frame.size.height / 2 - imageViewHeight / 2, imageViewWidth, imageViewHeight)
    self.view.backgroundColor = UIColor.blackColor()
    self.view.addSubview(imageView)
    
    let retakePhoto = "Retake"
    let retakeButton = UIButton(type: UIButtonType.Custom) as UIButton
    retakeButton.setTitle(retakePhoto, forState: .Normal)
    retakeButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    let retakeLabelSize = retakePhoto.sizeWithAttributes([NSFontAttributeName: retakeButton.titleLabel!.font])
    retakeButton.frame = CGRect(origin: CGPoint(x: 0, y: self.view.frame.size.height - bottomBarHeight), size: CGSize(width: retakeLabelSize.width + 2 * buttonMargin, height: bottomBarHeight))
    retakeButton.addTarget(self, action: "onRetakePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    self.view.addSubview(retakeButton)
    
    let usePhoto = "Use Photo"
    let useButton = UIButton(type: UIButtonType.Custom) as UIButton
    useButton.setTitle(usePhoto, forState: .Normal)
    useButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    let useLabelSize = usePhoto.sizeWithAttributes([NSFontAttributeName: useButton.titleLabel!.font])
    let useButtonWidth = useLabelSize.width + 2 * buttonMargin
    useButton.frame = CGRect(origin: CGPoint(x: self.view.frame.size.width - useButtonWidth, y: self.view.frame.size.height - bottomBarHeight), size: CGSize(width: useButtonWidth, height: bottomBarHeight))
    useButton.addTarget(self, action: "onUsePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    self.view.addSubview(useButton)
  }
  
  func onRetakePhoto(sender: UIButton) {
    if let delegate = self.delegate {
      delegate.retakePhoto(self)
    }
  }
  
  func onUsePhoto(sender: UIButton) {
    if let delegate = self.delegate {
      delegate.usePhoto(self, photo: image)
    }
  }
}

