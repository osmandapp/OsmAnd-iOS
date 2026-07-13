//
//  PlanRoutePoiViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRoutePoiViewController: UIViewController, PlanRouteTabContent {
    private static let separatorLeftInset: CGFloat = 72
    private static let bottomContentInset: CGFloat = 72
    private static let emptySectionsCount = 2
    private static let poiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
    
    let planRouteTab: PlanRouteTab = .poi
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var groups: [PlanRoutePoiGroup] = []
    private var didLoadTableData = false
    private var isContextMenuVisible = false
    private var shouldReloadTableView = false
    private var pendingContextMenuAction: (() -> Void)?
    private var sortModeByGroupName: [String: TrackFavoriteSortMode] = [:]
    private weak var dataSource: PlanRoutePoiDataSource?
    private var isEmptyState: Bool {
        groups.isEmpty
    }

    init(dataSource: PlanRoutePoiDataSource?) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        guard isViewLoaded else { return }
        let newGroups = sortedPoiGroups(dataSource?.poiGroups ?? [])
        let sameTableStructure = didLoadTableData && groups.elementsEqual(newGroups) {
            $0.name == $1.name && $0.points.count == $1.points.count
        }

        guard sameTableStructure else {
            guard !isContextMenuVisible else {
                shouldReloadTableView = true
                return
            }

            groups = newGroups
            didLoadTableData = true
            tableView.reloadData()
            return
        }

        groups = newGroups
        guard !isContextMenuVisible else { return }
        updateVisiblePoiCells()
    }

    private func sortedPoiGroups(_ groups: [PlanRoutePoiGroup]) -> [PlanRoutePoiGroup] {
        groups.map { PlanRoutePoiGroup(name: $0.name, points: TrackFavoriteSortModeHelper.sortTrackPointsWithMode($0.points, mode: sortMode(for: $0.name))) }
    }

    private func sortMode(for groupName: String) -> TrackFavoriteSortMode {
        sortModeByGroupName[groupName] ?? TrackFavoriteSortModeHelper.defaultSortMode
    }

    private func updateVisiblePoiCells() {
        tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard groups.indices.contains(indexPath.section), groups[indexPath.section].points.indices.contains(indexPath.row), let cell = tableView.cellForRow(at: indexPath) as? OASimpleTableViewCell else { return }
            configurePoiCell(cell, with: groups[indexPath.section].points[indexPath.row])
        }
    }

    private func finishContextMenuInteraction() {
        isContextMenuVisible = false
        if let pendingContextMenuAction {
            self.pendingContextMenuAction = nil
            shouldReloadTableView = false
            pendingContextMenuAction()
            return
        }
    
        guard shouldReloadTableView else { return }
        shouldReloadTableView = false
        reloadData()
    }

    private func performContextMenuAction(_ action: @escaping () -> Void) {
        guard isContextMenuVisible else {
            shouldReloadTableView = false
            action()
            return
        }

        pendingContextMenuAction = action
    }

    private func setupTableView() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Self.separatorLeftInset, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Self.bottomContentInset, right: 0)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 60
        tableView.sectionHeaderTopPadding = 0
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OARightIconTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OARightIconTableViewCell.reuseIdentifier)
        tableView.register(PlanRoutePoiGroupHeaderView.self, forHeaderFooterViewReuseIdentifier: PlanRoutePoiGroupHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configurePoiCell(_ cell: OASimpleTableViewCell, with point: PlanRoutePoiPoint) {
        cell.backgroundColor = .groupBg
        cell.selectionStyle = .none
        cell.titleLabel.text = point.name
        cell.titleLabel.textColor = .textColorPrimary
        cell.descriptionLabel.text = nil
        cell.descriptionLabel.textColor = .textColorSecondary
        let description = poiDescription(for: point)
        cell.descriptionLabel.attributedText = description
        cell.descriptionVisibility(description != nil)
        cell.leftIconView.image = point.icon
        cell.leftIconView.contentMode = .scaleAspectFit
        cell.leftIconVisibility(true)
        cell.leftEditButtonVisibility(false)
        cell.setLeftIconSize(36)
    }

    private func poiDescription(for point: PlanRoutePoiPoint) -> NSAttributedString? {
        let font = UIFont.scaledSystemFont(ofSize: 15)
        let directionAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.iconColorDirectionActive]
        let secondaryAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.textColorSecondary]
        let result = NSMutableAttributedString()
        let date = poiDate(for: point)
        let distanceAndDirection = poiDistanceAndDirection(for: point)
        if let distance = distanceAndDirection.distance, !distance.isEmpty {
            appendPoiSecondarySeparatorIfNeeded(to: result, attributes: secondaryAttributes)
            if let directionIcon = poiDirectionIcon(font: font, direction: distanceAndDirection.direction) {
                result.append(directionIcon)
            }
            result.append(NSAttributedString(string: distance, attributes: directionAttributes))
        }

        let address = poiAddress(for: point)
        appendPoiSecondaryText(address, to: result, attributes: secondaryAttributes)
        appendPoiSecondaryText(date, to: result, attributes: secondaryAttributes)

        return result.length > 0 ? result : nil
    }

    private func appendPoiSecondaryText(_ text: String?, to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard let text, !text.isEmpty else { return }
        appendPoiSecondarySeparatorIfNeeded(to: result, attributes: attributes)
        result.append(NSAttributedString(string: text, attributes: attributes))
    }

    private func appendPoiSecondarySeparatorIfNeeded(to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard result.length > 0 else { return }
        result.append(NSAttributedString(string: " • ", attributes: attributes))
    }

    private func poiDirectionIcon(font: UIFont, direction: CGFloat) -> NSAttributedString? {
        let size = UIFontMetrics.default.scaledValue(for: 18)
        guard let image = OAUtilities.resize(.icSmallDirection, newSize: CGSize(width: size, height: size))?.withTintColor(.iconColorDirectionActive, renderingMode: .alwaysOriginal) else { return nil }
        let rotatedImage = image.rotateWithDiagonalSize(radians: direction) ?? image
        let attachment = NSTextAttachment()
        attachment.image = rotatedImage
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - rotatedImage.size.height) / 2, width: rotatedImage.size.width, height: rotatedImage.size.height)
        return NSAttributedString(attachment: attachment)
    }

    private func poiDistanceAndDirection(for point: PlanRoutePoiPoint) -> (distance: String?, direction: CGFloat) {
        guard let wpt = point.item.point, let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation else { return (nil, 0) }
        let meters = OADistanceAndDirectionsUpdater.getDistanceFrom(location, toDestinationLatitude: wpt.lat, destinationLongitude: wpt.lon)
        return (OAOsmAndFormatter.getFormattedDistance(Float(meters)), OADistanceAndDirectionsUpdater.getDirectionAngle(from: location, toDestinationLatitude: wpt.lat, destinationLongitude: wpt.lon))
    }

    private func poiAddress(for point: PlanRoutePoiPoint) -> String {
        if !point.subtitle.isEmpty {
            return point.subtitle
        }

        guard let wpt = point.item.point, let region = OsmAndApp.swiftInstance()?.worldRegion.find(atLat: wpt.lat, lon: wpt.lon) else { return "" }
        return region.localizedName ?? region.nativeName ?? ""
    }

    private func poiDate(for point: PlanRoutePoiPoint) -> String? {
        guard let wpt = point.item.point else { return nil }
        let time = TimeInterval(wpt.time)
        guard time > 0 else { return nil }
        return Self.poiDateFormatter.string(from: Date(timeIntervalSince1970: time / 1000))
    }

    private func configureEmptyAddPointsCell(_ cell: OARightIconTableViewCell) {
        cell.backgroundColor = .groupBg
        cell.selectionStyle = .none
        cell.titleLabel.text = localizedString("add_points")
        cell.titleLabel.textColor = .textColorPrimary
        cell.descriptionLabel.text = localizedString("add_points_description")
        cell.descriptionLabel.textColor = .textColorSecondary
        cell.leftIconVisibility(false)
        cell.rightIconVisibility(true)
        cell.rightIconView.image = .icCustomFolderOpen
        cell.rightIconView.tintColor = .iconColorSecondary
    }

    private func configureEmptyAddGroupCell(_ cell: OASimpleTableViewCell) {
        cell.backgroundColor = .groupBg
        cell.selectionStyle = .default
        cell.titleLabel.text = localizedString("fav_add_new_group")
        cell.titleLabel.textColor = .textColorActive
        cell.leftIconVisibility(false)
        cell.descriptionLabel.text = nil
        cell.descriptionLabel.attributedText = nil
        cell.descriptionVisibility(false)
    }

    private func poiCountText(_ count: Int) -> String {
        "\(count) \(localizedString("shared_string_gpx_points").lowercased())"
    }

    private func showAddPoiGroupAlert() {
        let alert = UIAlertController(title: localizedString("fav_add_new_group"), message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = localizedString("shared_string_new_name")
        }
        
        let addAction = UIAlertAction(title: localizedString("shared_string_add"), style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }
            dataSource?.addPoiGroup(name)
            reloadData()
        }
        
        alert.addAction(addAction)
        alert.preferredAction = addAction
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
}

