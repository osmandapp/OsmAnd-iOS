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
        guard !((nav.visibleViewController as? OAWebViewController)?.urlString?.lowercased() == url.lowercased()) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        guard let webVC = OAWebViewController(urlAndTitle: url, title: localizedString("help_what_is_new")) else {
            NSLog("[DeepLinkAppRouter] Failed to create OAWebViewController (url=%@)", url)
            return
        }
        
        nav.pushViewController(webVC, animated: true)
    }
    
    func openGlobalSettingsMain() {
        guard let nav = root.navigationController else { return }
        guard (nav.visibleViewController as? OAGlobalSettingsViewController)?.settingsType != EOAGlobalSettingsMain else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OAGlobalSettingsViewController(settingsType: EOAGlobalSettingsMain) else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openCloudScreen() {
        guard let nav = root.navigationController else { return }
        let isRegistered = OABackupHelper.sharedInstance().isRegistered()
        let current = nav.visibleViewController
        guard !((isRegistered && current is OACloudBackupViewController) || (!isRegistered && current is OACloudIntroductionViewController)) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        nav.pushViewController(isRegistered ? OACloudBackupViewController() : OACloudIntroductionViewController(), animated: true)
    }
    
    func openPlugins() {
        guard let nav = root.navigationController else { return }
        guard !(nav.visibleViewController is OAPluginsViewController) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        nav.pushViewController(OAPluginsViewController(), animated: true)
    }
    
    func openPlugin(product: OAProduct?) {
        guard let nav = root.navigationController, let product else { return }
        guard product.isPurchased() else {
            guard let nav = dismissAndPopToRoot() else { return }
            OAChoosePlanHelper.showChoosePlanScreen(with: product, navController: nav)
            return
        }
        
        guard (nav.visibleViewController as? OAPluginDetailsViewController)?.product.productIdentifier != product.productIdentifier else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OAPluginDetailsViewController(product: product) else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openHelp() {
        guard let nav = root.navigationController else { return }
        guard !(nav.visibleViewController is OAHelpViewController) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        nav.pushViewController(OAHelpViewController(), animated: true)
    }
    
    func openPlanRoute() {
        let mapViewController = root.mapPanel.mapViewController
        guard !(mapViewController.presentedViewController is InitialRoutePlanningBottomSheetViewController) else { return }
        dismissAndPopToRoot()
        InitialRoutePlanningBottomSheetViewController().present(in: mapViewController)
    }
    
    func openWidgetsList(panel: WidgetsPanel) {
        guard let nav = root.navigationController, let mapPanel = root.mapPanel else { return }
        mapPanel.loadViewIfNeeded()
        guard (nav.visibleViewController as? WidgetsListViewController)?.widgetPanel != panel else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        nav.pushViewController(WidgetsListViewController(widgetPanel: panel), animated: true)
    }
    
    func openMapSettings(screen: EMapSettingsScreen) {
        guard let mapPanel = root.mapPanel else { return }
        let current = mapPanel.children.last as? OAMapSettingsViewController
        let appData = OsmAndApp.swiftInstance()?.data
        switch screen {
        case .wikipedia:
            guard let wikiProduct = OAIAPHelper.sharedInstance().wiki else { return }
            guard wikiProduct.isPurchased() else {
                openChoosePlan(feature: wikiProduct.feature)
                return
            }
            let shouldEnableProduct = wikiProduct.disabled
            let shouldEnableWikipedia = !(appData?.wikipedia ?? false)
            let shouldRefreshScreen = shouldEnableProduct || shouldEnableWikipedia
            if shouldEnableProduct {
                OAIAPHelper.sharedInstance().enableProduct(wikiProduct.productIdentifier)
            }
            if shouldEnableWikipedia {
                (OAPluginsHelper.getPlugin(OAWikipediaPlugin.self) as? OAWikipediaPlugin)?.wikipediaChanged(true)
            }
            guard let current, current.settingsScreen == screen else { break }
            if shouldRefreshScreen {
                (current.screenObj as? MapSettingsWikipediaScreen)?.updateResources()
            }
            return
        case .overlay:
            guard let appData else { break }
            let shouldEnableOverlay = appData.overlayMapSource == nil
            if shouldEnableOverlay {
                if appData.lastOverlayMapSource == nil {
                    appData.lastOverlayMapSource = OAMapSource.getOsmAndOnlineTiles()
                }
                appData.overlayMapSource = appData.lastOverlayMapSource
            }
            guard let current, current.settingsScreen == screen else { break }
            if shouldEnableOverlay {
                (current.screenObj as? OAMapSettingsOverlayUnderlayScreen)?.setupInitialState()
                current.screenObj.setupView()
                current.screenObj.tblView?.reloadData()
            }
            return
        case .underlay:
            guard let appData else { break }
            let settings = OAAppSettings.sharedManager()
            let shouldShowSlider = !settings.getUnderlayOpacitySliderVisibility()
            let shouldEnableUnderlay = appData.underlayMapSource == nil
            if shouldShowSlider {
                settings.setUnderlayOpacitySliderVisibility(true)
            }
            if shouldEnableUnderlay {
                if appData.lastUnderlayMapSource == nil {
                    appData.lastUnderlayMapSource = OAMapSource.getOsmAndOnlineTiles()
                }
                appData.underlayMapSource = appData.lastUnderlayMapSource
            }
            guard let current, current.settingsScreen == screen else { break }
            if shouldShowSlider || shouldEnableUnderlay {
                (current.screenObj as? OAMapSettingsOverlayUnderlayScreen)?.setupInitialState()
                current.screenObj.setupView()
                current.screenObj.tblView?.reloadData()
            }
            return
        default:
            break
        }
        
        openMapSettingsDashboard(screen: screen, mapPanel: mapPanel)
    }
    
    func openDestinations() {
        guard let nav = root.navigationController else { return }
        guard !(nav.visibleViewController is DestinationsListViewController) else { return }
        guard let nav = dismissAndPopToRoot(), let controller = DestinationsListViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openDestinationsDirectionAppearance() {
        guard let nav = root.navigationController else { return }
        guard !(nav.visibleViewController is OADirectionAppearanceViewController) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        nav.pushViewController(OADirectionAppearanceViewController(), animated: true)
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
        guard !OADeepLinkBridge.isMapsAndResourcesController(nav.visibleViewController) else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openMapsAndResourcesLocal() {
        guard let nav = root.navigationController else { return }
        guard !OADeepLinkBridge.isMapsAndResourcesLocalController(nav.visibleViewController) else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesLocalViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openMapsAndResourcesUpdates() {
        guard let nav = root.navigationController else { return }
        guard !OADeepLinkBridge.isMapsAndResourcesUpdatesController(nav.visibleViewController) else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OADeepLinkBridge.mapsAndResourcesUpdatesViewController() else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openChoosePlan(feature: OAFeature?) {
        guard let nav = root.navigationController else { return }
        let target = feature ?? OAFeature.osmand_CLOUD()
        guard !((nav.visibleViewController as? OAChoosePlanViewController)?.selectedFeature.isEqual(target) ?? false) else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        OAChoosePlanHelper.showChoosePlanScreen(with: target, navController: nav)
    }
    
    func openCustomButtonsAddAction() {
        guard let nav = root.navigationController else { return }
        guard !(nav.visibleViewController is CustomMapButtonsViewController) else {
            let current = nav.visibleViewController as! CustomMapButtonsViewController
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
        
        nav.pushViewController(ExternalSettingsWriteToTrackSettingsViewController(applicationMode: OAAppSettings.sharedManager().applicationMode.get()), animated: false)
    }
    
    func openTripRecordingSettings(appMode: OAApplicationMode) {
        guard let nav = root.navigationController else { return }
        guard !((nav.visibleViewController as? OATripRecordingSettingsViewController)?.settingsType == kTripRecordingSettingsScreenGeneral && (nav.visibleViewController as? OATripRecordingSettingsViewController)?.appMode.stringKey == appMode.stringKey) else { return }
        guard let nav = dismissAndPopToRoot(), let controller = OATripRecordingSettingsViewController(settingsType: kTripRecordingSettingsScreenGeneral, applicationMode: appMode) else { return }
        nav.pushViewController(controller, animated: true)
    }
    
    func openDistanceByTapSettings(appMode: OAApplicationMode) {
        guard let nav = root.navigationController else { return }
        guard (nav.visibleViewController as? DistanceByTapViewController)?.appMode.stringKey != appMode.stringKey else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        let controller = DistanceByTapViewController()
        controller.appMode = appMode
        nav.pushViewController(controller, animated: true)
    }
    
    func openSpeedometerSettings(appMode: OAApplicationMode) {
        guard let nav = root.navigationController else { return }
        guard (nav.visibleViewController as? SpeedometerWidgetSettingsViewController)?.appMode.stringKey != appMode.stringKey else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        let controller = SpeedometerWidgetSettingsViewController()
        controller.appMode = appMode
        nav.pushViewController(controller, animated: true)
    }
    
    func openNavigationScreen(appMode: OAApplicationMode) {
        guard let mapPanel = root.mapPanel else { return }
        guard !(mapPanel.isRouteInfoVisible() && OARoutingHelper.sharedInstance()?.getAppMode().stringKey == appMode.stringKey) else { return }
        dismissAndPopToRoot()
        mapPanel.showRouteInfo(true, appMode: appMode)
    }
    
    private func openMapSettingsDashboard(screen: EMapSettingsScreen, mapPanel: OAMapPanelViewController) {
        guard (mapPanel.children.last as? OAMapSettingsViewController)?.settingsScreen != screen else { return }
        dismissAndPopToRoot()
        mapPanel.mapSettingsButtonClick("")
        guard screen != .main else { return }
        guard let current = mapPanel.children.last as? OAMapSettingsViewController, let parent = current.parent, let controller = OAMapSettingsViewController(settingsScreen: screen) else { return }
        controller.show(parent, parentViewController: current, animated: true)
    }
    
    @discardableResult private func dismissAndPopToRoot() -> UINavigationController? {
        if let mapPanel = root.mapPanel, mapPanel.isDashboardVisible() {
            mapPanel.closeDashboard(withDuration: .zero)
        }
        
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
