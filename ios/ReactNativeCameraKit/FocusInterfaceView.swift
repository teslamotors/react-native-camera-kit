//
//  FocusInterfaceView.swift
//  ReactNativeCameraKit
//

import UIKit
import AVFoundation

enum FocusBehavior {
    case customFocus(resetFocusWhenMotionDetected: Bool, resetFocus: () -> Void, focusFinished: () -> Void)
    case continuousAutoFocus

    var isSubjectAreaChangeMonitoringEnabled: Bool {
        switch self {
        case let .customFocus(resetFocusWhenMotionDetected, _, _):
            return true && resetFocusWhenMotionDetected
        case .continuousAutoFocus:
            return false
        }
    }

    var avFocusMode: AVCaptureDevice.FocusMode {
        switch self {
        case .customFocus:
            return .autoFocus
        case .continuousAutoFocus:
            return .continuousAutoFocus
        }
    }

    var exposureMode: AVCaptureDevice.ExposureMode {
        switch self {
        case .customFocus:
            return .autoExpose
        case .continuousAutoFocus:
            return .continuousAutoExposure
        }
    }
}

protocol FocusInterfaceViewDelegate: AnyObject {
    func focus(at touchPoint: CGPoint, focusBehavior: FocusBehavior)
}

/*
 * Full screen focus interface
 */
class FocusInterfaceView: UIView {
    weak var delegate: FocusInterfaceViewDelegate?

    private var resetFocusTimeout = 0
    private var resetFocusWhenMotionDetected = false

    private let focusView: UIView = UIView(frame: .zero)
    private var hideFocusViewTimer: Timer?
    private var focusResetTimer: Timer?
    private var startFocusResetTimerAfterFocusing: Bool = false
    private var tapToFocusEngaged: Bool = false

    private var focusGestureRecognizer: UITapGestureRecognizer?

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        focusView.backgroundColor = .clear
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 1
        focusView.isHidden = true
        addSubview(focusView)

        isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print(touches)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func update(focusMode: FocusMode) {
        if focusMode == .on {
            if (focusGestureRecognizer == nil) {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap(_:)))
                addGestureRecognizer(tapGesture)
                focusGestureRecognizer = tapGesture
            }
        } else {
            if let focusGestureRecognizer {
                removeGestureRecognizer(focusGestureRecognizer)
                self.focusGestureRecognizer = nil
            }
        }
    }

    func update(resetFocusTimeout: Int) {
        self.resetFocusTimeout = resetFocusTimeout
    }

    func update(resetFocusWhenMotionDetected: Bool) {
        self.resetFocusWhenMotionDetected = resetFocusWhenMotionDetected
    }

    func focusFinished() {
        if startFocusResetTimerAfterFocusing, resetFocusTimeout > 0 {
            startFocusResetTimerAfterFocusing = false

            // Disengage manual focus after focusTimeout milliseconds
            let focusTimeoutSeconds = TimeInterval(self.resetFocusTimeout) / 1000
            focusResetTimer = Timer.scheduledTimer(withTimeInterval: focusTimeoutSeconds,
                                                   repeats: false) { [weak self] _ in
                self?.resetFocus()
            }
        }
    }

    func resetFocus() {
        if let focusResetTimer {
            focusResetTimer.invalidate()
            self.focusResetTimer = nil
        }

        // Resetting focus to continuous focus, so not interested in resetting anymore
        startFocusResetTimerAfterFocusing = false

        // Avoid showing reset-focus animation after each photo capture
        if !tapToFocusEngaged {
            return
        }
        tapToFocusEngaged = false

        DispatchQueue.main.async {
            let layerCenter = self.center

            // Reset current camera focus
            self.delegate?.focus(at: layerCenter, focusBehavior: .continuousAutoFocus)

            // Create animation to indicate the new focus location
            let halfDiagonal: CGFloat = 123
            let halfDiagonalAnimation = halfDiagonal * 2

            let focusViewFrame = CGRect(x: layerCenter.x - (halfDiagonal / 2),
                                        y: layerCenter.y - (halfDiagonal / 2),
                                        width: halfDiagonal,
                                        height: halfDiagonal)
            let focusViewFrameForAnimation = CGRect(x: layerCenter.x - (halfDiagonalAnimation / 2),
                                                    y: layerCenter.y - (halfDiagonalAnimation / 2),
                                                    width: halfDiagonalAnimation,
                                                    height: halfDiagonalAnimation)

            self.focusView.alpha = 0
            self.focusView.isHidden = false
            self.focusView.frame = focusViewFrameForAnimation

            UIView.animate(withDuration: 0.2, animations: {
                self.focusView.frame = focusViewFrame
                self.focusView.alpha = 1
            }) { _ in
                self.hideFocusViewTimer?.invalidate()
                self.hideFocusViewTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.focusView.alpha = 0
                    }) { _ in
                        self.focusView.isHidden = true
                    }
                }
            }
        }
    }

    // MARK: - Gesture selectors

    @objc func focusAndExposeTap(_ gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: self)
        delegate?.focus(at: touchPoint,
                        focusBehavior: .customFocus(resetFocusWhenMotionDetected: resetFocusWhenMotionDetected,
                                                    resetFocus: resetFocus,
                                                    focusFinished: focusFinished))

        // Disengage manual focus once focusing finishing (if focusTimeout > 0)
        // See [self observeValueForKeyPath]
        focusResetTimer?.invalidate()
        hideFocusViewTimer?.invalidate()
        startFocusResetTimerAfterFocusing = true
        tapToFocusEngaged = true

        // Animate focus rectangle
        let halfDiagonal: CGFloat = 73
        let halfDiagonalAnimation = halfDiagonal * 2

        let focusViewFrame = CGRect(x: touchPoint.x - (halfDiagonal / 2),
                                    y: touchPoint.y - (halfDiagonal / 2),
                                    width: halfDiagonal,
                                    height: halfDiagonal)

        focusView.alpha = 0
        focusView.isHidden = false
        focusView.frame = CGRect(x: touchPoint.x - (halfDiagonalAnimation / 2),
                                 y: touchPoint.y - (halfDiagonalAnimation / 2),
                                 width: halfDiagonalAnimation,
                                 height: halfDiagonalAnimation)

        UIView.animate(withDuration: 0.2, animations: {
            self.focusView.frame = focusViewFrame
            self.focusView.alpha = 1
        })
    }
}
