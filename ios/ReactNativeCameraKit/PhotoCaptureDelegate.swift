//
//  PhotoCaptureDelegate.swift
//  ReactNativeCameraKit
//

import AVFoundation

/*
 * AVCapturePhotoCapture is using a delegation pattern, this class makes it more convenient with a closure pattern.
 */
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings

    private let onWillCapture: () -> Void
    private let onCaptureSuccess: (_ uniqueID: Int64, _ imageData: Data, _ thumbnailData: Data?) -> Void
    private let onCaptureError: (_ uniqueID: Int64, _ message: String) -> Void

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         onWillCapture: @escaping () -> Void,
         onCaptureSuccess: @escaping (_ uniqueID: Int64, _ imageData: Data, _ thumbnailData: Data?) -> Void,
         onCaptureError: @escaping (_ uniqueID: Int64, _ errorMessage: String) -> Void) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.onWillCapture = onWillCapture
        self.onCaptureSuccess = onCaptureSuccess
        self.onCaptureError = onCaptureError
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        onWillCapture()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Could not capture still image: \(error)")
            onCaptureError(requestedPhotoSettings.uniqueID, "Could not capture still image")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            onCaptureError(requestedPhotoSettings.uniqueID, "Could not capture still image")
            return
        }

        var thumbnailData: Data? = nil
        if let previewPixelBuffer = photo.previewPixelBuffer {
            // The preview buffer orientation is usually wrong,
            // so grab the correct one from the main image
            var previewPhotoOrientation: CGImagePropertyOrientation?
            if let orientationNum = photo.metadata[kCGImagePropertyOrientation as String] as? NSNumber {
                previewPhotoOrientation = CGImagePropertyOrientation(rawValue: orientationNum.uint32Value)
            }
            
            var uiiOrientation: UIImage.Orientation = .up
            switch previewPhotoOrientation {
            case .none: fallthrough
            case .some(.up): uiiOrientation = .up
            case .some(.upMirrored): uiiOrientation = .upMirrored
            case .some(.right): uiiOrientation = .right
            case .some(.rightMirrored): uiiOrientation = .rightMirrored
            case .some(.down): uiiOrientation = .down
            case .some(.downMirrored): uiiOrientation = .downMirrored
            case .some(.left): uiiOrientation = .left
            case .some(.leftMirrored): uiiOrientation = .leftMirrored
            }

            let previewCiImage = CIImage(cvPixelBuffer: previewPixelBuffer)
            let uiImage = UIImage(ciImage: previewCiImage, scale: 1.0, orientation: uiiOrientation)
            // iOS compressionQuality seems to behave differently from many other apps
            // 0.1 seems to be >50% (little quality loss)
            thumbnailData = uiImage.jpegData(compressionQuality: 0.1)
        }

        onCaptureSuccess(requestedPhotoSettings.uniqueID, imageData, thumbnailData)
    }
}
