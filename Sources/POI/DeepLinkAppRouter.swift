//
//  DeepLinkAppRouter.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class DeepLinkAppRouter: NSObject {
    private let root: OARootViewController
    
    init(rootViewController: OARootViewController) {
        self.root = rootViewController
        super.init()
    }
    
    func openMainScreen() {
        dismissAndPopToRoot()
        root.mapPanel.closeRouteInfo()
    }
    
    func openLastReleaseNotes() {
        guard !(root.presentedViewController is OAWhatsNewBottomSheetViewController) else { return }
        OAWhatsNewBottomSheetViewController().present(in: root)
    }
    
    func openWhatsNew() {
        guard let nav = root.navigationController else { return }
        let url = kDocsLatestVersion.localizedURLIfAvailable()
        if let web = nav.visibleViewController as? OAWebViewController, let current = web.urlString?.lowercased(), current == url.lowercased() {
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        guard let webVC = OAWebViewController(urlAndTitle: url, title: localizedString("help_what_is_new")) else {
            NSLog("[DeepLinkAppRouter] Failed to create OAWebViewController (url=%@)", url)
            return
        }
        
        nav.pushViewController(webVC, animated: true)
    }
    
    func openGlobalSettingsMain() {
        guard let nav = root.navigationController else { return }
        if let current = nav.visibleViewController as? OAGlobalSettingsViewController, current.settingsType == EOAGlobalSettingsMain {
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let controller = OAGlobalSettingsViewController(settingsType: EOAGlobalSettingsMain) else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openCloudScreen() {
        guard let nav = root.navigationController else { return }
        let isRegistered = OABackupHelper.sharedInstance().isRegistered()
        let current = nav.visibleViewController
        if isRegistered && current is OACloudBackupViewController {
            return
        }
        
        if !isRegistered && current is OACloudIntroductionViewController {
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        let controller: UIViewController = isRegistered ? OACloudBackupViewController() : OACloudIntroductionViewController()
        nav.pushViewController(controller, animated: true)
    }
    
    func openHelp() {
        guard let nav = root.navigationController else { return }
        if nav.visibleViewController is OAHelpViewController {
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        let controller = OAHelpViewController()
        nav.pushViewController(controller, animated: true)
    }
    
    func openPlanRoute() {
        let mapViewController = root.mapPanel.mapViewController
        if mapViewController.presentedViewController is InitialRoutePlanningBottomSheetViewController {
            return
        }
        
        dismissAndPopToRoot()
        InitialRoutePlanningBottomSheetViewController().present(in: mapViewController)
    }
    
    func openDestinations() {
        guard let nav = root.navigationController else { return }
        if nav.visibleViewController is DestinationsListViewController {
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let controller = DestinationsListViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openDestinationsDirectionAppearance() {
        guard let nav = root.navigationController else { return }
        if nav.visibleViewController is OADirectionAppearanceViewController {
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        let controller = OADirectionAppearanceViewController()
        nav.pushViewController(controller, animated: true)
    }
    
    func openMyPlaces(tabClass: UIViewController.Type) {
        guard let nav = root.navigationController else { return }
        if let myPlaces = nav.visibleViewController as? OAMyPlacesTabBarViewController {
            selectMyPlacesTab(tabClass, in: myPlaces)
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let myPlaces = UIStoryboard(name: "MyPlaces", bundle: nil).instantiateInitialViewController() as? OAMyPlacesTabBarViewController else { return }
        myPlaces.loadViewIfNeeded()
        guard selectMyPlacesTab(tabClass, in: myPlaces) else { return }
        nav.pushViewController(myPlaces, animated: true)
    }
    
    func openMapsAndResources() {
        guard let nav = root.navigationController else { return }
        if OADeepLinkBridge.isMapsAndResourcesController(nav.visibleViewController) {
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openMapsAndResourcesLocal() {
        guard let nav = root.navigationController else { return }
        if OADeepLinkBridge.isMapsAndResourcesLocalController(nav.visibleViewController) {
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesLocalViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openMapsAndResourcesUpdates() {
        guard let nav = root.navigationController else { return }
        if OADeepLinkBridge.isMapsAndResourcesUpdatesController(nav.visibleViewController) {
            return
        }
        
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesUpdatesViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openChoosePlan(feature: OAFeature?) {
        guard let nav = root.navigationController else { return }
        let target = feature ?? OAFeature.osmand_CLOUD()
        if let vc = nav.visibleViewController as? OAChoosePlanViewController, vc.selectedFeature.isEqual(target) {
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        OAChoosePlanHelper.showChoosePlanScreen(with: target, navController: nav)
    }
    
    func openCustomButtonsAddAction() {
        guard let nav = root.navigationController else { return }
        if let current = nav.visibleViewController as? CustomMapButtonsViewController {
            DispatchQueue.main.async {
                current.onRightNavbarButtonPressed()
            }
            
            return
        }
        
        guard let nav = dismissAndPopToRoot() else { return }
        let vc = CustomMapButtonsViewController()
        nav.pushViewController(vc, animated: false)
        DispatchQueue.main.async {
            vc.onRightNavbarButtonPressed()
        }
    }
    
    func openExternalSensorsRecording() {
        guard let nav = root.navigationController, !(nav.visibleViewController is ExternalSettingsWriteToTrackSettingsViewController) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        guard let product = OAIAPHelper.sharedInstance().product(kInAppId_Addon_External_Sensors) else {
            root.requestProducts(withProgress: false, reload: false)
            OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.sensors(), navController: nav)
            return
        }
        
        guard product.isPurchased() else {
            OAChoosePlanHelper.showChoosePlanScreen(with: product, navController: nav)
            return
        }
        
        if product.disabled {
            OAIAPHelper.sharedInstance().enableProduct(product.productIdentifier)
        }
        
        let controller = ExternalSettingsWriteToTrackSettingsViewController(applicationMode: OAAppSettings.sharedManager().applicationMode.get())
        nav.pushViewController(controller, animated: false)
    }
    
    @discardableResult private func dismissAndPopToRoot() -> UINavigationController? {
        guard let nav = root.navigationController else { return nil }
        nav.dismiss(animated: false)
        nav.popToRootViewController(animated: false)
        return nav
    }
    
    @discardableResult private func selectMyPlacesTab(_ tabClass: UIViewController.Type, in controller: UITabBarController) -> Bool {
        guard let viewControllers = controller.viewControllers, let targetIndex = viewControllers.firstIndex(where: { $0.isKind(of: tabClass) }) else { return false }
        controller.selectedIndex = targetIndex
        return true
    }
}
