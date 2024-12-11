import CarPlay

final class CarPlaySceneDelegate: UIResponder {
    
    private var carPlayMapController: OACarPlayMapViewController?
    private var carPlayDashboardController: OACarPlayDashboardInterfaceController?
    private var windowToAttach: CPWindow?
    private var carPlayInterfaceController: CPInterfaceController?
    private var defaultAppMode: OAApplicationMode?
    private var isForegroundScene = false
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        OALog("[CarPlay] CarPlaySceneDelegate sceneWillEnterForeground")
        isForegroundScene = true
        configureScene()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        OALog("[CarPlay] CarPlaySceneDelegate sceneWillResignActive")
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
            configureCarPlayNavigationMode()
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
    
    private func configureCarPlayNavigationMode() {
        guard let settings = OAAppSettings.sharedManager(), let routingHelper = OARoutingHelper.sharedInstance() else { return }
        if defaultAppMode == nil {
            defaultAppMode = settings.applicationMode.get()
        }
        
        guard let defaultAppMode = defaultAppMode else { return }
        var appModeToSet: OAApplicationMode?
        if settings.isCarPlayModeDefault.get() {
            if !defaultAppMode.isDerivedRouting(from: OAApplicationMode.car()) {
                let derivedMode = OAApplicationMode.values()?.first(where: { $0.isDerivedRouting(from: OAApplicationMode.car()) })
                appModeToSet = derivedMode ?? defaultAppMode
            } else {
                appModeToSet = defaultAppMode
            }
        } else {
            appModeToSet = settings.carPlayMode.get()
        }
        
        if let appMode = appModeToSet {
            settings.setApplicationModePref(appMode, markAsLastUsed: false)
            routingHelper.setAppMode(appMode)
        }
        
        if defaultAppMode != settings.applicationMode.get() && isRoutingActive() {
            routingHelper.recalculateRouteDueToSettingsChange()
            OATargetPointsHelper.sharedInstance().updateRouteAndRefresh(true)
        }
    }
    
    private func isRoutingActive() -> Bool {
        OAAppSettings.sharedManager().followTheRoute.get() || OARoutingHelper.sharedInstance().isRouteCalculated() || OARoutingHelper.sharedInstance().isRouteBeingCalculated()
    }
    
    @objc private func appInitEventConfigureScene(notification: Notification) {
        OALog("[CarPlay] CarPlaySceneDelegate appInitEventConfigureScene")
        guard let userInfo = notification.userInfo,
              let item = userInfo["event"] as? Int,
              let event = AppLaunchEvent(rawValue: item) else { return }
        if case .setupRoot = event {
            guard isForegroundScene else { return }
            OALog("[CarPlay] CarPlaySceneDelegate appInitEventConfigureScene success")
            configureScene()
        }
    }
}

extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        OALog("[CarPlay] CarPlaySceneDelegate didConnect")
        
        OsmAndApp.swiftInstance().carPlayActive = true
        windowToAttach = window
        carPlayInterfaceController = interfaceController
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        OALog("[CarPlay] CarPlaySceneDelegate didDisconnect")
        
        OsmAndApp.swiftInstance().carPlayActive = false
        if defaultAppMode != nil && !isRoutingActive() {
            OAAppSettings.sharedManager().setApplicationModePref(defaultAppMode, markAsLastUsed: false)
        }
        
        defaultAppMode = nil
        guard let mapPanel = OARootViewController.instance()?.mapPanel else {
            OALog("[CarPlay] CarPlaySceneDelegate rootViewController mapPanel is nil")
            return
        }
        
        mapPanel.onCarPlayDisconnected { [weak self] in
            guard let self else { return }
            OALog("[CarPlay] CarPlaySceneDelegate onCarPlayDisconnected")
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
