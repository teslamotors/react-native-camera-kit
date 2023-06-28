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
    private let onCaptureSuccess: (_ uniqueID: Int64, _ imageData: Data) -> Void
    private let onCaptureError: (_ uniqueID: Int64, _ message: String) -> Void

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         onWillCapture: @escaping () -> Void,
         onCaptureSuccess: @escaping (_ uniqueID: Int64, _ imageData: Data) -> Void,
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

        onCaptureSuccess(requestedPhotoSettings.uniqueID, imageData)
    }
}
