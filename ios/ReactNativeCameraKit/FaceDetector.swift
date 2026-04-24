//
//  FaceDetector.swift
//  ReactNativeCameraKit
//

import AVFoundation
import CoreVideo
import Foundation
import Vision

struct FaceDetectionPayload {
    let id: Int
    let yaw: Double
    let pitch: Double
    let roll: Double
    let boundsX: Double
    let boundsY: Double
    let boundsWidth: Double
    let boundsHeight: Double

    var asDictionary: [String: Any] {
        return [
            "id": id,
            "yaw": yaw,
            "pitch": pitch,
            "roll": roll,
            "boundsX": boundsX,
            "boundsY": boundsY,
            "boundsWidth": boundsWidth,
            "boundsHeight": boundsHeight,
        ]
    }
}

final class FaceDetector {
    static let defaultThrottleMs: Int = 100

    private var throttleSeconds: TimeInterval = TimeInterval(FaceDetector.defaultThrottleMs) / 1000.0

    private let request: VNDetectFaceRectanglesRequest = {
        let r = VNDetectFaceRectanglesRequest()
        r.revision = VNDetectFaceRectanglesRequestRevision3
        return r
    }()

    private var lastEmit: TimeInterval = 0
    private var lastErrorDescription: String?

    func update(throttleMs: Int) {
        let validated = throttleMs < 0 ? FaceDetector.defaultThrottleMs : throttleMs
        throttleSeconds = TimeInterval(validated) / 1000.0
    }

    func process(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> [FaceDetectionPayload]? {
        let now = Date.timeIntervalSinceReferenceDate
        guard now - lastEmit >= throttleSeconds else { return nil }
        lastEmit = now

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
            lastErrorDescription = nil
        } catch {
            let description = "\(error)"
            if description != lastErrorDescription {
                print("CKCameraKit: face detection error: \(description)")
                lastErrorDescription = description
            }
            return []
        }

        let observations = request.results ?? []
        return observations.enumerated().map { build(from: $1, id: $0) }
    }

    private func build(from face: VNFaceObservation, id: Int) -> FaceDetectionPayload {
        let bounds = previewBounds(face.boundingBox)
        return FaceDetectionPayload(
            id: id,
            yaw: -degrees(from: face.yaw),
            pitch: degrees(from: face.pitch),
            roll: degrees(from: face.roll),
            boundsX: Double(bounds.origin.x),
            boundsY: Double(bounds.origin.y),
            boundsWidth: Double(bounds.size.width),
            boundsHeight: Double(bounds.size.height)
        )
    }

    private func degrees(from radians: NSNumber?) -> Double {
        guard let radians = radians?.doubleValue else { return 0 }
        return radians * 180.0 / .pi
    }

    private func previewBounds(_ rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.origin.x,
            y: 1.0 - rect.origin.y - rect.size.height,
            width: rect.size.width,
            height: rect.size.height
        )
    }
}
