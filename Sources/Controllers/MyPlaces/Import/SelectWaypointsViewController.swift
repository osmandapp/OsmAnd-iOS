//
//  SelectWaypointsViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

protocol SelectWaypointsDelegate: AnyObject {
    func onPointsSelected(_ trackItem: ImportTrackItem, selectedPoints: [WptPt])
}

final class SelectWaypointsViewController: OABaseButtonsViewController {
    private enum RowKey: String {
        case infoDescr
        case selectNearest
        case group
        case point
    }

    private enum RowObjKey {
        static let attributedTitleKey = "attributedTitle"
        static let wptItem = "wptItem"
        static let group = "group"
    }
    
    private class Group {
        let index: Int
        let name: String
        let items: [OAGpxWptItem]
        var isExpanded: Bool
        
        init(index: Int, name: String, items: [OAGpxWptItem], isExpanded: Bool) {
            self.index = index
            self.name = name
            self.items = items
            self.isExpanded = isExpanded
        }
    }
    
    enum SelectionState {
        case none, part, all
    }
    
    weak var delegate: SelectWaypointsDelegate?
    
    // Input
    private let track: ImportTrackItem
    private let allPoints: [WptPt]
    private var selectedPoints: Set<WptPt>
    private let suggestedPoints: [WptPt]
    
    private var initialSelectedPoints: Set<WptPt> = []
    private var groups: [Group] = []
    
    private var lastUpdate: TimeInterval?
    private let updateLock = NSLock()
    
    // MARK: - Init
    
//    @objc(initWithTrack:allPoints:)
    init(track: ImportTrackItem, allPoints: [WptPt]) {
        self.track = track
        self.allPoints = allPoints
        self.selectedPoints = Set(track.selectedPoints)
        self.suggestedPoints = track.suggestedPoints

        super.init()
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("init(track: ImportTrackItem, allPoints: [WptPt])")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        generateData()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDistanceAndDirection(force: true)
    }
    
