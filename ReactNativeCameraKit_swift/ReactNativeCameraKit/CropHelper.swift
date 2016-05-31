//
//  CropHelper.swift
//  ReactNativeCameraKit
//
//  Created by Natalia Grankina on 4/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//


import UIKit

struct CropInfo {
  var verticalExcess: CGFloat
  var horizontalExcess: CGFloat
  
  init(verticalExcess: CGFloat, horizontalExcess: CGFloat) {
    self.verticalExcess = verticalExcess
    self.horizontalExcess = horizontalExcess
  }
}

class CropHelper: NSObject {
  static func cropImage(image: UIImage, widthRatio: Int, heightRatio: Int, verticalPartToCrop: CGFloat = 0) -> UIImage {
    let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
    let contextSize: CGSize = contextImage.size
    
    let offset = verticalPartToCrop * contextSize.width
    let cropInfo = cropRectangleToFitRatio(contextSize.width - offset, originalRectangleHeight: contextSize.height, widthRatio: heightRatio, heightRatio: widthRatio)
    
    let rect = CGRectMake(offset / 2 + cropInfo.horizontalExcess / 2, cropInfo.verticalExcess / 2, contextSize.width - (offset + cropInfo.horizontalExcess), contextSize.height - cropInfo.verticalExcess)
    let imageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)
    let newImage = UIImage(CGImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
    
    return newImage
  }
  
  static func cropRectangleToFitRatio(originalRectangleWidth: CGFloat, originalRectangleHeight: CGFloat, widthRatio: Int, heightRatio: Int) -> CropInfo {
    var newHeight = originalRectangleHeight
    var newWidth = originalRectangleWidth
    
    if (widthRatio > heightRatio) {
      newHeight = originalRectangleWidth * CGFloat(heightRatio) / CGFloat(widthRatio)
    } else {
      if (widthRatio < heightRatio) {
        newWidth = originalRectangleHeight * CGFloat(widthRatio) / CGFloat(heightRatio)
      } else {
        if (originalRectangleWidth > originalRectangleHeight) {
          newWidth = originalRectangleHeight
        } else {
          newHeight = originalRectangleWidth
        }
      }
    }
    
    return CropInfo(verticalExcess: originalRectangleHeight - newHeight, horizontalExcess: originalRectangleWidth - newWidth)
  }
}

