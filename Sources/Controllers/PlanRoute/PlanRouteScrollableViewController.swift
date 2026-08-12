//
//  PlanRouteScrollableViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import CoreLocation

final class PlanRouteScrollableViewController: OABaseScrollableHudViewController {
    private static let topPartViewHeight: CGFloat = 50
    private static let sheetGrabberAreaHeight: CGFloat = 16
    private static let bottomToolbarReservedHeight: CGFloat = 60
    private static let sheetContentHorizontalInset: CGFloat = 16
    private static let sheetCornerRadius: CGFloat = 28
    private static let fullScreenSheetTopInset: CGFloat = 8
    private static let sheetAnimationDuration: TimeInterval = 0.3
    private static let sheetFlingVelocityThresholdPointsPerSecond: CGFloat = 800

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private let dataProvider: PlanRouteDataProvider

    private let sheetView = UIView()
    private let grabberView = UIView()
    private let topToolbar = PlanRouteTopToolbarView()
    private let bottomToolbar = PlanRouteBottomToolbarView()
    private let topPartView = PlanRouteTopPartView()
    private let segmentControl = UISegmentedControl()
    private let tabContainerView = UIView()
    private let crosshairView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    private let tabs = PlanRouteTab.allCases
    private let routeTypeButton = PlanRouteButtonFactory.iconMapButton(image: .icCustomQuestionmark)
    private var sheetState: EOADraggableMenuState = .expanded
    private var selectedTab: PlanRouteTab = .default
    private var sheetHeightConstraint: NSLayoutConstraint?
    private var crosshairCenterYConstraint: NSLayoutConstraint?
    private var dayNightObserver: OAAutoObserverProxy?
    private var routeTypeButtonBottomConstraint: NSLayoutConstraint?
    private var panStartHeight: CGFloat = 0
    private var navControllerHistory: [UIViewController] = []
    private var trackMenuState: OATrackMenuViewControllerState?
    private var isForceHiding = false
    private var isPendingSaveAsCopy = false
    private var pendingSegmentPointIndexes: [Int]?
    private var pointEditingView: OAInfoBottomView?
    private var pointEditingHeight: CGFloat?
    private var cachedMapViewportYScale: Double?
    private var approximationHeight: CGFloat?
    private var approximationPreviousSheetState: EOADraggableMenuState?
    private var approximationNavigationController: UINavigationController?
    private weak var currentTabViewController: UIViewController?

    private var suggestedFileName: String {
        switch dataProvider.mode {
        case .newRoute: OAUtilities.generateCurrentDateFilename()
        case .editTrack(let fileName): fileName
        }
    }

    private var currentScreenHeight: CGFloat {
        guard isViewLoaded, view.bounds.height > 0 else { return OAUtilities.calculateScreenHeight() }
        return view.bounds.height
    }

    init(dataProvider: PlanRouteDataProvider) {
        self.dataProvider = dataProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        dayNightObserver?.detach()
    }

