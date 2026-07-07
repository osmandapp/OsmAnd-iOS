//
//  SegmentRouteSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 24.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class SegmentRouteSettingsViewController: UIViewController {

    private enum ActiveTab {
        case routeType
        case settings
    }

    private let context: SegmentRouteContext
    private let applyFromPointIndex: Int?
    private let applyUpToPointIndex: Int?
    private var activeTab: ActiveTab = .routeType
    private var selectedMode: OAApplicationMode?
    private var routingParams: PlanRouteSegmentRoutingParams

    private let segmentControl = UISegmentedControl()
    private let tabContainerView = UIView()
    private var routeTypeVC: RouteTypeViewController?
    private var settingsVC: RouteSettingsViewController?
    private var activeTabViewController: UIViewController?
    private weak var dataSource: PlanRoutePointsDataSource?

    init(context: SegmentRouteContext, dataSource: PlanRoutePointsDataSource?, applyFromPointIndex: Int? = nil, applyUpToPointIndex: Int? = nil) {
        self.context = context
        self.applyFromPointIndex = applyFromPointIndex
        self.applyUpToPointIndex = applyUpToPointIndex
        self.dataSource = dataSource
        if case .wholeTrack = context {
            self.selectedMode = dataSource?.defaultMode
        } else {
            self.selectedMode = context.currentMode
        }
        self.routingParams = dataSource?.routingParams(for: context) ?? PlanRouteSegmentRoutingParams(useElevationData: false,
                                                                                                      considerTemporaryLimitations: true)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        setupNavigationBar()
        setupSegmentControl()
        setupTabContainer()
        switchTab(to: .routeType, animated: false)
    }

    private func setupNavigationBar() {
        navigationItem.title = context.screenTitle
        if let subtitle = context.screenSubtitle {
            let titleView = TwoLineTitleView(title: context.screenTitle, subtitle: subtitle)
            navigationItem.titleView = titleView
        }

        if context.usesCloseButton {
            let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(onCloseTapped))
            closeButton.tintColor = .textColorPrimary
            navigationItem.leftBarButtonItem = closeButton
        }

        let checkmarkImage = UIImage.templateImageNamed("ic_checkmark_default")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: checkmarkImage,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(onConfirmTapped))
    }

    private func setupSegmentControl() {
        segmentControl.removeAllSegments()
        segmentControl.insertSegment(withTitle: localizedString("layer_route"), at: 0, animated: false)
        segmentControl.insertSegment(withTitle: localizedString("shared_string_settings"), at: 1, animated: false)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.backgroundColor = .groupBgColorSecondary
        segmentControl.selectedSegmentTintColor = UIColor.white
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: UIFont.scaledSystemFont(ofSize: 13, weight: .medium)
        ]
        segmentControl.setTitleTextAttributes(attrs, for: .normal)
        segmentControl.setTitleTextAttributes(attrs, for: .selected)
        segmentControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func setupTabContainer() {
        tabContainerView.clipsToBounds = true
        tabContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabContainerView)
        NSLayoutConstraint.activate([
            tabContainerView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            tabContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func switchTab(to tab: ActiveTab, animated: Bool) {
        activeTab = tab
        let newVC: UIViewController
        switch tab {
        case .routeType:
            let vc = makeRouteTypeVC()
            routeTypeVC = vc
            newVC = vc
        case .settings:
            let vc = makeSettingsVC()
            settingsVC = vc
            newVC = vc
        }

        activeTabViewController?.willMove(toParent: nil)
        activeTabViewController?.view.removeFromSuperview()
        activeTabViewController?.removeFromParent()

        addChild(newVC)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        tabContainerView.addSubview(newVC.view)
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: tabContainerView.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: tabContainerView.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: tabContainerView.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: tabContainerView.bottomAnchor)
        ])
        newVC.didMove(toParent: self)
        activeTabViewController = newVC
    }

    private func makeRouteTypeVC() -> RouteTypeViewController {
        RouteTypeViewController(
            context: context,
            availableModes: dataSource?.availableModes ?? [],
            selectedMode: selectedMode,
            canStartNewSegment: context.usesCloseButton,
            onModeSelected: { [weak self] mode in
                self?.selectedMode = mode
            },
            onStartNewSegment: { [weak self] in
                self?.dataSource?.startNewSegment()
                self?.navigationController?.dismiss(animated: true)
            }
        )
    }

    private func makeSettingsVC() -> RouteSettingsViewController {
        let vc = RouteSettingsViewController(
            params: routingParams,
            onParamsChanged: { [weak self] updated in
                self?.routingParams = updated
            }
        )
        vc.onAvoidRoadsTapped = { [weak self] in
            guard let appMode = self?.selectedMode ?? OAApplicationMode.default(),
                  let avoidVC = OAAvoidPreferParametersViewController(appMode: appMode, isAvoid: true) else { return }
            self?.navigationController?.pushViewController(avoidVC, animated: true)
        }
        vc.onNavigationSettingsTapped = { [weak self] in
            guard let appMode = self?.selectedMode ?? OAApplicationMode.default(),
                  let navSettingsVC = OAProfileNavigationSettingsViewController(appMode: appMode) else { return }
            navSettingsVC.openFromRouteInfo = true
            self?.navigationController?.pushViewController(navSettingsVC, animated: true)
        }
        return vc
    }

    @objc private func onSegmentChanged() {
        let tab: ActiveTab = segmentControl.selectedSegmentIndex == 0 ? .routeType : .settings
        switchTab(to: tab, animated: false)
    }

    @objc private func onConfirmTapped() {
        if let fromIndex = applyFromPointIndex, case let .profileGroup(group, _) = context {
            guard let mode = selectedMode ?? OAApplicationMode.default() else { return }
            for point in group.points where point.index >= fromIndex {
                dataSource?.applyMode(mode, pointIndex: point.index, wholeRoute: false)
            }
        } else if let upToIndex = applyUpToPointIndex, case let .profileGroup(group, _) = context {
            guard let mode = selectedMode ?? OAApplicationMode.default() else { return }
            for point in group.points where point.index <= upToIndex {
                dataSource?.applyMode(mode, pointIndex: point.index, wholeRoute: false)
            }
        } else {
            dataSource?.applyModeToContext(selectedMode, context: context)
        }
        dataSource?.applyRoutingParams(routingParams, for: context)
        navigationController?.dismiss(animated: true)
    }

    @objc private func onCloseTapped() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - TwoLineTitleView

