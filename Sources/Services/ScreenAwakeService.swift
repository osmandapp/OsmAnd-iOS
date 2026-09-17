//
//  ScreenAwakeService.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class ScreenAwakeService: NSObject {
    static let shared = ScreenAwakeService()

    private var isStarted = false
    private var applicationModeChangedObserver: OAAutoObserverProxy?

    private override init() {
        super.init()
    }

    deinit {
        applicationModeChangedObserver?.detach()
        NotificationCenter.default.removeObserver(self)
    }

    // Start after profiles and migrations have been initialized.
    func start() {
        executeOnMainThread {
            if !self.isStarted {
                let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
                self.applicationModeChangedObserver = OAAutoObserverProxy(self,
                                                                         withHandler: #selector(self.updateIdleTimer),
                                                                         andObserve: app.applicationModeChangedObservable)
                for notificationName in [UIScene.didActivateNotification,
                                         UIScene.didEnterBackgroundNotification] {
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.onSceneStateDidChange),
                                                           name: notificationName,
                                                           object: nil)
                }
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.onProfileSettingDidChange),
                                                       name: NSNotification.Name(kNotificationSetProfileSetting),
                                                       object: nil)
                self.isStarted = true
            }
            self.updateIdleTimer()
        }
    }

    func updateIdleTimer() {
        executeOnMainThread {
            // Routing can request an update while its singleton is still initializing.
            guard self.isStarted else { return }

            let settings = OAAppSettings.sharedManager()
            let routingHelper = OARoutingHelper.sharedInstance()
            let isFollowingMode = routingHelper.isFollowingMode()
            let appMode: OAApplicationMode? = isFollowingMode ? routingHelper.getAppMode() : settings.applicationMode.get()
            let keepScreenOnMode: EOAKeepScreenOnMode
            if let appMode {
                keepScreenOnMode = EOAKeepScreenOnMode(rawValue: Int(settings.keepScreenOn.get(appMode))) ?? .systemDefault
            } else {
                keepScreenOnMode = .systemDefault
            }

            let sceneState = UIApplication.shared.mainScene?.activationState
            let isForeground = sceneState == .foregroundActive || sceneState == .foregroundInactive

            UIApplication.shared.isIdleTimerDisabled = isForeground
                && (keepScreenOnMode == .always || (keepScreenOnMode == .duringNavigation && isFollowingMode))
        }
    }

    @objc private func onSceneStateDidChange(notification: Notification) {
        guard let scene = notification.object as? UIScene, scene.session.role == .windowApplication else { return }
        updateIdleTimer()
    }

    @objc private func onProfileSettingDidChange(notification: Notification) {
        let preferenceKeys = notification.userInfo?[kPreferenceKeysUserInfoKey] as? Set<String>
        if let preferenceKeys, preferenceKeys.contains(OAAppSettings.sharedManager().keepScreenOn.key) {
            updateIdleTimer()
        }
    }
}
