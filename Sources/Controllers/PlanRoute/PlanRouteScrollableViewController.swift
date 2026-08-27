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
    private static let sidePanelWidth: CGFloat = 393
    private static let sidePanelHorizontalInset: CGFloat = 16
    private static let sidePanelTopPadding: CGFloat = 8
    private static let sidePanelVerticalInset: CGFloat = 16
    private static let sidePanelTopContentInset: CGFloat = 8
    private static let mapControlsSpacing: CGFloat = 16
    private static let mapToolbarSafeAreaBottomInset: CGFloat = 16
    private static let phoneSidePanelTopInset: CGFloat = 20
    private static let phoneMapToolbarBottomInset: CGFloat = 20
    private static let phoneMapToolbarHorizontalInset: CGFloat = 20

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private let dataProvider: PlanRouteDataProvider

    private let sheetView = UIView()
    private let grabberView = UIView()
    private let topToolbar = PlanRouteTopToolbarView()
    private let bottomToolbar = PlanRouteBottomToolbarView(useMapStyle: false)
    private let mapToolbar = PlanRouteBottomToolbarView(useMapStyle: true)
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
    private weak var currentTabViewController: UIViewController?
    private var sheetState: EOADraggableMenuState
    private var selectedTab: PlanRouteTab = .default
    private var sheetHeightConstraint: NSLayoutConstraint?
    private var sheetLeftConstraint: NSLayoutConstraint?
    private var sheetTopConstraint: NSLayoutConstraint?
    private var sheetBottomConstraint: NSLayoutConstraint?
    private var bottomSheetConstraints: [NSLayoutConstraint] = []
    private var sidePanelConstraints: [NSLayoutConstraint] = []
    private var mapToolbarConstraints: [NSLayoutConstraint] = []
    private var mapToolbarBottomConstraint: NSLayoutConstraint?
    private var topPartGrabberConstraint: NSLayoutConstraint?
    private var topPartSheetConstraint: NSLayoutConstraint?
    private var topToolbarBottomSheetLeftConstraint: NSLayoutConstraint?
    private var topToolbarSidePanelLeftConstraint: NSLayoutConstraint?
    private var crosshairCenterXConstraint: NSLayoutConstraint?
    private var crosshairCenterYConstraint: NSLayoutConstraint?
    private var dayNightObserver: OAAutoObserverProxy?
    private var routeTypeButtonBottomConstraint: NSLayoutConstraint?
    private var routeTypeButtonSidePanelBottomConstraint: NSLayoutConstraint?
    private var routeTypeButtonBottomSheetLeftConstraint: NSLayoutConstraint?
    private var routeTypeButtonSidePanelLeftConstraint: NSLayoutConstraint?
    private var sheetPanRecognizer: UIPanGestureRecognizer?
    private var panStartHeight: CGFloat = 0
    private var navControllerHistory: [UIViewController] = []
    private var trackMenuState: OATrackMenuViewControllerState?
    private var isForceHiding = false
    private var isPendingSaveAsCopy = false
    private var pendingSegmentPointIndexes: [Int]?
    private var pointEditingView: OAInfoBottomView?
    private var pointEditingHeight: CGFloat?
    private var cachedMapPositionX: Int32?
    private var cachedMapTargetScreenPointRatio: CGPoint?
    private var cachedMapViewportXScale: Double?
    private var cachedMapViewportYScale: Double?
    private var approximationHeight: CGFloat?
    private var approximationPreviousSheetState: EOADraggableMenuState?
    private var approximationNavigationController: UINavigationController?
    private var usesSidePanelLayout = false
    private var hasAppliedSidePanelViewportXScale = false
    private var lastMapCenterX: CGFloat = 0
    private var lastSidePanelMapInset: CGFloat = 0
    private var lastSidePanelTopInset: CGFloat = 0
    private var lastSidePanelBottomInset: CGFloat = 0
    private var lastMapControlsReservedHeight: CGFloat = 0
    private var transitionTargetSize: CGSize?

    var mapViewportBounds: CGRect {
        let bounds = view.bounds
        if usesSidePanelLayout {
            let minX = min(bounds.maxX, bounds.minX + sidePanelMapInset)
            let maxX = max(minX, bounds.maxX - view.safeAreaInsets.right)
            return CGRect(x: minX, y: bounds.minY, width: maxX - minX, height: bounds.height)
        }
        let minY = bounds.minY + getNavbarHeight()
        let sheetHeight = height(for: sheetState)
        let maxY = max(minY, bounds.maxY - sheetHeight)
        return CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)
    }

    private var suggestedFileName: String {
        switch dataProvider.mode {
        case .newRoute: uniqueFileName(for: OAUtilities.generateCurrentDateFilename())
        case .editTrack(let fileName): fileName
        }
    }

    private var suggestedFilePath: String? {
        guard case .editTrack(let fileName) = dataProvider.mode,
              let gpxFileName = (fileName as NSString).appendingPathExtension("gpx") else { return nil }
        guard let folder = dataProvider.editTrackFolder, !folder.isEmpty else { return gpxFileName }
        return (folder as NSString).appendingPathComponent(gpxFileName)
    }

    private var currentScreenHeight: CGFloat {
        guard isViewLoaded, view.bounds.height > 0 else { return OAUtilities.calculateScreenHeight() }
        return view.bounds.height
    }

    private var sidePanelLeftInset: CGFloat {
        let horizontalInset = Self.sidePanelHorizontalInset
        return max(horizontalInset, view.safeAreaInsets.left)
    }

    private var sidePanelMapInset: CGFloat {
        let panelWidth = Self.sidePanelWidth
        return sidePanelLeftInset + panelWidth
    }

    private var isApproximationChildVisible: Bool {
        guard let navigationController = approximationNavigationController else { return false }
        return navigationController.visibleViewController !== navigationController.viewControllers.first
    }

    init(dataProvider: PlanRouteDataProvider) {
        self.dataProvider = dataProvider
        sheetState = dataProvider.mode.isNewRoute ? .initial : .expanded
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        let mapViewSize = mapViewController.view.bounds.size
        if let mapTargetScreenPoint = mapViewController.mapRendererView?.mapTargetScreenPoint,
           mapViewSize.width > 0,
           mapViewSize.height > 0 {
            cachedMapTargetScreenPointRatio = CGPoint(x: mapTargetScreenPoint.x / mapViewSize.width,
                                                      y: mapTargetScreenPoint.y / mapViewSize.height)
        }
        cachedMapPositionX = mapViewController.mapPositionX
        cachedMapViewportXScale = mapViewController.viewportXScale
        cachedMapViewportYScale = mapViewController.viewportYScale
        (view as? OAUserInteractionPassThroughView)?.isScreenClickable = true
        setupSheet()
        setupTopPart()
        setupBottomToolbar()
        setupContent()
        setupTopToolbar()
        setupRouteTypeButton()
        setupCrosshair()
        applyLayoutMode(for: view.bounds.size)
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
        applyLayoutMode(for: view.bounds.size)
        updateCrosshairImage()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let height = approximationHeight ?? pointEditingHeight ?? height(for: sheetState)
        sheetHeightConstraint?.constant = height
        tabContainerView.alpha = usesSidePanelLayout || isContentVisible(in: sheetState) ? 1 : 0
        if view.window != nil {
            view.layoutIfNeeded()
        }
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height)
        routeTypeButtonBottomConstraint?.constant = pointEditingHeight == nil
            ? -routeTypeButtonBottomInset(for: sheetState)
            : -(height + 12)
        updateCrosshair(sheetHeight: height, preserveMapPosition: true)
        if animated {
            sheetView.transform = usesSidePanelLayout
                ? CGAffineTransform(translationX: -sidePanelMapInset, y: 0)
                : CGAffineTransform(translationX: 0, y: height)
            UIView.animate(withDuration: Self.sheetAnimationDuration) {
                self.sheetView.transform = .identity
            }
        }
        refreshMapControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLayout(for: view.bounds.size)
        view.layoutIfNeeded()
        setMapHudStatusBarHidden(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setMapHudStatusBarHidden(false)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let layoutSize = transitionTargetSize ?? view.bounds.size
        let layoutGeometryChanged = applyLayoutMode(for: layoutSize)
        guard layoutGeometryChanged, view.window != nil else { return }
        view.layoutIfNeeded()
        let height = approximationHeight ?? pointEditingHeight ?? self.height(for: sheetState, screenHeight: layoutSize.height)
        updateCrosshair(sheetHeight: height,
                        screenSize: layoutSize,
                        preserveMapPosition: true)
        refreshMapControls()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        transitionTargetSize = size
        usesSidePanelLayout = shouldUseSidePanelLayout(for: size)
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.updateLayout(for: size)
        } completion: { [weak self] _ in
            guard let self else { return }
            transitionTargetSize = nil
            updateLayout(for: view.bounds.size)
        }
    }

    override func getViewHeight() -> CGFloat {
        if usesSidePanelLayout {
            let size = transitionTargetSize ?? view.bounds.size
            return sidePanelMapControlsReservedHeight(for: size)
        }
        return approximationHeight ?? pointEditingHeight ?? mapControlsReservedHeight(for: sheetState)
    }

    override func getViewHeight(_ state: EOADraggableMenuState) -> CGFloat {
        if usesSidePanelLayout {
            let size = transitionTargetSize ?? view.bounds.size
            return sidePanelMapControlsReservedHeight(for: size)
        }
        return approximationHeight ?? pointEditingHeight ?? mapControlsReservedHeight(for: state)
    }

    override func getNavbarHeight() -> CGFloat {
        OAUtilities.getStatusBarHeight() + PlanRouteTopToolbarView.contentHeight
    }

    override func getToolbarHeight() -> CGFloat {
        let bottomToolbarReservedHeight = Self.bottomToolbarReservedHeight
        return usesSidePanelLayout ? 0 : bottomToolbarReservedHeight
    }

    override func getLandscapeViewWidth() -> CGFloat {
        let layoutSize = transitionTargetSize ?? view.bounds.size
        return usesSidePanelLayout ? sidePanelMapInset : layoutSize.width
    }

    override func shouldIgnoreTopBottomOffsets() -> Bool {
        true
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
            self.sheetView.transform = self.usesSidePanelLayout
                ? CGAffineTransform(translationX: -self.sidePanelMapInset, y: 0)
                : CGAffineTransform(translationX: 0, y: height)
        }, completion: { _ in dismiss() })
    }
    
    override func isLandscape() -> Bool {
        usesSidePanelLayout
    }

    override func isLeftSidePresentation() -> Bool {
        usesSidePanelLayout
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
        mapToolbar.isUndoEnabled = dataProvider.canUndo
        mapToolbar.isRedoEnabled = dataProvider.canRedo
        updateRouteTypeButton()
        currentTabViewController.flatMap { $0 as? PlanRouteTabContent }?.reloadData()
        updateCrosshair(sheetHeight: approximationHeight ?? pointEditingHeight ?? height(for: sheetState),
                        preserveMapPosition: true)
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
        bottomSheetConstraints = [
            sheetView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightConstraint
        ]
        NSLayoutConstraint.activate(bottomSheetConstraints)

        let leftConstraint = sheetView.leftAnchor.constraint(equalTo: view.leftAnchor)
        let topConstraint = sheetView.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let panelWidth = Self.sidePanelWidth
        let widthConstraint = sheetView.widthAnchor.constraint(equalToConstant: panelWidth)
        sheetLeftConstraint = leftConstraint
        sheetTopConstraint = topConstraint
        sheetBottomConstraint = bottomConstraint
        sidePanelConstraints = [leftConstraint, topConstraint, bottomConstraint, widthConstraint]

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
        sheetPanRecognizer = panRecognizer
    }

    private func setupTopPart() {
        let topContentInset = Self.sidePanelTopContentInset
        let topPartViewHeight = Self.topPartViewHeight
        topPartView.onTap = { [weak self] in
            guard let self, !usesSidePanelLayout else { return }
            toggleState()
        }
        topPartView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(topPartView)
        let grabberConstraint = topPartView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 6)
        let sheetConstraint = topPartView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: topContentInset)
        topPartGrabberConstraint = grabberConstraint
        topPartSheetConstraint = sheetConstraint
        NSLayoutConstraint.activate([
            grabberConstraint,
            topPartView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            topPartView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            topPartView.heightAnchor.constraint(equalToConstant: topPartViewHeight)
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
        configureBottomToolbar(bottomToolbar)
        configureBottomToolbar(mapToolbar)
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(bottomToolbar)
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomToolbar.heightAnchor.constraint(equalToConstant: PlanRouteButtonFactory.bottomButtonHeight)
        ])

        mapToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(mapToolbar, belowSubview: sheetView)
        let rightConstraint = mapToolbar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        let bottomConstraint = mapToolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        mapToolbarBottomConstraint = bottomConstraint
        mapToolbarConstraints = [
            mapToolbar.leftAnchor.constraint(equalTo: sheetView.rightAnchor),
            rightConstraint,
            bottomConstraint,
            mapToolbar.heightAnchor.constraint(equalToConstant: PlanRouteButtonFactory.toolbarButtonSize)
        ]
        mapToolbar.isHidden = true
    }

    private func configureBottomToolbar(_ toolbar: PlanRouteBottomToolbarView) {
        toolbar.isUndoEnabled = dataProvider.canUndo
        toolbar.isRedoEnabled = dataProvider.canRedo
        toolbar.onAddPoi = { [weak self] in
            self?.handleAddPoi()
        }
        toolbar.onUndo = { [weak self] in
            self?.handleUndo()
        }
        toolbar.onRedo = { [weak self] in
            self?.handleRedo()
        }
        toolbar.onAddRoutePoint = { [weak self] in
            self?.handleAddRoutePoint()
        }
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
        let bottomSheetLeftConstraint = topToolbar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
        let sidePanelLeftConstraint = topToolbar.leftAnchor.constraint(equalTo: sheetView.rightAnchor)
        topToolbarBottomSheetLeftConstraint = bottomSheetLeftConstraint
        topToolbarSidePanelLeftConstraint = sidePanelLeftConstraint
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            bottomSheetLeftConstraint,
            topToolbar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            topToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: PlanRouteTopToolbarView.contentHeight)
        ])
    }

    private func updateTopToolbar() {
        topToolbar.isSaveButtonVisible = true
        topToolbar.isSaveButtonEnabled = true
        topToolbar.optionsMenu = makeOptionsMenu()
    }

    @discardableResult
    private func applyLayoutMode(for size: CGSize) -> Bool {
        let phoneMapToolbarHorizontalInset = Self.phoneMapToolbarHorizontalInset
        let sidePanelHorizontalInset = Self.sidePanelHorizontalInset
        let sidePanelLayout = shouldUseSidePanelLayout(for: size)
        usesSidePanelLayout = sidePanelLayout

        if sidePanelLayout {
            NSLayoutConstraint.deactivate(bottomSheetConstraints)
            NSLayoutConstraint.activate(sidePanelConstraints)
            NSLayoutConstraint.activate(mapToolbarConstraints)
            topPartGrabberConstraint?.isActive = false
            topPartSheetConstraint?.isActive = true
            topToolbarBottomSheetLeftConstraint?.isActive = false
            topToolbarSidePanelLeftConstraint?.isActive = true
            routeTypeButtonBottomSheetLeftConstraint?.isActive = false
            routeTypeButtonBottomConstraint?.isActive = false
            routeTypeButtonSidePanelLeftConstraint?.isActive = true
            routeTypeButtonSidePanelBottomConstraint?.isActive = true
        } else {
            NSLayoutConstraint.deactivate(sidePanelConstraints)
            NSLayoutConstraint.deactivate(mapToolbarConstraints)
            NSLayoutConstraint.activate(bottomSheetConstraints)
            topPartSheetConstraint?.isActive = false
            topPartGrabberConstraint?.isActive = true
            topToolbarSidePanelLeftConstraint?.isActive = false
            topToolbarBottomSheetLeftConstraint?.isActive = true
            routeTypeButtonSidePanelLeftConstraint?.isActive = false
            routeTypeButtonSidePanelBottomConstraint?.isActive = false
            routeTypeButtonBottomSheetLeftConstraint?.isActive = true
            routeTypeButtonBottomConstraint?.isActive = true
        }

        let panelTopInset = sidePanelLayout ? sidePanelTopInset(for: size) : 0
        let panelBottomInset = sidePanelLayout ? sidePanelBottomInset(for: size) : 0
        sheetLeftConstraint?.constant = sidePanelLeftInset
        sheetTopConstraint?.constant = panelTopInset
        sheetBottomConstraint?.constant = -panelBottomInset
        mapToolbarBottomConstraint?.constant = -mapToolbarBottomInset(for: size)
        mapToolbar.leadingContentInset = isPhoneLandscape(size)
            ? phoneMapToolbarHorizontalInset
            : sidePanelHorizontalInset
        let showsBottomCorners = sidePanelLayout && !isPhoneLandscape(size)
        sheetView.layer.maskedCorners = showsBottomCorners
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        grabberView.isHidden = sidePanelLayout || isApproximationChildVisible
        sheetPanRecognizer?.isEnabled = !sidePanelLayout
        bottomToolbar.isHidden = sidePanelLayout
        topToolbar.showsGradient = !sidePanelLayout
        tabContainerView.alpha = sidePanelLayout || isContentVisible(in: sheetState) ? 1 : 0
        updateMapToolbarVisibility()

        let centerX = mapCenterX(for: size)
        let mapInset = sidePanelLayout ? sidePanelMapInset : 0
        let mapControlsReservedHeight = sidePanelLayout
            ? sidePanelMapControlsReservedHeight(for: size)
            : 0
        let layoutGeometryChanged = abs(lastMapCenterX - centerX) > 0.5
            || abs(lastSidePanelMapInset - mapInset) > 0.5
            || abs(lastSidePanelTopInset - panelTopInset) > 0.5
            || abs(lastSidePanelBottomInset - panelBottomInset) > 0.5
            || abs(lastMapControlsReservedHeight - mapControlsReservedHeight) > 0.5
        lastMapCenterX = centerX
        lastSidePanelMapInset = mapInset
        lastSidePanelTopInset = panelTopInset
        lastSidePanelBottomInset = panelBottomInset
        lastMapControlsReservedHeight = mapControlsReservedHeight
        return layoutGeometryChanged
    }

    private func shouldUseSidePanelLayout(for size: CGSize) -> Bool {
        OAUtilities.isIPad() || OAUtilities.isiOSAppOnMac() || size.width > size.height
    }

    private func sidePanelTopInset(for size: CGSize) -> CGFloat {
        let phoneSidePanelTopInset = Self.phoneSidePanelTopInset
        let topPadding = Self.sidePanelTopPadding
        if isPhoneLandscape(size) {
            return max(phoneSidePanelTopInset, view.safeAreaInsets.top)
        }
        return view.safeAreaInsets.top + topPadding
    }

    private func sidePanelBottomInset(for size: CGSize) -> CGFloat {
        let verticalInset = Self.sidePanelVerticalInset
        guard !isPhoneLandscape(size) else { return 0 }
        return max(verticalInset, view.safeAreaInsets.bottom)
    }

    private func mapToolbarBottomInset(for size: CGSize) -> CGFloat {
        let phoneMapToolbarBottomInset = Self.phoneMapToolbarBottomInset
        let safeAreaBottomInset = Self.mapToolbarSafeAreaBottomInset
        if isPhoneLandscape(size) {
            return phoneMapToolbarBottomInset
        }
        return view.safeAreaInsets.bottom + safeAreaBottomInset
    }

    private func sidePanelMapControlsReservedHeight(for size: CGSize) -> CGFloat {
        PlanRouteButtonFactory.toolbarButtonSize + mapToolbarBottomInset(for: size)
    }

    private func isPhoneLandscape(_ size: CGSize) -> Bool {
        !OAUtilities.isIPad() && !OAUtilities.isiOSAppOnMac() && size.width > size.height
    }

    private func updateMapToolbarVisibility() {
        mapToolbar.isHidden = !usesSidePanelLayout || pointEditingView != nil || approximationNavigationController != nil
        routeTypeButton.isHidden = approximationNavigationController != nil
            || (!usesSidePanelLayout && sheetState == .fullScreen)
    }

    private func updateLayout(for size: CGSize) {
        applyLayoutMode(for: size)
        let height = approximationHeight ?? pointEditingHeight ?? self.height(for: sheetState, screenHeight: size.height)
        sheetHeightConstraint?.constant = height
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height, screenHeight: size.height)
        routeTypeButtonBottomConstraint?.constant = pointEditingHeight == nil
            ? -routeTypeButtonBottomInset(for: sheetState)
            : -(height + 12)
        updateCrosshair(sheetHeight: height, screenSize: size, preserveMapPosition: true)
        refreshMapControls()
    }

    private func updateCrosshairImage() {
        let nightMode = OAAppSettings.sharedManager().nightMode
        crosshairView.image = .mapRulerCenter
        crosshairView.tintColor = nightMode ? .iconColorBlack.dark : .iconColorBlack.light
        crosshairView.isAccessibilityElement = false
    }

    private func setupCrosshair() {
        updateCrosshairImage()
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.isUserInteractionEnabled = false
        view.insertSubview(crosshairView, belowSubview: sheetView)
        let centerX = crosshairView.centerXAnchor.constraint(equalTo: view.leftAnchor, constant: mapCenterX(for: view.bounds.size))
        let centerY = crosshairView.centerYAnchor.constraint(equalTo: view.topAnchor, constant: crosshairCenterY(sheetHeight: height(for: sheetState)))
        crosshairCenterXConstraint = centerX
        crosshairCenterYConstraint = centerY
        NSLayoutConstraint.activate([
            centerX,
            centerY
        ])
    }

    private func setupRouteTypeButton() {
        let mapControlsSpacing = Self.mapControlsSpacing
        routeTypeButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(routeTypeButton, belowSubview: sheetView)
        let bottom = routeTypeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -routeTypeButtonBottomInset(for: sheetState))
        let sidePanelBottom = routeTypeButton.bottomAnchor.constraint(equalTo: mapToolbar.topAnchor, constant: -mapControlsSpacing)
        let bottomSheetLeft = routeTypeButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16)
        let sidePanelLeft = routeTypeButton.leftAnchor.constraint(equalTo: sheetView.rightAnchor, constant: mapControlsSpacing)
        routeTypeButtonBottomConstraint = bottom
        routeTypeButtonSidePanelBottomConstraint = sidePanelBottom
        routeTypeButtonBottomSheetLeftConstraint = bottomSheetLeft
        routeTypeButtonSidePanelLeftConstraint = sidePanelLeft
        NSLayoutConstraint.activate([
            bottomSheetLeft,
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
        updateMapToolbarVisibility()
        sheetView.addSubview(infoView)
        sheetView.bringSubviewToFront(infoView)
        sheetHeightConstraint?.constant = targetHeight
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: targetHeight)
        routeTypeButtonBottomConstraint?.constant = -(targetHeight + 12)
        updateCrosshair(sheetHeight: targetHeight)
        view.layoutIfNeeded()
        refreshMapControls()
    }

    private func hidePointEditingView() {
        pointEditingView?.removeFromSuperview()
        pointEditingView = nil
        pointEditingHeight = nil
        updateMapToolbarVisibility()
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
        updateMapToolbarVisibility()
        updateApproximationPopupHeight(warningViewController, animated: true)
        return true
    }

    private func dismissApproximationPopup() {
        guard let navigationController = approximationNavigationController else { return }
        navigationController.remove()
        approximationNavigationController = nil
        approximationHeight = nil
        sheetView.layer.cornerRadius = Self.sheetCornerRadius
        grabberView.isHidden = usesSidePanelLayout
        crosshairView.isHidden = false
        updateMapToolbarVisibility()
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
        updateCrosshair(sheetHeight: targetHeight)
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

    private func mapCenterX(for screenSize: CGSize) -> CGFloat {
        if usesSidePanelLayout {
            let mapInset = min(screenSize.width, sidePanelMapInset)
            let mapMaxX = max(mapInset, screenSize.width - view.safeAreaInsets.right)
            return mapInset + (mapMaxX - mapInset) / 2
        }
        return screenSize.width / 2
    }

    private func crosshairCenterY(sheetHeight: CGFloat, screenHeight: CGFloat? = nil) -> CGFloat {
        let targetScreenHeight = screenHeight ?? currentScreenHeight
        guard !usesSidePanelLayout else { return targetScreenHeight / 2 }
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

    private func updateCrosshair(sheetHeight: CGFloat, screenSize: CGSize? = nil, preserveMapPosition: Bool = false) {
        let targetScreenSize = screenSize ?? CGSize(width: view.bounds.width, height: currentScreenHeight)
        let centerY = crosshairCenterY(sheetHeight: sheetHeight, screenHeight: targetScreenSize.height)
        let centerX = mapCenterX(for: targetScreenSize)
        guard centerX > 0, targetScreenSize.height > 0 else { return }
        let screenPoint = CGPoint(x: centerX, y: centerY)
        crosshairCenterXConstraint?.constant = centerX
        crosshairCenterYConstraint?.constant = centerY
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        if usesSidePanelLayout {
            mapViewController.viewportXScale = Double(2 * centerX / targetScreenSize.width)
            hasAppliedSidePanelViewportXScale = true
        } else if hasAppliedSidePanelViewportXScale, let cachedMapViewportXScale {
            mapViewController.viewportXScale = cachedMapViewportXScale
            hasAppliedSidePanelViewportXScale = false
        }
        mapViewController.viewportYScale = Double(2 * centerY / targetScreenSize.height)
        if preserveMapPosition {
            mapViewController.mapRendererView?.reanchorMapTarget(screenPoint)
        } else {
            mapViewController.mapRendererView?.mapTargetScreenPoint = screenPoint
        }
        dataProvider.setCrosshairPosition(screenPoint: screenPoint)
    }

    private func restoreMapViewport() {
        let mapViewController = OARootViewController.instance().mapPanel.mapViewController
        let mapViewSize = mapViewController.view.bounds.size
        hasAppliedSidePanelViewportXScale = false
        if let cachedMapPositionX {
            self.cachedMapPositionX = nil
            mapViewController.mapPositionX = cachedMapPositionX
        }
        if let cachedMapViewportXScale, let cachedMapViewportYScale {
            self.cachedMapViewportXScale = nil
            self.cachedMapViewportYScale = nil
            mapViewController.setViewportScaleX(cachedMapViewportXScale, y: cachedMapViewportYScale)
        }
        if let cachedMapTargetScreenPointRatio,
           mapViewSize.width > 0,
           mapViewSize.height > 0 {
            self.cachedMapTargetScreenPointRatio = nil
            let mapTargetScreenPoint = CGPoint(x: cachedMapTargetScreenPointRatio.x * mapViewSize.width,
                                               y: cachedMapTargetScreenPointRatio.y * mapViewSize.height)
            mapViewController.mapRendererView?.reanchorMapTarget(mapTargetScreenPoint)
        }
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
        updateMapToolbarVisibility()
        let height = height(for: state)
        sheetHeightConstraint?.constant = height
        crosshairCenterYConstraint?.constant = crosshairCenterY(sheetHeight: height)
        routeTypeButtonBottomConstraint?.constant = -routeTypeButtonBottomInset(for: state)
        updateCrosshair(sheetHeight: height)
        let updates: () -> Void = { [weak self] in
            guard let self else { return }
            view.layoutIfNeeded()
            tabContainerView.alpha = usesSidePanelLayout || isContentVisible(in: state) ? 1 : 0
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
        let fileName: String
        let folder: String?
        switch dataProvider.mode {
        case .newRoute:
            fileName = suggestedFileName
            folder = nil
        case .editTrack(let existingFileName):
            fileName = existingFileName
            folder = dataProvider.editTrackFolder
        }
        dataProvider.saveAs(fileName: fileName, folder: folder, showOnMap: true) { [weak self] success, filePath in
            self?.handleSaveResult(success: success, filePath: filePath, fallbackFileName: fileName)
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
            presentSaveDialog(saveAsCopy: false)
        case .saveAsCopy:
            guard ensurePointsForSaving() else { return }
            presentSaveDialog(saveAsCopy: true)
        case .appendToExistingTrack:
            guard ensurePointsForSaving() else { return }
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

    private func presentSaveDialog(saveAsCopy: Bool) {
        isPendingSaveAsCopy = saveAsCopy
        pendingSegmentPointIndexes = nil
        let fileName = saveAsCopy ? uniqueCopyFileName(for: suggestedFileName) : suggestedFileName
        guard let vc = OASaveTrackViewController(fileName: fileName, filePath: suggestedFilePath, showOnMap: true, simplifiedTrack: false, duplicate: false) else { return }
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func uniqueCopyFileName(for fileName: String) -> String {
        let suffixPattern = #"_\((\d+)\)$"#
        var baseName = fileName
        var index = 2
        if let suffixRange = fileName.range(of: suffixPattern, options: .regularExpression) {
            let suffix = fileName[suffixRange]
            let number = suffix.dropFirst(2).dropLast()
            if let suffixNumber = Int(number), suffixNumber < Int.max {
                baseName = String(fileName[..<suffixRange.lowerBound])
                index = max(index, suffixNumber + 1)
            }
        }

        var gpxDirectory = URL(fileURLWithPath: OsmAndApp.swiftInstance().gpxPath)
        if let folder = dataProvider.editTrackFolder, !folder.isEmpty {
            gpxDirectory.appendPathComponent(folder, isDirectory: true)
        }
        let fileManager = FileManager.default
        for _ in 0..<100_000 {
            let candidate = "\(baseName)_(\(index))"
            let candidateFile = gpxDirectory.appendingPathComponent(candidate).appendingPathExtension("gpx")
            if !fileManager.fileExists(atPath: candidateFile.path) {
                return candidate
            }
            guard index < Int.max else { break }
            index += 1
        }
        return "\(baseName)_\(UUID().uuidString)"
    }

    private func uniqueFileName(for fileName: String) -> String {
        let gpxDirectory = URL(fileURLWithPath: OsmAndApp.swiftInstance().gpxPath)
        let fileManager = FileManager.default
        let initialFile = gpxDirectory.appendingPathComponent(fileName).appendingPathExtension("gpx")
        guard fileManager.fileExists(atPath: initialFile.path) else { return fileName }

        for index in 2..<100_000 {
            let candidate = "\(fileName)_(\(index))"
            let candidateFile = gpxDirectory.appendingPathComponent(candidate).appendingPathExtension("gpx")
            if !fileManager.fileExists(atPath: candidateFile.path) {
                return candidate
            }
        }
        return fileName
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

    private func handleSaveResult(success: Bool, filePath: String?, fallbackFileName: String) {
        guard success else {
            showSaveError()
            return
        }
        let path = filePath ?? fallbackFileName
        hide(true, duration: Self.sheetAnimationDuration) {
            let bottomSheet = OASaveTrackBottomSheetViewController(fileName: path)
            bottomSheet?.present(in: OARootViewController.instance())
        }
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
        let isComplex = dataProvider.pendingEmptySegmentIndex != nil
            || segments.count > 1
            || (segments.count == 1 && segments[0].multiMode)
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
        guard !usesSidePanelLayout, pointEditingView == nil else { return }
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

    deinit {
        dayNightObserver?.detach()
    }
}

extension PlanRouteScrollableViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard navigationController === approximationNavigationController else { return }
        grabberView.isHidden = usesSidePanelLayout || viewController !== navigationController.viewControllers.first
        updateApproximationPopupHeight(viewController, animated: animated)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PlanRouteScrollableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !usesSidePanelLayout, pointEditingView == nil, approximationNavigationController == nil else { return false }
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
            self?.handleSaveResult(success: success, filePath: filePath, fallbackFileName: fileName)
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
            guard success else {
                showSaveError()
                return
            }
            let absolutePath = OAUtilities.absoluteGpxPath(forPath: gpxFilePath)
            hide(true, duration: Self.sheetAnimationDuration) {
                let bottomSheet = OASaveTrackBottomSheetViewController(fileName: absolutePath)
                bottomSheet?.present(in: OARootViewController.instance())
            }
        }
    }
}
