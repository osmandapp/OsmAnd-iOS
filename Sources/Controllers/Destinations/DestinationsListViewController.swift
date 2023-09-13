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

    private var destinationItems: [OADestinationItem] = []
    private var activeIndexPath: IndexPath?
    private var isDecelerating = false
    private var lastUpdate: TimeInterval?

    //MARK: - Initialization

    override func commonInit() {
        for sortedDestination in OADestinationsHelper.instance().sortedDestinations {
            if let destination = sortedDestination as? OADestination {
                let item: OADestinationItem = OADestinationItem()
                item.destination = destination;
                destinationItems.append(item)
            }
        }
    }

    override func registerObservers() {
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let updateDistanceAndDirectionSelector = #selector(updateDistanceAndDirection as () -> Void)
        addObserver(OAAutoObserverProxy(self, withHandler: updateDistanceAndDirectionSelector, andObserve: app.locationServices.updateObserver))
    
    }

    //MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.isEditing = true
        isDecelerating = false
        updateDistanceAndDirection(true)
    }

    //MARK: - Base UI

    override func getTitle() -> String! {
        localizedString("map_markers")
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .horizontal
    }

    override func getTopButtonTitle() -> String! {
        localizedString("shared_string_history")
    }

    override func getBottomButtonTitle() -> String! {
        localizedString("shared_string_appearance")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }

    //MARK: - Table data

    override func rowsCount(_ section: Int) -> Int {
        return destinationItems.count
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let destinationItem = destinationItems[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
            cell = nib?.first as? OASimpleTableViewCell
        }
        if let cell = cell {
            cell.titleLabel.text = destinationItem.destination.desc
            cell.leftIconView.image = UIImage(named: destinationItem.destination.markerResourceName.appending("_small"))
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

    override func sectionsCount() -> Int {
        return 1
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        let destinationItem = destinationItems[indexPath.row]
        let destinationsHelper = OADestinationsHelper.instance()
        if destinationItem.destination.hidden {
            destinationsHelper?.show(onMap: destinationItem.destination)
        }
        destinationsHelper?.moveDestination(onTop:destinationItem.destination, wasSelected:true)
        let mapPanel = OARootViewController.instance().mapPanel
        mapPanel?.openTargetView(with: destinationItem.destination)
        dismiss()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        destinationItems.insert(destinationItems.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        for i in (sourceIndexPath.row < destinationIndexPath.row ? sourceIndexPath.row : destinationIndexPath.row)..<destinationItems.count {
            destinationItems[i].destination.index = i
        }
        OADestinationsHelper.instance().reorderDestinations(destinationItems)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let destinationItem = destinationItems[indexPath.row]
            let destinationsHelper = OADestinationsHelper.instance()
            destinationsHelper?.addHistoryItem(destinationItem.destination)
            destinationsHelper?.remove(destinationItem.destination)
            if let indexToDelete = destinationItems.firstIndex(of: destinationItem) {
                destinationItems.remove(at: indexToDelete)
            }
            for i in indexPath.row..<destinationItems.count {
                destinationItems[i].destination.index = i
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    //MARK: - Selectors

    override func onTopButtonPressed() {
        let historyViewController = OAHistoryViewController()
        show(historyViewController)
    }

    override func onBottomButtonPressed() {
        let vc = OADirectionAppearanceViewController()
        show(vc)
    }

    //MARK: - Additions

    @objc private func updateDistanceAndDirection() {
        updateDistanceAndDirection(false)
    }

    func updateDistanceAndDirection(_ forceUpdate: Bool) {
        if isDecelerating {
            return;
        }
        if let lastUpdate, (Date.now.timeIntervalSince1970 - lastUpdate < 0.3), !forceUpdate {
            return
        }
        lastUpdate = Date.now.timeIntervalSince1970
        OADistanceAndDirectionsUpdater.updateDistanceAndDirections(forceUpdate, items: destinationItems)
        refreshVisibleRows()
    }

    private func refreshVisibleRows() {
        DispatchQueue.main.async { [weak self] in
            if let visibleIndexPaths = self?.tableView.indexPathsForVisibleRows {
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
