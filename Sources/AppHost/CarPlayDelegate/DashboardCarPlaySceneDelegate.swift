import CarPlay

final class DashboardCarPlaySceneDelegate: UIResponder {
    
    private var dashboardVC: OACarPlayMapDashboardViewController?
    private var mapVC: OAMapViewController?
    private var window: UIWindow?
    private var isForegroundScene = false
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        NSLog("[CarPlay] DashboardCarPlaySceneDelegate sceneWillEnterForeground")
        isForegroundScene = true
        configureScene()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        NSLog("[CarPlay] DashboardCarPlaySceneDelegate sceneWillResignActive")
        NotificationCenter.default.removeObserver(self)
        isForegroundScene = false
        mapVC?.isCarPlayDashboardActive = false
    }
    
    private func configureScene() {
        NotificationCenter.default.removeObserver(self)
        guard let window else { return }
        guard let appDelegate = UIApplication.shared.delegate as? OAAppDelegate else { return }
        appDelegate.initialize()

        if case .setupRoot = appDelegate.appLaunchEvent {
            // if CarPlay was open without a connected device
            if appDelegate.rootViewController == nil {
                appDelegate.rootViewController = OARootViewController()
            }
            mapVC = OARootViewController.instance()?.mapPanel.mapViewController
            if mapVC == nil {
                mapVC = OAMapViewController()
                OARootViewController.instance()?.mapPanel.setMap(mapVC)
            }
            mapVC?.isCarPlayDashboardActive = true
            if let mapVC {
                let settings: OAAppSettings = OAAppSettings.sharedManager()

                dashboardVC = OACarPlayMapDashboardViewController(carPlay: mapVC)
                dashboardVC?.attachMapToWindow()
                self.window?.rootViewController = dashboardVC
                OARootViewController.instance()?.mapPanel.onCarPlayConnected()

                let carPlayMode = settings.isCarPlayModeDefault.get() == true
                    ? OAApplicationMode.getFirstAvailableNavigation()
                    : settings.carPlayMode.get()
                settings.setApplicationModePref(carPlayMode, markAsLastUsed: false)

                let isRoutePlanning = OARoutingHelper.sharedInstance().isRoutePlanningMode()
                let placement = settings.positionPlacementOnMap.get()
                var y: Double
                if placement == EOAPositionPlacement.auto.rawValue {
                    y = settings.rotateMap.get() == ROTATE_MAP_BEARING && !isRoutePlanning ? 1.5 : 1.0
                } else {
                    y = placement == EOAPositionPlacement.center.rawValue || isRoutePlanning ? 1.0 : 1.5
                }
                let heightOffset = 1 - (window.frame.height / mapVC.view.frame.height)
                mapVC.setViewportForCarPlayScaleX(1.0, y: y - heightOffset)
            }
        } else {
            // if the scene becomes active (sceneWillEnterForeground) before setting the root view controller
            NotificationCenter.default.addObserver(self, selector: #selector(appInitEventConfigureScene(notification:)), name: NSNotification.Name.OALaunchUpdateState, object: nil)
        }
    }
    
    @objc private func appInitEventConfigureScene(notification: Notification) {
        NSLog("[CarPlay] DashboardCarPlaySceneDelegate appInitEventConfigureScene")
        guard let userInfo = notification.userInfo,
              let item = userInfo["event"] as? Int,
              let event = AppLaunchEvent(rawValue: item) else { return }
        if case .setupRoot = event {
            guard isForegroundScene else { return }
            NSLog("[CarPlay] DashboardCarPlaySceneDelegate appInitEventConfigureScene success")
            configureScene()
        }
    }
}

extension DashboardCarPlaySceneDelegate: CPTemplateApplicationDashboardSceneDelegate {
    
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didConnect dashboardController: CPDashboardController, to window: UIWindow) {
        NSLog("[CarPlay] DashboardCarPlaySceneDelegate didConnect")
        self.window = window
        dashboardController.shortcutButtons = [
            CPDashboardButton(titleVariants: [localizedString("shared_string_navigation")], subtitleVariants: [""], image: UIImage(named: "ic_carplay_navigation")!, handler: { _ in
                guard let url = URL(string: "osmandmaps://navigation") else { return }
                templateApplicationDashboardScene.open(url, options: nil, completionHandler: nil)
            }),
            CPDashboardButton(titleVariants: [localizedString("address_search_desc")], subtitleVariants: [""], image: UIImage(named: "ic_carplay_search")!, handler: { _ in
                guard let url = URL(string: "osmandmaps://search") else { return }
                templateApplicationDashboardScene.open(url, options: nil, completionHandler: nil)
            })]
    }
    
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didDisconnect dashboardController: CPDashboardController, from window: UIWindow) {
        NSLog("[CarPlay] DashboardCarPlaySceneDelegate didDisconnect")
        dashboardVC?.detachFromCarPlayWindow()
        mapVC = nil
        self.window = nil
        OARootViewController.instance()?.mapPanel.detachFromCarPlayWindow()
    }
}
