//
//  DestinationsListViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 06.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

@objc(OADestinationsListViewController)
@objcMembers
class DestinationsListViewController: OABaseButtonsViewController {
    
    private let kDestinationItemKey = "destinationItem"
    
    private var activeIndexPath: IndexPath?
    private var isDecelerating = false
    private var lastUpdate: TimeInterval?
    private let lock = NSLock()

    private var editMode: Bool = false {
        didSet {
            tableView.setEditing(editMode, animated: true)
            if tableData.hasChanged || tableData.sectionCount() == 0 {
                updateUIAnimated(nil)
            } else {
                updateWithoutData()
            }
        }
    }
    
    //MARK: - Initialization
    
    override func registerObservers() {
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let updateDistanceAndDirectionSelector = #selector(updateDistanceAndDirection as () -> Void)
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateHeadingObserver))
    }
    
    //MARK: - UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isDecelerating = false
        updateDistanceAndDirection(true)
    }
    
    //MARK: - Base UI
    
    override func getTitle() -> String! {
        localizedString("map_markers")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        editMode ? localizedString("shared_string_cancel") : nil
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        return [createRightNavbarButton(editMode ? localizedString("shared_string_done") : localizedString("shared_string_edit"),
                                        iconName: nil,
                                        action: #selector(onRightNavbarButtonPressed),
                                        menu: nil)]
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }
    
    override func getTopButtonTitle() -> String! {
        editMode ? nil : localizedString("shared_string_history")
    }
    
    override func getBottomButtonTitle() -> String! {
        editMode ? nil : localizedString("shared_string_appearance")
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }
    
    //MARK: - Table data
    
    override func generateData() {
        var indexPaths = [IndexPath]()
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let sortedDestinations = OADestinationsHelper.instance().sortedDestinations ?? []
        for i in 0..<sortedDestinations.count {
            if let destination = sortedDestinations[i] as? OADestination {
                let item: OADestinationItem = OADestinationItem()
                item.destination = destination;
                let row = section.createNewRow()
                row.setObj(item, forKey: kDestinationItemKey)
                indexPaths.append(IndexPath(row: i, section: 0))
            }
        }
        OADistanceAndDirectionsUpdater.updateDistanceAndDirections(tableData, indexPaths: indexPaths, itemKey: kDestinationItemKey)
        tableData.resetChanges()
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        if let destinationItem = tableData.item(for: indexPath).obj(forKey: kDestinationItemKey) as? OADestinationItem {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
            }
            if let cell = cell {
                cell.titleLabel.text = destinationItem.destination.desc
                var imageName = ""
                if let markerResourceName = destinationItem.destination.markerResourceName {
                    imageName = markerResourceName
                } else {
                    imageName = "ic_destination_pin_1"
                }
                cell.leftIconView.image = UIImage(named: imageName.appending("_small"))
                if let descriptionStr = destinationItem.distanceStr, !descriptionStr.isEmpty {
                    cell.descriptionVisibility(true)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.preferredFont(forTextStyle: .footnote),
                        .foregroundColor: colorFromRGB(Int(color_text_footer)) ?? .gray
                    ]
                    let descriptionAttr = NSMutableAttributedString(string: " " + descriptionStr, attributes: attributes)
                    var directionImage = UIImage(named: "icon_favorite_direction")
                    if directionImage != nil {
                        directionImage = OAUtilities.resize(directionImage, newSize:CGSize(width: 11, height: 11))
                        directionImage = directionImage?.rotate(radians: destinationItem.direction)
                        if let directionImage {
                            descriptionAttr.attachImage(image: directionImage)
                        }
                    }
                    cell.descriptionLabel.attributedText = descriptionAttr
                } else {
                    cell.descriptionVisibility(false)
                    cell.descriptionLabel.text = ""
                }
            }
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        if let destinationItem = tableData.item(for: indexPath).obj(forKey: kDestinationItemKey) as? OADestinationItem {
            let destinationsHelper = OADestinationsHelper.instance()
            if destinationItem.destination.hidden {
                destinationsHelper?.show(onMap: destinationItem.destination)
            }
            destinationsHelper?.moveDestination(onTop:destinationItem.destination, wasSelected:true)
            let mapPanel = OARootViewController.instance().mapPanel
            mapPanel?.openTargetView(with: destinationItem.destination)
            dismiss()
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return editMode
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return editMode
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rowData = tableData.item(for: sourceIndexPath)
        tableData.removeRow(at: sourceIndexPath)
        tableData.addRow(at: destinationIndexPath, row: rowData)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableData.removeRow(at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    //MARK: - UIGestureRecognizer
    override func onGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer!) -> Bool {
        if (gestureRecognizer == navigationController?.interactivePopGestureRecognizer) {
            if editMode, tableData.hasChanged {
                showUnsavedChangesAlert(shouldDismiss: true)
                return false
            }
        }
        return true
    }

    //MARK: - Selectors

    override func onLeftNavbarButtonPressed() {
        if editMode {
            if tableData.hasChanged {
                showUnsavedChangesAlert(shouldDismiss: false)
            } else {
                editMode = false
            }
            return
        }
        super.onLeftNavbarButtonPressed()
    }

    override func onRightNavbarButtonPressed() {
        if tableData.hasChanged {
            reorderDestinations()
        }
        editMode = !editMode
    }

    override func onTopButtonPressed() {
        let historyViewController = OAHistoryViewController()
        show(historyViewController)
    }

    override func onBottomButtonPressed() {
        let vc = OADirectionAppearanceViewController()
        show(vc)
    }

    //MARK: - Additions

    private func reorderDestinations() {
        var order = [OADestinationItem]()
        for sec in 0..<tableData.sectionCount() {
            let section = tableData.sectionData(for: sec)
            for row in 0..<section.rowCount() {
                let rowData = section.getRow(row)
                if let destinationItem = rowData.obj(forKey: kDestinationItemKey) as? OADestinationItem {
                    destinationItem.destination.index = Int(row)
                    order.append(destinationItem)
                }
            }
        }
        OADestinationsHelper.instance().reorderDestinations(order)
    }

    private func showUnsavedChangesAlert(shouldDismiss: Bool) {
        let alert: UIAlertController = UIAlertController.init(title: localizedString("unsaved_changes"),
                                                              message: localizedString("unsaved_changes_will_be_lost_discard"),
                                                              preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_discard"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.editMode = false
            if (shouldDismiss) {
                self.dismiss()
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        let popPresenter = alert.popoverPresentationController
        popPresenter?.barButtonItem = getLeftNavbarButton();
        popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any;

        present(alert, animated: true)
    }

    @objc private func updateDistanceAndDirection() {
        updateDistanceAndDirection(false)
    }

    func updateDistanceAndDirection(_ forceUpdate: Bool) {
        lock.lock()

        if isDecelerating || editMode {
            lock.unlock()
            return
        }
        if let lastUpdate, (Date.now.timeIntervalSince1970 - lastUpdate < 0.3), !forceUpdate {
            lock.unlock()
            return
        }
        lastUpdate = Date.now.timeIntervalSince1970
        refreshVisibleRows()

        lock.unlock()
    }

    private func refreshVisibleRows() {
        DispatchQueue.main.async { [weak self] in
            if let visibleIndexPaths = self?.tableView.indexPathsForVisibleRows {
                OADistanceAndDirectionsUpdater.updateDistanceAndDirections(self?.tableData, indexPaths: visibleIndexPaths, itemKey: self?.kDestinationItemKey)
                self?.tableView.reloadRows(at: visibleIndexPaths, with: .none)
            }
        }
    }

    //MARK: - UIScrollViewDelegate

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDecelerating = true
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isDecelerating = false
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isDecelerating = false
    }

}
