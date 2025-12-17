//
//  MapButtonAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
final class MapButtonAppearanceViewController: OABaseNavbarViewController {
    override func getTitle() -> String {
        localizedString("shared_string_appearance")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(nil, iconName: "ic_navbar_reset", action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }
    
    override func onLeftNavbarButtonPressed() {
        // TODO
        //showUnsavedChangesAlert()
        super.onLeftNavbarButtonPressed()
    }
    
    override func onRightNavbarButtonPressed() {
        showResetToDefaultActionSheet()
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    private func showUnsavedChangesAlert() {
        let alert: UIAlertController = UIAlertController(title: localizedString("unsaved_changes"),
                                                         message: localizedString("unsaved_changes_will_be_lost_discard"),
                                                         preferredStyle: .alert)
        let discardAction = UIAlertAction(title: localizedString("shared_string_discard"), style: .default) { _ in
            self.dismiss()
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(discardAction)
        alert.preferredAction = discardAction

        present(alert, animated: true)
    }
    
    private func showResetToDefaultActionSheet() {
        let actionSheet = UIAlertController(title: localizedString("reset_to_default"),
                                            message: localizedString("reset_all_settings_desc"),
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
            // TODO
        })
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(actionSheet, animated: true)
    }
}
