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
    
    private var srtmPlugin: OASRTMPlugin? {
        OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin
    }
    
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
        guard !(root.presentedViewController is InitialRoutePlanningBottomSheetViewController) else { return }
        dismissAndPopToRoot { [weak self] _ in
            guard let self else { return }
            guard !(self.root.presentedViewController is InitialRoutePlanningBottomSheetViewController) else { return }
            InitialRoutePlanningBottomSheetViewController().present(in: self.root)
        }
    }
    
    func openWidgetsList(panel: WidgetsPanel) {
        guard let nav = root.navigationController, let mapPanel = root.mapPanel else { return }
        mapPanel.loadViewIfNeeded()
        guard (nav.visibleViewController as? WidgetsListViewController)?.widgetPanel != panel else { return }
        guard let nav = dismissAndPopToRoot() else { return }
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        nav.pushViewController(WidgetsListViewController(widgetPanel: panel,
                                                         screenLayoutMode: .default(forAppMode: appMode)),
                               animated: true)
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
    
    func openMyPlaces(tab: MyPlacesContainerViewController.Tab) {
        guard let nav = root.navigationController else { return }
        if let myPlaces = nav.visibleViewController as? MyPlacesContainerViewController {
            if myPlaces.availableTabs.contains(tab) {
                selectMyPlacesTab(tab, in: myPlaces)
                myPlaces.switchToWithSegmentControl(tab: tab)
            }
            return
        }
        
        let canOpenMyPlaces = tab == .favorites || tab == .tracks || (tab == .osm && OAIAPHelper.sharedInstance().osmEditing.isActive())
        guard let nav = dismissAndPopToRoot(), canOpenMyPlaces else { return }
        let myPlaces = MyPlacesContainerViewController()
        myPlaces.loadViewIfNeeded()
        selectMyPlacesTab(tab, in: myPlaces)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            guard let mapPanel = self.root.mapPanel else { return }
            if !OAApplicationMode.values().contains(where: { $0.stringKey == appMode.stringKey }) {
                OAApplicationMode.changeProfileAvailability(appMode, isSelected: true)
            }
            
            guard !(mapPanel.isRouteInfoVisible() && OARoutingHelper.sharedInstance().getAppMode().stringKey == appMode.stringKey) else { return }
            dismissAndPopToRoot()
            mapPanel.showRouteInfo(true, appMode: appMode)
        }
    }
    
    func openSearch(query: String?) {
        guard let mapPanel = root.mapPanel else { return }
        dismissAndPopToRoot()
        mapPanel.openSearch(nil, location: nil, searchQuery: query)
    }
    
    func openSearch(categoryKey: String) -> Bool {
        guard let mapPanel = root.mapPanel, let filter = poiFilter(forKey: categoryKey, onlyTopDefined: false) else {
            NSLog("[DeepLinkAppRouter] Unknown search category: %@", categoryKey)
            return false
        }
        
        dismissAndPopToRoot()
        mapPanel.openSearch(filter, location: nil)
        return true
    }
    
    func openPoiOverlay(categoryKey: String) -> Bool {
        guard let filter = poiFilter(forKey: categoryKey, onlyTopDefined: true) else {
            NSLog("[DeepLinkAppRouter] Unknown POI overlay category: %@", categoryKey)
            return false
        }
        
        switchToBrowseProfile()
        guard let filtersHelper = OAPOIFiltersHelper.sharedInstance() else { return false }
        if !filtersHelper.isPoiFilterSelected(filter) {
            if filter.isStandardFilter {
                filter.removeUnsavedFilterByName()
            }
            filtersHelper.addSelectedPoiFilter(filter)
            root.mapPanel?.mapViewController.updatePoiLayer()
        }
        showMapSettings(screen: .POI)
        return true
    }
    
    func openTopography() {
        guard activateProduct(OAIAPHelper.sharedInstance().srtm) else { return }
        switchToBrowseProfile()
        if let plugin = srtmPlugin, !plugin.isTerrainLayerEnabled() {
            plugin.setTerrainLayerEnabled(true)
        }
        showMapSettings(screen: .terrain)
    }
    
    func openContourLines() {
        guard activateProduct(OAIAPHelper.sharedInstance().srtm) else { return }
        switchToBrowseProfile()
        if let styleSettings = OAMapStyleSettings.sharedInstance(),
           let parameter = styleSettings.getParameter(CONTOUR_LINES),
           parameter.value.isEmpty || parameter.value == "disabled" {
            parameter.value = OAAppSettings.sharedManager().contourLinesZoom.get()
            styleSettings.save(parameter)
        }
        showMapSettings(screen: .contourLines)
    }
    
    func open3DBuildings() {
        switchToBrowseProfile()
        if let plugin = srtmPlugin, !plugin.is3dMapObjectsEnabled() {
            plugin.set3dMapObjectsEnabled(true)
        }
        showMapSettings(screen: .buildings3DVisibility)
    }
    
    func openGlobeView() {
        switchToBrowseProfile()
        let settings = OAAppSettings.sharedManager()
        if !settings.sphericalMap.get() {
            settings.sphericalMap.set(true)
            OsmAndApp.swiftInstance()?.mapSettingsChangeObservable.notifyEvent()
        }
        showMapSettings(screen: .main)
    }
    
    func openRouteType(key: String) -> Bool {
        guard let routeType = DeepLinkRouteType(rawValue: key) else {
            NSLog("[DeepLinkAppRouter] Unknown route type: %@", key)
            return false
        }
        
        if routeType == .ski {
            guard activateProduct(OAIAPHelper.sharedInstance().skiMap) else { return true }
        }
        switchToBrowseProfile()
        if let requiredStyle = routeType.requiredStyle(styleSettings: OAMapStyleSettings.sharedInstance()) {
            guard applyMapStyle(name: requiredStyle) else { return false }
        }
        routeType.enable()
        if let detailsParameter = routeType.detailsParameter {
            showMapSettings(screen: .routes, param: detailsParameter)
        } else {
            showMapSettings(screen: .main)
        }
        return true
    }
    
    func openMapStyle(key: String) -> Bool {
        guard let mapStyle = DeepLinkMapStyle(rawValue: key) else {
            NSLog("[DeepLinkAppRouter] Unknown map style: %@", key)
            return false
        }
        
        if let product = mapStyle.requiredProduct {
            guard activateProduct(product) else { return true }
        }
        switchToBrowseProfile()
        guard applyMapStyle(name: mapStyle.styleName) else { return false }
        showMapSettings(screen: .mapType)
        return true
    }
    
    private func poiFilter(forKey key: String, onlyTopDefined: Bool) -> OAPOIUIFilter? {
        guard let filtersHelper = OAPOIFiltersHelper.sharedInstance() else { return nil }
        if key == "all" {
            return filtersHelper.getShowAllPOIFilter()
        }
        
        var poiKey = key.replacingOccurrences(of: "-", with: "_")
        // The POI type key is misspelled in poi_types.xml, keep the URL spelled correctly
        if poiKey == "accommodation" {
            poiKey = "accomodation"
        }
        let filterId = STD_PREFIX + poiKey
        if onlyTopDefined {
            return filtersHelper.getTopDefinedPoiFilters().first { $0.filterId == filterId }
        }
        return filtersHelper.getFilterById(filterId)
    }
    
    private func activateProduct(_ product: OAProduct?) -> Bool {
        guard let product else { return false }
        guard product.isPurchased() else {
            if let nav = dismissAndPopToRoot() {
                OAChoosePlanHelper.showChoosePlanScreen(with: product, navController: nav)
            }
            return false
        }
        
        if product.disabled {
            OAIAPHelper.sharedInstance().enableProduct(product.productIdentifier)
        }
        return true
    }
    
    private func switchToBrowseProfile() {
        let settings = OAAppSettings.sharedManager()
        guard settings.applicationMode.get().stringKey != OAApplicationMode.default().stringKey else { return }
        settings.setApplicationModePref(OAApplicationMode.default())
    }
    
    private func applyMapStyle(name: String) -> Bool {
        guard let appData = OsmAndApp.swiftInstance()?.data,
              let mapSource = OADeepLinkBridge.offlineMapSource(withStyleName: name) else {
            NSLog("[DeepLinkAppRouter] Map style is not available: %@", name)
            return false
        }
        
        guard appData.lastMapSource != mapSource else { return true }
        if !mapSource.resourceId.hasPrefix("skimap"),
           let styleSettings = OAMapStyleSettings.sharedInstance(),
           let pisteRoutes = styleSettings.getParameter(PISTE_ROUTES_ATTR),
           pisteRoutes.value != "false" {
            pisteRoutes.value = "false"
            styleSettings.save(pisteRoutes)
        }
        appData.lastMapSource = mapSource
        appData.prevOfflineSource = mapSource
        OAAppSettings.sharedManager().renderer.set(mapSource.name)
        return true
    }
    
    private func showMapSettings(screen: EMapSettingsScreen, param: String? = nil) {
        guard let mapPanel = root.mapPanel else { return }
        if param == nil, let current = mapPanel.children.last as? OAMapSettingsViewController, current.settingsScreen == screen {
            current.screenObj.setupView()
            current.screenObj.tblView?.reloadData()
            return
        }
        
        openMapSettingsDashboard(screen: screen, param: param, mapPanel: mapPanel)
    }
    
    private func openMapSettingsDashboard(screen: EMapSettingsScreen, param: String? = nil, mapPanel: OAMapPanelViewController) {
        guard param != nil || (mapPanel.children.last as? OAMapSettingsViewController)?.settingsScreen != screen else { return }
        dismissAndPopToRoot()
        mapPanel.mapSettingsButtonClick("")
        guard screen != .main else { return }
        let controller = param.flatMap { OAMapSettingsViewController(settingsScreen: screen, param: $0) } ?? OAMapSettingsViewController(settingsScreen: screen)
        guard let current = mapPanel.children.last as? OAMapSettingsViewController, let parent = current.parent, let controller else { return }
        controller.show(parent, parentViewController: current, animated: true)
    }
    
    @discardableResult private func dismissAndPopToRoot(completion: ((UINavigationController) -> Void)? = nil) -> UINavigationController? {
        guard let nav = prepareRootNavigationTransition() else { return nil }
        if let completion {
            nav.dismiss(animated: false) {
                nav.popToRootViewController(animated: false)
                completion(nav)
            }
        } else {
            nav.dismiss(animated: false)
            nav.popToRootViewController(animated: false)
        }
        
        return nav
    }
    
    private func prepareRootNavigationTransition() -> UINavigationController? {
        if let mapPanel = root.mapPanel, mapPanel.isDashboardVisible() {
            mapPanel.closeDashboard(withDuration: .zero)
        }
        
        guard let nav = root.navigationController else { return nil }
        return nav
    }
    
    private func selectMyPlacesTab(_ tab: MyPlacesContainerViewController.Tab, in controller: MyPlacesContainerViewController) {
        controller.selectedTab = tab
    }
}

