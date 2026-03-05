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
}
