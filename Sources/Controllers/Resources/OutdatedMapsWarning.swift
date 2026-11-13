//
//  OutdatedMapsWarning.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 10.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class OutdatedMapsWarning: NSObject {
    private static var isChecking = false

    func showAfterUpgrade() {
        let settings = OAAppSettings.sharedManager()
        guard settings.shouldShowOutdatedMapsWarning, settings.useSharedSearch.get(), settings.useSpatialTextSearch.get(), !settings.shouldShowWhatsNewScreen, !AppEnvironment.isUITesting, !UIApplication.shared.isAnyCarPlaySceneActive, !Self.isChecking else { return }
        Self.isChecking = true
        DispatchQueue.global(qos: .utility).async {
            let needsWarning = self.hasMapsWithoutSpatialSearch()
            DispatchQueue.main.async {
                Self.isChecking = false
                if needsWarning {
                    self.show()
                } else {
                    settings.shouldShowOutdatedMapsWarning = false
                }
            }
        }
    }
    
    private func hasMapsWithoutSpatialSearch() -> Bool {
        OAObfFileList.travelAndMapFilePaths().contains { path in
            guard !path.hasSuffix(BINARY_TRAVEL_GUIDE_MAP_INDEX_EXT) else { return false }
            let resource = BinaryMapReaderResource(path: path)
            defer { resource.close() }
            guard let reader = resource.getShallowReader() else { return false }
            return !reader.isBasemap() && reader.containsPoiData() && !SpatialTextSearchAPI.companion.hasPoiTypesInNameIndex(reader: reader)
        }
    }
    
    private func show() {
        guard OAAppSettings.sharedManager().shouldShowOutdatedMapsWarning, !UIApplication.shared.isAnyCarPlaySceneActive, let root = OARootViewController.instance(), root.navigationController?.visibleViewController === root, root.viewIfLoaded?.window != nil, root.presentedViewController == nil else { return }
        let alert = UIAlertController(title: localizedString("outdated_maps_warning_title"), message: localizedString("outdated_maps_warning_descr"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("first_time_continue"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_update"), style: .default) { _ in
            self.openUpdates()
        })
        root.present(alert, animated: true) {
            OAAppSettings.sharedManager().shouldShowOutdatedMapsWarning = false
        }
    }
    
    private func openUpdates() {
        guard let controller = OADeepLinkBridge.mapsAndResourcesUpdatesViewController() else { return }
        OARootViewController.instance().navigationController?.pushViewController(controller, animated: true)
    }
}
