//
//  CKCompressedImage.swift
//  ReactNativeCameraKit
//

import UIKit

enum ImageQuality: String {
    case high
    case medium
    case original

    init(from string: String) {
        self = ImageQuality(rawValue: string) ?? .original
    }
}

struct CKCompressedImage {
    let image: UIImage
    let data: Data?

    init(inputImage: UIImage, imageQuality: ImageQuality) {
        var max: CGFloat = 1200.0

        switch imageQuality {
        case .high:
            max = 1200.0
        case .medium:
            max = 800.0
        case .original:
            image = inputImage
            data = inputImage.jpegData(compressionQuality: 1.0)
            return
        }

        let actualHeight = inputImage.size.height
        let actualWidth = inputImage.size.width

        let imgRatio = actualWidth / actualHeight

        let newHeight = (actualHeight > actualWidth) ? max : max / imgRatio
        let newWidth = (actualHeight > actualWidth) ? max * imgRatio : max

        let rect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: newHeight)
        UIGraphicsBeginImageContext(rect.size)
        inputImage.draw(in: rect)
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.data = image.jpegData(compressionQuality: 0.85)
    }
}
