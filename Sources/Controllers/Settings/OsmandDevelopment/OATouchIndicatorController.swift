//
//  OATouchIndicatorController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class OATouchIndicatorController: NSObject, UIGestureRecognizerDelegate {

    // MARK: - Subtypes

    private final class DotView: UIView {

        static let side: CGFloat = 44

        var isFadingOut = false

        init() {
            super.init(frame: CGRect(x: 0, y: 0, width: Self.side, height: Self.side))
            isUserInteractionEnabled = false
            backgroundColor = UIColor(red: 0.408, green: 0.165, blue: 0.835, alpha: 0.55)
            layer.cornerRadius = Self.side / 2
            layer.borderColor = UIColor(red: 0.290, green: 0.118, blue: 0.588, alpha: 0.9).cgColor
            layer.borderWidth = 2.5
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private final class OverlayWindow: UIWindow {

        private var dots: [ObjectIdentifier: DotView] = [:]

        override var rootViewController: UIViewController? {
            get {
                for scene in UIApplication.shared.connectedScenes {
                    guard let windowScene = scene as? UIWindowScene else { continue }
                    for window in windowScene.windows where window !== self {
                        if let controller = window.rootViewController {
                            return controller
                        }
                    }
                }
                return super.rootViewController
            }
            set {
                super.rootViewController = newValue
            }
        }

        func handle(_ touches: Set<UITouch>) {
            for touch in touches {
                let key = ObjectIdentifier(touch)
                switch touch.phase {
                case .began, .moved, .stationary:
                    if let existing = dots[key], existing.isFadingOut {
                        existing.layer.removeAllAnimations()
                        existing.removeFromSuperview()
                        dots[key] = nil
                    }
                    if dots[key] == nil, touch.phase != .stationary {
                        let dot = DotView()
                        addSubview(dot)
                        dots[key] = dot
                    }
                    if let dot = dots[key], !dot.isFadingOut {
                        dot.center = touch.location(in: self)
                    }
                case .ended, .cancelled:
                    if let dot = dots[key], !dot.isFadingOut {
                        dot.isFadingOut = true
                        dots[key] = nil
                        UIView.animate(withDuration: 0.25, animations: {
                            dot.alpha = 0
                            dot.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                        }, completion: { _ in
                            dot.removeFromSuperview()
                        })
                    }
                default:
                    break
                }
            }
        }

        func clear() {
            for dot in dots.values {
                dot.layer.removeAllAnimations()
                dot.removeFromSuperview()
            }
            dots.removeAll()
        }
    }

    private final class PassiveTouchRecognizer: UIGestureRecognizer {

        var onTouches: ((Set<UITouch>) -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouches?(touches)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouches?(touches)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouches?(touches)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouches?(touches)
        }
    }

    // MARK: - Type Properties

    static let shared = OATouchIndicatorController()

    // MARK: - Instance Properties

    private var isEnabled = false

    private var overlays: [ObjectIdentifier: OverlayWindow] = [:]

    private var recognizers: [PassiveTouchRecognizer] = []

    // MARK: - Initializers

    private override init() {
        super.init()
    }

    // MARK: - Methods

    func applyFromSettings() {
        setEnabled(OAAppSettings.sharedManager().showTouches.get())
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        if enabled {
            startObserving()
            attachToActiveScenes()
        } else {
            stopObserving()
            detachAll()
        }
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSceneChanged),
                                               name: UIScene.didActivateNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onSceneChanged),
                                               name: UIWindow.didBecomeKeyNotification,
                                               object: nil)
    }

    private func stopObserving() {
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeKeyNotification, object: nil)
    }

    private func attachToActiveScenes() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene,
                  windowScene.activationState == .foregroundActive else { continue }
            let overlay = overlay(for: windowScene)
            for window in windowScene.windows where window !== overlay {
                attachRecognizer(to: window, overlay: overlay)
            }
        }
    }

    private func attachRecognizer(to window: UIWindow, overlay: OverlayWindow) {
        guard !recognizers.contains(where: { $0.view === window }) else { return }
        let recognizer = PassiveTouchRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self
        recognizer.onTouches = { [weak overlay] touches in
            overlay?.handle(touches)
        }
        window.addGestureRecognizer(recognizer)
        recognizers.append(recognizer)
    }

    private func overlay(for windowScene: UIWindowScene) -> OverlayWindow {
        let key = ObjectIdentifier(windowScene)
        if let existing = overlays[key] {
            return existing
        }
        let overlay = OverlayWindow(windowScene: windowScene)
        overlay.isUserInteractionEnabled = false
        overlay.windowLevel = .statusBar + 100
        overlay.backgroundColor = .clear
        overlay.isHidden = false
        overlays[key] = overlay
        return overlay
    }

    private func detachAll() {
        for recognizer in recognizers {
            recognizer.onTouches = nil
            recognizer.view?.removeGestureRecognizer(recognizer)
        }
        recognizers.removeAll()
        for overlay in overlays.values {
            overlay.clear()
            overlay.isHidden = true
            overlay.windowScene = nil
        }
        overlays.removeAll()
    }

    @objc private func onSceneChanged() {
        guard isEnabled else { return }
        recognizers.removeAll { $0.view == nil }
        attachToActiveScenes()
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
