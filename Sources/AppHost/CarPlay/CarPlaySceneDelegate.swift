import CarPlay
import CoreLocation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    private var carPlayMapController: OACarPlayMapViewController?
    private var carPlayDashboardController: OACarPlayDashboardInterfaceController?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        print(#function)
        
        OsmAndApp.swiftInstance().carPlayActive = true
        
        if let appDelegate = UIApplication.shared.delegate as? OAAppDelegate,
           !appDelegate.appInitDone, !appDelegate.appInitializing {
            appDelegate.initialize()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.presentInCarPlay(interfaceController: interfaceController, window: window)
            }
            return
        }

        self.presentInCarPlay(interfaceController: interfaceController, window: window)

        let carPlayMode = OAAppSettings.sharedManager()?.isCarPlayModeDefault.get() == true
            ? OAApplicationMode.getFirstAvailableNavigation()
            : OAAppSettings.sharedManager()?.carPlayMode.get()

        OAAppSettings.sharedManager()?.setApplicationModePref(carPlayMode, markAsLastUsed: false)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        print(#function)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        print(#function)
        
        OsmAndApp.swiftInstance().carPlayActive = false
        OAAppSettings.sharedManager() .setApplicationModePref(OAAppSettings.sharedManager().defaultApplicationMode.get(), markAsLastUsed: false)

        OARootViewController.instance().mapPanel.onCarPlayDisconnected { [weak self] in
            guard let self else { return }
            carPlayMapController?.detachFromCarPlayWindow()
            carPlayDashboardController = nil
            carPlayMapController?.navigationController?.popViewController(animated: true)
            window.rootViewController = nil
            carPlayMapController = nil
        }
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        print(#function)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect navigationAlert: CPNavigationAlert) {
        print(#function)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect maneuver: CPManeuver) {
        print(#function)
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
