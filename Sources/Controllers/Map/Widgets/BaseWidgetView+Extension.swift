//
//  BaseWidgetView+Extension.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 14.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension OABaseWidgetView {
    
    @objc
    func configureContextMenu(addGroup: UIMenu, settingsGroup: UIMenu, deleteGroup: UIMenu) -> UIMenu {
        UIMenu(title: "", children: [addGroup, settingsGroup, deleteGroup])
    }
    
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
            guard let widgetInfo = getWidgetInfo() else {
                return nil
            }
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
            return configureContextMenu(addGroup: addGroup, settingsGroup: settingsGroup, deleteGroup: deleteGroup)
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
        guard let widgetInfo = getWidgetInfo() else { return }
        
        let vc = WidgetGroupListViewController()
        vc.widgetPanel = widgetInfo.widgetPanel
        vc.addToNext = addToNext
        vc.selectedWidget = selectedWidget
        OARootViewController.instance().navigationController?.present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    private func showWidgetConfiguration() {
        guard let widgetInfo = getWidgetInfo(),
        let vc = WidgetConfigurationViewController() else { return }
        
        vc.selectedAppMode = OAAppSettings.sharedManager().applicationMode.get()
        vc.widgetInfo = widgetInfo
        vc.widgetPanel = widgetInfo.widgetPanel
        vc.onWidgetStateChangedAction = {
            OARootViewController.instance().mapPanel.hudViewController?.mapInfoController.updateWidgetsInfo()
        }
        OARootViewController.instance().navigationController?.present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func showDeleteWidgetAlert() {
        guard let widgetInfo = getWidgetInfo() else { return }
        let alert = WidgetUtils.deleteWidgetAlert(with: OAAppSettings.sharedManager().applicationMode.get(), widgetInfo: widgetInfo)
        OARootViewController.instance().navigationController?.present(alert, animated: true)
    }
}
