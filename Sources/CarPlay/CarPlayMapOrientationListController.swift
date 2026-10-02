//
//  CarPlayMapOrientationListController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 30.09.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CarPlay

@objcMembers
final class CarPlayMapOrientationListController: OABaseCarPlayInterfaceController {
    private var listTemplate: CPListTemplate?

    override func present() {
        let template = CPListTemplate(title: localizedString("rotate_map_to"), sections: [makeSection()])
        listTemplate = template
        safePush(template, animated: true)
    }

    func currentTitle() -> String {
        currentMode().title
    }

    func reloadSections() {
        listTemplate?.updateSections([makeSection()])
    }

    private func currentMode() -> CompassMode {
        CompassMode.byValue(Int(OAAppSettings.sharedManager().rotateMap.get()))
    }

    private func makeSection() -> CPListSection {
        let current = currentMode()
        let items: [CPListItem] = CompassMode.allCases.map { mode in
            let item = CPListItem(
                text: mode.title,
                detailText: nil,
                image: icon(for: mode),
                accessoryImage: CarPlaySettingsUIHelper.checkmarkImage(isSelected: mode == current),
                accessoryType: .none
            )
            item.handler = { [weak self] _, completion in
                self?.select(mode)
                completion()
            }
            return item
        }
        return CPListSection(items: items)
    }

    private func icon(for mode: CompassMode) -> UIImage {
        switch mode {
        case .manuallyRotated: .icCustomDirectionManual
        case .movementDirection: .icCustomDirectionBearing
        case .compassDirection: .icCustomDirectionCompass
        case .northIsUp: .icCustomDirectionNorth
        }
    }

    private func select(_ mode: CompassMode) {
        OAAppSettings.sharedManager().rotateMap.set(Int32(mode.value))
        OAMapViewTrackingUtilities.instance().updateSettings()
        OARootViewController.instance()?.mapPanel.mapViewController.refreshMap()
        safePopTemplate(animated: true, completion: nil)
    }
}
