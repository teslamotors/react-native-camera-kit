//
//  SimulatorPreviewView.swift
//  ReactNativeCameraKit
//

import UIKit

class SimulatorPreviewView: UIView {
    let zoomLabel = UILabel()
    let focusAtLabel = UILabel()
    let torchModeLabel = UILabel()
    let flashModeLabel = UILabel()
    let cameraTypeLabel = UILabel()
    let orientationLabel = UILabel()
    let resizeModeLabel = UILabel()

    var balloonLayer = CALayer()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.masksToBounds = true

        layer.insertSublayer(balloonLayer, at: 0)

        let stackView = UIStackView()
        stackView.axis = .vertical
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        [zoomLabel, focusAtLabel, torchModeLabel, flashModeLabel, cameraTypeLabel, resizeModeLabel, orientationLabel].forEach {
            $0.numberOfLines = 0
            stackView.addArrangedSubview($0)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        randomize()
    }

    // MARK: - Public

    func snapshot(withTimestamp showTimestamp: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        var image = UIGraphicsGetImageFromCurrentImageContext()

        if showTimestamp {
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let stringFromDate = dateFormatter.string(from: date)
            let font = UIFont.boldSystemFont(ofSize: 20)

            image?.draw(in: CGRect(x: 0, y: 0, width: image?.size.width ?? 0, height: image?.size.height ?? 0))
            let rect = CGRect(x: 25, y: 125, width: image?.size.width ?? 0, height: image?.size.height ?? 0)
            UIColor.white.set()
            let textFontAttributes = [NSAttributedString.Key.font: font]
            stringFromDate.draw(in: rect.integral, withAttributes: textFontAttributes)

            image = UIGraphicsGetImageFromCurrentImageContext()
        }

        UIGraphicsEndImageContext()
        return image
    }

    func randomize() {
        layer.backgroundColor = UIColor(hue: CGFloat(Double.random(in: 0...1)), saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor
        balloonLayer.removeFromSuperlayer()
        balloonLayer = CALayer()
        layer.insertSublayer(balloonLayer, at: 0)

        for _ in 0..<5 {
            drawBalloon()
        }
    }

    // MARK: - Private

    private func drawBalloon() {
        let stringLength = CGFloat(200)
        let radius = CGFloat(Int.random(in: 50...150))

        let x = CGFloat(Int.random(in: 0...Int(frame.size.width)))
        let y = CGFloat(Int.random(in: 0...Int(frame.size.height + radius + stringLength)))
        let stretch = radius / 3

        let balloon = CALayer()
        balloon.frame = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2 + stringLength)

        // Balloon main circle
        let circle = CAShapeLayer()
        let colorHue = Double.random(in: 0...1)

        circle.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2 + stretch)).cgPath
        circle.fillColor = UIColor(hue: colorHue, saturation: 1.0, brightness: 0.95, alpha: 1.0).cgColor

        // Balloon reflection
        let reflection = CAShapeLayer()
        reflection.path = UIBezierPath(ovalIn: CGRect(x: radius / 2, y: radius / 2, width: radius * 0.7, height: radius * 0.7)).cgPath
        reflection.fillColor = UIColor(hue: colorHue, saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor

        // Balloon string
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        let startPoint = CGPoint(x: balloon.frame.size.width / 2, y: radius * 2)
        let endPoint = CGPoint(x: balloon.frame.size.width, y: (radius * 2) + stringLength)
        linePath.move(to: startPoint)
        linePath.addQuadCurve(to: endPoint, controlPoint: CGPoint(x: balloon.frame.size.width / 2, y: radius * 2 + stringLength / 2))
        line.path = linePath.cgPath
        line.fillColor = nil
        line.strokeColor = UIColor.darkGray.cgColor
        line.opacity = 1.0
        line.lineWidth = radius * 0.05

        // Add layers
        balloon.addSublayer(line)
        circle.addSublayer(reflection)
        balloon.addSublayer(circle)

        balloonLayer.addSublayer(balloon)

        // Apply animation
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = NSNumber(value: 0.7)
        scale.toValue = NSNumber(value: 1.0)
        scale.duration = 10.0
        scale.fillMode = .forwards
        scale.isRemovedOnCompletion = false
        scale.autoreverses = true
        scale.repeatCount = .greatestFiniteMagnitude

        let move = CABasicAnimation(keyPath: "position.y")
        move.fromValue = NSNumber(value: balloon.frame.origin.y)
        move.toValue = NSNumber(value: 0 - balloon.frame.size.height)
        move.duration = Double.random(in: 30...100)
        move.isRemovedOnCompletion = false
        move.repeatCount = .greatestFiniteMagnitude

        balloon.add(scale, forKey: "scale")
        balloon.add(move, forKey: "move")
    }
}
