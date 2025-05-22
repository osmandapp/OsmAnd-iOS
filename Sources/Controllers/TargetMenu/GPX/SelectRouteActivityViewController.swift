//
//  SelectRouteActivityViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol SelectRouteActivityViewControllerDelegate: AnyObject {
    func didApplyRouteActivitySelection()
}

@objcMembers
final class SelectRouteActivityViewController: OABaseNavbarViewController {
    private var searchController: UISearchController?
    private var routeActivityHelper: RouteActivityHelper?
    private var selectedActivity: RouteActivity?
    private var gpxFile: GpxFile
    
    weak var delegate: SelectRouteActivityViewControllerDelegate?
    
    init(gpxFile: GpxFile) {
        self.gpxFile = gpxFile
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        routeActivityHelper = RouteActivityHelper.shared
        selectedActivity = loadSelectedActivity()
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.delegate = self
        searchController?.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = localizedString("shared_string_search")
        searchController?.searchBar.returnKeyType = .go
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        localizedString("shared_string_activity")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(localizedString("shared_string_apply"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let noneSection = tableData.createNewSection()
        let noneRow = noneSection.createNewRow()
        noneRow.cellType = OASimpleTableViewCell.reuseIdentifier
        noneRow.key = "none"
        noneRow.title = localizedString("shared_string_none")
        noneRow.setObj(selectedActivity == nil, forKey: "isSelected")
        
        guard let groups = routeActivityHelper?.getActivityGroups() else { return }
        for group in groups {
            let section = tableData.createNewSection()
            section.headerText = group.label
            for activity in group.activities {
                let row = section.createNewRow()
                row.cellType = OASimpleTableViewCell.reuseIdentifier
                row.key = activity.id
                row.title = activity.label
                row.icon = UIImage.mapSvgImageNamed("mx_\(activity.iconName)") ?? .icCustomInfoOutlined
                row.iconTintColor = activity.id == selectedActivity?.id ? .iconColorActive : .iconColorDefault
                row.setObj(activity.id == selectedActivity?.id, forKey: "isSelected")
                row.setObj(activity, forKey: "routeActivity")
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(item.key != "none")
            cell.titleLabel.text = item.title
            cell.leftIconView.image = item.icon
            cell.leftIconView.tintColor = item.iconTintColor
            cell.accessoryType = item.bool(forKey: "isSelected") ? .checkmark : .none
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        selectedActivity = item.obj(forKey: "routeActivity") as? RouteActivity
        generateData()
        tableView.reloadData()
    }
    
    override func onRightNavbarButtonPressed() {
        routeActivityHelper?.saveRouteActivity(gpxFile: gpxFile, routeActivity: selectedActivity)
        delegate?.didApplyRouteActivitySelection()
        super.onLeftNavbarButtonPressed()
    }
    
    private func loadSelectedActivity() -> RouteActivity? {
        guard let routeActivityHelper, let rawId = gpxFile.metadata.extensions?["osmand:activity"] as? String, !rawId.isEmpty else { return nil }
        return routeActivityHelper.findRouteActivity(id: rawId)
    }
}

extension SelectRouteActivityViewController: UISearchBarDelegate, UISearchControllerDelegate {
}
