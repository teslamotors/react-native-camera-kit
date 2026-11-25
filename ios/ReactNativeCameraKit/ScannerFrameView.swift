//
//  ScannerFrame.swift
//  ReactNativeCameraKit
//

import UIKit

/*
 * Frame for the barcode scanner
 */
class ScannerFrameView: UIView {
    private let laserView = UIView()
    private let laserAnimationKey = "laser"
    private var isLaserRunning = false
    private var laserSize: CGSize = .zero
    private let frameViews: [UIView] = (0..<8).map { _ in UIView() }

    // MARK: - Lifecycle

    init(frameColor: UIColor, laserColor: UIColor) {
        super.init(frame: .zero)

        laserView.backgroundColor = laserColor
        addSubview(laserView)

        frameViews.forEach {
            $0.backgroundColor = frameColor
            addSubview($0)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        frameViews.enumerated().forEach { (index, view) in
            view.frame = sizeForFramePart(at: index)
        }
        // Patched: don't (re)start the laser from draw(_:). See startAnimatingScanner().
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The laser's path depends on this view's size, so re-lay it out when the size changes.
        if isLaserRunning && bounds.size != laserSize {
            startAnimatingScanner()
        }
    }

    // MARK: - Public

    // Patched: animate the laser with an explicit Core Animation animation on its own layer.
    // UIView.animate(withDuration:options: [.autoreverse, .repeat]) opens a UIView animation block; when it ran
    // while UIKit was laying out a presenting sheet (the camera mounting inside a form sheet), UIKit captured
    // the sheet's own transform into this infinite, auto-reversing animation. The sheet then "breathed" and
    // stopped receiving touches. A layer animation can't capture other views' changes.
    func startAnimatingScanner() {
        laserView.layer.removeAnimation(forKey: laserAnimationKey)
        UIView.performWithoutAnimation {
            laserView.frame = CGRect(x: 2, y: 2, width: frame.size.width - 4, height: 2)
        }

        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = laserView.layer.position.y
        animation.toValue = frame.size.height - 3
        animation.duration = 3
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        laserView.layer.add(animation, forKey: laserAnimationKey)

        isLaserRunning = true
        laserSize = bounds.size
    }

    func stopLaserAnimation() {
        laserView.layer.removeAnimation(forKey: laserAnimationKey)
        isLaserRunning = false
    }

    func stopAnimatingScanner() {
        laserView.removeFromSuperview()
    }

    func update(frameColor: UIColor) {
        frameViews.forEach { $0.backgroundColor = frameColor }
    }

    func update(laserColor: UIColor) {
        laserView.backgroundColor = laserColor
    }

    // MARK: - Private

    private func sizeForFramePart(at index: Int) -> CGRect {
        let cornerHeight: CGFloat = 20.0
        let cornerWidth: CGFloat = 2.0

        switch index {
        case 0:
            return .init(x: 0, y: 0, width: cornerWidth, height: cornerHeight)
        case 1:
            return .init(x: 0, y: 0, width: cornerHeight, height: cornerWidth)
        case 2:
            return .init(x: bounds.width - cornerHeight, y: 0, width: cornerHeight, height: cornerWidth)
        case 3:
            return .init(x: bounds.width - cornerWidth, y: 0, width: cornerWidth, height: cornerHeight)
        case 4:
            return .init(x: bounds.width - cornerWidth,
                         y: bounds.height - cornerHeight,
                         width: cornerWidth,
                         height: cornerHeight)
        case 5:
            return .init(x: bounds.width - cornerHeight, y: bounds.height - cornerWidth, width: cornerHeight, height: cornerWidth)
        case 6:
            return .init(x: 0, y: bounds.height - cornerWidth, width: cornerHeight, height: cornerWidth)
        case 7:
            return .init(x: 0, y: bounds.height - cornerHeight, width: cornerWidth, height: cornerHeight)
        default:
            fatalError("unknown index")
        }
    }
}
