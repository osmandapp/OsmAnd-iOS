//
//  RouteBetweenPointsViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 24.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteBetweenPointsViewController: UIViewController {

    private enum Row {
        case profileGroup(PlanRouteProfileGroup, segment: PlanRouteSegment)
        case continueRoute
        case startNewSegment
        case changeWholeTrack
    }

    private struct SectionModel {
        let headerTitle: String?
        let rows: [Row]
        var footerTitle: String?
    }

    private static let rowHeight: CGFloat = 50
    private static let sectionHeaderHeight: CGFloat = 44

    var onContinueEditing: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let fromPointIndex: Int?
    private let scopedSegment: PlanRouteSegment?
    private var sections: [SectionModel] = []
    private weak var dataSource: PlanRoutePointsDataSource?

    init(dataSource: PlanRoutePointsDataSource?, fromPointIndex: Int? = nil, scopedSegment: PlanRouteSegment? = nil) {
        self.dataSource = dataSource
        self.fromPointIndex = fromPointIndex
        self.scopedSegment = scopedSegment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = header.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isViewLoaded,
              previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        tableView.reloadData()
        view.setNeedsLayout()
    }

    private func setupNavigationBar() {
        title = localizedString("route_between_points")
        navigationItem.backButtonDisplayMode = .minimal
        let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(onCloseTapped))
        closeButton.tintColor = .textColorPrimary
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.register(RouteGroupCell.self, forCellReuseIdentifier: RouteGroupCell.reuseIdentifier)
        tableView.register(PlanRouteActionCell.self, forCellReuseIdentifier: PlanRouteActionCell.reuseIdentifier)
        tableView.tableHeaderView = makeHintHeaderView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeHintHeaderView() -> UIView {
        let label = UILabel()
        label.text = localizedString("plan_route_select_segment_hint")
        label.font = .scaledSystemFont(ofSize: 15)
        label.textColor = .textColorSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    private func reloadData() {
        sections = buildSections()
        tableView.reloadData()
    }

    private func buildSections() -> [SectionModel] {
        var segments: [PlanRouteSegment]
        if let scoped = scopedSegment {
            segments = [scoped]
        } else {
            segments = dataSource?.routeSegments ?? []
            if let pendingEmptySegment = makePendingEmptySegment(after: segments) {
                segments.append(pendingEmptySegment)
            }
        }
        var result: [SectionModel] = segments.enumerated().map { index, segment in
            makeSegmentSection(segment, isLast: index == segments.count - 1)
        }
        var actions: [Row] = []
        var footerTitle: String?
        if scopedSegment == nil, dataSource?.canStartNewSegment ?? false {
            actions.append(.startNewSegment)
            footerTitle = localizedString("plan_route_new_segment_separate_hint")
        }
        actions.append(.changeWholeTrack)
        result.append(SectionModel(headerTitle: nil, rows: actions, footerTitle: footerTitle))
        return result
    }

    private func makePendingEmptySegment(after segments: [PlanRouteSegment]) -> PlanRouteSegment? {
        guard scopedSegment == nil,
              let pendingIndex = dataSource?.pendingEmptySegmentIndex else { return nil }
        let mode = dataSource?.defaultMode
        let group = PlanRouteProfileGroup(appMode: mode,
                                          distance: 0,
                                          lastPointIndex: segments.last?.pointIndexes.last ?? 0,
                                          points: [])
        return PlanRouteSegment(index: pendingIndex - 1,
                                groups: [group],
                                routed: mode != nil,
                                multiMode: false,
                                singleMode: mode,
                                distance: 0,
                                isPendingEmpty: true,
                                gapAfter: nil)
    }

    private func makeSegmentSection(_ segment: PlanRouteSegment, isLast: Bool) -> SectionModel {
        let effective = mergedGroups(from: segment.groups)
        var rows: [Row] = effective.map { .profileGroup($0, segment: segment) }
        if isLast && scopedSegment == nil {
            rows.append(.continueRoute)
        }
        let title = String(format: localizedString("segments_count"), segment.index + 1)
        return SectionModel(headerTitle: title, rows: rows)
    }

    private func mergedGroups(from groups: [PlanRouteProfileGroup]) -> [PlanRouteProfileGroup] {
        var result: [PlanRouteProfileGroup] = []
        for group in groups {
            if let last = result.last, last.appMode?.stringKey == group.appMode?.stringKey {
                result[result.count - 1] = PlanRouteProfileGroup(
                    appMode: last.appMode,
                    distance: last.distance + group.distance,
                    lastPointIndex: group.lastPointIndex,
                    points: last.points + group.points
                )
            } else {
                result.append(group)
            }
        }
        return result
    }

    private func openSettings(context: SegmentRouteContext, applyFromPointIndex: Int? = nil) {
        let detailVC = SegmentRouteSettingsViewController(context: context, dataSource: dataSource, applyFromPointIndex: applyFromPointIndex)
        detailVC.onContinueEditing = onContinueEditing
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func openFutureRouteSelection(_ action: SegmentRouteSettingsViewController.FutureRouteAction) {
        let controller = SegmentRouteSettingsViewController(context: .wholeTrack, dataSource: dataSource, futureRouteAction: action)
        controller.onContinueEditing = onContinueEditing
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func onCloseTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension RouteBetweenPointsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case let .profileGroup(group, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteGroupCell.reuseIdentifier, for: indexPath) as? RouteGroupCell else {
                return UITableViewCell()
            }
            cell.configure(group: group)
            return cell
        case .continueRoute:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteActionCell.reuseIdentifier, for: indexPath) as? PlanRouteActionCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_continue_with_different_type"), isDestructive: false, showsDisclosure: true)
            return cell
        case .startNewSegment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteActionCell.reuseIdentifier, for: indexPath) as? PlanRouteActionCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("gpx_start_new_segment"), isDestructive: false, showsDisclosure: true)
            return cell
        case .changeWholeTrack:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteActionCell.reuseIdentifier, for: indexPath) as? PlanRouteActionCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_change_for_whole_track"), isDestructive: false, showsDisclosure: true)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension RouteBetweenPointsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if case .profileGroup = sections[indexPath.section].rows[indexPath.row] {
            return Self.rowHeight
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footerTitle
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].headerTitle != nil ? Self.sectionHeaderHeight : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sections[section].headerTitle else { return nil }
        let header = UITableViewHeaderFooterView()
        var config = header.defaultContentConfiguration()
        config.text = title
        config.textProperties.font = .scaledSystemFont(ofSize: 17, weight: .semibold)
        config.textProperties.color = .textColorSecondary
        header.contentConfiguration = config
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case let .profileGroup(group, segment):
            openSettings(context: .profileGroup(group, segment: segment), applyFromPointIndex: fromPointIndex)
        case .continueRoute:
            openFutureRouteSelection(.continueRoute)
        case .startNewSegment:
            openFutureRouteSelection(.startNewSegment)
        case .changeWholeTrack:
            openSettings(context: .wholeTrack)
        }
    }
}