    @objc static func showNewRoute() {
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .newRoute))
    }

    @objc(showNewRouteWithInitialPoint:) static func showNewRoute(withInitialPoint initialPoint: CLLocationCoordinate2D) {
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .newRoute, initialPoint: initialPoint))
    }

    @objc(showNewRouteWithApplicationMode:) static func showNewRoute(applicationMode: OAApplicationMode) {
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .newRoute, applicationMode: applicationMode))
    }

    @objc static func openExistingTrack(filePath: String) {
        openExistingTrack(filePath: filePath, navControllerHistory: [])
    }

    static func openExistingTrack(filePath: String, navControllerHistory: [UIViewController]) {
        let fileName = ((filePath as NSString).lastPathComponent as NSString).deletingPathExtension
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .editTrack(fileName: fileName), filePath: filePath),
                      navControllerHistory: navControllerHistory)
    }

    @objc(openExistingTrackWithFilePath:trackMenuState:) static func openExistingTrack(filePath: String, trackMenuState: OATrackMenuViewControllerState) {
        let fileName = ((filePath as NSString).lastPathComponent as NSString).deletingPathExtension
        showPlanRoute(dataProvider: PlanRouteEditingContextDataProvider(mode: .editTrack(fileName: fileName), filePath: filePath),
                      trackMenuState: trackMenuState)
    }

    private static func showPlanRoute(dataProvider: PlanRouteDataProvider, navControllerHistory: [UIViewController] = [], trackMenuState: OATrackMenuViewControllerState? = nil) {
        let controller = PlanRouteScrollableViewController(dataProvider: dataProvider)
        controller.navControllerHistory = navControllerHistory
        controller.trackMenuState = trackMenuState
        OARootViewController.instance().mapPanel?.showScrollableHudViewController(controller)
    }

    override func loadView() {
        view = OAUserInteractionPassThroughView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cachedMapViewportYScale = OARootViewController.instance().mapPanel.mapViewController.viewportYScale
        (view as? OAUserInteractionPassThroughView)?.isScreenClickable = true
        setupSheet()
        setupTopPart()
        setupBottomToolbar()
        setupContent()
        setupTopToolbar()
        setupRouteTypeButton()
        setupCrosshair()
        dayNightObserver = OAAutoObserverProxy(self,
                                               withHandler: #selector(onDayNightModeChanged),
                                               andObserve: OsmAndApp.swiftInstance().dayNightModeObservable)
        dataProvider.presenterViewController = self
        dataProvider.onDataChanged = { [weak self] in
            self?.reloadData()
        }
        dataProvider.onRouteInfoChanged = { [weak self] in
            self?.reloadRouteInfo()
        }
        dataProvider.onChangeRouteTypeBefore = { [weak self] pointIndex in self?.presentChangeRouteType(before: pointIndex) }
        dataProvider.onChangeRouteTypeAfter = { [weak self] pointIndex in self?.presentChangeRouteType(after: pointIndex) }
        dataProvider.onPointEditModeRequested = { [weak self] mode in
            self?.showPointEditingView(mode: mode)
        }
        dataProvider.onApproximationPopupDismissed = { [weak self] in
            DispatchQueue.main.async {
                self?.dismissApproximationPopup()
            }
        }
        selectTab(.default)
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCrosshairImage()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let height = approximationHeight ?? pointEditingHeight ?? height(for: sheetState)
        sheetHeightConstraint?.constant = height
        tabContainerView.alpha = isContentVisible(in: sheetState) ? 1 : 0
        if view.window != nil {
            view.layoutIfNeeded()
        }
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height)
        routeTypeButtonBottomConstraint?.constant = pointEditingHeight == nil
            ? -routeTypeButtonBottomInset(for: sheetState)
            : -(height + 12)
        updateCrosshairMapCenter(sheetHeight: height)
        if animated {
            sheetView.transform = CGAffineTransform(translationX: 0, y: height)
            UIView.animate(withDuration: Self.sheetAnimationDuration) {
                self.sheetView.transform = .identity
            }
        }
        refreshMapControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setMapHudStatusBarHidden(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setMapHudStatusBarHidden(false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let self else { return }
            let height = approximationHeight ?? pointEditingHeight ?? self.height(for: sheetState, screenHeight: size.height)
            sheetHeightConstraint?.constant = height
            crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height, screenHeight: size.height)
            routeTypeButtonBottomConstraint?.constant = pointEditingHeight == nil
                ? -routeTypeButtonBottomInset(for: sheetState)
                : -(height + 12)
            updateCrosshairMapCenter(sheetHeight: height, screenSize: size)
            refreshMapControls()
        }
    }

    override func getViewHeight() -> CGFloat {
        approximationHeight ?? pointEditingHeight ?? mapControlsReservedHeight(for: sheetState)
    }

    override func getViewHeight(_ state: EOADraggableMenuState) -> CGFloat {
        approximationHeight ?? pointEditingHeight ?? mapControlsReservedHeight(for: state)
    }

    override func getNavbarHeight() -> CGFloat {
        OAUtilities.getStatusBarHeight() + PlanRouteTopToolbarView.contentHeight
    }

    override func getToolbarHeight() -> CGFloat {
        Self.bottomToolbarReservedHeight
    }

    override func getLandscapeViewWidth() -> CGFloat {
        view.bounds.width
    }

    override func hide() {
        hide(true, duration: Self.sheetAnimationDuration, onComplete: nil)
    }

    override func forceHide() {
        isForceHiding = true
        hide(false, duration: 0, onComplete: nil)
    }

    override func hide(_ animated: Bool, duration: TimeInterval, onComplete: (() -> Void)?) {
        let dismiss: () -> Void = { [weak self] in
            guard let self else { return }
            setMapHudStatusBarHidden(false)
            restoreMapViewport()
            dataProvider.dismissLayer()
            OARootViewController.instance().mapPanel?.hideScrollableHudViewController()
            removeFromParent()
            view.removeFromSuperview()
            restorePreviousScreenIfNeeded()
            onComplete?()
        }
        guard animated else {
            dismiss()
            return
        }
        UIView.animate(withDuration: duration, animations: {
            let height = self.approximationHeight ?? self.height(for: self.sheetState)
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: height)
        }, completion: { _ in dismiss() })
    }
    
    override func isLeftSidePresentation() -> Bool {
        false
    }
    
    override var currentState: EOADraggableMenuState {
        sheetState
    }

    func reloadData() {
        let routeInfo = dataProvider.routeInfo
        topPartView.configure(with: routeInfo, isCalculatingRoute: dataProvider.isCalculatingRoute)
        updateTopToolbar()
        bottomToolbar.isUndoEnabled = dataProvider.canUndo
        bottomToolbar.isRedoEnabled = dataProvider.canRedo
        updateRouteTypeButton()
        currentTabViewController.flatMap { $0 as? PlanRouteTabContent }?.reloadData()
        updateCrosshairMapCenter(sheetHeight: approximationHeight ?? pointEditingHeight ?? height(for: sheetState))
        refreshMapControls()
    }

    private func restorePreviousScreenIfNeeded() {
        if isForceHiding {
            let hasNavHistory = !navControllerHistory.isEmpty
                || !(trackMenuState?.navControllerHistory?.isEmpty ?? true)
            if hasNavHistory {
                OARootViewController.instance().navigationController?.restoreForceHidingScrollableHud()
            }
            return
        }
        if let trackMenuState {
            restoreTrackMenu(trackMenuState)
            return
        }
        guard !navControllerHistory.isEmpty,
              let navigationController = OARootViewController.instance().navigationController else { return }
        navigationController.setViewControllers(navControllerHistory, animated: true)
    }

    private func restoreTrackMenu(_ state: OATrackMenuViewControllerState) {
        if state.openedFromTracksList, !state.openedFromTrackMenu,
           let history = state.navControllerHistory, !history.isEmpty {
            OARootViewController.instance().navigationController?.setViewControllers(history, animated: true)
            return
        }
        state.openedFromTrackMenu = false
        guard let filePath = state.gpxFilePath, !filePath.isEmpty,
              let gpx = OAGPXDatabase.sharedDb().getGPXItem(filePath) else { return }
        let trackItem = TrackItem(file: gpx.file)
        trackItem.dataItem = gpx
        OARootViewController.instance().mapPanel?.openTargetView(withGPX: trackItem, trackHudMode: .menuHudMode, state: state)
    }

    private func reloadRouteInfo() {
        guard isViewLoaded else { return }
        topPartView.configure(with: dataProvider.routeInfo, isCalculatingRoute: dataProvider.isCalculatingRoute)
        updateTopToolbar()
    }

    private func setupSheet() {
        sheetView.backgroundColor = .viewBg
        sheetView.layer.cornerRadius = Self.sheetCornerRadius
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)
        let heightConstraint = sheetView.heightAnchor.constraint(equalToConstant: height(for: sheetState))
        sheetHeightConstraint = heightConstraint
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
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
            topPartView.heightAnchor.constraint(equalToConstant: Self.topPartViewHeight)
        ])
    }

    private func setupContent() {
        let horizontalInset = Self.sheetContentHorizontalInset
        setupSegmentControl()
        tabContainerView.clipsToBounds = true
        let contentViews = [segmentControl, tabContainerView]
        for contentView in contentViews {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            sheetView.addSubview(contentView)
        }
        sheetView.bringSubviewToFront(bottomToolbar)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: topPartView.bottomAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: horizontalInset),
            segmentControl.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -horizontalInset),

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
        segmentControl.selectedSegmentTintColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: 0x636366) : .white }
        let segmentFont = UIFont.scaledSystemFont(ofSize: 13, weight: .medium)
        let segmentTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.textColorPrimary,
            .font: segmentFont
        ]
        segmentControl.setTitleTextAttributes(segmentTextAttributes, for: .normal)
        segmentControl.setTitleTextAttributes(segmentTextAttributes, for: .selected)
        segmentControl.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)
        segmentControl.addTarget(self, action: #selector(onSegmentTapped), for: .touchUpInside)
    }

    private func setupBottomToolbar() {
        bottomToolbar.isUndoEnabled = dataProvider.canUndo
        bottomToolbar.isRedoEnabled = dataProvider.canRedo
        bottomToolbar.onAddPoi = { [weak self] in
            self?.handleAddPoi()
        }
        bottomToolbar.onUndo = { [weak self] in
            self?.handleUndo()
        }
        bottomToolbar.onRedo = { [weak self] in
            self?.handleRedo()
        }
        bottomToolbar.onAddRoutePoint = { [weak self] in
            self?.handleAddRoutePoint()
        }
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(bottomToolbar)
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomToolbar.heightAnchor.constraint(equalToConstant: PlanRouteButtonFactory.bottomButtonHeight)
        ])
    }

    private func setupTopToolbar() {
        topToolbar.titleText = dataProvider.mode.title
        updateTopToolbar()
        topToolbar.onClose = { [weak self] in
            self?.handleClose()
        }
        topToolbar.onSave = { [weak self] in
            self?.handleSave()
        }
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topToolbar)
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            topToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: PlanRouteTopToolbarView.contentHeight)
        ])
    }

    private func updateTopToolbar() {
        topToolbar.isSaveButtonVisible = true
        topToolbar.isSaveButtonEnabled = true
        topToolbar.optionsMenu = makeOptionsMenu()
    }

    private func updateCrosshairImage() {
        crosshairView.image = OAAppSettings.sharedManager().nightMode
            ? .mapRulerCenterNight
            : .mapRulerCenterDay
        crosshairView.isAccessibilityElement = false
    }

    private func setupCrosshair() {
        updateCrosshairImage()
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
        let bottom = routeTypeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -routeTypeButtonBottomInset(for: sheetState))
        routeTypeButtonBottomConstraint = bottom
        NSLayoutConstraint.activate([
            routeTypeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottom
        ])
        routeTypeButton.accessibilityLabel = localizedString("route_between_points")
        routeTypeButton.addTarget(self, action: #selector(onRouteTypeButtonTapped), for: .touchUpInside)
        updateRouteTypeButton()
    }

    private func routeTypeButtonBottomInset(for state: EOADraggableMenuState) -> CGFloat {
        mapControlsReservedHeight(for: state) + 12
    }

    private func updateRouteTypeButton() {
        let mode = dataProvider.defaultMode
        let icon: UIImage?
        if !dataProvider.isTrackReadyToCalculate {
            icon = .icCustomQuestionmark
        } else if let mode {
            icon = mode.getIcon()?.withRenderingMode(.alwaysTemplate)
        } else {
            icon = .icCustomStraightLine
        }
        routeTypeButton.setImage(icon, for: .normal)
        let activeColor = UIColor.mapButtonIconColorActive
        routeTypeButton.tintColorDay = activeColor.light
        routeTypeButton.tintColorNight = activeColor.dark
        routeTypeButton.updateColors(forPressedState: false)
    }

    private func presentRouteBetweenPoints() {
        presentRouteBetweenPoints(RouteBetweenPointsViewController(dataSource: dataProvider))
    }

    private func presentRouteBetweenPoints(_ listVC: RouteBetweenPointsViewController) {
        showMediumSheetViewController(viewController: listVC, isLargeAvailable: true)
        }

    private func presentSegmentReorder() {
        showMediumSheetViewController(viewController: SegmentReorderViewController(dataSource: dataProvider), isLargeAvailable: true)
        }

    private func presentPointMenuVC(point: PlanRoutePoint, group: PlanRouteProfileGroup, segment: PlanRouteSegment) {
        let menuVC = PlanRoutePointMenuViewController(point: point, segment: segment, group: group, dataSource: dataProvider)
        menuVC.onChangeRouteType = { [weak self] context, fromPointIndex, upToPointIndex in
            self?.presentSettingsForContext(context, applyFromPointIndex: fromPointIndex, applyUpToPointIndex: upToPointIndex)
        }
        showMediumToLargeSheetViewController(menuVC)
    }

    private func showPointEditingView(mode: PlanRoutePointEditMode) {
        pointEditingView?.removeFromSuperview()
        let infoType: EOABottomInfoViewType
        switch mode {
        case .move:
            infoType = .move
        case .addBefore:
            infoType = .addBefore
        case .addAfter:
            infoType = .addAfter
        }
        let infoView = OAInfoBottomView(type: infoType)
        guard let leftButton = infoView.leftButton,
              let rightButton = infoView.rightButton,
              let leftIconView = infoView.leftIconView,
              let titleView = infoView.titleView else {
            dataProvider.cancelPointEdit()
            return
        }
        infoView.frame = sheetView.bounds
        infoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        infoView.delegate = self
        infoView.headerViewText = localizedString("move_point_descr")
        leftButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
        rightButton.setTitle(localizedString("shared_string_apply"), for: .normal)
        switch mode {
        case .move:
            leftIconView.image = .icCustomChangeObjectPosition
            titleView.text = localizedString("move_point")
        case .addBefore:
            leftIconView.image = .icCustomAddPointBefore
            titleView.text = localizedString("add_point_before")
        case .addAfter:
            leftIconView.image = .icCustomAddPointAfter
            titleView.text = localizedString("add_point_after")
        }
        let targetHeight = infoView.getHeight()
        pointEditingView = infoView
        pointEditingHeight = targetHeight
        sheetView.addSubview(infoView)
        sheetView.bringSubviewToFront(infoView)
        sheetHeightConstraint?.constant = targetHeight
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: targetHeight)
        routeTypeButtonBottomConstraint?.constant = -(targetHeight + 12)
        updateCrosshairMapCenter(sheetHeight: targetHeight)
        view.layoutIfNeeded()
        refreshMapControls()
    }

    private func hidePointEditingView() {
        pointEditingView?.removeFromSuperview()
        pointEditingView = nil
        pointEditingHeight = nil
        setState(.initial, animated: true)
    }

    private func presentChangeRouteType(before pointIndex: Int) {
        let segments = dataProvider.routeSegments
        guard let (segment, group, _) = findPointContext(index: pointIndex, in: segments) else { return }
        let groupIndex = segment.groups.firstIndex(where: { $0.lastPointIndex == group.lastPointIndex }) ?? 0
        if groupIndex > 0 {
            let prevGroup = segment.groups[groupIndex - 1]
            presentSettingsForContext(.profileGroup(prevGroup, segment: segment))
        } else {
            presentSettingsForContext(.profileGroup(group, segment: segment), applyUpToPointIndex: pointIndex)
        }
    }

    private func presentChangeRouteType(after pointIndex: Int) {
        let segments = dataProvider.routeSegments
        guard let (segment, group, _) = findPointContext(index: pointIndex, in: segments) else { return }
        presentSettingsForContext(.profileGroup(group, segment: segment), applyFromPointIndex: pointIndex)
    }

    private func presentSettingsForContext(_ context: SegmentRouteContext, applyFromPointIndex: Int? = nil, applyUpToPointIndex: Int? = nil) {
        guard !presentApproximationWarningIfNeeded() else { return }
        let settingsVC = SegmentRouteSettingsViewController(context: context, dataSource: dataProvider, applyFromPointIndex: applyFromPointIndex, applyUpToPointIndex: applyUpToPointIndex)
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(nav, animated: true)
    }

    private func presentApproximationWarningIfNeeded() -> Bool {
        presentApproximationWarning(force: false)
    }

    @discardableResult
    private func presentApproximationWarning(force: Bool) -> Bool {
        if approximationNavigationController != nil { return true }
        guard (force || dataProvider.shouldShowApproximationWarning),
              let warningViewController = dataProvider.approximationWarningViewController else { return false }
        let navigationController = UINavigationController(rootViewController: warningViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.delegate = self
        navigationController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        approximationPreviousSheetState = sheetState
        approximationNavigationController = navigationController
        add(navigationController, frame: sheetView.bounds)
        sheetView.addSubview(navigationController.view)
        sheetView.bringSubviewToFront(grabberView)
        routeTypeButton.isHidden = true
        crosshairView.isHidden = true
        updateApproximationPopupHeight(warningViewController, animated: true)
        return true
    }

    private func dismissApproximationPopup() {
        guard let navigationController = approximationNavigationController else { return }
        navigationController.remove()
        approximationNavigationController = nil
        approximationHeight = nil
        sheetView.layer.cornerRadius = Self.sheetCornerRadius
        grabberView.isHidden = false
        routeTypeButton.isHidden = false
        crosshairView.isHidden = false
        let state = approximationPreviousSheetState ?? sheetState
        approximationPreviousSheetState = nil
        setState(state, animated: true)
    }

    private func updateApproximationPopupHeight(_ viewController: UIViewController, animated: Bool) {
        guard let popupViewController = viewController as? OAPlanningPopupBaseViewController else { return }
        sheetView.layoutIfNeeded()
        popupViewController.loadViewIfNeeded()
        popupViewController.view.layoutIfNeeded()
        sheetView.layer.cornerRadius = popupViewController.view.layer.cornerRadius
        let targetHeight = min(popupViewController.initialHeight(), height(for: .fullScreen))
        approximationHeight = targetHeight
        sheetHeightConstraint?.constant = targetHeight
        updateCrosshairMapCenter(sheetHeight: targetHeight)
        let updates: () -> Void = { [weak self] in
            guard let self else { return }
            view.layoutIfNeeded()
            approximationNavigationController?.view.frame = sheetView.bounds
            approximationNavigationController?.view.setNeedsLayout()
            approximationNavigationController?.view.layoutIfNeeded()
            popupViewController.view.setNeedsLayout()
            popupViewController.view.layoutIfNeeded()
            refreshMapControls()
        }
        if animated {
            UIView.animate(withDuration: Self.sheetAnimationDuration, animations: updates)
        } else {
            updates()
        }
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

    private func crosshairCenterY(sheetHeight: CGFloat, screenHeight: CGFloat? = nil) -> CGFloat {
        let targetScreenHeight = screenHeight ?? currentScreenHeight
        if sheetHeight <= height(for: .initial, screenHeight: targetScreenHeight) {
            return targetScreenHeight / 2.0
        }
        let coveredHeight: CGFloat
        if pointEditingView == nil {
            coveredHeight = min(sheetHeight, height(for: .expanded, screenHeight: targetScreenHeight))
        } else {
            coveredHeight = sheetHeight
        }
        let visibleTop = getNavbarHeight()
        let visibleBottom = targetScreenHeight - coveredHeight
        return visibleTop + (visibleBottom - visibleTop) / 2
    }

    private func updateCrosshairMapCenter(sheetHeight: CGFloat, screenSize: CGSize? = nil) {
        let targetScreenSize = screenSize ?? CGSize(width: view.bounds.width, height: currentScreenHeight)
        let centerY = crosshairCenterY(sheetHeight: sheetHeight, screenHeight: targetScreenSize.height)
        let centerX = targetScreenSize.width / 2
        guard centerX > 0, targetScreenSize.height > 0 else { return }
        let viewportYScale = Double(2 * centerY / targetScreenSize.height)
        OARootViewController.instance().mapPanel.mapViewController.setViewportScaleY(viewportYScale)
        dataProvider.setCrosshairPosition(screenPoint: CGPoint(x: centerX, y: centerY))
    }

    private func restoreMapViewport() {
        guard let cachedMapViewportYScale else { return }
        self.cachedMapViewportYScale = nil
        OARootViewController.instance().mapPanel.mapViewController.setViewportScaleY(cachedMapViewportYScale)
    }

    private func height(for state: EOADraggableMenuState, screenHeight: CGFloat? = nil) -> CGFloat {
        let targetScreenHeight = screenHeight ?? currentScreenHeight
        let collapsed = Self.sheetGrabberAreaHeight + Self.topPartViewHeight + 8 + segmentControl.intrinsicContentSize.height + 12
            + PlanRouteButtonFactory.bottomButtonHeight + 8 + OAUtilities.getBottomMargin()
        switch state {
        case .initial:
            return collapsed
        case .expanded:
            return targetScreenHeight / 2
        case .fullScreen:
            return targetScreenHeight - getNavbarHeight() - Self.fullScreenSheetTopInset
        @unknown default:
            return targetScreenHeight / 2
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
        let height = height(for: state)
        sheetHeightConstraint?.constant = height
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height)
        routeTypeButtonBottomConstraint?.constant = -routeTypeButtonBottomInset(for: state)
        updateCrosshairMapCenter(sheetHeight: height)
        let updates: () -> Void = { [weak self] in
            guard let self else { return }
            view.layoutIfNeeded()
            tabContainerView.alpha = isContentVisible(in: state) ? 1 : 0
            refreshMapControls()
        }
        if animated {
            UIView.animate(withDuration: Self.sheetAnimationDuration, animations: updates)
            crosshairView.layer.removeAnimation(forKey: "position")
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
        if velocity < -Self.sheetFlingVelocityThresholdPointsPerSecond { return .fullScreen }
        if velocity > Self.sheetFlingVelocityThresholdPointsPerSecond { return .initial }
        let candidates: [EOADraggableMenuState] = [.initial, .expanded, .fullScreen]
        return candidates.min { abs(height(for: $0) - currentHeight) < abs(height(for: $1) - currentHeight) } ?? .expanded
    }

    private func refreshMapControls() {
        let style: UIStatusBarStyle = OAAppSettings.sharedManager().nightMode ? .lightContent : .default
        OARootViewController.instance().mapPanel?.targetUpdateControlsLayout(true, customStatusBarStyle: style)
    }

    private func setMapHudStatusBarHidden(_ isHidden: Bool) {
        OARootViewController.instance()
            .mapPanel?
            .hudViewController?
            .statusBarView?
            .isHidden = isHidden
    }

    private func makeTabViewController(for tab: PlanRouteTab) -> UIViewController {
        switch tab {
        case .poi:
            return PlanRoutePoiViewController(dataSource: dataProvider)
        case .analyze:
            let analyzeViewController = PlanRouteAnalyzeViewController(dataSource: dataProvider)
            analyzeViewController.onAttachToRoadsRequested = { [weak self] in
                guard let self, dataProvider.isApproximationNeeded else { return }
                presentApproximationWarning(force: true)
            }
            return analyzeViewController
        case .route:
            let routeVC = PlanRouteRouteViewController(dataSource: dataProvider)
            routeVC.onPointSelected = { [weak self] point, _, _ in
                self?.dataProvider.showPointOptions(at: point.index)
            }
            routeVC.onChangeRouteType = { [weak self] context in
                self?.presentSettingsForContext(context)
            }
            routeVC.onSaveSegment = { [weak self] pointIndexes in
                self?.presentSegmentSaveDialog(pointIndexes: pointIndexes)
            }
            return routeVC
        }
    }

    private func selectTab(_ tab: PlanRouteTab) {
        guard tab != selectedTab || currentTabViewController == nil else { return }
        selectedTab = tab
        let newController = makeTabViewController(for: tab)
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
        let visibleActions = Set(PlanRouteMenuAction.actions(for: dataProvider.mode))
        let sections: [[PlanRouteMenuAction]] = [
            [.saveAs, .saveAsCopy, .appendToExistingTrack],
            [.changeSegmentOrder],
            [.reverseRoute],
            [.navigation],
            [.clearAllPoints]
        ]
        let children = sections.compactMap { section -> UIMenu? in
            let actions = section
                .filter { visibleActions.contains($0) }
                .map(makeMenuAction)
            guard !actions.isEmpty else { return nil }
            return UIMenu(options: .displayInline, children: actions)
        }
        return UIMenu(children: children)
    }

    private func makeMenuAction(_ action: PlanRouteMenuAction) -> UIAction {
        UIAction(title: action.title,
                 image: action.icon,
                 attributes: action.isDestructive ? .destructive : []) { [weak self] _ in
            self?.handleMenuAction(action)
        }
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
        guard ensurePointsForSaving() else { return }
        switch dataProvider.mode {
        case .newRoute:
            presentSaveDialog(duplicate: false)
        case .editTrack(let fileName):
            dataProvider.saveAs(fileName: fileName, folder: dataProvider.editTrackFolder, showOnMap: true) { [weak self] success, _ in
                guard let self else { return }
                if success {
                    let message = String(format: localizedString("gpx_saved_successfully"), fileName)
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
                    hide(true, duration: Self.sheetAnimationDuration) {
                        OARootViewController.instance().present(alert, animated: true)
                    }
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
    }

    private func handleRedo() {
        dataProvider.redo()
    }

    private func handleAddRoutePoint() {
        dataProvider.addRoutePoint()
    }

    private func handleMenuAction(_ action: PlanRouteMenuAction) {
        switch action {
        case .saveAs:
            guard ensurePointsForSaving() else { return }
            presentSaveDialog(duplicate: false)
        case .saveAsCopy:
            guard ensurePointsForSaving() else { return }
            presentSaveDialog(duplicate: true)
        case .appendToExistingTrack:
            presentAppendToTrack()
        case .changeSegmentOrder:
            presentSegmentReorder()
        case .reverseRoute:
            dataProvider.reverseRoute()
        case .navigation:
            restoreMapViewport()
            hide()
            dataProvider.enterNavigation()
        case .clearAllPoints:
            confirmClearAllPoints()
        }
    }

    private func ensurePointsForSaving() -> Bool {
        guard dataProvider.hasPoints else {
            let alert = UIAlertController(title: nil,
                                          message: localizedString("none_point_error"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
            present(alert, animated: true)
            return false
        }
        return true
    }

    private func presentSaveDialog(duplicate: Bool) {
        isPendingSaveAsCopy = duplicate
        pendingSegmentPointIndexes = nil
        guard let vc = OASaveTrackViewController(fileName: suggestedFileName, filePath: nil, showOnMap: true, simplifiedTrack: false, duplicate: duplicate) else { return }
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func presentSegmentSaveDialog(pointIndexes: [Int]) {
        pendingSegmentPointIndexes = pointIndexes
        isPendingSaveAsCopy = false
        guard let vc = OASaveTrackViewController(fileName: suggestedFileName, filePath: nil, showOnMap: true, simplifiedTrack: false, duplicate: false) else { return }
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

    @objc private func onRouteTypeButtonTapped() {
        guard !presentApproximationWarningIfNeeded() else { return }
        let segments = dataProvider.routeSegments
        let isComplex = segments.count > 1 || (segments.count == 1 && segments[0].multiMode)
        if isComplex {
            presentRouteBetweenPoints()
        } else {
            presentSettingsForContext(.wholeTrack)
        }
    }

    @objc private func onDayNightModeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateCrosshairImage()
            self?.topToolbar.updateMapTheme()
            self?.updateRouteTypeButton()
            self?.setNeedsStatusBarAppearanceUpdate()
        }
    }

    @objc private func onSegmentChanged() {
        let index = segmentControl.selectedSegmentIndex
        guard tabs.indices.contains(index) else { return }
        selectTab(tabs[index])
        if sheetState == .initial {
            setState(.expanded, animated: true)
        }
    }

    @objc private func onSegmentTapped() {
        if sheetState == .initial {
            setState(.expanded, animated: true)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard pointEditingView == nil else { return }
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
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            setState(nearestState(for: sheetHeightConstraint.constant, velocity: velocity), animated: true)
        default:
            break
        }
    }
}

extension PlanRouteScrollableViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard navigationController === approximationNavigationController else { return }
        grabberView.isHidden = viewController !== navigationController.viewControllers.first
        updateApproximationPopupHeight(viewController, animated: animated)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PlanRouteScrollableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard pointEditingView == nil, approximationNavigationController == nil else { return false }
        let location = gestureRecognizer.location(in: tabContainerView)
        return !tabContainerView.bounds.contains(location)
    }
}

extension PlanRouteScrollableViewController: OAInfoBottomViewDelegate {
    func onLeftButtonPressed() {
        dataProvider.cancelPointEdit()
        hidePointEditingView()
    }

    func onRightButtonPressed() {
        dataProvider.applyPointEdit()
        hidePointEditingView()
    }

    func onCloseButtonPressed() {
        dataProvider.cancelPointEdit()
        hidePointEditingView()
    }

    func onAddOneMorePointPressed(_ mode: EOAAddPointMode) {
        dataProvider.addAnotherPoint()
    }
}

// MARK: - OASaveTrackViewControllerDelegate
extension PlanRouteScrollableViewController: OASaveTrackViewControllerDelegate {
    func onSave(asNewTrack fileName: String, showOnMap: Bool, simplifiedTrack: Bool, openTrack: Bool) {
        let onComplete: (Bool, String?) -> Void = { [weak self] success, filePath in
            guard let self else { return }
            if success {
                let path = filePath ?? fileName
                hide(true, duration: Self.sheetAnimationDuration) {
                    let bottomSheet = OASaveTrackBottomSheetViewController(fileName: path)
                    bottomSheet?.present(in: OARootViewController.instance())
                }
            } else {
                showSaveError()
            }
        }
        if let pointIndexes = pendingSegmentPointIndexes {
            pendingSegmentPointIndexes = nil
            dataProvider.saveSegment(pointIndexes: pointIndexes, fileName: fileName, showOnMap: showOnMap, onComplete: onComplete)
        } else if isPendingSaveAsCopy {
            dataProvider.saveAsCopy(fileName: fileName, folder: nil, showOnMap: showOnMap, onComplete: onComplete)
        } else {
            dataProvider.saveAs(fileName: fileName, folder: nil, showOnMap: showOnMap, onComplete: onComplete)
        }
    }
}

// MARK: - OAOpenAddTrackDelegate
extension PlanRouteScrollableViewController: OAOpenAddTrackDelegate {
    func onFileSelected(_ gpxFilePath: String) {
        dataProvider.appendToTrack(filePath: gpxFilePath) { [weak self] success in
            guard let self else { return }
            if !success { showSaveError() }
        }
    }
}