    override func registerObservers() {
        super.registerObservers()
        guard let app = OsmAndApp.swiftInstance() else { return }
        let selector = #selector(updateDistanceAndDirection as () -> Void)
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateLocationObserver))
        addObserver(OAAutoObserverProxy(self, withHandler: selector, andObserve: app.locationServices.updateHeadingObserver))
    }

    // MARK: - Table
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OASelectionCollapsableCell.reuseIdentifier)
        addCell(OAPointWithRegionTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()

        // Info
        let infoSection = tableData.createNewSection()
        infoSection.footerText = localizedString("auto_select_nearest_footer")

        let descrRow = infoSection.createNewRow()
        descrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        descrRow.key = RowKey.infoDescr.rawValue
        descrRow.setObj(makeTopDescription(fileName: track.name), forKey: RowObjKey.attributedTitleKey)

        let importAsOneRow = infoSection.createNewRow()
        importAsOneRow.cellType = OASimpleTableViewCell.reuseIdentifier
        importAsOneRow.key = RowKey.selectNearest.rawValue
        importAsOneRow.title = localizedString("auto_select_nearest_points")
        
        // Points
        for group in groups {
            let section = tableData.createNewSection()
            let groupRow = section.createNewRow()
            groupRow.cellType = OASelectionCollapsableCell.reuseIdentifier
            groupRow.key = RowKey.group.rawValue
            groupRow.title = group.name
            groupRow.setObj(group, forKey: RowObjKey.group)
            
            if group.isExpanded {
                for item in group.items {
                    let row = section.createNewRow()
                    row.cellType = OAPointWithRegionTableViewCell.reuseIdentifier
                    row.key = RowKey.point.rawValue
                    row.title = item.point.name ?? ""
                    row.setObj(item, forKey: RowObjKey.wptItem)
                }
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)

        switch item.cellType {
        case OASimpleTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                                                     for: indexPath) as! OASimpleTableViewCell
            cell.leftIconVisibility(false)
            cell.setCustomLeftSeparatorInset(true)
            
            if item.key == RowKey.infoDescr.rawValue,
                let attributed = item.obj(forKey: RowObjKey.attributedTitleKey) as? NSAttributedString {
                cell.descriptionLabel.attributedText = attributed
                cell.descriptionVisibility(true)
                cell.titleVisibility(false)
                hideSeparator(for: cell, false)
                cell.selectionStyle = .none
            } else if item.key == RowKey.selectNearest.rawValue {
                cell.titleLabel.text = item.title
                cell.titleLabel.textColor = .textColorActive
                cell.titleVisibility(true)
                cell.descriptionVisibility(false)
                hideSeparator(for: cell, true)
                cell.selectionStyle = .default
            }
            cell.textStackView.isHidden = false
            return cell
        case OASelectionCollapsableCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OASelectionCollapsableCell.reuseIdentifier,
                                                     for: indexPath) as! OASelectionCollapsableCell
            guard let group = item.obj(forKey: RowObjKey.group) as? Group else { return cell }
            
            let expanded = group.isExpanded
            let tag = group.index
            
            cell.selectionStyle = .none
            cell.separatorInset = .zero
            cell.showOptionsButton(false)
            cell.makeSelectable(true)
            cell.titleView.text = item.title
            cell.leftIconView.image = .templateImageNamed("ic_custom_folder")
            cell.leftIconView.tintColor = item.iconTintColor ?? .iconColorActive
            cell.arrowIconView.tintColor = .iconColorActive
            cell.arrowIconView.image = .templateImageNamed(expanded ? "ic_custom_arrow_down" : "ic_custom_arrow_up")
            cell.selectionButton.setImage(groupSelectionImage(group), for: .normal)
            cell.openCloseGroupButton.tag = tag
            cell.openCloseGroupButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.openCloseGroupButton.addTarget(self, action: #selector(openCloseGroupAction(_:)), for: .touchUpInside)
            cell.selectionButton.tag = tag
            cell.selectionGroupButton.tag = tag
            cell.selectionButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.selectionGroupButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.selectionButton.addTarget(self, action: #selector(onGroupSelectTapped(_:)), for: .touchUpInside)
            cell.selectionGroupButton.addTarget(self, action: #selector(onGroupSelectTapped(_:)), for: .touchUpInside)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 0)
            cell.setNeedsUpdateConstraints()
            return cell
        case OAPointWithRegionTableViewCell.reuseIdentifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OAPointWithRegionTableViewCell.reuseIdentifier, for: indexPath) as! OAPointWithRegionTableViewCell
            guard let wptItem = item.obj(forKey: RowObjKey.wptItem) as? OAGpxWptItem else {
                return cell
            }

            cell.setRegion(wptItem.point.getAddress() ?? "")
            cell.titleView.text = wptItem.point.name ?? ""
            cell.iconView.image = wptItem.compositeIconWithDefaultColor()
            cell.setShowWaypointButtonVisiblity(false)
            if let distance = wptItem.distance, !distance.isEmpty {
                cell.setDirection(distance)
                cell.directionIconView.image = .templateImageNamed("ic_small_direction")
                cell.directionIconView.tintColor = UIColor(named: "iconColorActive")
                cell.directionIconView.transform = CGAffineTransform(rotationAngle: wptItem.direction)
            } else {
                cell.setDirection("")
            }
            let bgView = UIView()
            bgView.backgroundColor = cell.backgroundColor
            cell.selectedBackgroundView = bgView
            cell.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 0)
            cell.setNeedsUpdateConstraints()
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        switch item.key {
        case RowKey.selectNearest.rawValue:
            selectNearestAction()
        case RowKey.point.rawValue:
            togglePoint(at: indexPath)
        default:
            break
        }
    }
    
    override func onRowDeselected(_ indexPath: IndexPath) {
        guard tableData.item(for: indexPath).key == RowKey.point.rawValue else { return }
        togglePoint(at: indexPath)
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        let headerText = tableData.sectionData(for: UInt(section)).headerText
        if !headerText.isEmpty {
            return UITableView.automaticDimension
        }
        return 16
    }
    
    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        let headerText = tableData.sectionData(for: UInt(section)).footerText
        if !headerText.isEmpty {
            return UITableView.automaticDimension
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section > 0, indexPath.row > 0 else { return }
        guard let wptItem = tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem) as? OAGpxWptItem else { return }
        if selectedPoints.contains(wptItem.point) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section > 0 && indexPath.row > 0
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    // MARK: - NavBar
    
    override func getTitle() -> String? {
        localizedString("shared_string_waypoints")
    }

    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        guard let image = UIImage.templateImageNamed("ic_navbar_close") else { return nil }
        return OAUtilities.resize(image, newSize: CGSize(width: 24, height: 24))
    }
    
    override func getCustomAccessibilityForLeftNavbarButton() -> String? {
        localizedString("shared_string_close")
    }
    
    override func onLeftNavbarButtonPressed() {
        showExitConfirmationAction()
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        let allSelected = selectedPoints.count == allPoints.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        let item = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(onSelectAllAction))
        item.tintColor = .label
        item.accessibilityLabel = title
        return [item]
    }
    
    private func updateSelectAllButtonTitle() {
        let allSelected = selectedPoints.count == allPoints.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let item = navigationItem.rightBarButtonItems?.first else { return }
        item.title = title
        item.accessibilityLabel = title
    }
    
    // MARK: - Bottom buttons
    
    override func getTopButtonTitle() -> String? {
        return localizedString("shared_string_apply")
    }
    
    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func onTopButtonPressed() {
        applyAction()
    }
    
    // MARK: - Setup
    
    private func setup() {
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.isEditing = true
        
        self.initialSelectedPoints = Set(track.selectedPoints)
        
        self.groups = self.makeGroups(allPoints)
    }

    // MARK: - Actions
    
    @objc private func onSelectAllAction() {
        if selectedPoints.count == allPoints.count {
            selectedPoints.removeAll()
        } else {
            selectedPoints = Set(allPoints)
        }
        updateSelectAllButtonTitle()
        tableView.reloadData()
    }
    
    private func applyAction() {
        delegate?.onPointsSelected(track, selectedPoints: Array(selectedPoints))
        dismiss(animated: true)
    }
    
    private func selectNearestAction() {
        selectedPoints = Set(suggestedPoints)
        updateSelectAllButtonTitle()
        tableView.reloadData()
    }
    
    @objc private func showExitConfirmationAction() {
        guard selectedPoints != initialSelectedPoints else {
            dismiss(animated: true)
            return
        }
        let alert = UIAlertController(title: localizedString("unsaved_changes"),
                                      message: localizedString("selected_waypoints_exit_descr"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_continue"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_close"), style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func onGroupSelectTapped(_ sender: UIButton) {
        guard let group = groups.first(where: { $0.index == sender.tag }) else { return }

        let points = group.items.compactMap(\.point)
        let allSelected = !points.isEmpty && points.allSatisfy { selectedPoints.contains($0) }
        if allSelected {
            points.forEach { selectedPoints.remove($0) }
        } else {
            points.forEach { selectedPoints.insert($0) }
        }
        updateSelectAllButtonTitle()
        tableView.reloadSections(IndexSet(integer: indexGroupToIndexPath(group.index).section), with: .none)
    }
    
    @objc private func openCloseGroupAction(_ sender: UIButton) {
        guard let group = groups.first(where: { $0.index == sender.tag }) else { return }
        toggleExpandGroup(group)
    }

    // MARK: - Helpers methods
    
    private func hideSeparator(for cell: UITableViewCell, _ isHide: Bool) {
        let inset = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        cell.separatorInset = .init(top: 0, left: isHide ? inset : 16, bottom: 0, right: isHide ? -inset : 16)
    }
    
    private func makeTopDescription(fileName: String) -> NSAttributedString {
        let text: String = String(format: localizedString("selected_waypoints_descr"), fileName)

        let baseFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let boldFont = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        
        let result = NSMutableAttributedString(string: text, attributes: [.font: baseFont,
                                                                          .foregroundColor: UIColor.textColorPrimary])

        let fileRange = (text as NSString).range(of: fileName)
        if fileRange.location != NSNotFound {
            result.addAttribute(.font, value: boldFont, range: fileRange)
        }

        return result
    }
    
    // MARK: - Helpers groups
    
    private func makeGroups(_ points: [WptPt]) -> [Group] {
        var dict: [String: [OAGpxWptItem]] = [:]
        let defaultName = localizedString("shared_string_gpx_points")
        for pt in points {
            let key: String
            if let category = pt.category, !category.isEmpty {
                key = category
            } else {
                key = defaultName
            }
            dict[key, default: []].append(OAGpxWptItem.withGpxWpt(pt))
        }
        
        let sorted: [(String, [OAGpxWptItem])] = dict.keys.sorted().compactMap({ key in
            guard let array = dict[key], !array.isEmpty else { return nil }
            return (key, array)
        })
        
        return sorted.enumerated().map { Group(index: $0, name: $1.0, items: $1.1, isExpanded: true) }
    }
    
    private func toggleExpandGroup(_ group: Group?) {
        guard let group else { return }
        group.isExpanded.toggle()
        generateData()
        tableView.reloadSections(.init(integer: group.index + 1), with: .automatic)
    }

    private func groupSelectionImage(_ group: Group) -> UIImage? {
        switch getGroupSelectionState(group) {
        case .all: return UIImage(named: "ic_system_checkbox_selected")
        case .part: return UIImage(named: "ic_system_checkbox_indeterminate")
        case .none: return nil
        }
    }
    
    private func getGroup(_ indexPath: IndexPath) -> Group? {
        tableData.item(for: .init(row: 0, section: indexPath.section)).obj(forKey: RowObjKey.group) as? Group
    }
    
    private func getGroupSelectionState(_ group: Group) -> SelectionState {
        guard !group.items.isEmpty else { return .none }
        let selectedCount = group.items.filter { selectedPoints.contains($0.point) }.count
        if selectedCount == 0 {
            return .none
        }
        if selectedCount == group.items.count {
            return .all
        }
        return .part
    }
    
    private func indexGroupToIndexPath(_ index: Int) -> IndexPath {
        .init(row: 0, section: index + 1)
    }
    
    // MARK: - Helpers points
    
    private func togglePoint(at indexPath: IndexPath) {
        guard let group = getGroup(indexPath) else { return }
        guard let wptItem = tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem) as? OAGpxWptItem,
                let point = wptItem.point else { return }
        
        let oldState = getGroupSelectionState(group)
        
        if selectedPoints.contains(point) {
            selectedPoints.remove(point)
        } else {
            selectedPoints.insert(point)
        }
        
        let newState = getGroupSelectionState(group)
        
        updateSelectAllButtonTitle()
        if oldState != newState {
            tableView.reloadRows(at: [.init(row: 0, section: indexPath.section)], with: .none)
        }
    }
    
    private func updateWaypointDistanceAndDirection(for item: OAGpxWptItem) {
        guard let point = item.point, let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation else {
            item.distance = nil
            return
        }

        let meters = OADistanceAndDirectionsUpdater.getDistanceFrom(
            location,
            toDestinationLatitude: point.lat,
            destinationLongitude: point.lon
        )
        item.distanceMeters = Double(meters)
        item.distance = OAOsmAndFormatter.getFormattedDistance(Float(meters))

        item.direction = OADistanceAndDirectionsUpdater.getDirectionAngle(
            from: location,
            toDestinationLatitude: point.lat,
            destinationLongitude: point.lon
        )
    }

    private func updateAllWaypointsDistanceAndDirection() {
        groups.flatMap(\.items).forEach { updateWaypointDistanceAndDirection(for: $0) }
    }
    
    @objc private func updateDistanceAndDirection() {
        updateDistanceAndDirection(force: false)
    }

    private func updateDistanceAndDirection(force: Bool) {
        updateLock.lock()
        defer { updateLock.unlock() }

        if let lastUpdate, Date.now.timeIntervalSince1970 - lastUpdate < 0.5, !force {
            return
        }
        lastUpdate = Date.now.timeIntervalSince1970

        updateAllWaypointsDistanceAndDirection()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let visible = self.tableView.indexPathsForVisibleRows?.filter { $0.section > 0 && $0.row > 0 } ?? []
            guard !visible.isEmpty else { return }
            for indexPath in visible {
                guard let cell = self.tableView.cellForRow(at: indexPath) as? OAPointWithRegionTableViewCell else { continue }
                guard let item = self.tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem) as? OAGpxWptItem else { continue }
                
                self.updatePointDistanceAndDirectionCell(cell, wptItem: item)
            }
        }
    }
    
    private func updatePointDistanceAndDirectionCell(_ cell: OAPointWithRegionTableViewCell, wptItem: OAGpxWptItem) {
        if let distance = wptItem.distance, !distance.isEmpty {
            cell.setDirection(distance)
            cell.directionIconView.image = .templateImageNamed("ic_small_direction")
            cell.directionIconView.tintColor = .iconColorActive
            cell.directionIconView.transform = CGAffineTransform(rotationAngle: wptItem.direction)
        } else {
            cell.setDirection("")
        }
    }
}
