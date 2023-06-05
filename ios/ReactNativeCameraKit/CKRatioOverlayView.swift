//
//  CKRatioOverlayView.swift
//  ReactNativeCameraKit
//

import UIKit

@objc(CKRatioOverlayView)
public class CKRatioOverlayView: UIView {
    private var overlayObject: CKOverlayObject

    private let topView: UIView = UIView()
    private let centerView: UIView = UIView()
    private let bottomView: UIView = UIView()

    // MARK: - Public

    @objc(initWithFrame:ratioString:overlayColor:)
    public init(frame: CGRect, ratioString: String, overlayColor: UIColor?) {
        overlayObject = CKOverlayObject(from: ratioString)

        let color = overlayColor ?? UIColor.black.withAlphaComponent(0.3)
        topView.backgroundColor = color
        bottomView.backgroundColor = color

        super.init(frame: frame)

        addSubview(topView)
        addSubview(centerView)
        addSubview(bottomView)

        setOverlayParts()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc public func setRatio(_ ratioString: String) {
        overlayObject = CKOverlayObject(from: ratioString)

        UIView.animate(withDuration: 0.2) {
            self.setOverlayParts()
        }
    }

    // MARK: - Private

    private func setOverlayParts() {
        guard overlayObject.ratio != 0 else {
            isHidden = true

            return
        }

        isHidden = false

        var centerSize = CGSize.zero
        var sideSize = CGSize.zero

        if overlayObject.width < overlayObject.height {
            centerSize.width = frame.size.width
            centerSize.height = frame.size.height * CGFloat(overlayObject.ratio)

            sideSize.width = centerSize.width
            sideSize.height = (frame.size.height - centerSize.height) / 2.0

            topView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: sideSize.width,
                                   height: sideSize.height)
            centerView.frame = CGRect(x: 0,
                                      y: topView.frame.size.height + topView.frame.origin.y,
                                      width: centerSize.width,
                                      height: centerSize.height)
            bottomView.frame = CGRect(x: 0,
                                      y: centerView.frame.size.height + centerView.frame.origin.y,
                                      width: sideSize.width,
                                      height: sideSize.height)
        } else if overlayObject.width > overlayObject.height {
            centerSize.width = frame.size.width / CGFloat(overlayObject.ratio)
            centerSize.height = frame.size.height

            sideSize.width = (frame.size.width - centerSize.width) / 2.0
            sideSize.height = centerSize.height

            topView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: sideSize.width,
                                   height: sideSize.height)
            centerView.frame = CGRect(x: topView.frame.size.width + topView.frame.origin.x,
                                      y: 0,
                                      width: centerSize.width,
                                      height: centerSize.height)
            bottomView.frame = CGRect(x: centerView.frame.size.width + centerView.frame.origin.x,
                                      y: 0,
                                      width: sideSize.width,
                                      height: sideSize.height)
        } else { // ratio is 1:1
            centerSize.width = frame.size.width
            centerSize.height = frame.size.width

            sideSize.width = centerSize.width
            sideSize.height = (frame.size.height - centerSize.height) / 2.0

            topView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: sideSize.width,
                                   height: sideSize.height)
            centerView.frame = CGRect(x: 0,
                                      y: topView.frame.size.height + topView.frame.origin.y,
                                      width: centerSize.width,
                                      height: centerSize.height)
            bottomView.frame = CGRect(x: 0,
                                      y: centerView.frame.size.height + centerView.frame.origin.y,
                                      width: sideSize.width,
                                      height: sideSize.height)
        }
    }
}
