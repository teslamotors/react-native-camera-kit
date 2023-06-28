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

        startAnimatingScanner()
    }

    // MARK: - Public

    func startAnimatingScanner() {
        if laserView.frame.origin.y != 0 {
            laserView.frame = CGRect(x: 2, y: 2, width: frame.size.width - 4, height: 2)
        }


        UIView.animate(withDuration: 3, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.laserView.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - 3)
        })
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
