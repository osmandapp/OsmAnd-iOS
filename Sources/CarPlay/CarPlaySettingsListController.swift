//
//  CarPlaySettingsListController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 23.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CarPlay

@objcMembers
final class CarPlaySettingsListController: NSObject {
    private let interfaceController: CPInterfaceController
    private var listTemplate: CPListTemplate?
    private var mapModeController: CarPlayMapModeListController?

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        super.init()
    }

    func present() {
        let template = CPListTemplate(title: localizedString("shared_string_settings"), sections: [makeSection()])
        listTemplate = template
        
        interfaceController.pushTemplate(template, animated: true) { completed, error in
            if !completed || error != nil {
                NSLog("[CarPlay] push Settings failed: %@", String(describing: error))
            }
        }
    }

    private func makeSection() -> CPListSection {
        let mapMode = CPListItem(text: localizedString("map_mode"), detailText: CarPlayMapModeListController.currentTitle())
        mapMode.accessoryType = .disclosureIndicator
        mapMode.handler = { [weak self] _, completion in
            guard let self else {
                completion()
                return
            }
            let controller = CarPlayMapModeListController(
                interfaceController: self.interfaceController
            ) { [weak self] in
                self?.reloadSections()
            }
            self.mapModeController = controller
            controller.present()
            completion()
        }
        return CPListSection(items: [mapMode])
    }

    private func reloadSections() {
        listTemplate?.updateSections([makeSection()])
    }
}
