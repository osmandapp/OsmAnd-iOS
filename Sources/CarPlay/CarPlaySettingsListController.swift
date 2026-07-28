//
//  CarPlaySettingsListController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 23.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CarPlay

@objcMembers
final class CarPlaySettingsListController: OABaseCarPlayInterfaceController {
    private var listTemplate: CPListTemplate?
    private var mapModeController: CarPlayMapModeListController?

    override func present() {
        let template = CPListTemplate(title: localizedString("shared_string_settings"), sections: [makeSection()])
        listTemplate = template
        safePush(template, animated: true)
    }

    private func makeSection() -> CPListSection {
        if mapModeController == nil {
            mapModeController = CarPlayMapModeListController(
                interfaceController: interfaceController
            ) { [weak self] in
                self?.reloadSections()
            }
        }
        let mapMode = CPListItem(text: localizedString("map_mode"), detailText: mapModeController?.currentTitle())
        mapMode.accessoryType = .disclosureIndicator
        mapMode.handler = { [weak self] _, completion in
            guard let self else {
                completion()
                return
            }
            self.mapModeController?.present()
            completion()
        }
        return CPListSection(items: [mapMode])
    }

    private func reloadSections() {
        listTemplate?.updateSections([makeSection()])
    }
}
