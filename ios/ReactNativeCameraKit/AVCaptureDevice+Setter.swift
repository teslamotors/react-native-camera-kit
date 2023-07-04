//
//  AVCaptureDevice+Setter.swift
//  ReactNativeCameraKit
//

import AVFoundation

extension AVCaptureDevice {
    func setTorchMode(_ newTorchMode: AVCaptureDevice.TorchMode) {
        if isTorchModeSupported(newTorchMode) && hasTorch {
            do {
                try lockForConfiguration()

                defer { unlockForConfiguration() }

                torchMode = newTorchMode
            } catch {
                print("Error setting torch mode: \(error)")
            }
        }
    }

    func incrementZoomFactor(_ zoomFactorIncrement: CGFloat) {
        do {
            try lockForConfiguration()

            defer { unlockForConfiguration() }

            let desiredZoomFactor = videoZoomFactor + zoomFactorIncrement
            videoZoomFactor = max(1.0, min(desiredZoomFactor, activeFormat.videoMaxZoomFactor))
        } catch {
            print("Error setting zoom factor: \(error)")
        }
   }

    func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode,
                       exposeWithMode exposureMode: AVCaptureDevice.ExposureMode,
                       atDevicePoint point: CGPoint,
                       isSubjectAreaChangeMonitoringEnabled: Bool) {
        do {
            try lockForConfiguration()

            defer { unlockForConfiguration() }

            if isFocusPointOfInterestSupported && isFocusModeSupported(focusMode) {
                focusPointOfInterest = point
                self.focusMode = focusMode
            }

            if isExposurePointOfInterestSupported && isExposureModeSupported(exposureMode) {
                exposurePointOfInterest = point
                self.exposureMode = exposureMode
            }

            self.isSubjectAreaChangeMonitoringEnabled = isSubjectAreaChangeMonitoringEnabled
        } catch {
            print("Error setting focus: \(error)")
        }
    }
}
