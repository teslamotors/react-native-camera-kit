//
//  CameraProtocol.swift
//  ReactNativeCameraKit
//

import AVFoundation

protocol CameraProtocol: AnyObject, FocusInterfaceViewDelegate {
    var previewView: UIView { get }

    func setup(cameraType: CameraType, supportedBarcodeType: [CodeFormat])
    func cameraRemovedFromSuperview()

    func update(eventEmitter: CameraEventEmitter?)

    func update(torchMode: TorchMode)
    func update(flashMode: FlashMode)
    func update(cameraType: CameraType)
    func update(zoom: Double?)
    func update(maxZoom: Double?)
    func update(resizeMode: ResizeMode)
    func update(maxPhotoQualityPrioritization: MaxPhotoQualityPrioritization?)
    func update(barcodeFrameSize: CGSize?)

    func zoomPinchStart()
    func zoomPinchChange(pinchScale: CGFloat)

    func isBarcodeScannerEnabled(_ isEnabled: Bool,
                                 supportedBarcodeTypes: [CodeFormat],
                                 onBarcodeRead: ((_ barcode: String, _ codeFormat: CodeFormat) -> Void)?)

    func update(scannerFrameSize: CGRect?)

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data, _ thumbnailData: Data?, _ dimensions: CMVideoDimensions) -> Void,
                        onError: @escaping (_ message: String) -> Void)
}
