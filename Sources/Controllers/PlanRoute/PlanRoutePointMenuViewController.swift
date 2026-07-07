//
//  PlanRoutePointMenuViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 24.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRoutePointMenuViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case movePoint
        case addPoint
        case trim
        case changeRouteType
        case delete
    }

    fileprivate enum Row {
        case movePoint
        case addBefore
        case addAfter
        case trimBefore
        case trimAfter
        case changeTypeBefore
        case changeTypeAfter
        case delete
    }

    fileprivate struct RowModel {
        let row: Row
        let title: String
        let subtitle: String?
        let icon: UIImage?
        let isEnabled: Bool
        let isDestructive: Bool
    }

    var onChangeRouteType: ((SegmentRouteContext, Int?, Int?) -> Void)?
    var onDismissed: (() -> Void)?

    private let point: PlanRoutePoint
    private let segment: PlanRouteSegment
    private let group: PlanRouteProfileGroup
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [[RowModel]] = []
    private weak var dataSource: PlanRoutePointsDataSource?

    init(point: PlanRoutePoint,
         segment: PlanRouteSegment,
         group: PlanRouteProfileGroup,
         dataSource: PlanRoutePointsDataSource?) {
        self.point = point
        self.segment = segment
        self.group = group
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
        setupCancelButton()
        buildSections()
    }

    private func setupNavigationBar() {
        title = point.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(onCloseTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .textColorPrimary
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.register(PlanRouteMenuActionCell.self, forCellReuseIdentifier: PlanRouteMenuActionCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
    }

    private func setupCancelButton() {
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
        cancelButton.setTitleColor(.iconColorActive, for: .normal)
        cancelButton.titleLabel?.font = .scaledSystemFont(ofSize: 17, weight: .medium)
        cancelButton.backgroundColor = .groupBg
        cancelButton.layer.cornerRadius = 16
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func buildSections() {
        let groupIndex = segment.groups.firstIndex(where: { $0.lastPointIndex == group.lastPointIndex }) ?? 0
        let prevGroup: PlanRouteProfileGroup? = groupIndex > 0 ? segment.groups[groupIndex - 1] : nil

        let trimBeforeSubtitle: String? = point.isStart ? localizedString("start_point") : nil
        let trimAfterSubtitle: String? = point.isDestination ? localizedString("route_descr_destination") : formattedDistance(point.distanceFromPrevious)

        let changeTypeBeforeIcon = (prevGroup ?? group).appMode?.getIcon() ?? .templateImageNamed("ic_custom_straight_line")
        let changeTypeAfterIcon = group.appMode?.getIcon() ?? .templateImageNamed("ic_custom_straight_line")

        sections = [
            [RowModel(row: .movePoint,
                      title: localizedString("plan_route_move_point"),
                      subtitle: nil,
                      icon: .templateImageNamed("ic_custom_move"),
                      isEnabled: true,
                      isDestructive: false)],
            [RowModel(row: .addBefore,
                      title: localizedString("plan_route_add_point_before"),
                      subtitle: nil,
                      icon: .templateImageNamed("ic_custom_add_point_before"),
                      isEnabled: true,
                      isDestructive: false),
             RowModel(row: .addAfter,
                      title: localizedString("plan_route_add_point_after"),
                      subtitle: nil,
                      icon: .templateImageNamed("ic_custom_add_point_after"),
                      isEnabled: true,
                      isDestructive: false)],
            [RowModel(row: .trimBefore,
                      title: localizedString("plan_route_trim_before"),
                      subtitle: trimBeforeSubtitle,
                      icon: .templateImageNamed("ic_custom_trim_before"),
                      isEnabled: !point.isStart,
                      isDestructive: false),
             RowModel(row: .trimAfter,
                      title: localizedString("plan_route_trim_after"),
                      subtitle: trimAfterSubtitle,
                      icon: .templateImageNamed("ic_custom_trim_after"),
                      isEnabled: !point.isDestination,
                      isDestructive: false)],
            [RowModel(row: .changeTypeBefore,
                      title: localizedString("plan_route_change_route_type_before"),
                      subtitle: nil,
                      icon: changeTypeBeforeIcon,
                      isEnabled: !point.isStart,
                      isDestructive: false),
             RowModel(row: .changeTypeAfter,
                      title: localizedString("plan_route_change_route_type_after"),
                      subtitle: nil,
                      icon: changeTypeAfterIcon,
                      isEnabled: true,
                      isDestructive: false)],
            [RowModel(row: .delete,
                      title: localizedString("plan_route_delete_point"),
                      subtitle: nil,
                      icon: .templateImageNamed("ic_custom_trash_outlined"),
                      isEnabled: true,
                      isDestructive: true)]
        ]
        tableView.reloadData()
    }

    private func handle(row: Row) {
        switch row {
        case .movePoint:
            NSLog("[PlanRouteDbg] pointMenu: movePoint index=%d", point.index)
            dataSource?.selectRoutePoint(at: point.index)
            dismiss(animated: true)
        case .addBefore:
            NSLog("[PlanRouteDbg] pointMenu: addBefore index=%d", point.index)
            dataSource?.addPointBefore(index: point.index)
            dismiss(animated: true)
        case .addAfter:
            NSLog("[PlanRouteDbg] pointMenu: addAfter index=%d", point.index)
            dataSource?.addPointAfter(index: point.index)
            dismiss(animated: true)
        case .trimBefore:
            NSLog("[PlanRouteDbg] pointMenu: trimBefore index=%d", point.index)
            dataSource?.trimBefore(index: point.index)
            dismiss(animated: true)
        case .trimAfter:
            NSLog("[PlanRouteDbg] pointMenu: trimAfter index=%d", point.index)
            dataSource?.trimAfter(index: point.index)
            dismiss(animated: true)
        case .changeTypeBefore:
            let groupIndex = segment.groups.firstIndex(where: { $0.lastPointIndex == group.lastPointIndex }) ?? 0
            if groupIndex > 0 {
                let prevGroup = segment.groups[groupIndex - 1]
                let context = SegmentRouteContext.profileGroup(prevGroup, segment: segment)
                NSLog("[PlanRouteDbg] pointMenu: changeTypeBefore pointIndex=%d -> profileGroup prevGroup.appMode=%@ prevGroup.lastPointIndex=%d prevGroup.points=%d",
                      point.index, prevGroup.appMode?.stringKey ?? "nil", prevGroup.lastPointIndex, prevGroup.points.count)
                dismiss(animated: true) { [weak self] in
                    self?.onChangeRouteType?(context, nil, nil)
                }
            } else {
                let context = SegmentRouteContext.profileGroup(group, segment: segment)
                let upToIndex = point.index
                NSLog("[PlanRouteDbg] pointMenu: changeTypeBefore pointIndex=%d -> profileGroup(first) upToIndex=%d group.points=%d",
                      point.index, upToIndex, group.points.count)
                dismiss(animated: true) { [weak self] in
                    self?.onChangeRouteType?(context, nil, upToIndex)
                }
            }
        case .changeTypeAfter:
            let context = SegmentRouteContext.profileGroup(group, segment: segment)
            let fromIndex = point.index
            NSLog("[PlanRouteDbg] pointMenu: changeTypeAfter pointIndex=%d group.appMode=%@ group.lastPointIndex=%d group.points=%d",
                  fromIndex, group.appMode?.stringKey ?? "nil", group.lastPointIndex, group.points.count)
            dismiss(animated: true) { [weak self] in
                self?.onChangeRouteType?(context, fromIndex, nil)
            }
        case .delete:
            NSLog("[PlanRouteDbg] pointMenu: deletePoint index=%d", point.index)
            dataSource?.deleteRoutePoint(at: point.index)
            dismiss(animated: true)
        }
    }

    private func formattedDistance(_ meters: Double) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters)) ?? ""
    }

    @objc private func onCloseTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismissed?()
        }
    }
}

