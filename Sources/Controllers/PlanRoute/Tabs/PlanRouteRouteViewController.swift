//
//  PlanRouteRouteViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteRouteViewController: UIViewController, PlanRouteTabContent {
    let planRouteTab: PlanRouteTab = .route

    private enum Row {
        case profileGroup(PlanRouteProfileGroup, segment: PlanRouteSegment)
        case point(PlanRoutePoint, color: UIColor)
        case empty
    }

    private struct SectionModel {
        let headerTitle: String?
        let headerSubtitle: String?
        let headerMenu: UIMenu?
        let rows: [Row]
        let isStartNewSegment: Bool
    }

    private static let separatorLeftInset: CGFloat = 76
    private static let bottomContentInset: CGFloat = 72

    private weak var dataSource: PlanRoutePointsDataSource?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [SectionModel] = []

    init(dataSource: PlanRoutePointsDataSource?) {
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

    func reloadData() {
        guard isViewLoaded else { return }
        sections = buildSections()
        tableView.reloadData()
    }

    private func setupTableView() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Self.separatorLeftInset, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Self.bottomContentInset, right: 0)
        tableView.sectionHeaderTopPadding = 0
        tableView.register(PlanRoutePointCell.self, forCellReuseIdentifier: PlanRoutePointCell.cellReuseId)
        tableView.register(PlanRouteProfileGroupCell.self, forCellReuseIdentifier: PlanRouteProfileGroupCell.cellReuseId)
        tableView.register(PlanRouteEmptyCell.self, forCellReuseIdentifier: PlanRouteEmptyCell.cellReuseId)
        tableView.register(PlanRouteStartSegmentCell.self, forCellReuseIdentifier: PlanRouteStartSegmentCell.cellReuseId)
        tableView.register(PlanRouteSegmentHeaderView.self, forHeaderFooterViewReuseIdentifier: PlanRouteSegmentHeaderView.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buildSections() -> [SectionModel] {
        let segments = dataSource?.routeSegments ?? []
        guard !segments.isEmpty else {
            return [SectionModel(headerTitle: localizedString("route_points"),
                                 headerSubtitle: nil,
                                 headerMenu: makeRouteTypeMenu(pointIndex: 0),
                                 rows: [.empty],
                                 isStartNewSegment: false)]
        }

        let multipleSegments = segments.count > 1
        var result: [SectionModel] = segments.map { makeSection(for: $0, multipleSegments: multipleSegments) }
        if dataSource?.canStartNewSegment ?? false {
            result.append(SectionModel(headerTitle: nil,
                                       headerSubtitle: nil,
                                       headerMenu: nil,
                                       rows: [],
                                       isStartNewSegment: true))
        }
        return result
    }

    private func makeSection(for segment: PlanRouteSegment, multipleSegments: Bool) -> SectionModel {
        var rows: [Row] = []
        for group in segment.groups {
            let color = group.appMode?.getProfileColor() ?? .iconColorActive
            if segment.multiMode, group.appMode != nil {
                rows.append(.profileGroup(group, segment: segment))
            }
            rows.append(contentsOf: group.points.map { Row.point($0, color: color) })
        }

        let title: String
        if segment.routed || multipleSegments {
            title = String(format: localizedString("segments_count"), segment.index + 1)
        } else {
            title = localizedString("route_points")
        }

        var subtitle: String?
        if segment.routed, !segment.multiMode, let mode = segment.singleMode {
            let modeName = mode.toHumanString() ?? ""
            subtitle = "\(modeName) • \(formattedDistance(segment.distance))"
        }

        return SectionModel(headerTitle: title,
                            headerSubtitle: subtitle,
                            headerMenu: makeSegmentMenu(for: segment),
                            rows: rows,
                            isStartNewSegment: false)
    }

    private func makeSegmentMenu(for segment: PlanRouteSegment) -> UIMenu {
        var children: [UIMenuElement] = []
        if segment.multiMode {
            children.append(UIAction(title: localizedString("set_single_mode"),
                                     image: .templateImageNamed("ic_custom_point_to_point")) { [weak self] _ in
                self?.setSingleMode(for: segment)
            })
        } else {
            children.append(UIAction(title: localizedString("change_mode"),
                                     subtitle: segment.singleMode?.toHumanString(),
                                     image: segment.singleMode?.getIcon()) { [weak self] _ in
                self?.presentModePicker(pointIndex: segment.pointIndexes.last ?? 0, wholeRoute: true)
            })
        }
        children.append(makeSortMenu(pointIndexes: segment.pointIndexes))
        children.append(UIAction(title: localizedString("plan_route_save_as"),
                                 image: .templateImageNamed("ic_custom_save_to_file")) { [weak self] _ in
            self?.dataSource?.saveSegment(pointIndexes: segment.pointIndexes)
        })
        children.append(UIAction(title: localizedString("delete_segment"),
                                 image: .templateImageNamed("ic_custom_trash_outlined"),
                                 attributes: .destructive) { [weak self] _ in
            self?.deleteSegment(pointIndexes: segment.pointIndexes)
        })
        return UIMenu(children: children)
    }

    private func makeGroupMenu(for group: PlanRouteProfileGroup, in segment: PlanRouteSegment) -> UIMenu {
        let groupIndexes = group.points.map { $0.index }
        let changeRouteType = UIAction(title: localizedString("change_mode"),
                                       subtitle: group.appMode?.toHumanString(),
                                       image: group.appMode?.getIcon()) { [weak self] _ in
            self?.presentModePicker(pointIndex: group.lastPointIndex, wholeRoute: false)
        }
        let deleteSection = UIAction(title: localizedString("delete_section"),
                                     image: .templateImageNamed("ic_custom_trash_outlined"),
                                     attributes: .destructive) { [weak self] _ in
            self?.deleteSegment(pointIndexes: groupIndexes)
        }
        return UIMenu(children: [changeRouteType, makeSortMenu(pointIndexes: groupIndexes), deleteSection])
    }

    private func makeRouteTypeMenu(pointIndex: Int) -> UIMenu {
        let changeRouteType = UIAction(title: localizedString("change_mode"),
                                       image: .templateImageNamed("ic_custom_point_to_point")) { [weak self] _ in
            self?.presentModePicker(pointIndex: pointIndex, wholeRoute: true)
        }
        return UIMenu(children: [changeRouteType])
    }

    private func makeSortMenu(pointIndexes: [Int]) -> UIMenu {
        let sortImage = UIImage(systemName: "arrow.up.arrow.down")
        let manual = UIAction(title: localizedString("shared_string_manual"),
                              image: sortImage,
                              state: .on) { _ in }
        let doorToDoor = UIAction(title: localizedString("intermediate_items_sort_by_distance"),
                                  image: .templateImageNamed("ic_custom_sort_door_to_door")) { [weak self] _ in
            self?.dataSource?.sortDoorToDoor(pointIndexes: pointIndexes)
            self?.reloadData()
        }
        return UIMenu(title: localizedString("shared_string_sort"), image: sortImage, children: [manual, doorToDoor])
    }

    private func presentModePicker(pointIndex: Int, wholeRoute: Bool) {
        guard let dataSource else { return }
        let alert = UIAlertController(title: localizedString("change_mode"), message: nil, preferredStyle: .actionSheet)
        for mode in dataSource.availableModes {
            alert.addAction(UIAlertAction(title: mode.toHumanString(), style: .default) { [weak self] _ in
                dataSource.applyMode(mode, pointIndex: pointIndex, wholeRoute: wholeRoute)
                self?.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func setSingleMode(for segment: PlanRouteSegment) {
        guard let mode = segment.groups.compactMap({ $0.appMode }).first else { return }
        dataSource?.applyMode(mode, pointIndex: segment.pointIndexes.last ?? 0, wholeRoute: true)
        reloadData()
    }

    private func deleteSegment(pointIndexes: [Int]) {
        dataSource?.deleteSegment(pointIndexes: pointIndexes)
        reloadData()
    }

    private func deletePoint(at index: Int) {
        dataSource?.deleteRoutePoint(at: index)
        reloadData()
    }

    private func startNewSegment() {
        dataSource?.startNewSegment()
        reloadData()
    }

    private func formattedDistance(_ meters: Double) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters)) ?? ""
    }
}

// MARK: - UITableViewDataSource
extension PlanRouteRouteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let model = sections[section]
        return model.isStartNewSegment ? 1 : model.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        if section.isStartNewSegment {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteStartSegmentCell.cellReuseId, for: indexPath) as? PlanRouteStartSegmentCell else {
                return UITableViewCell()
            }
            return cell
        }
        switch section.rows[indexPath.row] {
        case .empty:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteEmptyCell.cellReuseId, for: indexPath) as? PlanRouteEmptyCell else {
                return UITableViewCell()
            }
            return cell
        case let .profileGroup(group, segment):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteProfileGroupCell.cellReuseId, for: indexPath) as? PlanRouteProfileGroupCell else {
                return UITableViewCell()
            }
            let mode = group.appMode
            cell.configure(title: mode?.toHumanString() ?? "",
                           distanceText: formattedDistance(group.distance),
                           icon: mode?.getIcon(),
                           tintColor: mode?.getProfileColor() ?? .iconColorActive,
                           menu: makeGroupMenu(for: group, in: segment))
            return cell
        case let .point(point, color):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRoutePointCell.cellReuseId, for: indexPath) as? PlanRoutePointCell else {
                return UITableViewCell()
            }
            cell.configure(with: point, tintColor: color)
            cell.onDelete = { [weak self] in
                self?.deletePoint(at: point.index)
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension PlanRouteRouteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section].headerTitle else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlanRouteSegmentHeaderView.reuseId) as? PlanRouteSegmentHeaderView else {
            return nil
        }
        header.configure(title: title, subtitle: sections[section].headerSubtitle, menu: sections[section].headerMenu)
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = sections[indexPath.section]
        if section.isStartNewSegment {
            startNewSegment()
            return
        }
        if case let .point(point, _) = section.rows[indexPath.row] {
            dataSource?.selectRoutePoint(at: point.index)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard !sections[indexPath.section].isStartNewSegment else { return false }
        if case .point = sections[indexPath.section].rows[indexPath.row] {
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let rows = sections[sourceIndexPath.section].rows
        let pointRows = rows.indices.filter { if case .point = rows[$0] { return true } else { return false } }
        guard let first = pointRows.first, let last = pointRows.last else { return sourceIndexPath }
        if proposedDestinationIndexPath.section != sourceIndexPath.section {
            let row = proposedDestinationIndexPath.section < sourceIndexPath.section ? first : last
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        let clampedRow = min(max(proposedDestinationIndexPath.row, first), last)
        return IndexPath(row: clampedRow, section: sourceIndexPath.section)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rows = sections[sourceIndexPath.section].rows
        let pointGlobals: [Int] = rows.compactMap { row in
            if case let .point(point, _) = row { return point.index }
            return nil
        }
        let fromPosition = pointPosition(in: rows, beforeRow: sourceIndexPath.row)
        let toPosition = pointPosition(in: rows, beforeRow: destinationIndexPath.row)
        guard pointGlobals.indices.contains(fromPosition), pointGlobals.indices.contains(toPosition) else {
            reloadData()
            return
        }
        dataSource?.moveRoutePoint(from: pointGlobals[fromPosition], to: pointGlobals[toPosition])
        reloadData()
    }

    private func pointPosition(in rows: [Row], beforeRow row: Int) -> Int {
        var count = 0
        for index in 0..<min(row, rows.count) {
            if case .point = rows[index] {
                count += 1
            }
        }
        return count
    }
}

final class PlanRouteSegmentHeaderView: UITableViewHeaderFooterView {
    static let reuseId = "PlanRouteSegmentHeaderView"

    private static let optionsButtonSize: CGFloat = 30

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let optionsButton = UIButton(type: .system)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String?, menu: UIMenu?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
        optionsButton.menu = menu
        optionsButton.isHidden = menu == nil
    }

    private func setupView() {
        titleLabel.font = .scaledSystemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis")
        configuration.baseForegroundColor = .iconColorActive
        configuration.background.backgroundColor = UIColor.iconColorActive.withAlphaComponent(0.1)
        configuration.background.cornerRadius = Self.optionsButtonSize / 2
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true

        [textStack, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.optionsButtonSize)
        ])
    }
}

