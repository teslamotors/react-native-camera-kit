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
                torchMode = newTorchMode
                unlockForConfiguration()
            } catch {
                print("Error setting torch mode: \(error)")
            }
        }
    }

    func incrementZoomFactor(_ zoomFactorIncrement: CGFloat) {
        do {
            try lockForConfiguration()

            var zoomFactor = videoZoomFactor + zoomFactorIncrement
            if zoomFactor > activeFormat.videoMaxZoomFactor {
                zoomFactor = activeFormat.videoMaxZoomFactor
            } else if zoomFactor < 1 {
                zoomFactor = 1.0
            }
            videoZoomFactor = zoomFactor
            unlockForConfiguration()
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

            if isFocusPointOfInterestSupported && isFocusModeSupported(focusMode) {
                focusPointOfInterest = point
                self.focusMode = focusMode
            }

            if isExposurePointOfInterestSupported && isExposureModeSupported(exposureMode) {
                exposurePointOfInterest = point
                self.exposureMode = exposureMode
            }

            self.isSubjectAreaChangeMonitoringEnabled = isSubjectAreaChangeMonitoringEnabled
            unlockForConfiguration()
        } catch {
            print("Error setting focus: \(error)")
        }
    }
}
