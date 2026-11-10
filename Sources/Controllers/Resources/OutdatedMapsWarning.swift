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
    func showAfterUpgrade() {
        // TODO: When the new search is on by default, remove the useSharedSearch check. If that happens after 5.5, set VERSION_5_5 in OsmAndAppImpl to that version. https://github.com/osmandapp/OsmAnd-iOS/issues/6134
        guard OAAppSettings.sharedManager().shouldShowOutdatedMapsWarning, OAAppSettings.sharedManager().useSharedSearch.get() else { return }
        OAAppSettings.sharedManager().shouldShowOutdatedMapsWarning = false
        DispatchQueue.global(qos: .utility).async {
            guard self.hasMapsWithoutSpatialSearch() else { return }
            DispatchQueue.main.async {
                self.show()
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
        guard let root = OARootViewController.instance(), root.navigationController?.visibleViewController === root else { return }
        let alert = UIAlertController(title: localizedString("outdated_maps_warning_title"), message: localizedString("outdated_maps_warning_descr"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("first_time_continue"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_update"), style: .default) { _ in
            self.openUpdates()
        })
        root.present(alert, animated: true)
    }
    
    private func openUpdates() {
        guard let controller = OADeepLinkBridge.mapsAndResourcesUpdatesViewController() else { return }
        OARootViewController.instance().navigationController?.pushViewController(controller, animated: true)
    }
}