final class PlanRouteProfileGroupCell: UITableViewCell {
    static let cellReuseId = "PlanRouteProfileGroupCell"

    private static let iconSize: CGFloat = 24
    private static let optionsButtonSize: CGFloat = 30

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let optionsButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, distanceText: String, icon: UIImage?, tintColor: UIColor, menu: UIMenu) {
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        distanceLabel.text = distanceText
        optionsButton.menu = menu
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .textColorPrimary

        distanceLabel.font = .scaledSystemFont(ofSize: 15)
        distanceLabel.textColor = .textColorSecondary
        distanceLabel.setContentHuggingPriority(.required, for: .horizontal)

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis")
        configuration.baseForegroundColor = .iconColorActive
        configuration.background.backgroundColor = .clear
        configuration.background.strokeColor = .iconColorTertiary
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = Self.optionsButtonSize / 2
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true

        [iconView, titleLabel, distanceLabel, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),

            distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            optionsButton.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 12),
            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.optionsButtonSize)
        ])
    }
}

final class PlanRouteStartSegmentCell: UITableViewCell {
    static let cellReuseId = "PlanRouteStartSegmentCell"

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.text = localizedString("gpx_start_new_segment")
        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .iconColorActive
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }
}

final class PlanRoutePointCell: UITableViewCell {
    static let cellReuseId = "PlanRoutePointCell"

