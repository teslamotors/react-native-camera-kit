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
    case code39Mod43 = "code-39-mod-43"
    case code93 = "code-93"
    case ean13 = "ean-13"
    case ean8 = "ean-8"
    case itf14 = "itf-14"
    case upce = "upc-e"
    case qr = "qr"
    case pdf417 = "pdf-417"
    case aztec = "aztec"
    case dataMatrix = "data-matrix"
    case interleaved2of5 = "interleaved-2of5"
    case unknown = "unknown"
    @available(iOS 15.4, *)
    case codabar = "codabar"
    @available(iOS 15.4, *)
    case gs1DataBar = "gs1-data-bar"
    @available(iOS 15.4, *)
    case gs1DataBarLimited = "gs1-data-bar-limited"
    @available(iOS 15.4, *)
    case gs1DataBarExpanded = "gs1-data-bar-expanded"

    static var allCases: [CodeFormat] {
        var supportedBarcodeTypes: [CodeFormat] =
        [.upce, .code39, .code39Mod43,
         .ean13, .ean8, .code93, .code128,
         .pdf417, .qr, .itf14, .aztec,
         .dataMatrix, .interleaved2of5]
        
        if #available(iOS 15.4, *) {
            supportedBarcodeTypes.append(contentsOf: [
                .codabar, .gs1DataBar, .gs1DataBarLimited, .gs1DataBarExpanded
            ])
        }
        
        return supportedBarcodeTypes
    }

    // Convert from AVMetadataObject.ObjectType to CodeFormat
    static func fromAVMetadataObjectType(_ type: AVMetadataObject.ObjectType) -> CodeFormat {
        switch type {
        case .code128: return .code128
        case .code39: return .code39
        case .code39Mod43: return .code39Mod43
        case .code93: return .code93
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .itf14: return .itf14
        case .upce: return .upce
        case .qr: return .qr
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        case .interleaved2of5: return .interleaved2of5
        @available(iOS 15.4, *)
        case .codabar: return .codabar
        @available(iOS 15.4, *)
        case .gs1DataBar: return .gs1DataBar
        @available(iOS 15.4, *)
        case .gs1DataBarLimited: return .gs1DataBarLimited
        @available(iOS 15.4, *)
        case .gs1DataBarExpanded: return .gs1DataBarExpanded
        default: return .unknown
        }
    }

    // Convert from CodeFormat to AVMetadataObject.ObjectType
    func toAVMetadataObjectType() -> AVMetadataObject.ObjectType {
        switch self {
        case .code128: return .code128
        case .code39: return .code39
        case .code39Mod43: return .code39Mod43
        case .code93: return .code93
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .itf14: return .itf14
        case .upce: return .upce
        case .qr: return .qr
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        case .interleaved2of5: return .interleaved2of5
        @available(iOS 15.4, *)
        case .codabar: return .codabar
        @available(iOS 15.4, *)
        case .gs1DataBar: return .gs1DataBar
        @available(iOS 15.4, *)
        case .gs1DataBarLimited: return .gs1DataBarLimited
        @available(iOS 15.4, *)
        case .gs1DataBarExpanded: return .gs1DataBarExpanded
        case .unknown: return .init(rawValue: "unknown")
        }
    }
}
