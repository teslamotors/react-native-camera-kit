//
//  CodeFormat.swift
//  ReactNativeCameraKit
//
//  Created by Imdad on 2023-12-22.
//

import Foundation
import AVFoundation

enum CodeFormat: String, CaseIterable {
    case code128 = "code-128"
    case code39 = "code-39"
    case code93 = "code-93"
    case ean13 = "ean-13"
    case ean8 = "ean-8"
    case itf14 = "itf-14"
    case upce = "upc-e"
    case qr = "qr"
    case pdf417 = "pdf-417"
    case aztec = "aztec"
    case dataMatrix = "data-matrix"
    case unknown = "unknown"

    // Convert from AVMetadataObject.ObjectType to CodeFormat
    static func fromAVMetadataObjectType(_ type: AVMetadataObject.ObjectType) -> CodeFormat {
        switch type {
        case .code128: return .code128
        case .code39: return .code39
        case .code93: return .code93
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .itf14: return .itf14
        case .upce: return .upce
        case .qr: return .qr
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        default: return .unknown
        }
    }

    // Convert from CodeFormat to AVMetadataObject.ObjectType
    func toAVMetadataObjectType() -> AVMetadataObject.ObjectType {
        switch self {
        case .code128: return .code128
        case .code39: return .code39
        case .code93: return .code93
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .itf14: return .itf14
        case .upce: return .upce
        case .qr: return .qr
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        case .unknown: return .init(rawValue: "unknown")
        }
    }
}
