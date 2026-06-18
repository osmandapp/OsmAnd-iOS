//
//  SelectPointsViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

protocol SelectPointsDelegate: AnyObject {
    func onPointsSelected(_ trackItem: ImportTrackItem, selectedPoints: [WptPt])
}

final class SelectPointsViewController: OABaseButtonsViewController {

    private enum RowKey: String {
        case infoDescr
        case selectNearest
        case group
        case point
    }

    private enum RowObjKey: String {
        case attributedTitleKey = "attributedTitle"
        case wptItem = "wptItem"
        case group = "group"
    }

    private enum SelectionState {
        case none, part, all
    }

    private final class WaypointGroup {
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

    weak var delegate: SelectPointsDelegate?

    private let track: ImportTrackItem
    private let allPoints: [WptPt]
    private let suggestedPoints: [WptPt]
    private let selection: SelectionManager<WptPt>
    private var groups: [WaypointGroup] = []

    private var lastUpdate: TimeInterval?
    private let updateLock = NSLock()

    // MARK: - Init

    init(track: ImportTrackItem, allPoints: [WptPt]) {
        self.track = track
        self.allPoints = allPoints
        self.selection = SelectionManager(allItems: allPoints, initiallySelected: track.selectedPoints)
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
        setupTable()
        groups = makeGroups(from: allPoints)
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
        appendInfoSection()
        groups.forEach { appendGroupSection(for: $0) }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)

        switch item.cellType {
        case OASimpleTableViewCell.reuseIdentifier:
            return configuredSimpleCell(for: item, at: indexPath)
        case OASelectionCollapsableCell.reuseIdentifier:
            return configuredGroupCell(for: item, at: indexPath)
        case OAPointWithRegionTableViewCell.reuseIdentifier:
            return configuredPointCell(for: item, at: indexPath)
        default:
            return UITableViewCell()
        }
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        switch tableData.item(for: indexPath).key {
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

    override func hideFirstHeader() -> Bool { true }

    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        tableData.sectionData(for: UInt(section)).headerText.isEmpty ? 16 : UITableView.automaticDimension
    }

    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        tableData.sectionData(for: UInt(section)).footerText.isEmpty ? 0 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section > 0, indexPath.row > 0 else { return }
        guard let wptItem = tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem.rawValue) as? OAGpxWptItem else { return }

        if selection.selectedItems.contains(wptItem.point) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        cell.separatorInset = UIEdgeInsets(top: 0, left: cell.contentView.frame.minX + 66, bottom: 0, right: 16)
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
        return OAUtilities.resize(image, newSize: CGSize(width: 24, height: 24))?.withRenderingMode(.alwaysTemplate)
    }

    override func getCustomAccessibilityForLeftNavbarButton() -> String? {
        localizedString("shared_string_close")
    }

    override func onLeftNavbarButtonPressed() {
        showExitConfirmationAction()
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem]? {
        let title = localizedString(selection.areAllSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        let item = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(onSelectAllAction))
        item.tintColor = .label
        item.accessibilityLabel = title
        return [item]
    }

    override func updateNavbar() {
        super.updateNavbar()
        (getLeftNavbarButton()?.customView as? UIButton)?.tintColor = .label
    }

    // MARK: - Bottom buttons

    override func getTopButtonTitle() -> String? {
        localizedString("shared_string_apply")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }

    override func isBottomSeparatorVisible() -> Bool { false }

    override func onTopButtonPressed() {
        applyAction()
    }
}

// MARK: - Table Data

private extension SelectPointsViewController {
    func appendInfoSection() {
        let section = tableData.createNewSection()

        let descriptionRow = section.createNewRow()
        descriptionRow.cellType = OASimpleTableViewCell.reuseIdentifier
        descriptionRow.key = RowKey.infoDescr.rawValue
        descriptionRow.setObj(makeTopDescription(), forKey: RowObjKey.attributedTitleKey.rawValue)

        if !suggestedPoints.isEmpty {
            section.footerText = localizedString("auto_select_nearest_footer")
            
            let selectNearestRow = section.createNewRow()
            selectNearestRow.cellType = OASimpleTableViewCell.reuseIdentifier
            selectNearestRow.key = RowKey.selectNearest.rawValue
            selectNearestRow.title = localizedString("auto_select_nearest_points")
        }
    }

