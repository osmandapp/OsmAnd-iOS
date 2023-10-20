import CarPlay

final class DashboardCarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate, CPTemplateApplicationDashboardSceneDelegate {
    var dashboardVC: OACarPlayMapDashboardViewController?
    var mapVC: OAMapViewController?
    var window: UIWindow?
    
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didConnect dashboardController: CPDashboardController, to window: UIWindow) {
        debugPrint("[CarPlay] templateApplicationDashboardScene didConnect")
        self.window = window
        let nightMode = templateApplicationDashboardScene.dashboardWindow.traitCollection.userInterfaceStyle == .dark
        dashboardController.shortcutButtons = [
            CPDashboardButton(titleVariants: [localizedString("shared_string_navigation")], subtitleVariants: [""], image: UIImage(named: nightMode ? "ic_carplay_navigation_night" : "ic_carplay_navigation")!, handler: { _ in
                guard let url = URL(string: "osmandmaps://navigation") else { return }
                templateApplicationDashboardScene.open(url, options: nil, completionHandler: nil)
            }),
            CPDashboardButton(titleVariants: [localizedString("address_search_desc")], subtitleVariants: [""], image: UIImage(named: nightMode ? "ic_carplay_search_night" : "ic_carplay_search")!, handler: { _ in
                guard let url = URL(string: "osmandmaps://search") else { return }
                templateApplicationDashboardScene.open(url, options: nil, completionHandler: nil)
            })]
    }
    
    private func configureScene() {
        mapVC = OARootViewController.instance()?.mapPanel.mapViewController
        if mapVC == nil {
            mapVC = OAMapViewController()
            OARootViewController.instance()?.mapPanel.setMap(mapVC)
        }
        if let window, let mapVC {
            let widthOffset: CGFloat = 1 - (window.frame.width - max(window.safeAreaInsets.left, window.safeAreaInsets.right)) / mapVC.view.frame.width
            let heightOffset = 1 - (window.frame.height / mapVC.view.frame.height)
            mapVC.setViewportScaleX(1.0 - widthOffset, y: 1.0 - heightOffset)
            dashboardVC = OACarPlayMapDashboardViewController(carPlay: mapVC)
            dashboardVC?.attachMapToWindow()
            self.window?.rootViewController = dashboardVC
            OARootViewController.instance()?.mapPanel.onCarPlayConnected()
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        debugPrint("[CarPlay] templateApplicationDashboardScene sceneWillEnterForeground")
        configureScene()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        debugPrint("[CarPlay] templateApplicationDashboardScene sceneWillResignActive")
    }
    
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didDisconnect dashboardController: CPDashboardController, from window: UIWindow) {
        debugPrint("[CarPlay] templateApplicationDashboardScene didDisconnect")
        dashboardVC?.detachFromCarPlayWindow()
        mapVC = nil
        self.window = nil
        OARootViewController.instance()?.mapPanel.detachFromCarPlayWindow()
    }
}