private final class TwoLineTitleView: UIView {
    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .scaledSystemFont(ofSize: 12)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - RouteTypeViewController

private final class RouteTypeViewController: UIViewController {

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
        tableView.register(RouteActionCell.self, forCellReuseIdentifier: RouteActionCell.reuseId)
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteActionCell.reuseId, for: indexPath) as? RouteActionCell else {
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

// MARK: - RouteTypeModeCell

private final class RouteTypeModeCell: UITableViewCell {
    static let reuseId = "RouteTypeModeCell"

    private static let checkmarkSize: CGFloat = 20
    private static let iconSize: CGFloat = 24
    private static let gap: CGFloat = 8
    private static let leadingInset: CGFloat = 16
    private static let verticalPadding: CGFloat = 12

    private let checkmarkView = UIImageView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, icon: UIImage?, tintColor: UIColor, isSelected: Bool) {
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = tintColor
        titleLabel.text = title
        checkmarkView.image = isSelected ? .templateImageNamed("ic_checkmark_default") : nil
        accessoryType = .none
        let inset = Self.leadingInset + Self.checkmarkSize + Self.gap + Self.iconSize + Self.gap
        separatorInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: Self.leadingInset)
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.tintColor = .iconColorActive
        checkmarkView.isAccessibilityElement = false

        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0

        [checkmarkView, iconView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            checkmarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.leadingInset),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: Self.checkmarkSize),
            checkmarkView.heightAnchor.constraint(equalToConstant: Self.checkmarkSize),

            iconView.leadingAnchor.constraint(equalTo: checkmarkView.trailingAnchor, constant: Self.gap),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Self.gap),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Self.leadingInset),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Self.verticalPadding),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Self.verticalPadding),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }
}

// MARK: - RouteActionCell (reused from RouteBetweenPointsViewController)

private final class RouteActionCell: UITableViewCell {
    static let reuseId = "RouteActionCell_Settings"

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isDestructive: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isDestructive ? .systemRed : .iconColorActive
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .default