    private func appendGroupSection(for group: WaypointGroup) {
        let section = tableData.createNewSection()

        let groupRow = section.createNewRow()
        groupRow.cellType = OASelectionCollapsableCell.reuseIdentifier
        groupRow.key = RowKey.group.rawValue
        groupRow.title = group.name
        groupRow.setObj(group, forKey: RowObjKey.group.rawValue)

        guard group.isExpanded else { return }

        for item in group.items {
            let pointRow = section.createNewRow()
            pointRow.cellType = OAPointWithRegionTableViewCell.reuseIdentifier
            pointRow.key = RowKey.point.rawValue
            pointRow.title = item.point.name ?? ""
            pointRow.setObj(item, forKey: RowObjKey.wptItem.rawValue)
        }
    }
}

// MARK: - Cell Configuration

private extension SelectPointsViewController {
    func configuredSimpleCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.leftIconVisibility(false)
        cell.setCustomLeftSeparatorInset(true)
        cell.textStackView.isHidden = false

        switch item.key {
        case RowKey.infoDescr.rawValue:
            cell.descriptionLabel.attributedText = item.obj(forKey: RowObjKey.attributedTitleKey.rawValue) as? NSAttributedString
            cell.descriptionVisibility(true)
            cell.titleVisibility(false)
            hideSeparator(for: cell, false)
            cell.selectionStyle = .none
            cell.accessibilityLabel = cell.descriptionLabel.attributedText?.string
            cell.accessibilityTraits = .staticText
        case RowKey.selectNearest.rawValue:
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorActive
            cell.titleVisibility(true)
            cell.descriptionVisibility(false)
            hideSeparator(for: cell, true)
            cell.selectionStyle = .default
            cell.accessibilityLabel = item.title
            cell.accessibilityTraits = .button
        default:
            break
        }
        return cell
    }

    func configuredGroupCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OASelectionCollapsableCell.reuseIdentifier, for: indexPath) as! OASelectionCollapsableCell
        guard let group = item.obj(forKey: RowObjKey.group.rawValue) as? WaypointGroup else { return cell }

        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        cell.showOptionsButton(false)
        cell.makeSelectable(true)
        cell.titleView.text = item.title
        cell.leftIconView.image = .icCustomFolder
        cell.leftIconView.tintColor = item.iconTintColor ?? .iconColorActive
        cell.arrowIconView.tintColor = .iconColorActive
        cell.arrowIconView.image = group.isExpanded ? .icCustomArrowDown : .icCustomArrowUp
        cell.selectionButton.setImage(groupSelectionImage(for: group), for: .normal)
        cell.selectionButton.tintColor = .iconColorActive

        configureGroupButton(cell.openCloseGroupButton, tag: group.index, action: #selector(openCloseGroupAction(_:)))
        configureGroupButton(cell.selectionButton, tag: group.index, action: #selector(onGroupSelectTapped(_:)))
        configureGroupButton(cell.selectionGroupButton, tag: group.index, action: #selector(onGroupSelectTapped(_:)))
        
        let state = groupSelectionState(for: group)
        let selectedValue: String = switch state {
        case .all: localizedString("shared_string_selected")
        case .none: localizedString("shared_string_not_selected")
        case .part: String(format: localizedString("ltr_or_rtl_combine_via_slash"),
                           "\(group.items.filter { selection.selectedItems.contains($0.point) }.count)",
                           "\(group.items.count)")
        }
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = group.name
        cell.accessibilityValue = selectedValue
        cell.accessibilityTraits = .button
        
        cell.openCloseGroupButton.accessibilityLabel = localizedString(
            group.isExpanded ? "shared_string_collapse" : "shared_string_show"
        )
        cell.selectionButton.isAccessibilityElement = false
        cell.selectionGroupButton.isAccessibilityElement = false
        cell.leftIconView.isAccessibilityElement = false
        cell.arrowIconView.isAccessibilityElement = false

        cell.setNeedsUpdateConstraints()
        return cell
    }

    func configuredPointCell(for item: OATableRowData, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OAPointWithRegionTableViewCell.reuseIdentifier, for: indexPath) as! OAPointWithRegionTableViewCell
        guard let wptItem = item.obj(forKey: RowObjKey.wptItem.rawValue) as? OAGpxWptItem else { return cell }

        cell.setRegion(wptItem.point.getAddress() ?? "")
        cell.titleView.text = wptItem.point.name ?? ""
        cell.iconView.image = wptItem.compositeIconWithDefaultColor()
        cell.setShowWaypointButtonVisiblity(false)
        updatePointDistanceAndDirectionCell(cell, wptItem: wptItem)

        cell.contentView.backgroundColor = .groupBg
        if cell.selectedBackgroundView?.backgroundColor != .groupBg {
            let backgroundView = UIView()
            backgroundView.backgroundColor = .groupBg
            cell.selectedBackgroundView = backgroundView
        }
        
        let isSelected = selection.selectedItems.contains(wptItem.point)
        let name = wptItem.point.name ?? localizedString("shared_string_waypoint")
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = name
        cell.accessibilityTraits = isSelected ? [.button, .selected] : .button
        cell.accessibilityValue = [
            localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected"),
            wptItem.point.getAddress(),
            wptItem.distance
        ].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
        cell.iconView.isAccessibilityElement = false
        cell.directionIconView.isAccessibilityElement = false
        
        cell.setNeedsUpdateConstraints()
        return cell
    }

    func configureGroupButton(_ button: UIButton, tag: Int, action: Selector) {
        button.tag = tag
        button.removeTarget(nil, action: nil, for: .allEvents)
        button.addTarget(self, action: action, for: .touchUpInside)
    }
}

