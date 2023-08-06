import CarPlay

final class CarPlayRootVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

final class DashboardCarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate, CPTemplateApplicationDashboardSceneDelegate {
    var dashboardVC = CarPlayRootVC()
    var mapVC: OAMapViewController?
    var window: UIWindow?
    
    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene, didConnect dashboardController: CPDashboardController, to window: UIWindow) {
        mapVC = OARootViewController.instance()?.mapPanel.mapViewController
        self.window = window
        if mapVC == nil {
            mapVC = OAMapViewController()
            OARootViewController.instance()?.mapPanel.setMap(mapVC)
        }
        dashboardVC.add(mapVC!)
        self.window?.rootViewController = dashboardVC
        OARootViewController.instance()?.mapPanel.onCarPlayConnected()
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
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        guard let mapVC, let window else { return }
        let widthOffset: CGFloat = 1 - (window.frame.width - max(window.safeAreaInsets.left, window.safeAreaInsets.right)) / mapVC.view.frame.width
        let heightOffset = 1 - (window.frame.height / mapVC.view.frame.height)
        mapVC.viewportX(1.0 - widthOffset, y: 1.0 - heightOffset)
        dashboardVC.add(mapVC)
        window.rootViewController = dashboardVC
    }
}
