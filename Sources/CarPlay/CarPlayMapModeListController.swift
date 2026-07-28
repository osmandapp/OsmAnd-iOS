//
//  CarPlayMapModeListController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 23.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CarPlay

@objcMembers
final class CarPlayMapModeListController: OABaseCarPlayInterfaceController {
    private static let modes: [DayNightMode] = [.appTheme, .day, .night, .auto]
    private let onModeChanged: (() -> Void)?

    init(interfaceController: CPInterfaceController, onModeChanged: (() -> Void)? = nil) {
        self.onModeChanged = onModeChanged
        super.init(interfaceController: interfaceController)
    }

    override func present() {
        let template = CPListTemplate(title: localizedString("map_mode"), sections: [makeSection()])
        safePush(template, animated: true)
    }
    
    func currentTitle() -> String {
        let mode = DayNightMode(rawValue: OAAppSettings.sharedManager().carPlayMapAppearanceMode.get()) ?? .appTheme
        return title(for: mode)
    }
    
    private func title(for mode: DayNightMode) -> String {
        switch mode {
        case .appTheme:
            return localizedString("carplay_map_mode_vehicle_appearance")
        case .day, .night, .auto:
            return mode.title
        }
    }

    private func makeSection() -> CPListSection {
        let current = DayNightMode(
            rawValue: OAAppSettings.sharedManager().carPlayMapAppearanceMode.get()
        )
        let items: [CPListItem] = Self.modes.map { mode in
            let checkmark: UIImage? = mode == current ? .icCheckmarkDefault : nil
            
            let item = CPListItem(
                text: title(for: mode),
                detailText: nil,
                image: mapModeIcon(for: mode),
                accessoryImage: checkmark,
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
    
    private func mapModeIcon(for mode: DayNightMode) -> UIImage? {
        if mode == .appTheme {
            return .icCustomMapModeVehicle
        } else {
            return .templateImageNamed(mode.iconName)
        }
    }

    private func select(_ mode: DayNightMode) {
        OAAppSettings.sharedManager().carPlayMapAppearanceMode.set(mode.rawValue)
        CarPlayService.shared.applyCarPlayMapAppearance()
        onModeChanged?()
        safePopTemplate(animated: true, completion: nil)
    }
}
