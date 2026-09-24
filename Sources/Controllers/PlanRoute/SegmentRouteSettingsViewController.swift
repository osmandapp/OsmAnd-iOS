//
//  SegmentRouteSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 24.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class SegmentRouteSettingsViewController: UIViewController {

    enum FutureRouteAction {
        case continueRoute
        case startNewSegment
    }

    private enum ActiveTab {
        case routeType
        case settings
    }

    var onContinueEditing: (() -> Void)?

    private let context: SegmentRouteContext
    private let applyFromPointIndex: Int?
    private let applyUpToPointIndex: Int?
    private let futureRouteAction: FutureRouteAction?

    private let segmentControl = UISegmentedControl(items: [
        localizedString("layer_route"),
        localizedString("shared_string_settings")
    ])
    private let tabContainerView = UIView()
    private var activeTab: ActiveTab = .routeType
    private var selectedMode: OAApplicationMode?
    private var routeTypeVC: RouteTypeViewController?
    private var settingsVC: RouteSettingsViewController?
    private var activeTabViewController: UIViewController?
    private weak var dataSource: PlanRoutePointsDataSource?

    private var settingsMode: OAApplicationMode? {
        selectedMode ?? context.currentMode ?? dataSource?.defaultMode ?? OAApplicationMode.getFirstAvailableNavigation()
    }

    init(context: SegmentRouteContext, dataSource: PlanRoutePointsDataSource?, applyFromPointIndex: Int? = nil, applyUpToPointIndex: Int? = nil, futureRouteAction: FutureRouteAction? = nil) {
        self.context = context
        self.applyFromPointIndex = applyFromPointIndex
        self.applyUpToPointIndex = applyUpToPointIndex
        self.dataSource = dataSource
        self.futureRouteAction = futureRouteAction
        if case .wholeTrack = context {
            self.selectedMode = dataSource?.defaultMode
        } else {
            self.selectedMode = context.currentMode
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBg
        setupNavigationBar()
        if futureRouteAction == nil {
            setupSegmentControl()
        }
        setupTabContainer()
        switchTab(to: .routeType, animated: false)
    }

    override func isNavbarVisible() -> Bool {
        true
    }

    private func setupNavigationBar() {
        navigationItem.title = context.screenTitle
        if let subtitle = context.screenSubtitle {
            let titleView = TwoLineTitleView(title: context.screenTitle, subtitle: subtitle)
            navigationItem.titleView = titleView
        }

        if context.usesCloseButton && navigationController?.viewControllers.first === self {
            let closeButton = UIBarButtonItem(image: UIImage(systemName: "xmark"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(onCloseTapped))
            closeButton.tintColor = .textColorPrimary
            navigationItem.leftBarButtonItem = closeButton
        }

        guard futureRouteAction == nil else { return }
        let checkmarkColor: UIColor
        if #available(iOS 26.0, *) {
            checkmarkColor = .white
        } else {
            checkmarkColor = .iconColorActive
        }
        let checkmarkImage = UIImage.icCheckmarkDefault.withTintColor(checkmarkColor, renderingMode: .alwaysOriginal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: checkmarkImage,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(onConfirmTapped))
    }

    private func setupSegmentControl() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupTabContainer() {
        tabContainerView.clipsToBounds = true
        tabContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabContainerView)
        NSLayoutConstraint.activate([
            tabContainerView.topAnchor.constraint(equalTo: futureRouteAction == nil ? segmentControl.bottomAnchor : view.safeAreaLayoutGuide.topAnchor, constant: 12),
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
        let showsContinuationActions = futureRouteAction == nil
            && context.usesCloseButton
            && navigationController?.viewControllers.first === self
        return RouteTypeViewController(
            context: context,
            availableModes: dataSource?.availableModes ?? [],
            selectedMode: selectedMode,
            canStartNewSegment: showsContinuationActions && (dataSource?.canStartNewSegment ?? false),
            showsRecalculationHint: futureRouteAction == nil,
            onContinueRoute: showsContinuationActions && !(dataSource?.routeSegments.isEmpty ?? true) ? { [weak self] in
                self?.openFutureRouteSelection(.continueRoute)
            } : nil,
            onModeSelected: { [weak self] mode in
                guard let self else { return }
                selectedMode = mode
                if let futureRouteAction {
                    switch futureRouteAction {
                    case .continueRoute:
                        dataSource?.continueRoute(mode: mode)
                    case .startNewSegment:
                        dataSource?.startNewSegment(mode: mode)
                    }
                    let completion = onContinueEditing
                    navigationController?.dismiss(animated: true, completion: completion)
                }
            },
            onStartNewSegment: { [weak self] in
                self?.openFutureRouteSelection(.startNewSegment)
            }
        )
    }

    private func makeSettingsVC() -> RouteSettingsViewController {
        guard let settingsMode else {
            return RouteSettingsViewController(appMode: OAApplicationMode.default())
        }
        let vc = RouteSettingsViewController(appMode: settingsMode)
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
        vc.settingsChangedHandler = { [weak self] in
            self?.dataSource?.refreshRoute(for: settingsMode)
        }
        return vc
    }

    private func openFutureRouteSelection(_ action: FutureRouteAction) {
        let controller = SegmentRouteSettingsViewController(context: .wholeTrack, dataSource: dataSource, futureRouteAction: action)
        controller.onContinueEditing = onContinueEditing
        navigationController?.pushViewController(controller, animated: true)
    }

    private func refreshSettingsState() {
        settingsVC?.reloadData()
    }

    @objc private func onSegmentChanged() {
        let tab: ActiveTab = segmentControl.selectedSegmentIndex == 0 ? .routeType : .settings
        switchTab(to: tab, animated: false)
    }

    @objc private func onConfirmTapped() {
        if let fromIndex = applyFromPointIndex, case let .profileGroup(group, _) = context {
            guard let mode = selectedMode ?? OAApplicationMode.default() else { return }
            let pointIndexes = group.points.filter { $0.index >= fromIndex }.map(\.index)
            dataSource?.applyMode(mode, pointIndexes: pointIndexes)
        } else if let upToIndex = applyUpToPointIndex, case let .profileGroup(group, _) = context {
            guard let mode = selectedMode ?? OAApplicationMode.default() else { return }
            let pointIndexes = group.points.filter { $0.index <= upToIndex }.map(\.index)
            dataSource?.applyMode(mode, pointIndexes: pointIndexes)
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
}