// MARK: - Setup & Helpers

private extension SelectPointsViewController {
    func setupTable() {
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.isEditing = true
    }

    func hideSeparator(for cell: UITableViewCell, _ isHidden: Bool) {
        let inset = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        cell.separatorInset = UIEdgeInsets(
            top: 0,
            left: isHidden ? inset : 16,
            bottom: 0,
            right: isHidden ? -inset : 16
        )
    }

    func makeTopDescription() -> NSAttributedString {
        let text = String(format: localizedString("selected_waypoints_descr"), track.name)
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let boldFont = baseFont.fontDescriptor.withSymbolicTraits(.traitBold).map { UIFont(descriptor: $0, size: 0) } ?? baseFont

        let result = NSMutableAttributedString(
            string: text,
            attributes: [.font: baseFont, .foregroundColor: UIColor.textColorPrimary]
        )

        let fileRange = (text as NSString).range(of: track.name)
        if fileRange.location != NSNotFound {
            result.addAttribute(.font, value: boldFont, range: fileRange)
        }
        return result
    }

    func updateSelectAllButtonTitle() {
        let title = localizedString(selection.areAllSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let item = navigationItem.rightBarButtonItems?.first else { return }
        item.title = title
        item.accessibilityLabel = title
    }
}

// MARK: - Groups

private extension SelectPointsViewController {
    private func makeGroups(from points: [WptPt]) -> [WaypointGroup] {
        var groupedItems: [String: [OAGpxWptItem]] = [:]
        let defaultName = localizedString("shared_string_gpx_points")

        for point in points {
            let groupName = point.category.flatMap { $0.isEmpty ? nil : $0 } ?? defaultName
            groupedItems[groupName, default: []].append(OAGpxWptItem.withGpxWpt(point))
        }

        return groupedItems.keys.sorted().compactMap { name -> (String, [OAGpxWptItem])? in
            guard let items = groupedItems[name], !items.isEmpty else { return nil }
            return (name, items)
        }.enumerated().map { index, entry in
            WaypointGroup(index: index, name: entry.0, items: entry.1, isExpanded: true)
        }
    }

    private func group(at indexPath: IndexPath) -> WaypointGroup? {
        tableData.item(for: IndexPath(row: 0, section: indexPath.section))
            .obj(forKey: RowObjKey.group.rawValue) as? WaypointGroup
    }

    private func groupSelectionState(for group: WaypointGroup) -> SelectionState {
        guard !group.items.isEmpty else { return .none }
        let selectedCount = group.items.filter { selection.selectedItems.contains($0.point) }.count
        if selectedCount == 0 { return .none }
        if selectedCount == group.items.count { return .all }
        return .part
    }

    private func groupSelectionImage(for group: WaypointGroup) -> UIImage? {
        switch groupSelectionState(for: group) {
        case .all: return UIImage(named: "ic_system_checkbox_selected")
        case .part: return UIImage(named: "ic_system_checkbox_indeterminate")
        case .none: return nil
        }
    }

    private func indexPath(forGroupAt index: Int) -> IndexPath {
        IndexPath(row: 0, section: index + 1)
    }

