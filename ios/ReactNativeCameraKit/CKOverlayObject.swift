//
//  CKOverlayObject.swift
//  ReactNativeCameraKit
//

import Foundation

struct CKOverlayObject: CustomStringConvertible {
    let width: Float
    let height: Float
    let ratio: Float

    init(from inputString: String) {
        let values = inputString.split(separator: ":")

        if values.count == 2,
           let inputHeight = Float(values[0]),
           let inputWidth = Float(values[1]),
           inputHeight != 0,
           inputWidth != 0 {
                height = inputHeight
                width = inputWidth
                ratio = width / height
        } else {
            height = 0
            width = 0
            ratio = 0
        }
    }

    // MARK: CustomStringConvertible

    var description: String {
        return "height:\(height) width:\(width) ratio:\(ratio)"
    }
}
