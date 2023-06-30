//
//  CameraProtocol.swift
//  ReactNativeCameraKit
//

import AVFoundation

protocol CameraProtocol: AnyObject, FocusInterfaceViewDelegate {
    var previewView: UIView { get }

    func setup(cameraType: CameraType, supportedBarcodeType: [AVMetadataObject.ObjectType])
    func cameraRemovedFromSuperview()

    func update(zoomVelocity: CGFloat)
    func update(torchMode: TorchMode)
    func update(flashMode: FlashMode)
    func update(cameraType: CameraType)

    func isBarcodeScannerEnabled(_ isEnabled: Bool,
                                 supportedBarcodeType: [AVMetadataObject.ObjectType],
                                 onBarcodeRead: ((_ barcode: String) -> Void)?)
    func update(scannerFrameSize: CGRect?)

    func capturePicture(onWillCapture: @escaping () -> Void,
                        onSuccess: @escaping (_ imageData: Data) -> (),
                        onError: @escaping (_ message: String) -> ())
}