// MARK: - UITableViewDataSource
extension PlanRoutePointMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = sections[indexPath.section][indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteMenuActionCell.reuseId, for: indexPath) as? PlanRouteMenuActionCell else {
            return UITableViewCell()
        }
        cell.configure(model: model)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PlanRoutePointMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 0 : 8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = sections[indexPath.section][indexPath.row]
        guard model.isEnabled else { return }
        handle(row: model.row)
    }
}

// MARK: - PlanRouteMenuActionCell

private final class PlanRouteMenuActionCell: UITableViewCell {
    static let reuseId = "PlanRouteMenuActionCell"

    private static let iconSize: CGFloat = 24

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: PlanRoutePointMenuViewController.RowModel) {
        let titleColor: UIColor
        if model.isDestructive {
            titleColor = .systemOrange
        } else if model.isEnabled {
            titleColor = .textColorPrimary
        } else {
            titleColor = .textColorSecondary
        }
        titleLabel.text = model.title
        titleLabel.textColor = titleColor

        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        iconView.image = model.icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = model.isDestructive ? .systemOrange :
                             (model.isEnabled ? .iconColorActive : .iconColorTertiary)
        isUserInteractionEnabled = model.isEnabled || model.isDestructive
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 1

        iconView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [textStack, iconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -8),

            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])
    }
}