extension PlanRoutePoiViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        isEmptyState ? Self.emptySectionsCount : groups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isEmptyState ? 1 : groups[section].points.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isEmptyState {
            if indexPath.section == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier, for: indexPath) as? OARightIconTableViewCell else { return UITableViewCell() }
                configureEmptyAddPointsCell(cell)
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else { return UITableViewCell() }
            configureEmptyAddGroupCell(cell)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell else { return UITableViewCell() }
        configurePoiCell(cell, with: groups[indexPath.section].points[indexPath.row])
        return cell
    }
}

extension PlanRoutePoiViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isEmptyState else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlanRoutePoiGroupHeaderView.reuseIdentifier) as? PlanRoutePoiGroupHeaderView else { return nil }
        let group = groups[section]
        header.configure(title: group.name, subtitle: poiCountText(group.points.count), menu: makePoiGroupMenu(for: group))

        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isEmptyState {
            if indexPath.section == 1 {
                showAddPoiGroupAlert()
            }
            return
        }

        OARootViewController.instance().mapPanel?.openTargetView(withWpt: groups[indexPath.section].points[indexPath.row].item, pushed: false)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !isEmptyState, groups.indices.contains(indexPath.section), groups[indexPath.section].points.indices.contains(indexPath.row) else { return nil }
        isContextMenuVisible = true
        let point = groups[indexPath.section].points[indexPath.row]
        let menuProvider: UIContextMenuActionProvider = { _ in
            let edit = UIAction(title: localizedString("shared_string_edit"), image: .icCustomEdit) { [weak self] _ in
                self?.performContextMenuAction {
                    self?.onEditPoiPoint(point)
                }
            }
            let delete = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
                self?.performContextMenuAction {
                    self?.onDeletePoiPoint(point)
                }
            }
            return UIMenu.composedMenu(from: [[edit], [delete]])
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menuProvider)
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        isContextMenuVisible = true
        return nil
    }

    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        guard let animator else {
            finishContextMenuInteraction()
            return
        }

        animator.addCompletion { [weak self] in
            self?.finishContextMenuInteraction()
        }
    }
}

