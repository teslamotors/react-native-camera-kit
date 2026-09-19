//
//  RatioOverlayView.swift
//  ReactNativeCameraKit
//

import UIKit

/*
 * A `width:height` ratio, as accepted by the `ratioOverlay` prop, eg. "16:9" or "4:5".
 *
 * Width comes first, so "4:5" describes a window that is taller than it is wide,
 * and "16:9" one that is wider than it is tall.
 */
struct RatioOverlayData: CustomStringConvertible {
    let width: Float
    let height: Float
    let ratio: Float

    init(from inputString: String) {
        let values = inputString.split(separator: ":")

        if values.count == 2,
           let inputWidth = Float(values[0]),
           let inputHeight = Float(values[1]),
           inputWidth > 0,
           inputHeight > 0 {
            width = inputWidth
            height = inputHeight
            ratio = width / height
        } else {
            width = 0
            height = 0
            ratio = 0
        }
    }

    /*
     * The largest rect of this ratio that fits inside `size`, centered.
     *
     * Returns nil when there is nothing to draw, ie. the ratio was unparseable
     * or the container has not been laid out yet.
     */
    func centeredWindow(fitting size: CGSize) -> CGRect? {
        guard ratio > 0, size.width > 0, size.height > 0 else {
            return nil
        }

        let targetRatio = CGFloat(ratio)
        let containerRatio = size.width / size.height

        // Aspect fit: the tighter of the two axes spans the container,
        // the other one is derived from the requested ratio.
        let windowSize = targetRatio > containerRatio
            ? CGSize(width: size.width, height: size.width / targetRatio)
            : CGSize(width: size.height * targetRatio, height: size.height)

        return CGRect(x: (size.width - windowSize.width) / 2.0,
                      y: (size.height - windowSize.height) / 2.0,
                      width: windowSize.width,
                      height: windowSize.height)
    }

    // MARK: CustomStringConvertible

    var description: String {
        return "width:\(width) height:\(height) ratio:\(ratio)"
    }
}

/*
 * Full screen overlay that can appear on top of the camera as an hint for the expected ratio
 */
class RatioOverlayView: UIView {
    private var ratioData: RatioOverlayData?

    // The two bars framing the ratio window: above/below it when letterboxing,
    // left/right of it when pillarboxing.
    private let leadingBarView: UIView = UIView()
    private let trailingBarView: UIView = UIView()

    // MARK: - Lifecycle

    init(frame: CGRect, ratioString: String, overlayColor: UIColor?) {
        super.init(frame: frame)

        isUserInteractionEnabled = false

        let color = overlayColor ?? UIColor.black.withAlphaComponent(0.3)
        setColor(color)

        addSubview(leadingBarView)
        addSubview(trailingBarView)

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
        leadingBarView.backgroundColor = color
        trailingBarView.backgroundColor = color
    }

    // MARK: - Private

    private func setOverlayParts() {
        guard let window = ratioData?.centeredWindow(fitting: bounds.size) else {
            isHidden = true

            return
        }

        isHidden = false

        if window.height < bounds.height {
            // Letterbox: mask the strips above and below the ratio window.
            leadingBarView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: bounds.width,
                                          height: window.minY)
            trailingBarView.frame = CGRect(x: 0,
                                           y: window.maxY,
                                           width: bounds.width,
                                           height: bounds.height - window.maxY)
        } else {
            // Pillarbox: mask the strips left and right of the ratio window.
            leadingBarView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: window.minX,
                                          height: bounds.height)
            trailingBarView.frame = CGRect(x: window.maxX,
                                           y: 0,
                                           width: bounds.width - window.maxX,
                                           height: bounds.height)
        }
    }
}
