//
//  SegmentReorderViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 03.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class SegmentReorderViewController: UIViewController {

    private enum Row {
        case segment(PlanRouteSegment)
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var rows: [Row] = []
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
        setupNavigationBar()
        setupTableView()
        reloadRows()
    }

    private func setupNavigationBar() {
        title = localizedString("plan_route_change_segment_order")
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
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = false
        tableView.sectionHeaderTopPadding = 0
        tableView.register(SegmentReorderCell.self, forCellReuseIdentifier: SegmentReorderCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadRows() {
        rows = (dataSource?.routeSegments ?? []).map { Row.segment($0) }
        tableView.reloadData()
    }

    @objc private func onCloseTapped() {
        dismiss(animated: true)
    }
}

extension SegmentReorderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SegmentReorderCell.reuseId, for: indexPath) as? SegmentReorderCell else {
            return UITableViewCell()
        }
        if case let .segment(segment) = rows[indexPath.row] {
            let title = String(format: localizedString("segments_count"), segment.index + 1)
            let modeNames: String
            if segment.multiMode {
                modeNames = segment.groups.compactMap { $0.appMode?.toHumanString() }.joined(separator: ", ")
            } else {
                modeNames = segment.singleMode?.toHumanString() ?? localizedString("plan_route_straight_line")
            }
            let pointCount = segment.pointIndexes.count
            let subtitle = "\(modeNames) · \(pointCount) \(localizedString("points"))"
            cell.configure(title: title, subtitle: subtitle)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool { false }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        let moved = rows.remove(at: sourceIndexPath.row)
        rows.insert(moved, at: destinationIndexPath.row)
        dataSource?.moveSegment(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
}

extension SegmentReorderViewController: UITableViewDelegate {}

private final class SegmentReorderCell: UITableViewCell {
    static let reuseId = "SegmentReorderCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func setupView() {
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .textColorPrimary

        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
}
