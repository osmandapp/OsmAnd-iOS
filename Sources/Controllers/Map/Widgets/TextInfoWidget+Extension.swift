//
//  TextInfoWidget+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 29.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension OATextInfoWidget {
    @objc
    func configureContextWidgetMenu() -> UIMenu? {
        enum ContextWidgetMenu {
            case addItemRight, addItemLeft, addItemAbove, addItemBelow, settings, delete
            
            var title: String {
                switch self {
                case .addItemRight: "add_widget_to_the_right"
                case .addItemLeft: "add_widget_to_the_left"
                case .addItemAbove: "add_widget_above"
                case .addItemBelow: "add_widget_below"
                case .settings: "shared_string_settings"
                case .delete: "shared_string_delete"
                }
            }
            
            var image: UIImage {
                switch self {
                case .addItemRight: .icCustomAddItemRight
                case .addItemLeft: .icCustomAddItemLeft
                case .addItemAbove: .icCustomAddItemAbove
                case .addItemBelow: .icCustomAddItemBelow
                case .settings: .icCustomSettingsOutlined
                case .delete: .icCustomTrashOutlined
                }
            }
        }
        
        func configureMenu() -> UIMenu? {
            if let widgetInfo = getInfo() ?? OAMapWidgetRegistry.sharedInstance().getWidgetInfo(byId: widgetType?.id ?? "") {
                let isPanelVertical = widgetInfo.widgetPanel.isPanelVertical
                let addGroup = UIMenu(options: .displayInline, children: [
                    createAction(for: isPanelVertical ? .addItemLeft : .addItemAbove, selectedWidget: widgetInfo.key),
                    createAction(for: isPanelVertical ? .addItemRight : .addItemBelow, selectedWidget: widgetInfo.key)
                ])
                let settingsGroup = UIMenu(options: .displayInline, children: [
                    createAction(for: .settings, selectedWidget: widgetInfo.key)
                ])
                let deleteGroup = UIMenu(options: .displayInline, children: [
                    createAction(for: .delete, selectedWidget: widgetInfo.key)
                ])
                return UIMenu(title: "", children: [addGroup, settingsGroup, deleteGroup])
            }
            return nil
        }
        
        func createAction(for menuItem: ContextWidgetMenu, selectedWidget: String) -> UIAction {
            return UIAction(title: localizedString(menuItem.title), image: menuItem.image) { [weak self] _ in
                guard let self else { return }
                switch menuItem {
                case .addItemRight, .addItemBelow:
                    showAddWidgetController(addToNext: true, selectedWidget: selectedWidget)
                case .addItemLeft, .addItemAbove:
                    showAddWidgetController(addToNext: false, selectedWidget: selectedWidget)
                case .settings:
                    showWidgetConfiguration()
                case .delete:
                    showDeleteWidgetAlert()
                }
            }
        }
        return configureMenu()
    }
    
    private func showAddWidgetController(addToNext: Bool, selectedWidget: String) {
        if let widgetInfo = getInfo() ?? OAMapWidgetRegistry.sharedInstance().getWidgetInfo(byId: widgetType?.id ?? "") {
            let vc = WidgetGroupListViewController()
            vc.widgetPanel = widgetInfo.widgetPanel
            vc.addToNext = addToNext
            vc.selectedWidget = selectedWidget
            OARootViewController.instance().navigationController?.present(UINavigationController(rootViewController: vc), animated: true)
        }
    }
    
    private func showWidgetConfiguration() {
        //   let widgetId = customId != null ? customId : widgetType.id;
        if let vc = WidgetConfigurationViewController(),
           let widgetInfo = getInfo() ?? OAMapWidgetRegistry.sharedInstance().getWidgetInfo(byId: widgetType?.id ?? "") {
            vc.selectedAppMode = OAAppSettings.sharedManager().applicationMode.get()
            vc.widgetInfo = widgetInfo
            vc.widgetPanel = widgetInfo.widgetPanel
            OARootViewController.instance().navigationController?.present(UINavigationController(rootViewController: vc), animated: true)
        }
    }

    private func showDeleteWidgetAlert() {
        let alert = UIAlertController(title: localizedString("delete_widget"),
                                      message: localizedString("delete_widget_description"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            if let widgetInfo = getInfo() ?? OAMapWidgetRegistry.sharedInstance().getWidgetInfo(byId: widgetType?.id ?? "") {
                let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
                widgetRegistry.enableDisableWidget(for: OAAppSettings.sharedManager().applicationMode.get(), widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))        
        OARootViewController.instance().navigationController?.present(alert, animated: true)
    }
}

extension OATextInfoWidget {
    @objc var widgetSizeStyle: EOAWidgetSizeStyle {
        guard widgetSizePref != nil else {
            return .medium
        }
        return widgetSizePref?.get(OAAppSettings.sharedManager().applicationMode.get()!) ?? .medium
    }
    
    func updateWith(style: EOAWidgetSizeStyle, appMode: OAApplicationMode) {
        refreshLayout()
        guard widgetSizeStyle != style else {
            return
        }
        widgetSizePref?.set(style, mode: appMode)
    }
}

extension Array where Element == OATextInfoWidget {
    func updateWithMostFrequentStyle(with appMode: OAApplicationMode) {
        var styleCounts: [EOAWidgetSizeStyle: Int] = [:]
        
        for widget in self {
            let style = widget.widgetSizeStyle
            styleCounts[style] = (styleCounts[style] ?? 0) + 1
        }
        guard let mostFrequentStyle = styleCounts.max(by: { $0.value < $1.value })?.key else {
            return
        }
        forEach { $0.updateWith(style: mostFrequentStyle, appMode: appMode) }
    }
}
