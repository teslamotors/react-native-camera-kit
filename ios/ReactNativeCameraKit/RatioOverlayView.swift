//
//  RatioOverlayView.swift
//  ReactNativeCameraKit
//

import UIKit

struct RatioOverlayData: CustomStringConvertible {
    let width: Float
    let height: Float
    let ratio: Float

    init(from inputString: String) {
        let values = inputString.split(separator: ":")

        if values.count == 2,
           let inputHeight = Float(values[0]),
           let inputWidth = Float(values[1]),
           inputHeight != 0,
           inputWidth != 0 {
            height = inputHeight
            width = inputWidth
            ratio = width / height
        } else {
            height = 0
            width = 0
            ratio = 0
        }
    }

    // MARK: CustomStringConvertible

    var description: String {
        return "height:\(height) width:\(width) ratio:\(ratio)"
    }
}

/*
 * Full screen overlay that can appear on top of the camera as an hint for the expected ratio
 */
class RatioOverlayView: UIView {
    private var ratioData: RatioOverlayData?

    private let topView: UIView = UIView()
    private let bottomView: UIView = UIView()

    // MARK: - Lifecycle

    init(frame: CGRect, ratioString: String, overlayColor: UIColor?) {
        super.init(frame: frame)

        isUserInteractionEnabled = false

        let color = overlayColor ?? UIColor.black.withAlphaComponent(0.3)
        setColor(color)

        addSubview(topView)
        addSubview(bottomView)

        setRatio(ratioString)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setOverlayParts()
    }

    // MARK: - Public

    func setRatio(_ ratioString: String) {
        ratioData = RatioOverlayData(from: ratioString)

        UIView.animate(withDuration: 0.2) {
            self.setOverlayParts()
        }
    }

    func setColor(_ color: UIColor) {
        topView.backgroundColor = color
        bottomView.backgroundColor = color
    }

    // MARK: - Private

    private func setOverlayParts() {
        guard let ratioData, ratioData.ratio != 0 else {
            isHidden = true

            return
        }

        isHidden = false

        var centerSize = CGSize.zero
        var sideSize = CGSize.zero
        var centerFrame: CGRect

        if ratioData.width < ratioData.height {
            centerSize.width = frame.size.width
            centerSize.height = frame.size.height * CGFloat(ratioData.ratio)

            sideSize.width = centerSize.width
            sideSize.height = (frame.size.height - centerSize.height) / 2.0

            topView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: sideSize.width,
                                   height: sideSize.height)
            centerFrame = CGRect(x: 0,
                          y: topView.frame.size.height + topView.frame.origin.y,
                          width: centerSize.width,
                          height: centerSize.height)
            bottomView.frame = CGRect(x: 0,
                                      y: centerFrame.size.height + centerFrame.origin.y,
                                      width: sideSize.width,
                                      height: sideSize.height)
        } else if ratioData.width > ratioData.height {
            centerSize.width = frame.size.width / CGFloat(ratioData.ratio)
            centerSize.height = frame.size.height

            sideSize.width = (frame.size.width - centerSize.width) / 2.0
            sideSize.height = centerSize.height

            topView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: sideSize.width,
                                   height: sideSize.height)
            centerFrame = CGRect(x: topView.frame.size.width + topView.frame.origin.x,
                          y: 0,
                          width: centerSize.width,
                          height: centerSize.height)
            bottomView.frame = CGRect(x: centerFrame.size.width + centerFrame.origin.x,
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
            centerFrame = CGRect(x: 0,
                                  y: topView.frame.size.height + topView.frame.origin.y,
                                  width: centerSize.width,
                                  height: centerSize.height)
            bottomView.frame = CGRect(x: 0,
                                      y: centerFrame.size.height + centerFrame.origin.y,
                                      width: sideSize.width,
                                      height: sideSize.height)
        }
    }
}
