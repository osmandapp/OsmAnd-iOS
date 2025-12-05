//
//  DefaultMapButtonsViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

struct DefaultMapButtons {
    private var map3DButtonState: Map3DButtonState
    private var compassButtonState: CompassButtonState
    private var zoomInButtonState: ZoomInButtonState
    private var zoomOutButtonState: ZoomOutButtonState
    private var searchButtonState: SearchButtonState
    private var navigationModeButtonState: DriveModeButtonState
    private var myLocationButtonState: MyLocationButtonState
    
    init() {
        let mapButtonsHelper = OAMapButtonsHelper.sharedInstance()
        map3DButtonState = mapButtonsHelper.getMap3DButtonState()
        compassButtonState = mapButtonsHelper.getCompassButtonState()
        zoomInButtonState = mapButtonsHelper.getZoomInButtonState()
        zoomOutButtonState = mapButtonsHelper.getZoomOutButtonState()
        searchButtonState = mapButtonsHelper.getSearchButtonState()
        navigationModeButtonState = mapButtonsHelper.getNavigationModeButtonState()
        myLocationButtonState = mapButtonsHelper.getMyLocationButtonState()
    }
    
    func resetMode(toDefault appMode: OAApplicationMode) {
        map3DButtonState.visibilityPref.resetMode(toDefault: appMode)
        compassButtonState.visibilityPref.resetMode(toDefault: appMode)
        zoomInButtonState.visibilityPref.resetMode(toDefault: appMode)
        zoomOutButtonState.visibilityPref.resetMode(toDefault: appMode)
        searchButtonState.visibilityPref.resetMode(toDefault: appMode)
        navigationModeButtonState.visibilityPref.resetMode(toDefault: appMode)
        myLocationButtonState.visibilityPref.resetMode(toDefault: appMode)
    }
    
    func states() -> [MapButtonState] {
        [map3DButtonState,
         compassButtonState,
         zoomInButtonState,
         zoomOutButtonState,
         searchButtonState,
         navigationModeButtonState,
         myLocationButtonState]
    }
    
    func key(for state: MapButtonState) -> String {
        switch state {
        case is Map3DButtonState: return "map3DMode"
        case is CompassButtonState: return "compass"
        case is ZoomInButtonState: return "zoomIn"
        case is ZoomOutButtonState: return "zoomOut"
        case is SearchButtonState: return "search"
        case is DriveModeButtonState: return "navigation"
        case is MyLocationButtonState: return "myLocation"
        default: return ""
        }
    }
        
    func copyProfile(_ fromAppMode: OAApplicationMode, to appMode: OAApplicationMode) {
        map3DButtonState.visibilityPref.set(map3DButtonState.getVisibility(fromAppMode).rawValue, mode: appMode)
        compassButtonState.visibilityPref.set(compassButtonState.getVisibility(fromAppMode).rawValue, mode: appMode)
        zoomInButtonState.visibilityPref.set(zoomInButtonState.visibilityPref.get(fromAppMode), mode: appMode)
        zoomOutButtonState.visibilityPref.set(zoomOutButtonState.visibilityPref.get(fromAppMode), mode: appMode)
        searchButtonState.visibilityPref.set(searchButtonState.visibilityPref.get(fromAppMode), mode: appMode)
        navigationModeButtonState.visibilityPref.set(navigationModeButtonState.visibilityPref.get(fromAppMode), mode: appMode)
        myLocationButtonState.visibilityPref.set(myLocationButtonState.visibilityPref.get(fromAppMode), mode: appMode)
    }
}

final class DefaultMapButtonsViewController: OABaseNavbarViewController {
    
    weak var delegate: MapButtonsDelegate?
    private var defaultMapButtons: DefaultMapButtons!
    private var appMode: OAApplicationMode?
    
    // MARK: Initialization
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
        defaultMapButtons = DefaultMapButtons()
    }
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    // MARK: Base UI
    
    override func getTitle() -> String {
        localizedString("default_buttons")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var resetAlert: UIAlertController?
        resetAlert = UIAlertController(title: title,
                                       message: localizedString("reset_all_settings_desc"),
                                       preferredStyle: .actionSheet)
        let resetAction: UIAction = UIAction(title: localizedString("reset_to_default"),
                                             image: .icCustomReset) { [weak self] _ in
            let actionSheet = UIAlertController(title: self?.title,
                                                message: localizedString("reset_all_settings_desc"),
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
                guard let self, let appMode = self.appMode else { return }
                self.defaultMapButtons.resetMode(toDefault: appMode)
                self.onSettingsChanged()
            })
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.barButtonItem = self?.navigationItem.rightBarButtonItem
            }
            self?.present(actionSheet, animated: true)
        }
        let copyAction: UIAction = UIAction(title: localizedString("copy_from_other_profile"),
                                            image: .icCustomCopy) { [weak self] _ in
            guard let self, let appMode = self.appMode else { return }
            
            let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler(mode: appMode)
            bottomSheet.delegate = self
            bottomSheet.present(in: self)
        }
        let menuElements = [resetAction, copyAction]
        let menu = UIMenu(children: menuElements)
        let button = createRightNavbarButton(nil,
                                             iconName: "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        button?.accessibilityLabel = localizedString("shared_string_options")
        let popover = resetAlert?.popoverPresentationController
        popover?.barButtonItem = button
        var buttons = [UIBarButtonItem]()
        if let button {
            buttons.append(button)
        }
        return buttons
    }
    
    // MARK: Table data
    
    override func generateData() {
        tableData.clearAllData()
        guard let appMode else { return }
        let iconTintColor = appMode.getProfileColor()
        let buttonsSection = tableData.createNewSection()
        
        for buttonState in defaultMapButtons.states() {
            let row = buttonsSection.createNewRow()
            row.key = defaultMapButtons.key(for: buttonState)
            row.cellType = OAValueTableViewCell.reuseIdentifier
            row.title = buttonState.getName()
            row.descr = getDescription(buttonState)
            row.accessibilityLabel = row.title
            row.accessibilityValue = row.descr
            row.iconTintColor = buttonState.isEnabled() ? iconTintColor : .iconColorDefault
            row.icon = buttonState.getIcon()
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.descriptionVisibility(false)
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let data = tableData.item(for: indexPath)
        if data.key == "compass" {
            let vc = CompassVisibilityViewController()
            vc.delegate = self
            showMediumSheetViewController(vc, isLargeAvailable: false)
        } else if data.key == "map3DMode" {
            let vc = Map3dModeButtonVisibilityViewController()
            vc.delegate = self
            showMediumSheetViewController(vc, isLargeAvailable: false)
        }
    }
    
    // MARK: Additions
    
    private func onSettingsChanged() {
        reloadDataWith(animated: true, completion: nil)
        delegate?.onButtonsChanged()
    }
    
    private func getDescription(_ buttonState: MapButtonState) -> String {
        switch buttonState {
        case let map3DButtonState as Map3DButtonState:
            return map3DButtonState.getVisibility().title
        case let compassButtonState as CompassButtonState:
            return compassButtonState.getVisibility().title
        default:
            return localizedString(buttonState.isEnabled() ? "shared_string_on" : "shared_string_off")
        }
    }
}

// MARK: WidgetStateDelegate
extension DefaultMapButtonsViewController: WidgetStateDelegate {
    func onWidgetStateChanged() {
        onSettingsChanged()
    }
}

// MARK: OACopyProfileBottomSheetDelegate
extension DefaultMapButtonsViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }
    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        guard let appMode else { return }
        defaultMapButtons.copyProfile(fromAppMode, to: appMode)
        onSettingsChanged()
    }
}