    private func toggleExpandGroup(_ group: WaypointGroup) {
        group.isExpanded.toggle()
        generateData()
        tableView.reloadSections(IndexSet(integer: group.index + 1), with: .automatic)
    }
}

// MARK: - Points

private extension SelectPointsViewController {
    func togglePoint(at indexPath: IndexPath) {
        guard let group = group(at: indexPath),
              let wptItem = tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem.rawValue) as? OAGpxWptItem,
              let point = wptItem.point else { return }

        let previousState = groupSelectionState(for: group)
        selection.toggle(point)

        updateSelectAllButtonTitle()
        if previousState != groupSelectionState(for: group) {
            tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
        }
    }
}

// MARK: - Actions

private extension SelectPointsViewController {
    @objc func onSelectAllAction() {
        if selection.areAllSelected {
            selection.deselectAll()
        } else {
            selection.selectAll()
        }
        updateSelectAllButtonTitle()
        tableView.reloadData()
    }

    func applyAction() {
        delegate?.onPointsSelected(track, selectedPoints: Array(selection.selectedItems))
        dismiss(animated: true)
    }

    func selectNearestAction() {
        selection.deselectAll()
        Set(suggestedPoints).forEach { selection.toggle($0) }
        updateSelectAllButtonTitle()
        tableView.reloadData()
    }

    @objc func showExitConfirmationAction() {
        guard selection.hasChanges else {
            dismiss(animated: true)
            return
        }

        let alert = UIAlertController(
            title: localizedString("unsaved_changes"),
            message: localizedString("selected_waypoints_exit_descr"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("shared_string_continue"), style: .default))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_close"), style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc func onGroupSelectTapped(_ sender: UIButton) {
        guard let group = groups.first(where: { $0.index == sender.tag }) else { return }

        let points = group.items.compactMap(\.point)
        let shouldDeselect = !points.isEmpty && points.allSatisfy { selection.selectedItems.contains($0) }
        points.forEach { point in
            if shouldDeselect == selection.selectedItems.contains(point) {
                selection.toggle(point)
            }
        }

        updateSelectAllButtonTitle()
        tableView.reloadSections(IndexSet(integer: indexPath(forGroupAt: group.index).section), with: .none)
    }

    @objc func openCloseGroupAction(_ sender: UIButton) {
        guard let group = groups.first(where: { $0.index == sender.tag }) else { return }
        toggleExpandGroup(group)
    }
}

// MARK: - Distance And Direction

private extension SelectPointsViewController {
    func updateWaypointDistanceAndDirection(for item: OAGpxWptItem) {
        guard let point = item.point,
              let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation else {
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

    @objc func updateDistanceAndDirection() {
        updateDistanceAndDirection(force: false)
    }

    func updateDistanceAndDirection(force: Bool) {
        updateLock.lock()
        defer { updateLock.unlock() }

        if let lastUpdate, Date.now.timeIntervalSince1970 - lastUpdate < 0.5, !force {
            return
        }
        lastUpdate = Date.now.timeIntervalSince1970

        groups.flatMap(\.items).forEach { updateWaypointDistanceAndDirection(for: $0) }

        DispatchQueue.main.async { [weak self] in
            self?.refreshVisiblePointCells()
        }
    }

    func refreshVisiblePointCells() {
        let visibleIndexPaths = tableView.indexPathsForVisibleRows?.filter { $0.section > 0 && $0.row > 0 } ?? []
        for indexPath in visibleIndexPaths {
            guard let cell = tableView.cellForRow(at: indexPath) as? OAPointWithRegionTableViewCell,
                  let wptItem = tableData.item(for: indexPath).obj(forKey: RowObjKey.wptItem.rawValue) as? OAGpxWptItem else { continue }
            updatePointDistanceAndDirectionCell(cell, wptItem: wptItem)
        }
    }

    func updatePointDistanceAndDirectionCell(_ cell: OAPointWithRegionTableViewCell, wptItem: OAGpxWptItem) {
        if let distance = wptItem.distance, !distance.isEmpty {
            cell.setDirection(distance)
            cell.directionIconView.image = .icSmallDirection
            cell.directionIconView.tintColor = .iconColorActive
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                cell.directionIconView.transform = CGAffineTransform(rotationAngle: wptItem.direction)
            }
        } else {
            cell.setDirection("")
        }
    }
}