private enum DeepLinkRouteType: String {
    case cycle
    case mtb
    case hiking
    case alpineHiking = "alpine-hiking"
    case travel
    case ski
    case horse
    case whitewater
    case running
    case fitness
    case dirtbike
    case climbing
    
    var detailsParameter: String? {
        switch self {
        case .cycle:
            return SHOW_CYCLE_ROUTES_ATTR
        case .mtb:
            return SHOW_MTB_ROUTES
        case .hiking:
            return HIKING_ROUTES_OSMC_ATTR
        case .alpineHiking:
            return SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES
        case .travel:
            return TRAVEL_ROUTES
        default:
            return nil
        }
    }
    
    private var booleanParameter: String? {
        switch self {
        case .alpineHiking:
            return ALPINE_HIKING_ATTR
        case .ski:
            return PISTE_ROUTES_ATTR
        case .whitewater:
            return WHITE_WATER_SPORTS_ATTR
        case .fitness:
            return SHOW_FITNESS_TRAILS_ATTR
        case .dirtbike:
            return DIRTBIKE_ROUTES_ATTR
        case .climbing:
            return CLIMBING_ROUTES
        default:
            return nil
        }
    }
    
    private var quickAction: BaseRouteQuickAction? {
        switch self {
        case .cycle:
            return ShowHideCycleRoutesAction()
        case .mtb:
            return ShowHideMtbRoutesAction()
        case .hiking:
            return ShowHideHikingRoutesAction()
        case .horse:
            return ShowHideHorseRoutesAction()
        case .running:
            return ShowHideRunningRoutesAction()
        default:
            return nil
        }
    }
    
