//
//  RouteTypeViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class RouteTypeViewController: UIViewController {

    private enum Row {
        case straightLine
        case mode(OAApplicationMode)
        case startNewSegment
    }

    private struct SectionModel {
        let rows: [Row]
        let footerTitle: String?
    }

    private let context: SegmentRouteContext
    private let availableModes: [OAApplicationMode]
    private var selectedMode: OAApplicationMode?
    private let canStartNewSegment: Bool
    private let onModeSelected: (OAApplicationMode?) -> Void
    private let onStartNewSegment: () -> Void

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [SectionModel] = []

    init(context: SegmentRouteContext,
         availableModes: [OAApplicationMode],
         selectedMode: OAApplicationMode?,
         canStartNewSegment: Bool,
         onModeSelected: @escaping (OAApplicationMode?) -> Void,
         onStartNewSegment: @escaping () -> Void) {
        self.context = context
        self.availableModes = availableModes
        self.selectedMode = selectedMode
        self.canStartNewSegment = canStartNewSegment
        self.onModeSelected = onModeSelected
        self.onStartNewSegment = onStartNewSegment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        rebuildSections()
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.register(RouteTypeModeCell.self, forCellReuseIdentifier: RouteTypeModeCell.reuseId)
        tableView.register(PlanRouteActionCell.self, forCellReuseIdentifier: PlanRouteActionCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func rebuildSections() {
        var result: [SectionModel] = []

        result.append(SectionModel(rows: [.straightLine], footerTitle: nil))

        let modeRows: [Row] = availableModes.map { .mode($0) }
        result.append(SectionModel(rows: modeRows, footerTitle: nil))

        if canStartNewSegment {
            result.append(SectionModel(rows: [.startNewSegment],
                                       footerTitle: localizedString("plan_route_start_new_segment_hint")))
        }

        sections = result
        tableView.reloadData()
    }

    private func isSelected(_ mode: OAApplicationMode?) -> Bool {
        selectedMode?.stringKey == mode?.stringKey
    }
}

extension RouteTypeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .straightLine:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteTypeModeCell.reuseId, for: indexPath) as? RouteTypeModeCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_straight_line"),
                           icon: .templateImageNamed("ic_custom_straight_line"),
                           tintColor: .iconColorActive,
                           isSelected: selectedMode == nil)
            return cell
        case let .mode(mode):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteTypeModeCell.reuseId, for: indexPath) as? RouteTypeModeCell else {
                return UITableViewCell()
            }
            cell.configure(title: mode.toHumanString() ?? "",
                           icon: mode.getIcon(),
                           tintColor: .iconColorActive,
                           isSelected: isSelected(mode))
            return cell
        case .startNewSegment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteActionCell.reuseId, for: indexPath) as? PlanRouteActionCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("gpx_start_new_segment"), isDestructive: false)
            return cell
        }
    }
}

extension RouteTypeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        let header = UITableViewHeaderFooterView()
        var config = header.defaultContentConfiguration()
        config.text = context.recalculateSubtitle
        config.textProperties.font = .scaledSystemFont(ofSize: 13)
        config.textProperties.color = .textColorSecondary
        config.textProperties.numberOfLines = 0
        header.contentConfiguration = config
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footerTitle
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .straightLine:
            selectedMode = nil
            onModeSelected(nil)
            tableView.reloadData()
        case let .mode(mode):
            selectedMode = mode
            onModeSelected(mode)
            tableView.reloadData()
        case .startNewSegment:
            onStartNewSegment()
        }
    }
}
