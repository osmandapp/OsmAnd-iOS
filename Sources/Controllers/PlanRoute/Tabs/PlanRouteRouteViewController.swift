//
//  PlanRouteRouteViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteRouteViewController: UIViewController, PlanRouteTabContent {
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

    let planRouteTab: PlanRouteTab = .route
    var onPointSelected: ((PlanRoutePoint, PlanRouteProfileGroup, PlanRouteSegment) -> Void)?
    var onChangeRouteType: ((SegmentRouteContext) -> Void)?
    var onOpenRouteBetweenPoints: ((PlanRouteSegment) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [SectionModel] = []
    private var pendingEmptySegmentIndex: Int?
    private var lastContentSignature: String?
    private var doorToDoorSortedKeys: Set<String> = []
    private var isApplyingDoorToDoorSort = false
    private weak var dataSource: PlanRoutePointsDataSource?

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
        let segments = dataSource?.routeSegments ?? []
        if let pendingIndex = pendingEmptySegmentIndex,
           segments.count >= pendingIndex {
            pendingEmptySegmentIndex = nil
        }
        let signature = contentSignature(for: segments)
        guard lastContentSignature != signature else { return }
        if !isApplyingDoorToDoorSort {
            doorToDoorSortedKeys.removeAll()
        }
        isApplyingDoorToDoorSort = false
        lastContentSignature = signature
        sections = buildSections(with: segments)
        tableView.reloadData()
    }

    private func setupTableView() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.alwaysBounceVertical = true
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

    private func buildSections(with segments: [PlanRouteSegment]) -> [SectionModel] {
        guard !segments.isEmpty else {
            pendingEmptySegmentIndex = nil
            return [SectionModel(headerTitle: localizedString("route_points"),
                                 headerSubtitle: nil,
                                 headerMenu: makeRouteTypeMenu(pointIndex: 0),
                                 rows: [.empty],
                                 isStartNewSegment: false)]
        }

        let multipleSegments = segments.count > 1 || pendingEmptySegmentIndex != nil
        var result: [SectionModel] = segments.flatMap { makeSections(for: $0, multipleSegments: multipleSegments) }

        if let pendingIndex = pendingEmptySegmentIndex {
            let title = String(format: localizedString("segments_count"), pendingIndex)
            result.append(SectionModel(headerTitle: title,
                                       headerSubtitle: nil,
                                       headerMenu: nil,
                                       rows: [.empty],
                                       isStartNewSegment: false))
        } else if dataSource?.canStartNewSegment ?? false {
            result.append(SectionModel(headerTitle: nil,
                                       headerSubtitle: nil,
                                       headerMenu: nil,
                                       rows: [],
                                       isStartNewSegment: true))
        }
        return result
    }

    private func contentSignature(for segments: [PlanRouteSegment]) -> String {
        let pendingSignature = pendingEmptySegmentIndex.map(String.init) ?? "nil"
        let canStartNewSegment = dataSource?.canStartNewSegment ?? false
        let segmentsSignature = segments.map { segment in
            let segmentMode = segment.singleMode?.toHumanString() ?? "nil"
            let groupsSignature = segment.groups.map { group in
                let groupMode = group.appMode?.toHumanString() ?? "nil"
                let pointIndexes = group.points.map(\.index).map(String.init).joined(separator: ",")
                return "mode=\(groupMode),distance=\(Int(group.distance.rounded())),last=\(group.lastPointIndex),points=\(pointIndexes)"
            }.joined(separator: ";")
            return "index=\(segment.index),routed=\(segment.routed),multi=\(segment.multiMode),mode=\(segmentMode),distance=\(Int(segment.distance.rounded())),groups=\(groupsSignature)"
        }.joined(separator: "|")
        return "pending=\(pendingSignature),canStart=\(canStartNewSegment),segments=\(segmentsSignature)"
    }

    private func makeSections(for segment: PlanRouteSegment, multipleSegments: Bool) -> [SectionModel] {
        let straightLineColor: UIColor = .buttonAccentsBlue

        let title = multipleSegments
            ? String(format: localizedString("segments_count"), segment.index + 1)
            : localizedString("route_points")
        let segmentMenu = makeSegmentMenu(for: segment)

        if segment.multiMode {
            var rows: [Row] = []
            let allGroups = segment.groups
            for (i, group) in allGroups.enumerated() {
                let isLastGroup = i == allGroups.count - 1
                let isBoundaryMarker = multipleSegments
                    && isLastGroup
                    && group.appMode == nil
                    && group.points.count == 1
                    && allGroups.count > 1
                if isBoundaryMarker {
                    let prevColor = allGroups[i - 1].appMode?.getProfileColor() ?? straightLineColor
                    rows.append(contentsOf: group.points.map { Row.point($0, color: prevColor) })
                } else {
                    let groupColor = group.appMode?.getProfileColor() ?? straightLineColor
                    rows.append(.profileGroup(group, segment: segment))
                    rows.append(contentsOf: group.points.map { Row.point($0, color: groupColor) })
                }
            }
            return [SectionModel(headerTitle: title,
                                 headerSubtitle: nil,
                                 headerMenu: segmentMenu,
                                 rows: rows,
                                 isStartNewSegment: false)]
        } else {
            let segmentColor = segment.singleMode?.getProfileColor() ?? straightLineColor
            var subtitle: String?
            if segment.routed, let mode = segment.singleMode {
                subtitle = "\(mode.toHumanString() ?? "") • \(formattedDistance(segment.distance))"
            }
            var rows: [Row] = []
            for group in segment.groups {
                rows.append(contentsOf: group.points.map { Row.point($0, color: segmentColor) })
            }
            return [SectionModel(headerTitle: title,
                                 headerSubtitle: subtitle,
                                 headerMenu: segmentMenu,
                                 rows: rows,
                                 isStartNewSegment: false)]
        }
    }

    private func makeSegmentMenu(for segment: PlanRouteSegment) -> UIMenu {
        var children: [UIMenuElement] = []
        if !segment.multiMode {
            children.append(UIAction(title: localizedString("change_mode"),
                                     subtitle: segment.singleMode?.toHumanString(),
                                     image: segment.singleMode?.getIcon()) { [weak self] _ in
                self?.onOpenRouteBetweenPoints?(segment)
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
        let modeSubtitle = group.appMode?.toHumanString() ?? localizedString("plan_route_straight_line")
        let modeIcon = group.appMode?.getIcon() ?? .templateImageNamed("ic_custom_straight_line")
        let changeRouteType = UIAction(title: localizedString("change_mode"),
                                       subtitle: modeSubtitle,
                                       image: modeIcon) { [weak self] _ in
            self?.onChangeRouteType?(.profileGroup(group, segment: segment))
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
            self?.onChangeRouteType?(.wholeTrack)
        }
        return UIMenu(children: [changeRouteType])
    }

    private func sortKey(for pointIndexes: [Int]) -> String {
        pointIndexes.sorted().map(String.init).joined(separator: ",")
    }

    private func makeSortMenu(pointIndexes: [Int]) -> UIMenu {
        let sortImage = UIImage.templateImageNamed("ic_custom_swap")
        let key = sortKey(for: pointIndexes)
        let isSortedDoorToDoor = doorToDoorSortedKeys.contains(key)

        let manual = UIAction(title: localizedString("shared_string_manual"),
                              image: sortImage,
                              state: isSortedDoorToDoor ? .off : .on) { [weak self] _ in
            self?.doorToDoorSortedKeys.remove(key)
            self?.rebuildSections()
        }
        let doorToDoor = UIAction(title: localizedString("intermediate_items_sort_by_distance"),
                                  image: .templateImageNamed("ic_custom_sort_door_to_door"),
                                  state: isSortedDoorToDoor ? .on : .off) { [weak self] _ in
            guard let self else { return }
            doorToDoorSortedKeys.insert(key)
            isApplyingDoorToDoorSort = true
            dataSource?.sortDoorToDoor(pointIndexes: pointIndexes)
        }
        return UIMenu(title: localizedString("shared_string_sort"), image: sortImage, children: [manual, doorToDoor])
    }

    private func rebuildSections() {
        let segments = dataSource?.routeSegments ?? []
        sections = buildSections(with: segments)
        tableView.reloadData()
    }

    private func deleteSegment(pointIndexes: [Int]) {
        dataSource?.deleteSegment(pointIndexes: pointIndexes)
    }

    private func deletePoint(at index: Int) {
        dataSource?.deleteRoutePoint(at: index)
    }

    private func startNewSegment() {
        let nextIndex = (dataSource?.routeSegments.count ?? 0) + 1
        pendingEmptySegmentIndex = nextIndex
        dataSource?.startNewSegment()
    }

    private func findSegmentAndGroup(for pointIndex: Int) -> (PlanRouteSegment, PlanRouteProfileGroup)? {
        for segment in dataSource?.routeSegments ?? [] {
            for group in segment.groups where group.points.contains(where: { $0.index == pointIndex }) {
                return (segment, group)
            }
        }
        return nil
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
            cell.configure(title: mode?.toHumanString() ?? localizedString("plan_route_straight_line"),
                           distanceText: formattedDistance(group.distance),
                           icon: mode?.getIcon() ?? .templateImageNamed("ic_custom_straight_line"),
                           tintColor: mode?.getProfileColor() ?? .buttonAccentsBlue,
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
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard sections[section].headerTitle != nil else { return 0 }
        return sections[section].headerSubtitle != nil ? 60 : 44
    }

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
        switch section.rows[indexPath.row] {
        case let .point(point, _):
            if let (seg, grp) = findSegmentAndGroup(for: point.index) {
                onPointSelected?(point, grp, seg)
            }
        case let .profileGroup(group, segment):
            onChangeRouteType?(.profileGroup(group, segment: segment))
        case .empty:
            break
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
        let srcSection = sourceIndexPath.section
        let rows = sections[srcSection].rows
        let pointRows = rows.indices.filter { if case .point = rows[$0] { return true } else { return false } }
        guard let firstPoint = pointRows.first, let lastPoint = pointRows.last else { return sourceIndexPath }

        if proposedDestinationIndexPath.section != srcSection {
            let boundary = proposedDestinationIndexPath.section < srcSection ? firstPoint : lastPoint
            return IndexPath(row: boundary, section: srcSection)
        }

        let proposedRow = proposedDestinationIndexPath.row
        if case .point = rows[proposedRow] {
            return proposedDestinationIndexPath
        }

        let before = pointRows.filter { $0 < proposedRow }
        let after = pointRows.filter { $0 > proposedRow }
        let nearest: Int
        if proposedRow > sourceIndexPath.row {
            nearest = after.first ?? before.last ?? firstPoint
        } else {
            nearest = before.last ?? after.first ?? lastPoint
        }
        return IndexPath(row: nearest, section: srcSection)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let rows = sections[sourceIndexPath.section].rows
        guard case let .point(srcPoint, _) = rows[sourceIndexPath.row],
              case let .point(dstPoint, _) = rows[destinationIndexPath.row] else {
            reloadData()
            return
        }
        dataSource?.moveRoutePoint(from: srcPoint.index, to: dstPoint.index)
    }
}

final class PlanRouteSegmentHeaderView: UITableViewHeaderFooterView {
    static let reuseId = "PlanRouteSegmentHeaderView"

    private static let optionsButtonSize: CGFloat = 44

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
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .scaledSystemFont(ofSize: 15)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        var configuration = UIButton.Configuration.plain()
        configuration.title = "⋯"
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = .systemFont(ofSize: 17, weight: .bold)
            return updated
        }
        configuration.baseForegroundColor = .buttonAccentsBlue
        configuration.background.image = UIImage(named: "blue_circle_fill")
        configuration.contentInsets = .zero
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true

        [textStack, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
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

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary

        distanceLabel.font = .scaledSystemFont(ofSize: 17)
        distanceLabel.textColor = .textColorSecondary
        distanceLabel.setContentHuggingPriority(.required, for: .horizontal)

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage.templateImageNamed("ic_custom_overflow_menu_stroke")
        configuration.baseForegroundColor = .iconColorDefault
        configuration.background.backgroundColor = .clear
        configuration.contentInsets = .zero
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
        numberContainer.backgroundColor = tintColor
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

        numberContainer.layer.cornerRadius = Self.circleSize / 2
        numberContainer.layer.borderWidth = 2
        numberContainer.layer.borderColor = UIColor.white.cgColor
        numberLabel.font = .scaledSystemFont(ofSize: 13, weight: .semibold)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.minimumScaleFactor = 0.5
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
            numberLabel.leadingAnchor.constraint(greaterThanOrEqualTo: numberContainer.leadingAnchor, constant: 2),
            numberLabel.trailingAnchor.constraint(lessThanOrEqualTo: numberContainer.trailingAnchor, constant: -2),

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
        titleLabel.font = .scaledSystemFont(ofSize: 17)
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