    // Name of the map style to switch to when the current style can't show this route type
    func requiredStyle(styleSettings: OAMapStyleSettings?) -> String? {
        switch self {
        case .ski:
            let resourceId = OsmAndApp.swiftInstance()?.data.lastMapSource?.resourceId ?? ""
            return resourceId.hasPrefix("skimap") ? nil : WINTER_SKI_RENDER
        case .alpineHiking:
            return styleSettings?.getParameter(ALPINE_HIKING_ATTR) == nil ? DEFAULT_RENDER : nil
        default:
            return nil
        }
    }
    
    func enable() {
        if let action = quickAction {
            if !action.isEnabled() {
                action.execute()
            }
            return
        }
        
        guard let booleanParameter,
              let styleSettings = OAMapStyleSettings.sharedInstance(),
              let parameter = styleSettings.getParameter(booleanParameter),
              parameter.value != "true" else { return }
        parameter.value = "true"
        styleSettings.save(parameter)
    }
}

private enum DeepLinkMapStyle: String {
    case `default`
    case touring
    case topo
    case offroad
    case osmCarto = "osm-carto"
    case unirs
    case lightrs
    case nautical
    case marine
    case desert
    case snowmobile
    case winterSki = "winter-ski"
    
    var styleName: String {
        switch self {
        case .default:
            return DEFAULT_RENDER
        case .touring:
            return TOURING_VIEW
        case .topo:
            return TOPO_RENDER
        case .offroad:
            return OFFROAD_RENDER
        case .osmCarto:
            return OSM_CARTO_RENDER
        case .unirs:
            return UNIRS_RENDER
        case .lightrs:
            return LIGHTRS_RENDER
        case .nautical:
            return NAUTICAL_RENDER
        case .marine:
            return MARINE_RENDER
        case .desert:
            return DESERT_RENDER
        case .snowmobile:
            return SNOWMOBILE_RENDER
        case .winterSki:
            return WINTER_SKI_RENDER
        }
    }
    
    // Same rule as the Map type screen: only Winter and ski is hidden without its plugin
    var requiredProduct: OAProduct? {
        self == .winterSki ? OAIAPHelper.sharedInstance().skiMap : nil
    }
}
