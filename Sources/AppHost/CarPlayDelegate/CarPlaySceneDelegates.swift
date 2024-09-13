import CarPlay

final class CarPlaySceneDelegate: UIResponder {
    
    private var carPlayMapController: OACarPlayMapViewController?
    private var carPlayDashboardController: OACarPlayDashboardInterfaceController?
    private var windowToAttach: CPWindow?
    private var carPlayInterfaceController: CPInterfaceController?
    private var isForegroundScene = false
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        NSLog("[CarPlay] CarPlaySceneDelegate sceneWillEnterForeground")
        isForegroundScene = true
        configureScene()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        NSLog("[CarPlay] CarPlaySceneDelegate sceneWillResignActive")
        NotificationCenter.default.removeObserver(self)
        isForegroundScene = false
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let str = URLContexts.first?.url.absoluteString else { return }
        if str.contains("search") {
            carPlayDashboardController?.openSearch()
        } else if str.contains("navigation") {
            carPlayDashboardController?.openNavigation()
        }
    }
    
    private func configureScene() {
        NotificationCenter.default.removeObserver(self)
        guard let carPlayInterfaceController, let windowToAttach else { return }
        guard let appDelegate = UIApplication.shared.delegate as? OAAppDelegate else { return }
        appDelegate.initialize()
        
        if case .setupRoot = appDelegate.appLaunchEvent {
            // if CarPlay was open without a connected device
            if appDelegate.rootViewController == nil {
                appDelegate.rootViewController = OARootViewController()
            }
            presentInCarPlay(interfaceController: carPlayInterfaceController, window: windowToAttach)
            configureNavigationSettings()
        } else {
            // if the scene becomes active (sceneWillEnterForeground) before setting the root view controller
            NotificationCenter.default.addObserver(self, selector: #selector(appInitEventConfigureScene(notification:)), name: NSNotification.Name.OALaunchUpdateState, object: nil)
        }
    }
    
    private func presentInCarPlay(interfaceController: CPInterfaceController, window: CPWindow) {
        if OAIAPHelper.sharedInstance().isCarPlayAvailable() {
            var mapVc = OARootViewController.instance()?.mapPanel.mapViewController
            if mapVc == nil {
                mapVc = OAMapViewController()
                OARootViewController.instance()?.mapPanel.setMap(mapVc)
            }
            mapVc?.isCarPlayDashboardActive = false
            carPlayMapController = OACarPlayMapViewController(carPlay: window, mapViewController: mapVc)
            carPlayDashboardController = OACarPlayDashboardInterfaceController(interfaceController: interfaceController)
            carPlayDashboardController?.delegate = carPlayMapController
            carPlayMapController?.delegate = carPlayDashboardController
            window.rootViewController = carPlayMapController
            carPlayDashboardController?.present()
            OARootViewController.instance()?.mapPanel.onCarPlayConnected()
        } else {
            let vc = OACarPlayActiveViewController()
            vc.messageText = localizedString("carplay_available_in_sub_plans")
            vc.smallLogo = true
            let purchaseController = OACarPlayPurchaseViewController(carPlay: window, viewController: vc)
            window.rootViewController = purchaseController
            carPlayDashboardController = OACarPlayDashboardInterfaceController(interfaceController: interfaceController)
            carPlayDashboardController?.present()
            if let navigationController = OARootViewController.instance()?.navigationController {
                OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.carplay(), navController: navigationController)
            }
        }
    }
    
    private func configureNavigationSettings() {
        guard let settings = OAAppSettings.sharedManager(), let routingHelper = OARoutingHelper.sharedInstance(), let initialAppMode = settings.applicationMode.get() else { return }
        if OsmAndApp.swiftInstance().carPlayActive {
            configureCarPlaySettings(initialAppMode: initialAppMode)
        } else {
            configureStandardSettings()
        }
        
        if initialAppMode != settings.applicationMode.get() && routingHelper.isRouteCalculated() {
            routingHelper.recalculateRouteDueToSettingsChange()
            OATargetPointsHelper.sharedInstance().updateRouteAndRefresh(true)
        }
    }
    
    private func configureCarPlaySettings(initialAppMode: OAApplicationMode) {
        guard let settings = OAAppSettings.sharedManager(), let routingHelper = OARoutingHelper.sharedInstance() else { return }
        if settings.isCarPlayModeDefault.get() {
            let carPlayMode = findAppropriateCarMode(defaultAppMode: initialAppMode)
            settings.setApplicationModePref(carPlayMode, markAsLastUsed: false)
            routingHelper.setAppMode(carPlayMode)
        } else {
            let carPlayMode = settings.carPlayMode.get()
            settings.setApplicationModePref(carPlayMode, markAsLastUsed: false)
            routingHelper.setAppMode(carPlayMode)
        }
    }
    
    private func configureStandardSettings() {
        guard let settings = OAAppSettings.sharedManager() else { return }
        let lastUsedMode = settings.useLastApplicationModeByDefault.get() ? OAApplicationMode.value(ofStringKey: settings.lastUsedApplicationMode.get(), def: OAApplicationMode.default()) : settings.defaultApplicationMode.get()
        settings.setApplicationModePref(lastUsedMode, markAsLastUsed: false)
        OARoutingHelper.sharedInstance().setAppMode(lastUsedMode)
    }
    
    private func findAppropriateCarMode(defaultAppMode: OAApplicationMode) -> OAApplicationMode? {
        if !OAApplicationMode.isAppModeDerived(fromCar: defaultAppMode) {
            let availableAppModes = OAApplicationMode.values() ?? []
            for appMode in availableAppModes where OAApplicationMode.isAppModeDerived(fromCar: appMode) {
                return appMode
            }
        }
        
        return defaultAppMode
    }
    
    @objc private func appInitEventConfigureScene(notification: Notification) {
        NSLog("[CarPlay] CarPlaySceneDelegate appInitEventConfigureScene")
        guard let userInfo = notification.userInfo,
              let item = userInfo["event"] as? Int,
              let event = AppLaunchEvent(rawValue: item) else { return }
        if case .setupRoot = event {
            guard isForegroundScene else { return }
            NSLog("[CarPlay] CarPlaySceneDelegate appInitEventConfigureScene success")
            configureScene()
        }
    }
}

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        NSLog("[CarPlay] CarPlaySceneDelegate didConnect")
        
        OsmAndApp.swiftInstance().carPlayActive = true
        windowToAttach = window
        carPlayInterfaceController = interfaceController
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        NSLog("[CarPlay] CarPlaySceneDelegate didDisconnect")
        
        OsmAndApp.swiftInstance().carPlayActive = false
        configureNavigationSettings()
        
        guard let mapPanel = OARootViewController.instance()?.mapPanel else {
            NSLog("[CarPlay] CarPlaySceneDelegate rootViewController mapPanel is nil")
            return
        }
        
        mapPanel.onCarPlayDisconnected { [weak self] in
            guard let self else { return }
            NSLog("[CarPlay] CarPlaySceneDelegate onCarPlayDisconnected")
            carPlayMapController?.detachFromCarPlayWindow()
            carPlayDashboardController = nil
            carPlayMapController?.navigationController?.popViewController(animated: true)
            window.rootViewController = nil
            carPlayMapController = nil
            windowToAttach = nil
            carPlayInterfaceController = nil
        }
    }
}

// MARK: - OAWidgetListener

extension CarPlaySceneDelegate: OAWidgetListener {
    func widgetChanged(_ widget: OABaseWidgetView?) {
        if widget is SpeedometerView {
            carPlayMapController?.configureSpeedometer()
        }
    }
    
    func widgetVisibilityChanged(_ widget: OABaseWidgetView, visible: Bool) { }
    
    func widgetClicked(_ widget: OABaseWidgetView) { }
}
