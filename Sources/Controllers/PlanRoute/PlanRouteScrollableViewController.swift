//
//  PlanRouteScrollableViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteScrollableViewController: OABaseScrollableHudViewController {
    private static let topPartHeight: CGFloat = 50
    private static let grabberAreaHeight: CGFloat = 16
    private static let segmentedControlHeight: CGFloat = 36
    private static let bottomToolbarAreaHeight: CGFloat = 60
    private static let horizontalInset: CGFloat = 20
    private static let cornerRadius: CGFloat = 16
    private static let fullScreenTopGap: CGFloat = 8
    private static let animationDuration: TimeInterval = 0.3

    private let dataProvider: PlanRouteDataProvider

    private let sheetView = UIView()
    private let grabberView = UIView()
    private let topToolbar = PlanRouteTopToolbarView()
    private let bottomToolbar = PlanRouteBottomToolbarView()
    private let topPartView = PlanRouteTopPartView()
    private let segmentControl = UISegmentedControl()
    private let tabContainerView = UIView()
    private let crosshairView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "map_ruler_center_day"))
        imageView.contentMode = .center
        return imageView
    }()

    private let tabs = PlanRouteTab.allCases
    private var sheetState: EOADraggableMenuState = .expanded
    private var selectedTab: PlanRouteTab = .default
    private var tabViewControllers: [PlanRouteTab: UIViewController] = [:]
    private var sheetHeightConstraint: NSLayoutConstraint?
    private var crosshairCenterYConstraint: NSLayoutConstraint?
    private var panStartHeight: CGFloat = 0
    private weak var currentTabViewController: UIViewController?
    private let routeTypeButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_straight_line"))

    init(dataProvider: PlanRouteDataProvider) {
        self.dataProvider = dataProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc(showNewRoute)
    static func showNewRoute() {
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .newRoute))
    }

    @objc(openExistingTrackWithFilePath:)
    static func openExistingTrack(filePath: String) {
        let fileName = ((filePath as NSString).lastPathComponent as NSString).deletingPathExtension
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .editTrack(fileName: fileName), filePath: filePath))
    }

    private static func showPlanRoute(dataProvider: PlanRouteDataProvider) {
        let controller = PlanRouteScrollableViewController(dataProvider: dataProvider)
        OARootViewController.instance().mapPanel?.showScrollableHudViewController(controller)
    }

    override func loadView() {
        let root = OAUserInteractionPassThroughView()
        root.isScreenClickable = true
        view = root
    }

    override func viewDidLoad() {
        setupSheet()
        setupTopPart()
        setupBottomToolbar()
        setupContent()
        setupTopToolbar()
        setupRouteTypeButton()
        setupCrosshair()
        dataProvider.onDataChanged = { [weak self] in self?.reloadData() }
        dataProvider.onPointSelected = { [weak self] index in self?.presentPointMenu(for: index) }
        dataProvider.onChangeRouteTypeBefore = { [weak self] pointIndex in self?.presentChangeRouteType(before: pointIndex) }
        dataProvider.onChangeRouteTypeAfter = { [weak self] pointIndex in self?.presentChangeRouteType(after: pointIndex) }
        selectTab(.default)
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        applyHeight(for: sheetState)
        tabContainerView.alpha = isContentVisible(in: sheetState) ? 1 : 0
        view.layoutIfNeeded()
        updateCrosshairPosition(sheetHeight: height(for: sheetState))
        if animated {
            sheetView.transform = CGAffineTransform(translationX: 0, y: height(for: sheetState))
            UIView.animate(withDuration: Self.animationDuration) { [weak self] in
                self?.sheetView.transform = .identity
            }
        }
        refreshMapControls()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] _ in
            guard let self else { return }
            applyHeight(for: sheetState)
            updateCrosshairPosition(sheetHeight: height(for: sheetState))
            refreshMapControls()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        OAAppSettings.sharedManager().nightMode ? .lightContent : .default
    }

    override func getViewHeight() -> CGFloat {
        mapControlsReservedHeight(for: sheetState)
    }

    override func getViewHeight(_ state: EOADraggableMenuState) -> CGFloat {
        mapControlsReservedHeight(for: state)
    }

    override func getNavbarHeight() -> CGFloat {
        OAUtilities.getStatusBarHeight() + PlanRouteTopToolbarView.contentHeight
    }

    override func getToolbarHeight() -> CGFloat {
        Self.bottomToolbarAreaHeight
    }

    override func getLandscapeViewWidth() -> CGFloat {
        view.bounds.width
    }

    override func hide() {
        hide(true, duration: Self.animationDuration, onComplete: nil)
    }

    override func forceHide() {
        hide(false, duration: 0, onComplete: nil)
    }

    override func hide(_ animated: Bool, duration: TimeInterval, onComplete: (() -> Void)!) {
        let dismiss: () -> Void = { [weak self] in
            self?.dataProvider.dismissLayer()
            OARootViewController.instance().mapPanel?.hideScrollableHudViewController()
            self?.removeFromParent()
            self?.view.removeFromSuperview()
            onComplete?()
        }
        guard animated else {
            dismiss()
            return
        }
        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let self else { return }
            sheetView.transform = CGAffineTransform(translationX: 0, y: height(for: sheetState))
        }, completion: { _ in dismiss() })
    }

    func reloadData() {
        topPartView.configure(with: dataProvider.routeInfo)
        bottomToolbar.isUndoEnabled = dataProvider.canUndo
        bottomToolbar.isRedoEnabled = dataProvider.canRedo
        updateRouteTypeButton()
        currentTabViewController.flatMap { $0 as? PlanRouteTabContent }?.reloadData()
    }

    private func setupSheet() {
        sheetView.backgroundColor = .viewBg
        sheetView.layer.cornerRadius = Self.cornerRadius
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)
        let heightConstraint = sheetView.heightAnchor.constraint(equalToConstant: height(for: sheetState))
        sheetHeightConstraint = heightConstraint
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint
        ])

        grabberView.backgroundColor = .iconColorTertiary
        grabberView.layer.cornerRadius = 2.5
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(grabberView)
        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 8),
            grabberView.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 36),
            grabberView.heightAnchor.constraint(equalToConstant: 5)
        ])

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.delegate = self
        sheetView.addGestureRecognizer(panRecognizer)
    }

    private func setupTopPart() {
        topPartView.onTap = { [weak self] in
            self?.toggleState()
        }
        topPartView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(topPartView)
        NSLayoutConstraint.activate([
            topPartView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 6),
            topPartView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            topPartView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            topPartView.heightAnchor.constraint(equalToConstant: Self.topPartHeight)
        ])
    }

    private func setupContent() {
        setupSegmentControl()
        tabContainerView.clipsToBounds = true
        [segmentControl, tabContainerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            sheetView.addSubview($0)
        }
        sheetView.bringSubviewToFront(bottomToolbar)
        let inset = Self.horizontalInset
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: topPartView.bottomAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: inset),
            segmentControl.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -inset),
            segmentControl.heightAnchor.constraint(equalToConstant: Self.segmentedControlHeight),

            tabContainerView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            tabContainerView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            tabContainerView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            tabContainerView.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor)
        ])
    }

    private func setupSegmentControl() {
        segmentControl.removeAllSegments()
        for (index, tab) in tabs.enumerated() {
            segmentControl.insertSegment(withTitle: tab.title, at: index, animated: false)
        }
        segmentControl.selectedSegmentIndex = tabs.firstIndex(of: selectedTab) ?? 0
        segmentControl.backgroundColor = .groupBgColorSecondary
        segmentControl.selectedSegmentTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        let segmentAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: UIFont.scaledSystemFont(ofSize: 13, weight: .medium)
        ]
        segmentControl.setTitleTextAttributes(segmentAttributes, for: .normal)
        segmentControl.setTitleTextAttributes(segmentAttributes, for: .selected)
        segmentControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onSegmentTapped))
        segmentControl.addGestureRecognizer(tapGesture)
    }

    private func setupBottomToolbar() {
        bottomToolbar.isUndoEnabled = dataProvider.canUndo
        bottomToolbar.isRedoEnabled = dataProvider.canRedo
        bottomToolbar.onAddPoi = { [weak self] in self?.handleAddPoi() }
        bottomToolbar.onUndo = { [weak self] in self?.handleUndo() }
        bottomToolbar.onRedo = { [weak self] in self?.handleRedo() }
        bottomToolbar.onAddRoutePoint = { [weak self] in self?.handleAddRoutePoint() }
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(bottomToolbar)
        let inset = Self.horizontalInset
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: inset),
            bottomToolbar.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -inset),
            bottomToolbar.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomToolbar.heightAnchor.constraint(equalToConstant: PlanRouteButtonFactory.bottomButtonHeight)
        ])
    }

    private func setupTopToolbar() {
        topToolbar.titleText = dataProvider.mode.title
        topToolbar.isSaveButtonVisible = true
        topToolbar.optionsMenu = makeOptionsMenu()
        topToolbar.onClose = { [weak self] in self?.handleClose() }
        topToolbar.onSave = { [weak self] in self?.handleSave() }
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topToolbar)
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: PlanRouteTopToolbarView.contentHeight)
        ])
    }

    private func setupCrosshair() {
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.isUserInteractionEnabled = false
        view.insertSubview(crosshairView, belowSubview: sheetView)
        let centerY = crosshairView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: crosshairCenterY(sheetHeight: height(for: sheetState)))
        crosshairCenterYConstraint = centerY
        NSLayoutConstraint.activate([
            crosshairView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerY
        ])
    }

    private func setupRouteTypeButton() {
        routeTypeButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(routeTypeButton, belowSubview: sheetView)
        NSLayoutConstraint.activate([
            routeTypeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            routeTypeButton.bottomAnchor.constraint(equalTo: sheetView.topAnchor, constant: -12)
        ])
        routeTypeButton.addTarget(self, action: #selector(onRouteTypeButtonTapped), for: .touchUpInside)
        updateRouteTypeButton()
    }

    private func updateRouteTypeButton() {
        let segments = dataProvider.routeSegments
        let mode = segments.last?.singleMode
        let icon: UIImage?
        if let mode {
            icon = mode.getIcon()?.withRenderingMode(.alwaysTemplate)
        } else {
            icon = .templateImageNamed("ic_custom_straight_line")
        }
        routeTypeButton.setImage(icon, for: .normal)
    }

    private func presentRouteBetweenPoints() {
        let listVC = RouteBetweenPointsViewController(dataSource: dataProvider)
        let navController = UINavigationController(rootViewController: listVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }

    func presentPointMenu(for pointIndex: Int) {
        dataProvider.showPointOptions(index: pointIndex, in: self)
    }

    private func presentChangeRouteType(before pointIndex: Int) {
        let segments = dataProvider.routeSegments
        guard let (segment, group, _) = findPointContext(index: pointIndex, in: segments) else { return }
        let groupIndex = segment.groups.firstIndex(where: { $0.lastPointIndex == group.lastPointIndex }) ?? 0
        guard groupIndex > 0 else { return }
        let prevGroup = segment.groups[groupIndex - 1]
        presentSettingsForContext(.profileGroup(prevGroup, segment: segment))
    }

    private func presentChangeRouteType(after pointIndex: Int) {
        let segments = dataProvider.routeSegments
        guard let (segment, group, _) = findPointContext(index: pointIndex, in: segments) else { return }
        presentSettingsForContext(.profileGroup(group, segment: segment))
    }

    private func presentSettingsForContext(_ context: SegmentRouteContext) {
        let settingsVC = SegmentRouteSettingsViewController(context: context, dataSource: dataProvider)
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func findPointContext(index: Int, in segments: [PlanRouteSegment]) -> (PlanRouteSegment, PlanRouteProfileGroup, PlanRoutePoint)? {
        for segment in segments {
            for group in segment.groups {
                if let point = group.points.first(where: { $0.index == index }) {
                    return (segment, group, point)
                }
            }
        }
        return nil
    }

    @objc private func onRouteTypeButtonTapped() {
        presentRouteBetweenPoints()
    }

    private func crosshairCenterY(sheetHeight: CGFloat) -> CGFloat {
        let h = OAUtilities.calculateScreenHeight()
        if sheetHeight <= height(for: .initial) {
            return h / 2.0
        }
        let visibleTop = getNavbarHeight()
        let visibleBottom = h - min(sheetHeight, height(for: .expanded))
        return visibleTop + (visibleBottom - visibleTop) / 2
    }

    private func updateCrosshairPosition(sheetHeight: CGFloat) {
        let centerY = crosshairCenterY(sheetHeight: sheetHeight)
        crosshairCenterYConstraint?.constant = centerY
        let x = view.bounds.midX
        guard x > 0 else { return }
        if sheetHeight > height(for: .initial) {
            dataProvider.setCrosshairPosition(screenPoint: CGPoint(x: x, y: centerY))
        } else {
            dataProvider.setCrosshairPosition(screenPoint: .zero)
        }
    }

    private func height(for state: EOADraggableMenuState) -> CGFloat {
        let screenHeight = OAUtilities.calculateScreenHeight()
        let collapsed = Self.grabberAreaHeight + Self.topPartHeight + 8 + Self.segmentedControlHeight + 12
            + PlanRouteButtonFactory.bottomButtonHeight + 8 + OAUtilities.getBottomMargin()
        switch state {
        case .initial:
            return collapsed
        case .expanded:
            return screenHeight / 2
        case .fullScreen:
            return screenHeight - getNavbarHeight() - Self.fullScreenTopGap
        @unknown default:
            return screenHeight / 2
        }
    }

    private func applyHeight(for state: EOADraggableMenuState) {
        sheetHeightConstraint?.constant = height(for: state)
    }

    private func mapControlsReservedHeight(for state: EOADraggableMenuState) -> CGFloat {
        min(height(for: state), height(for: .expanded))
    }

    private func setState(_ state: EOADraggableMenuState, animated: Bool) {
        sheetState = state
        let h = height(for: state)
        sheetHeightConstraint?.constant = h
        updateCrosshairPosition(sheetHeight: h)
        let updates: () -> Void = { [weak self] in
            guard let self else { return }
            view.layoutIfNeeded()
            tabContainerView.alpha = isContentVisible(in: state) ? 1 : 0
            refreshMapControls()
        }
        if animated {
            UIView.animate(withDuration: Self.animationDuration, animations: updates)
        } else {
            updates()
        }
    }

    private func isContentVisible(in state: EOADraggableMenuState) -> Bool {
        state != .initial
    }

    private func toggleState() {
        setState(sheetState == .initial ? .expanded : .initial, animated: true)
    }

    private func nearestState(for currentHeight: CGFloat, velocity: CGFloat) -> EOADraggableMenuState {
        if velocity < -800 { return .fullScreen }
        if velocity > 800 { return .initial }
        let candidates: [EOADraggableMenuState] = [.initial, .expanded, .fullScreen]
        return candidates.min { abs(height(for: $0) - currentHeight) < abs(height(for: $1) - currentHeight) } ?? .expanded
    }

    private func refreshMapControls() {
        let style: UIStatusBarStyle = OAAppSettings.sharedManager().nightMode ? .lightContent : .default
        OARootViewController.instance().mapPanel?.targetUpdateControlsLayout(true, customStatusBarStyle: style)
    }

    private func tabViewController(for tab: PlanRouteTab) -> UIViewController {
        if let existing = tabViewControllers[tab] {
            return existing
        }
        let controller: UIViewController
        switch tab {
        case .poi: controller = PlanRoutePoiViewController(dataSource: dataProvider)
        case .analyze: controller = PlanRouteAnalyzeViewController(dataSource: dataProvider)
        case .route:
            let routeVC = PlanRouteRouteViewController(dataSource: dataProvider)
            routeVC.onPointSelected = { [weak self] point, group, segment in
                self?.presentPointMenu(for: point.index)
            }
            controller = routeVC
        }
        tabViewControllers[tab] = controller
        return controller
    }

    private func selectTab(_ tab: PlanRouteTab) {
        selectedTab = tab
        let newController = tabViewController(for: tab)
        guard newController !== currentTabViewController else { return }
        currentTabViewController?.willMove(toParent: nil)
        currentTabViewController?.view.removeFromSuperview()
        currentTabViewController?.removeFromParent()

        addChild(newController)
        newController.view.translatesAutoresizingMaskIntoConstraints = false
        tabContainerView.addSubview(newController.view)
        NSLayoutConstraint.activate([
            newController.view.topAnchor.constraint(equalTo: tabContainerView.topAnchor),
            newController.view.leadingAnchor.constraint(equalTo: tabContainerView.leadingAnchor),
            newController.view.trailingAnchor.constraint(equalTo: tabContainerView.trailingAnchor),
            newController.view.bottomAnchor.constraint(equalTo: tabContainerView.bottomAnchor)
        ])
        newController.didMove(toParent: self)
        currentTabViewController = newController
    }

    private func makeOptionsMenu() -> UIMenu {
        let actions = PlanRouteMenuAction.actions(for: dataProvider.mode).map { action in
            UIAction(title: action.title,
                     image: action.icon,
                     attributes: action.isDestructive ? .destructive : []) { [weak self] _ in
                self?.handleMenuAction(action)
            }
        }
        return UIMenu(children: actions)
    }

    private func handleClose() {
        guard dataProvider.hasChanges else {
            hide()
            return
        }
        let alert = UIAlertController(title: localizedString("exit_without_saving"),
                                      message: nil,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_discard"), style: .destructive) { [weak self] _ in
            self?.hide()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func handleSave() {
        switch dataProvider.mode {
        case .newRoute:
            presentSaveDialog(duplicate: false)
        case .editTrack(let fileName):
            dataProvider.saveAs(fileName: fileName, folder: nil, showOnMap: true) { [weak self] success, _ in
                guard let self else { return }
                if success {
                    reloadData()
                } else {
                    showSaveError()
                }
            }
        }
    }

    private func handleAddPoi() {
        dataProvider.openAddPoi(from: self)
    }

    private func handleUndo() {
        dataProvider.undo()
        reloadData()
    }

    private func handleRedo() {
        dataProvider.redo()
        reloadData()
    }

    private func handleAddRoutePoint() {
        dataProvider.addRoutePoint()
        reloadData()
    }

    private func handleMenuAction(_ action: PlanRouteMenuAction) {
        switch action {
        case .saveAs:
            presentSaveDialog(duplicate: false)
        case .saveAsCopy:
            presentSaveDialog(duplicate: true)
        case .appendToExistingTrack:
            presentAppendToTrack()
        case .changeSegmentOrder:
            break
        case .viewDirections:
            break
        case .reverseRoute:
            dataProvider.reverseRoute()
            reloadData()
        case .navigation:
            hide()
            dataProvider.enterNavigation()
        case .clearAllPoints:
            confirmClearAllPoints()
        }
    }

    private func presentSaveDialog(duplicate: Bool) {
        let fileName: String
        switch dataProvider.mode {
        case .newRoute: fileName = localizedString("quick_action_new_route")
        case .editTrack(let name): fileName = name
        }
        guard let vc = OASaveTrackViewController(fileName: fileName, filePath: nil, showOnMap: true, simplifiedTrack: false, duplicate: duplicate) else { return }
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func presentAppendToTrack() {
        guard let vc = OAOpenAddTrackViewController(screenType: .addToATrack) else { return }
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func confirmClearAllPoints() {
        let alert = UIAlertController(title: localizedString("distance_measurement_clear_route"),
                                      message: nil,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_clear"), style: .destructive) { [weak self] _ in
            self?.dataProvider.clearAllPoints()
            self?.reloadData()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func showSaveError() {
        let alert = UIAlertController(title: localizedString("gpx_export_failed"),
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
        present(alert, animated: true)
    }

    @objc private func onSegmentChanged() {
        let index = segmentControl.selectedSegmentIndex
        guard tabs.indices.contains(index) else { return }
        selectTab(tabs[index])
    }

    @objc private func onSegmentTapped() {
        if sheetState == .initial {
            setState(.expanded, animated: true)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sheetHeightConstraint else { return }
        let translation = gesture.translation(in: view).y
        switch gesture.state {
        case .began:
            panStartHeight = sheetHeightConstraint.constant
        case .changed:
            let lower = height(for: .initial)
            let upper = height(for: .fullScreen)
            let newHeight = min(max(panStartHeight - translation, lower), upper)
            sheetHeightConstraint.constant = newHeight
            updateCrosshairPosition(sheetHeight: newHeight)
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            setState(nearestState(for: sheetHeightConstraint.constant, velocity: velocity), animated: true)
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PlanRouteScrollableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: tabContainerView)
        return !tabContainerView.bounds.contains(location)
    }
}

// MARK: - OASaveTrackViewControllerDelegate
extension PlanRouteScrollableViewController: OASaveTrackViewControllerDelegate {
    func onSave(asNewTrack fileName: String, showOnMap: Bool, simplifiedTrack: Bool, openTrack: Bool) {
        dataProvider.saveAs(fileName: fileName, folder: nil, showOnMap: showOnMap) { [weak self] success, _ in
            guard let self else { return }
            if success {
                topToolbar.titleText = fileName
                reloadData()
            } else {
                showSaveError()
            }
        }
    }
}

// MARK: - OAOpenAddTrackDelegate
extension PlanRouteScrollableViewController: OAOpenAddTrackDelegate {
    func onFileSelected(_ gpxFilePath: String) {
        let fileName = ((gpxFilePath as NSString).lastPathComponent as NSString).deletingPathExtension
        dataProvider.saveAs(fileName: fileName, folder: nil, showOnMap: false) { [weak self] success, _ in
            guard let self else { return }
            if !success { showSaveError() }
        }
    }
}
