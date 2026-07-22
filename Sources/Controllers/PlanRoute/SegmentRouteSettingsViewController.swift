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

    private var defaultRoutingParams: PlanRouteSegmentRoutingParams {
        PlanRouteSegmentRoutingParams(useElevationData: false,
                                      considerTemporaryLimitations: true)
    }

    private var settingsMode: OAApplicationMode? {
        selectedMode ?? context.currentMode ?? dataSource?.defaultMode ?? OAApplicationMode.getFirstAvailableNavigation()
    }

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
        let resolvedSettingsMode = self.selectedMode ?? context.currentMode ?? dataSource?.defaultMode ?? OAApplicationMode.getFirstAvailableNavigation()
        self.routingParams = resolvedSettingsMode.flatMap { dataSource?.routingParams(for: $0) } ?? PlanRouteSegmentRoutingParams(useElevationData: false,
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
            reloadRoutingParams()
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
                self?.applyRoutingParams(updated)
            }
        )
        vc.onAvoidRoadsTapped = { [weak self] in
            guard let self, let appMode = self.settingsMode,
                  let avoidVC = OAAvoidPreferParametersViewController(appMode: appMode, isAvoid: true) else { return }
            avoidVC.delegate = self
            navigationController?.pushViewController(avoidVC, animated: true)
        }
        vc.onNavigationSettingsTapped = { [weak self] in
            guard let self, let appMode = self.settingsMode,
                  let navSettingsVC = OAProfileNavigationSettingsViewController(appMode: appMode) else { return }
            navSettingsVC.openFromRouteInfo = true
            navSettingsVC.delegate = self
            navigationController?.pushViewController(navSettingsVC, animated: true)
        }
        return vc
    }

    private func reloadRoutingParams() {
        guard let settingsMode else {
            routingParams = defaultRoutingParams
            return
        }
        routingParams = dataSource?.routingParams(for: settingsMode) ?? defaultRoutingParams
    }

    private func applyRoutingParams(_ updatedParams: PlanRouteSegmentRoutingParams) {
        routingParams = updatedParams
        guard let settingsMode else { return }
        dataSource?.applyRoutingParams(updatedParams, mode: settingsMode)
    }

    private func refreshSettingsState() {
        reloadRoutingParams()
        settingsVC?.update(params: routingParams)
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
        navigationController?.dismiss(animated: true)
    }

    @objc private func onCloseTapped() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - OASettingsDataDelegate

extension SegmentRouteSettingsViewController: OASettingsDataDelegate {
    func onSettingsChanged() {
        refreshSettingsState()
        guard let settingsMode else { return }
        dataSource?.refreshRoute(for: settingsMode)
    }

    func closeSettingsScreenWithRouteInfo() {
    }

    func openNavigationSettings() {
    }
}
