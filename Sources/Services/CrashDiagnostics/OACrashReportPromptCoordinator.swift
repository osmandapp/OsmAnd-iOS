//
//  OACrashReportPromptCoordinator.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// Presents the crash-report opt-in prompt once for each newest diagnostic.
/// Reports are never uploaded automatically; the user must explicitly tap Send
/// and choose a destination in the system share sheet.
@objcMembers
final class OACrashReportPromptCoordinator: NSObject {
    static let shared = OACrashReportPromptCoordinator()

    private static let lastPromptedReportKey = "lastPromptedCrashDiagnostic"
    private static let presentationRetryDelay: TimeInterval = 1
    private static let preferredSheetSafeAreaHeight: CGFloat = 400

    private let userDefaults: UserDefaults
    private let readyMainApplicationScenes = NSHashTable<UIScene>.weakObjects()
    private var isStarted = false
    private weak var mainApplicationScene: UIScene?
    private weak var presentedPrompt: OACrashReportPromptViewController?
    private var presentationRetryWorkItem: DispatchWorkItem?

    private override init() {
        userDefaults = .standard
        super.init()
    }

    func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isStarted else { return }
            self.isStarted = true

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onCrashReportsDidChange(_:)),
                name: OACrashDiagnosticsManager.reportsDidChangeNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onSceneDidActivate(_:)),
                name: UIScene.didActivateNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.onMainApplicationUIReady(_:)),
                name: NSNotification.Name.OAMainApplicationUIReady,
                object: nil
            )
            self.requestPresentation()
        }
    }

    @objc private func onCrashReportsDidChange(_ notification: Notification) {
        requestPresentation()
    }

    @objc private func onSceneDidActivate(_ notification: Notification) {
        guard let scene = notification.object as? UIScene,
              readyMainApplicationScenes.contains(scene),
              mainApplicationWindow(for: scene) != nil else {
            return
        }
        mainApplicationScene = scene
        requestPresentation()
    }

    @objc private func onMainApplicationUIReady(_ notification: Notification) {
        guard let scene = notification.object as? UIScene else { return }
        readyMainApplicationScenes.add(scene)
        mainApplicationScene = scene
        // The first-launch controller can be pushed immediately after the root
        // is installed. Defer presentation until all synchronous launch-state
        // observers have completed their UI updates.
        DispatchQueue.main.async { [weak self] in
            self?.requestPresentation()
        }
    }

    private func requestPresentation() {
        dispatchPrecondition(condition: .onQueue(.main))

        presentationRetryWorkItem?.cancel()
        presentationRetryWorkItem = nil
        presentPromptIfNeeded()
    }

    private func presentPromptIfNeeded() {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let scene = activeMainApplicationScene(),
              let window = mainApplicationWindow(for: scene),
              isMainApplicationRootInstalled(in: window),
              presentedPrompt == nil else {
            return
        }
        mainApplicationScene = scene

        let reportURLs = OACrashDiagnosticsManager.shared.latestCrashReportURLs
        guard let newestReportURL = reportURLs.first else { return }

        let reportIdentifier = newestReportURL.lastPathComponent
        guard userDefaults.string(forKey: Self.lastPromptedReportKey) != reportIdentifier else {
            return
        }

        guard let presenter = topViewController(from: window.rootViewController) else {
            schedulePresentationRetry()
            return
        }
        // Pushed startup and feature screens signal again when the map root
        // becomes visible, so there is no need to poll in the background.
        guard presenter is OARootViewController else { return }

        guard let presenterWindow = presenter.viewIfLoaded?.window,
              presenterWindow.windowScene === scene else {
            schedulePresentationRetry()
            return
        }

        guard !presenter.isBeingPresented,
              !presenter.isBeingDismissed,
              presenter.presentedViewController?.isBeingDismissed != true,
              presenter.transitionCoordinator == nil else {
            schedulePresentationRetry()
            return
        }

        let prompt = OACrashReportPromptViewController()
        prompt.onDismiss = { [weak self, weak prompt] in
            guard let self else { return }
            if self.presentedPrompt === prompt {
                self.presentedPrompt = nil
            }
            self.requestPresentation()
        }

        let navigationController = UINavigationController(rootViewController: prompt)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let identifier = UISheetPresentationController.Detent.Identifier(
                    "crashReportPrompt"
                )
                sheet.detents = [
                    .custom(identifier: identifier) { context in
                        min(Self.preferredSheetSafeAreaHeight, context.maximumDetentValue)
                    }
                ]
                sheet.selectedDetentIdentifier = identifier
            } else {
                // iOS 15 has no custom detents. A large detent is the only size
                // that guarantees the complete prompt remains visible.
                sheet.detents = [.large()]
            }
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }

        presentedPrompt = prompt
        presenter.present(navigationController, animated: true) { [weak self] in
            self?.userDefaults.set(reportIdentifier, forKey: Self.lastPromptedReportKey)
        }
    }

    private func schedulePresentationRetry() {
        guard presentationRetryWorkItem == nil,
              mainApplicationScene?.activationState == .foregroundActive else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.presentationRetryWorkItem = nil
            self.requestPresentation()
        }
        presentationRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.presentationRetryDelay,
            execute: workItem
        )
    }

    private func mainApplicationWindow(for scene: UIScene) -> UIWindow? {
        guard let windowScene = scene as? UIWindowScene else { return nil }
        if let keyWindow = windowScene.keyWindow,
           isMainApplicationRootInstalled(in: keyWindow) {
            return keyWindow
        }
        return windowScene.windows.first(where: { isMainApplicationRootInstalled(in: $0) })
    }

    private func activeMainApplicationScene() -> UIScene? {
        if let scene = mainApplicationScene,
           scene.activationState == .foregroundActive,
           mainApplicationWindow(for: scene) != nil {
            return scene
        }
        return readyMainApplicationScenes.allObjects.first {
            $0.activationState == .foregroundActive
                && mainApplicationWindow(for: $0) != nil
        }
    }

    private func isMainApplicationRootInstalled(in window: UIWindow) -> Bool {
        guard let rootViewController = window.rootViewController else { return false }
        if rootViewController is OARootViewController {
            return true
        }
        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.viewControllers.contains { $0 is OARootViewController }
        }
        return false
    }

    private func topViewController(from viewController: UIViewController?) -> UIViewController? {
        guard let viewController else { return nil }

        // Do not interrupt alerts, activity sheets, onboarding, or any other
        // modal flow. The scene-bound retry will continue after it is dismissed.
        guard viewController.presentedViewController == nil else { return nil }
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        return viewController
    }
}
