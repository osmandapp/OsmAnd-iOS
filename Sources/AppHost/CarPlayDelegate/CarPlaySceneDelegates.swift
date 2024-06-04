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
            let carPlayMode = OAAppSettings.sharedManager()?.isCarPlayModeDefault.get() == true
                ? OAApplicationMode.getFirstAvailableNavigation()
                : OAAppSettings.sharedManager()?.carPlayMode.get()

            OAAppSettings.sharedManager()?.setApplicationModePref(carPlayMode, markAsLastUsed: false)
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
            OARootViewController.instance()?.mapPanel.didUpdateSpeedometer = { [weak self] in
                guard let self else { return }
                carPlayMapController?.configureSpeedometer()
            }
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
        OAAppSettings.sharedManager().setApplicationModePref(OAAppSettings.sharedManager().defaultApplicationMode.get(), markAsLastUsed: false)
        
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