    private static let circleSize: CGFloat = 28
    private static let deleteSize: CGFloat = 24

    var onDelete: (() -> Void)?

    private let deleteButton = UIButton(type: .system)
    private let numberLabel = UILabel()
    private let numberContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with point: PlanRoutePoint, tintColor: UIColor) {
        numberLabel.text = "\(point.index + 1)"
        numberLabel.textColor = tintColor
        numberContainer.layer.borderColor = tintColor.cgColor
        titleLabel.text = point.name
        subtitleLabel.text = subtitle(for: point)
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none
        showsReorderControl = true

        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(onDeleteTapped), for: .touchUpInside)

        numberContainer.backgroundColor = .clear
        numberContainer.layer.cornerRadius = Self.circleSize / 2
        numberContainer.layer.borderWidth = 1.5
        numberContainer.layer.borderColor = UIColor.iconColorActive.cgColor
        numberLabel.font = .scaledSystemFont(ofSize: 13, weight: .semibold)
        numberLabel.textColor = .iconColorActive
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberContainer.addSubview(numberLabel)

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary

        let textStack = UIStackView(arrangedSubviews: [subtitleLabel, titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [deleteButton, numberContainer, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Self.deleteSize),
            deleteButton.heightAnchor.constraint(equalToConstant: Self.deleteSize),

            numberContainer.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 12),
            numberContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberContainer.widthAnchor.constraint(equalToConstant: Self.circleSize),
            numberContainer.heightAnchor.constraint(equalToConstant: Self.circleSize),
            numberLabel.centerXAnchor.constraint(equalTo: numberContainer.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberContainer.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: numberContainer.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8)
        ])
    }

    private func subtitle(for point: PlanRoutePoint) -> String {
        if point.isStart {
            return localizedString("start_point")
        }
        let distance = OAOsmAndFormatter.getFormattedDistance(Float(point.distanceFromPrevious)) ?? ""
        if point.isDestination {
            return "\(distance) • \(localizedString("route_descr_destination"))"
        }
        return "\(distance) • \(Int(point.bearing))°"
    }

    @objc private func onDeleteTapped() {
        onDelete?()
    }
}

final class PlanRouteEmptyCell: UITableViewCell {
    static let cellReuseId = "PlanRouteEmptyCell"

    private static let iconSize: CGFloat = 30

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        titleLabel.text = localizedString("plan_route_no_points_title")
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0

        descriptionLabel.text = localizedString("plan_route_no_points_descr")
        descriptionLabel.font = .scaledSystemFont(ofSize: 15)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 0

        iconView.image = .templateImageNamed("ic_custom_plan_route")
        iconView.tintColor = .iconColorActive
        iconView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        [textStack, iconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            iconView.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 12),
            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])
    }
}
