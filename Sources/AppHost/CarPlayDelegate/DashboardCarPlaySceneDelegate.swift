import CarPlay

final class DashboardCarPlaySceneDelegate: UIResponder {
    
    private var dashboardVC: OACarPlayMapDashboardViewController?
    private var mapVC: OAMapViewController?
    private var window: UIWindow?
    private var defaultAppMode: OAApplicationMode?
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
        guard window != nil else { return }
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
            configureCarPlayNavigationMode()
            if let mapVC {
                let settings: OAAppSettings = OAAppSettings.sharedManager()

                dashboardVC = OACarPlayMapDashboardViewController(carPlay: mapVC)
                dashboardVC?.attachMapToWindow()
                self.window?.rootViewController = dashboardVC
                OARootViewController.instance()?.mapPanel.onCarPlayConnected()
                let isRoutePlanning = OARoutingHelper.sharedInstance().isRoutePlanningMode()
                let placement = settings.positionPlacementOnMap.get()
                var y: Double
                if placement == EOAPositionPlacement.auto.rawValue {
                    y = settings.rotateMap.get() == ROTATE_MAP_BEARING && !isRoutePlanning ? mapCenterBottomY() : 1.0
                } else {
                    y = placement == EOAPositionPlacement.center.rawValue || isRoutePlanning ? 1.0 : mapCenterBottomY()
                }
                mapVC.setViewportForCarPlayScaleX(1.0, y: y)
            }
        } else {
            // if the scene becomes active (sceneWillEnterForeground) before setting the root view controller
            NotificationCenter.default.addObserver(self, selector: #selector(appInitEventConfigureScene(notification:)), name: NSNotification.Name.OALaunchUpdateState, object: nil)
        }
    }
    
    private func configureCarPlayNavigationMode() {
        guard let routing = OARoutingHelper.sharedInstance() else { return }
        let settings = OAAppSettings.sharedManager()
        defaultAppMode = defaultAppMode ?? settings.applicationMode.get()
        guard let defaultAppMode else { return }
        let firstCar = OAApplicationMode.values()?.first { $0.isDerivedRouting(from: .car()) } ?? defaultAppMode
        let resolvedMode: OAApplicationMode = settings.isCarPlayModeDefault.get()
        ? (defaultAppMode.isDerivedRouting(from: .car()) ? defaultAppMode : firstCar)
        : settings.carPlayMode.get()
        let oldMode = settings.applicationMode.get()
        guard resolvedMode != oldMode else { return }
        settings.setApplicationModePref(resolvedMode)
        routing.setAppMode(resolvedMode)
        if isRoutingActive() {
            routing.recalculateRouteDueToSettingsChange()
            OATargetPointsHelper.sharedInstance().updateRouteAndRefresh(true)
        }
    }
    
    private func isRoutingActive() -> Bool {
        OAAppSettings.sharedManager().followTheRoute.get() || OARoutingHelper.sharedInstance().isRouteCalculated() || OARoutingHelper.sharedInstance().isRouteBeingCalculated()
    }
    
    private func mapCenterBottomY(bottomMargin: CGFloat = 60.0) -> CGFloat {
        guard let screenHeight = dashboardVC?.view.frame.height, screenHeight > 0 else {
            return 1.5
        }
        return 2.0 - (bottomMargin / (screenHeight / 2.0))
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
        if let defaultAppMode, !isRoutingActive() {
            OAAppSettings.sharedManager().setApplicationModePref(defaultAppMode)
        }

        defaultAppMode = nil
        dashboardVC?.detachFromCarPlayWindow()
        mapVC = nil
        self.window = nil
        OARootViewController.instance()?.mapPanel.detachFromCarPlayWindow()
    }
}