extension PlanRoutePoiViewController {
    func makePoiGroupMenu(for group: PlanRoutePoiGroup) -> UIMenu {
        let rename = UIAction(title: localizedString("shared_string_rename"), image: .icCustomEdit) { [weak self] _ in
            self?.onRenamePoiGroup(group)
        }
        let changeAppearance = UIAction(title: localizedString("change_appearance"), image: .icCustomAppearanceOutlined) { [weak self] _ in
            self?.onChangePoiGroupAppearance(group)
        }
        let delete = UIAction(title: localizedString("shared_string_delete"), image: .icCustomTrashOutlined, attributes: .destructive) { [weak self] _ in
            self?.onDeletePoiGroup(group)
        }

        return UIMenu.composedMenu(from: [
            [rename, changeAppearance],
            [makePoiGroupSortMenu(group)],
            [delete]
        ])
    }

    func makePoiGroupSortMenu(_ group: PlanRoutePoiGroup) -> UIMenu {
        let sortingOptions = UIMenu(options: .displayInline, children: [makePoiGroupSortAction(.lastModified, group: group)])
        let alphabeticalOptions = UIMenu(options: .displayInline, children: [makePoiGroupSortAction(.nameAZ, group: group), makePoiGroupSortAction(.nameZA, group: group)])
        let dateOptions = UIMenu(options: .displayInline, children: [makePoiGroupSortAction(.newestDateFirst, group: group), makePoiGroupSortAction(.oldestDateFirst, group: group)])
        return UIMenu(title: localizedString("shared_string_sort"), image: .templateImageNamed("ic_custom_swap"), children: [sortingOptions, alphabeticalOptions, dateOptions])
    }

    func makePoiGroupSortAction(_ sortMode: TrackFavoriteSortMode, group: PlanRoutePoiGroup) -> UIAction {
        UIAction(title: sortMode.title, image: sortMode.image, state: sortMode == self.sortMode(for: group.name) ? .on : .off) { [weak self] _ in
            self?.onSortPoiGroup(group, sortMode: sortMode)
        }
    }

    func onRenamePoiGroup(_ group: PlanRoutePoiGroup) {
        let alert = UIAlertController(title: localizedString("shared_string_rename"), message: localizedString("enter_new_name"), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = group.name
        }

        let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let newName = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !newName.isEmpty, newName != group.name else { return }
            (dataSource as? PlanRouteEditingContextDataProvider)?.renamePoiGroup(from: group.name, to: newName)
            sortModeByGroupName[newName] = sortModeByGroupName.removeValue(forKey: group.name)
            reloadData()
        }

        alert.addAction(applyAction)
        alert.preferredAction = applyAction
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func onChangePoiGroupAppearance(_ group: PlanRoutePoiGroup) {
        (dataSource as? PlanRouteEditingContextDataProvider)?.openPoiGroupAppearance(group.name, from: self)
    }

    func onSortPoiGroup(_ group: PlanRoutePoiGroup, sortMode: TrackFavoriteSortMode) {
        sortModeByGroupName[group.name] = sortMode
        groups = sortedPoiGroups(dataSource?.poiGroups ?? groups)
        tableView.reloadData()
    }

    func onDeletePoiGroup(_ group: PlanRoutePoiGroup) {
        sortModeByGroupName.removeValue(forKey: group.name)
        (dataSource as? PlanRouteEditingContextDataProvider)?.deletePoiGroup(group.name)
    }

    func onEditPoiPoint(_ point: PlanRoutePoiPoint) {
        (dataSource as? PlanRouteEditingContextDataProvider)?.openEditPoiPoint(point, from: self)
    }
    
    func onDeletePoiPoint(_ point: PlanRoutePoiPoint) {
        (dataSource as? PlanRouteEditingContextDataProvider)?.deletePoiPoint(point)
    }
}
