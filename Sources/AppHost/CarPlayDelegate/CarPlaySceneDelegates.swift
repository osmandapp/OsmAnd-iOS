import CarPlay
import CoreLocation

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    private var carPlayMapController: OACarPlayMapViewController?
    private var carPlayDashboardController: OACarPlayDashboardInterfaceController?
    private var windowToAttach: CPWindow?
    private var carPlayInterfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        print(#function)
        OsmAndApp.swiftInstance().carPlayActive = true
        windowToAttach = window
        carPlayInterfaceController = interfaceController
        
        NotificationCenter.default.addObserver(self, selector: #selector(configureScene), name: NSNotification.Name("kAppInitDone"), object: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        print(#function)
        
        OsmAndApp.swiftInstance().carPlayActive = false
        NotificationCenter
            .default
            .removeObserver(self, name: NSNotification.Name("kAppInitDone"), object: nil)
        OAAppSettings.sharedManager().setApplicationModePref(OAAppSettings.sharedManager().defaultApplicationMode.get(), markAsLastUsed: false)

        OARootViewController.instance().mapPanel.onCarPlayDisconnected { [weak self] in
            guard let self else { return }
            carPlayMapController?.detachFromCarPlayWindow()
            carPlayDashboardController = nil
            carPlayMapController?.navigationController?.popViewController(animated: true)
            window.rootViewController = nil
            carPlayMapController = nil
            windowToAttach = nil
            carPlayInterfaceController = nil
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        carPlayMapController?.detachFromCarPlayWindow()
        configureScene()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let str = URLContexts.first?.url.absoluteString else { return }
        
        if str.contains("search") {
            carPlayDashboardController?.openSearch()
        } else if str.contains("navigation") {
            carPlayDashboardController?.openNavigation()
        }
    }
    
    @objc private func configureScene() {
        guard let carPlayInterfaceController, let windowToAttach else { return }
        presentInCarPlay(interfaceController: carPlayInterfaceController, window: windowToAttach)
        let carPlayMode = OAAppSettings.sharedManager()?.isCarPlayModeDefault.get() == true
        ? OAApplicationMode.getFirstAvailableNavigation()
        : OAAppSettings.sharedManager()?.carPlayMode.get()

        OAAppSettings.sharedManager()?.setApplicationModePref(carPlayMode, markAsLastUsed: false)
    }
}

extension CarPlaySceneDelegate {
    func presentInCarPlay(interfaceController: CPInterfaceController, window: CPWindow) {
        if OAIAPHelper.sharedInstance().isCarPlayAvailable() {
            var mapVc = OARootViewController.instance()?.mapPanel.mapViewController
            if mapVc == nil {
                mapVc = OAMapViewController()
                OARootViewController.instance()?.mapPanel.setMap(mapVc)
            }
            
            carPlayMapController = OACarPlayMapViewController(carPlay: window, mapViewController: mapVc)
            window.rootViewController = carPlayMapController
            
            carPlayDashboardController = OACarPlayDashboardInterfaceController(interfaceController: interfaceController)
            carPlayDashboardController?.delegate = carPlayMapController
            carPlayDashboardController?.present()
            carPlayMapController?.delegate = carPlayDashboardController
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
}
