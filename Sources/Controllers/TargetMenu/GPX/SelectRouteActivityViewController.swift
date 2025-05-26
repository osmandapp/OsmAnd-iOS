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
    private var gpxFile: GpxFile?
    private var tracks: Set<TrackItem>?
    private var searchText: String?
    private var isSearchActive = false
    private var isCheckmarkAllowed = true
    
    weak var delegate: SelectRouteActivityViewControllerDelegate?
    
    init(gpxFile: GpxFile) {
        self.gpxFile = gpxFile
        self.tracks = nil
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        commonInit()
    }
    
    init(tracks: Set<TrackItem>) {
        self.gpxFile = nil
        self.tracks = tracks
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func commonInit() {
        routeActivityHelper = RouteActivityHelper.shared
        selectedActivity = determineInitialActivity()
        initTableData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.delegate = self
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
        
        if !isSearchActive {
            let noneSection = tableData.createNewSection()
            let noneRow = noneSection.createNewRow()
            noneRow.cellType = OASimpleTableViewCell.reuseIdentifier
            noneRow.key = "none"
            noneRow.title = localizedString("shared_string_none")
            if isCheckmarkAllowed {
                noneRow.setObj(selectedActivity == nil, forKey: "isSelected")
            }
        }
        
        guard let groups = routeActivityHelper?.getActivityGroups() else { return }
        if isSearchActive {
            let flatSection = tableData.createNewSection()
            let allActivities = groups.flatMap { $0.activities }
            let matches = allActivities.filter { activity in
                guard let txt = searchText, !txt.isEmpty else { return true }
                return activity.label.range(of: txt, options: .caseInsensitive) != nil
            }
            
            for activity in matches {
                let row = flatSection.createNewRow()
                row.cellType = OASimpleTableViewCell.reuseIdentifier
                row.key = activity.id
                row.title = activity.label
                row.icon = UIImage.mapSvgImageNamed("mx_\(activity.iconName)") ?? .icCustomInfoOutlined
                row.iconTintColor = (activity.id == selectedActivity?.id) ? .iconColorActive : .iconColorDefault
                row.setObj(activity.id == selectedActivity?.id, forKey: "isSelected")
                row.setObj(activity, forKey: "routeActivity")
            }
        } else {
            for group in groups {
                let section = tableData.createNewSection()
                section.headerText = group.label
                for activity in group.activities {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.reuseIdentifier
                    row.key = activity.id
                    row.title = activity.label
                    row.icon = UIImage.mapSvgImageNamed("mx_\(activity.iconName)") ?? .icCustomInfoOutlined
                    row.iconTintColor = (activity.id == selectedActivity?.id) ? .iconColorActive : .iconColorDefault
                    row.setObj(activity, forKey: "routeActivity")
                    if isCheckmarkAllowed {
                        row.setObj(activity.id == selectedActivity?.id, forKey: "isSelected")
                    }
                }
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
        isCheckmarkAllowed = true
        updateData()
    }
    
    override func onRightNavbarButtonPressed() {
        if let tracks {
            routeActivityHelper?.saveRouteActivity(trackItems: tracks, routeActivity: selectedActivity)
        } else if let gpxFile {
            routeActivityHelper?.saveRouteActivity(gpxFile: gpxFile, routeActivity: selectedActivity)
            delegate?.didApplyRouteActivitySelection()
        }
        
        super.onLeftNavbarButtonPressed()
    }
    
    private func determineInitialActivity() -> RouteActivity? {
        guard let routeActivityHelper else { return nil }
        if let tracks, !tracks.isEmpty {
            let activities: [String?] = tracks.map { let raw = $0.dataItem?.getParameter(parameter: .activityType) as? String
                return raw?.isEmpty == false ? raw : nil
            }
            
            let nonNilSet = Set(activities.compactMap { $0 })
            let hasNone = activities.contains(nil)
            switch (nonNilSet.count, hasNone) {
            case (1, false):
                isCheckmarkAllowed = true
                return routeActivityHelper.findRouteActivity(id: nonNilSet.first)
            case (0, true):
                isCheckmarkAllowed = true
                return nil
            default:
                isCheckmarkAllowed = false
                return nil
            }
        }
        
        guard let raw = gpxFile?.metadata.extensions?["osmand:activity"] as? String, !raw.isEmpty else { return nil }
        return routeActivityHelper.findRouteActivity(id: raw)
    }
    
    private func updateData() {
        generateData()
        tableView.reloadData()
    }
}

extension SelectRouteActivityViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        updateData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        updateData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchController?.isActive = false
        isSearchActive = false
        searchText = nil
        updateData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        self.searchText = nil
        updateData()
    }
}