        titleLabel.font = .scaledSystemFont(ofSize: 17)
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

// MARK: - RouteSettingsViewController

private final class RouteSettingsViewController: UIViewController {

    private enum Row {
        case useElevationData
        case avoidRoads
        case considerTempLimitations
        case navigationSettings
    }

    private struct SectionModel {
        let rows: [Row]
    }

    var onAvoidRoadsTapped: (() -> Void)?
    var onNavigationSettingsTapped: (() -> Void)?

    private var params: PlanRouteSegmentRoutingParams
    private let onParamsChanged: (PlanRouteSegmentRoutingParams) -> Void

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sections: [SectionModel] = [
        SectionModel(rows: [.useElevationData]),
        SectionModel(rows: [.avoidRoads, .considerTempLimitations]),
        SectionModel(rows: [.navigationSettings])
    ]

    init(params: PlanRouteSegmentRoutingParams, onParamsChanged: @escaping (PlanRouteSegmentRoutingParams) -> Void) {
        self.params = params
        self.onParamsChanged = onParamsChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionHeaderTopPadding = 0
        tableView.register(RouteSettingToggleCell.self, forCellReuseIdentifier: RouteSettingToggleCell.reuseId)
        tableView.register(RouteSettingNavigationCell.self, forCellReuseIdentifier: RouteSettingNavigationCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension RouteSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .useElevationData:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingToggleCell.reuseId, for: indexPath) as? RouteSettingToggleCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_use_elevation_data"),
                           isOn: params.useElevationData) { [weak self] isOn in
                guard let self else { return }
                self.params.useElevationData = isOn
                self.onParamsChanged(self.params)
            }
            return cell
        case .avoidRoads:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseId, for: indexPath) as? RouteSettingNavigationCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_avoid_roads"))
            return cell
        case .considerTempLimitations:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingToggleCell.reuseId, for: indexPath) as? RouteSettingToggleCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_consider_temp_limitations"),
                           isOn: params.considerTemporaryLimitations) { [weak self] isOn in
                guard let self else { return }
                self.params.considerTemporaryLimitations = isOn
                self.onParamsChanged(self.params)
            }
            return cell
        case .navigationSettings:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: RouteSettingNavigationCell.reuseId, for: indexPath) as? RouteSettingNavigationCell else {
                return UITableViewCell()
            }
            cell.configure(title: localizedString("plan_route_navigation_settings"))
            return cell
        }
    }
}

extension RouteSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .avoidRoads:
            onAvoidRoadsTapped?()
        case .navigationSettings:
            onNavigationSettingsTapped?()
        default:
            break
        }
    }
}

// MARK: - RouteSettingToggleCell

private final class RouteSettingToggleCell: UITableViewCell {
    static let reuseId = "RouteSettingToggleCell"

    private static let iconSize: CGFloat = 24

    private let iconContainer = UIView()
    private let titleLabel = UILabel()
    private let toggle = UISwitch()
    private var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) {
        titleLabel.text = title
        toggle.isOn = isOn
        self.onToggle = onToggle
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        iconContainer.backgroundColor = .iconColorDefault
        iconContainer.layer.cornerRadius = Self.iconSize / 2

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0

        toggle.onTintColor = UIColor(rgbValue: 0x65C366)
        toggle.addTarget(self, action: #selector(onToggleSwitched), for: .valueChanged)

        [iconContainer, titleLabel, toggle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconContainer.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),

            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func onToggleSwitched() {
        onToggle?(toggle.isOn)
    }
}

// MARK: - RouteSettingNavigationCell

private final class RouteSettingNavigationCell: UITableViewCell {
    static let reuseId = "RouteSettingNavigationCell"

    private static let iconSize: CGFloat = 24

    private let iconContainer = UIView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    private func setupCell() {
        backgroundColor = .groupBg
        accessoryType = .disclosureIndicator
        selectionStyle = .default

        iconContainer.backgroundColor = .iconColorDefault
        iconContainer.layer.cornerRadius = Self.iconSize / 2

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary

        [iconContainer, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconContainer.heightAnchor.constraint(equalToConstant: Self.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12)
        ])
    }
}
