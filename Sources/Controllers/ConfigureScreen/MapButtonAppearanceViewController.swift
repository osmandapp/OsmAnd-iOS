//
//  MapButtonAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
final class MapButtonAppearanceViewController: OABaseNavbarViewController {
    weak var mapButtonState: MapButtonState?
    
    private var appMode: OAApplicationMode?
    private var appearanceParams: ButtonAppearanceParams?
    private var originalAppearanceParams: ButtonAppearanceParams?
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let mapButtonState else { return }
        let savedIconName = mapButtonState.savedIconName()
        appearanceParams = mapButtonState.createAppearanceParams()
        originalAppearanceParams = mapButtonState.createAppearanceParams()
        appearanceParams?.iconName = savedIconName
        originalAppearanceParams?.iconName = savedIconName
    }
    
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
    
    override func registerCells() {
        addCell(PreviewImageViewTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        let visibilitySection = tableData.createNewSection()
        let imageHeaderRow = visibilitySection.createNewRow()
        imageHeaderRow.cellType = PreviewImageViewTableViewCell.reuseIdentifier
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let mapButtonState else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == PreviewImageViewTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: PreviewImageViewTableViewCell.reuseIdentifier) as! PreviewImageViewTableViewCell
            cell.configure(appearanceParams: appearanceParams, buttonState: mapButtonState)
            if mapButtonState is CompassButtonState {
                cell.rotateImage(-CGFloat(OARootViewController.instance().mapPanel.mapViewController.azimuth()) / 180.0 * CGFloat.pi)
            }
            return cell
        }
        return nil
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
