//
//  SkyObjectInfoBottomSheet.swift
//  OsmAnd Maps
//
//  Replaced by AstroContextMenuViewController.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import OsmAndShared
import UIKit

struct AstroContextMenuDependencies {
    let currentDate: () -> Date
    let observer: () -> Observer
    let dataProvider: AstroDataProvider?
    let preferredLocale: () -> String?
    let trackableObjects: () -> [SkyObject]
    let constellations: () -> [Constellation]
    let onClose: () -> Void
    let onDismissed: () -> Void
    let onCenterObject: (SkyObject) -> Void
    let onFavoriteChanged: (SkyObject, Bool) -> Void
    let onDirectionChanged: (SkyObject, Bool) -> Int
    let onCelestialPathChanged: (SkyObject, Bool) -> Void
    let onSetObjectPinned: (SkyObject, Bool, Bool) -> Void
    let onRefreshObjects: () -> Void
    let onCatalogClick: (Catalog) -> Void
}

final class AstroContextMenuViewController: UIViewController {
    enum Tab: Int {
        case overview
        case visibility
        case schedule
    }

    private let dependencies: AstroContextMenuDependencies
    private let visibilityController = AstroVisibilityCardController()
    private let scheduleController = AstroScheduleCardController()
    private let knowledgeBaseController = AstroKnowledgeBaseController()
    private let cardFactory = AstroContextCardFactory()
    private let metricsAdapter = MetricsAdapter()
    private let sheetHeaderView = UIView()
    private let sheetHeaderBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .close)
    private let headerType = UILabel()
    private let metricsContainer = UIView()
    private let actionsStack = UIStackView()
    private let scrollView = CancelableScrollView()
    private let contentStack = UIStackView()
    private let cardsStack = UIStackView()
    private let tabBar = UITabBar()
    private let knowledgeDownloadButtonRefreshInterval: TimeInterval = 0.5
    private let saveButton = UIButton(type: .system)
    private let locationButton = UIButton(type: .system)
    private let directionButton = UIButton(type: .system)
    private let pathButton = UIButton(type: .system)
    private let headerHeight: CGFloat = 78
    private let compactThreshold: CGFloat = 8
    private let expandThreshold: CGFloat = 2
    
    private var skyObject: SkyObject?
    private var article: AstroArticle?
    private var uiState = AstroContextUiState()
    private var cardViewsByKey: [AstroContextCardKey: UIView] = [:]
    private var selectedTab: Tab = .overview
    private var isProgrammaticTabScroll = false
    private var redFilterEnabled = false
    private var downloadTaskProgressObserver: OAAutoObserverProxy?
    private var downloadTaskCompletedObserver: OAAutoObserverProxy?
    private var localResourcesChangedObserver: OAAutoObserverProxy?
    private var latestKnowledgeDownloadProgress: Float?
    private var knowledgeDownloadProgressRenderScheduled = false
    private var lastRenderedKnowledgeDownloadButtonTitle: String?
    private var displayedKnowledgeDownloadActive = false
    private var isHeaderCompact = false

    private lazy var galleryLoader = AstroGalleryLoader(onStateChanged: { [weak self] wid, state in
        self?.onGalleryStateChanged(wid: wid, state: state)
    })
    private lazy var adapter = AstroContextMenuAdapter(
        presentingController: self,
        onDescriptionRead: { [weak self] item in self?.openDescriptionCard(item) },
        onGalleryToggle: { [weak self] wid in self?.onGalleryToggle(wid) },
        onUpdateImage: { [weak self] in
            guard let wid = self?.skyObject?.wid, !wid.isEmpty else {
                return
            }
            self?.loadGallery(wid)
        },
        onKnowledgeCardAction: { [weak self] in self?.onKnowledgeCardAction() },
        onVisibilityResetToToday: { [weak self] in self?.resetVisibilityToToday() },
        onVisibilityCursorChanged: { [weak self] referenceTimeMillis in self?.onVisibilityCursorChanged(referenceTimeMillis) },
        onScheduleResetPeriod: { [weak self] in self?.resetScheduleToCurrentPeriod() },
        onScheduleShiftPeriod: { [weak self] daysDelta in self?.shiftSchedulePeriod(daysDelta: daysDelta) },
        onScheduleSelectDate: { [weak self] date in self?.selectVisibilityDate(date) },
        onCatalogsToggleExpanded: { [weak self] in self?.toggleCatalogsExpanded() },
        onCatalogClick: { [weak self] catalog in self?.openCatalogSearch(catalog) }
    )
    private lazy var overviewTabItem = makeTabBarItem(title: localizedString("shared_string_overview"),
                                                      iconName: overviewTabIconName(for: skyObject?.type),
                                                      tag: Tab.overview.rawValue)
    private lazy var visibilityTabItem = makeTabBarItem(title: localizedString("gpx_visibility_txt"),
                                                        iconName: "ic_custom_telescope",
                                                        tag: Tab.visibility.rawValue)
    private lazy var scheduleTabItem = makeTabBarItem(title: localizedString("astronomy_schedule"),
                                                      iconName: "ic_custom_calendar_month",
                                                      tag: Tab.schedule.rawValue)
    private var isEmbeddedLeftPanel: Bool {
        navigationController?.parent is StarMapViewController
    }
    
    init(object: SkyObject, dependencies: AstroContextMenuDependencies) {
        self.skyObject = object
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        applyTheme()
        configureNavigationBar()
        bindControllerCallbacks()
        setupDownloadObservers()
        if let skyObject {
            updateObjectInfo(skyObject)
        }
        applyRedFilter(enabled: redFilterEnabled)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.sheetPresentationController?.delegate = self
        syncTabBarVisibilityWithSheetDetent(animated: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyTheme()
            cardsStack.arrangedSubviews.forEach { $0.setNeedsDisplay() }
            applyRedFilter(enabled: redFilterEnabled)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let tabBarHeight = tabBar.bounds.height > 0 ? tabBar.bounds.height : 49
        let bottomInset = tabBar.alpha > 0 ? tabBarHeight + view.safeAreaInsets.bottom + 16 : 16
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    func updateObjectInfo(_ obj: SkyObject) {
        skyObject = obj
        guard isViewLoaded else {
            return
        }
        let currentTime = dependencies.currentDate()
        let currentDate = normalizedDay(currentTime)
        let objectChanged = uiState.selectedObjectId != obj.id
        if objectChanged {
            resetOverviewStateForNewObject()
        }
        if objectChanged {
            galleryLoader.cancel()
            uiState = AstroContextUiState(selectedObjectId: obj.id,
                                          currentLocalDate: currentDate,
                                          visibilityCursorReferenceTimeMillis: millis(currentTime),
                                          schedulePeriodStart: currentDate)
        } else {
            uiState.selectedObjectId = obj.id
            uiState.currentLocalDate = currentDate
            uiState.visibilityCursorReferenceTimeMillis = uiState.visibilityCursorReferenceTimeMillis ?? millis(currentTime)
            uiState.schedulePeriodStart = uiState.schedulePeriodStart ?? currentDate
        }

        article = dependencies.dataProvider?.getAstroArticle(wikidataId: obj.wid, lang: dependencies.preferredLocale())
        setTitle(obj.niceName())
        updateOverviewTabIcon(for: obj.type)
        headerType.text = buildHeaderTypeText(obj)

        updateMetrics(obj)
        updateButtons(obj)
        updateVisibilityCard(obj)
        updateScheduleCard(obj)
        ensureKnowledgeCardPrerequisites()
        if case .loading = uiState.galleryState {
            galleryLoader.startLoading(obj.wid)
        }
        submitCards()
    }
    
    func isDisplaying(_ object: SkyObject) -> Bool {
        skyObject?.id == object.id
    }

    func applyRedFilter(enabled: Bool) {
        redFilterEnabled = enabled
        guard isViewLoaded else {
            return
        }
        AstroRedFilter.apply(enabled, to: view)
    }

    func onTimeChanged() {
        guard let obj = skyObject,
              isViewLoaded else {
            return
        }
        updateMetrics(obj, useTargetCoordinates: true)
        let currentDate = normalizedDay(dependencies.currentDate())
        let previousDate = uiState.currentLocalDate
        if previousDate == currentDate {
            return
        }

        let currentScheduleStart = uiState.schedulePeriodStart
        let shouldShiftSchedulePeriod = currentScheduleStart == nil || currentScheduleStart == previousDate
        uiState.currentLocalDate = currentDate
        uiState.schedulePeriodStart = shouldShiftSchedulePeriod ? currentDate : currentScheduleStart

        if uiState.selectedVisibilityDateOverride == nil {
            updateVisibilityCard(obj)
        }
        if shouldShiftSchedulePeriod {
            updateScheduleCard(obj, periodStartOverride: currentDate)
        }
        submitCards()
    }

    func onLocationChanged() {
        guard let obj = skyObject,
              isViewLoaded else {
            return
        }
        updateMetrics(obj)
        updateVisibilityCard(obj)
        updateScheduleCard(obj, periodStartOverride: uiState.schedulePeriodStart)
        submitCards()
    }

    private func setTabBarVisible(_ visible: Bool, animated: Bool) {
        guard isViewLoaded else {
            return
        }
        let updates = {
            self.tabBar.alpha = visible ? 1 : 0
            self.tabBar.isUserInteractionEnabled = visible
            let tabBarHeight = self.tabBar.bounds.height > 0 ? self.tabBar.bounds.height : 49
            let bottomInset = visible ? tabBarHeight + self.view.safeAreaInsets.bottom + 16 : 16
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.tabBar.invalidateIntrinsicContentSize()
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func syncTabBarVisibilityWithSheetDetent(animated: Bool) {
        let visible: Bool
        if isEmbeddedLeftPanel {
            visible = true
        } else {
            visible = navigationController?.sheetPresentationController?.selectedDetentIdentifier == .large
        }
        setTabBarVisible(visible, animated: animated)
    }

    private func setupView() {
        view.backgroundColor = .viewBg
        
        sheetHeaderBlurView.translatesAutoresizingMaskIntoConstraints = false
        sheetHeaderBlurView.clipsToBounds = true
        sheetHeaderBlurView.alpha = 0

        sheetHeaderView.addSubview(sheetHeaderBlurView)
        sheetHeaderView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .textColorPrimary
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1
        titleLabel.accessibilityTraits = .header
        sheetHeaderView.addSubview(titleLabel)

        var closeButtonConfig: UIButton.Configuration
        if #available(iOS 26.0, *) {
            closeButtonConfig = UIButton.Configuration.glass()
        } else {
            closeButtonConfig = UIButton.Configuration.plain()
        }
        closeButtonConfig.image = UIImage(systemName: "xmark")
        closeButtonConfig.baseForegroundColor = .label
        closeButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        closeButtonConfig.cornerStyle = .capsule
        closeButtonConfig.background.backgroundColor = .clear
        closeButtonConfig.background.visualEffect = UIBlurEffect(style: .systemThinMaterial)
        
        closeButton.configuration = closeButtonConfig
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .textColorPrimary
        closeButton.accessibilityLabel = localizedString("shared_string_close")
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dependencies.onClose()
        }, for: .touchUpInside)
        sheetHeaderView.addSubview(closeButton)

        headerType.translatesAutoresizingMaskIntoConstraints = false
        headerType.font = .preferredFont(forTextStyle: .subheadline)
        headerType.adjustsFontForContentSizeCategory = true
        headerType.numberOfLines = 2

        metricsContainer.translatesAutoresizingMaskIntoConstraints = false

        actionsStack.axis = .horizontal
        actionsStack.alignment = .fill
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 6
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        [saveButton, locationButton, directionButton, pathButton].forEach {
            configureActionButton($0)
            actionsStack.addArrangedSubview($0)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        view.addSubview(sheetHeaderView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(headerType)
        contentStack.setCustomSpacing(12, after: headerType)
        contentStack.addArrangedSubview(metricsContainer)
        contentStack.setCustomSpacing(11, after: metricsContainer)
        contentStack.addArrangedSubview(actionsStack)

        cardsStack.axis = .vertical
        cardsStack.spacing = 16
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(cardsStack)

        setupTabBar()
        view.addSubview(tabBar)
        tabBar.invalidateIntrinsicContentSize()
        tabBar.layoutIfNeeded()
        tabBar.alpha = 0

        NSLayoutConstraint.activate([
            sheetHeaderBlurView.leadingAnchor.constraint(equalTo: sheetHeaderView.leadingAnchor),
            sheetHeaderBlurView.trailingAnchor.constraint(equalTo: sheetHeaderView.trailingAnchor),
            sheetHeaderBlurView.topAnchor.constraint(equalTo: sheetHeaderView.topAnchor),
            sheetHeaderBlurView.bottomAnchor.constraint(equalTo: sheetHeaderView.bottomAnchor),
            
            sheetHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sheetHeaderView.heightAnchor.constraint(equalToConstant: headerHeight),

            titleLabel.leadingAnchor.constraint(equalTo: sheetHeaderView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: sheetHeaderView.topAnchor, constant: 22),

            closeButton.trailingAnchor.constraint(equalTo: sheetHeaderView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: sheetHeaderView.topAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            actionsStack.heightAnchor.constraint(equalToConstant: 74),

            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 63),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func setupTabBar() {
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.delegate = self
        tabBar.isTranslucent = true
        tabBar.setContentCompressionResistancePriority(.required, for: .vertical)
        tabBar.setContentCompressionResistancePriority(.required, for: .horizontal)
        tabBar.setItems([overviewTabItem, visibilityTabItem, scheduleTabItem], animated: false)
        tabBar.selectedItem = overviewTabItem
        tabBar.isUserInteractionEnabled = false
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = .zero
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = .zero
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        scrollView.contentInset.bottom = 16
        scrollView.verticalScrollIndicatorInsets.bottom = 16
    }

    private func applyTheme() {
        view.backgroundColor = .viewBg
        titleLabel.textColor = .textColorPrimary
        closeButton.tintColor = .textColorPrimary
        headerType.textColor = .textColorSecondary
        metricsContainer.backgroundColor = .clear
        configureTabBarAppearance()
        configureNavigationBar()
        [saveButton, locationButton, directionButton, pathButton].forEach { button in
            var config = button.configuration ?? UIButton.Configuration.filled()
            config.baseBackgroundColor = .buttonBgColorTertiary
            config.baseForegroundColor = .iconColorActive
            button.configuration = config
        }
    }

    private func configureNavigationBar() {
        title = nil
        navigationItem.title = nil
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureTabBarAppearance() {
        tabBar.tintColor = .iconColorActive
        tabBar.unselectedItemTintColor = .iconColorBlack
    }

    private func makeTabBarItem(title: String, iconName: String, tag: Int) -> UITabBarItem {
        let image = AstroIcon.template(iconName)
        let item = UITabBarItem(title: title, image: image, selectedImage: image)
        item.tag = tag
        item.accessibilityLabel = title
        return item
    }

    private func updateOverviewTabIcon(for type: SkyObjectType?) {
        let image = AstroIcon.template(overviewTabIconName(for: type))
        overviewTabItem.image = image
        overviewTabItem.selectedImage = image
    }

    private func overviewTabIconName(for type: SkyObjectType?) -> String {
        guard let type else {
            return "ic_custom_planet"
        }
        switch type {
        case .SUN, .MOON, .PLANET:
            return "ic_custom_planet"
        case .CONSTELLATION:
            return "ic_custom_constellations"
        case .STAR:
            return "ic_custom_star_shine"
        case .NEBULA:
            return "ic_custom_nebulas"
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return "ic_custom_star_clusters"
        case .GALAXY, .GALAXY_CLUSTER, .BLACK_HOLE:
            return "ic_custom_galaxy"
        }
    }

    private func configureActionButton(_ button: UIButton) {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .top
        config.imagePadding = 8
        config.baseBackgroundColor = .buttonBgColorTertiary
        config.baseForegroundColor = .buttonTextColorSecondary
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 4, bottom: 10, trailing: 4)
        config.background.cornerRadius = 16
        config.titleLineBreakMode = .byTruncatingTail
        config.imageColorTransformer = UIConfigurationColorTransformer { _ in
            .iconColorActive
        }
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .caption1)
            return outgoing
        }
        
        button.configuration = config
        button.configurationUpdateHandler = { button in
            var configuration = button.configuration ?? config
            let isOn = button.isHighlighted
            
            configuration.baseBackgroundColor = isOn ? .buttonBgColorTap : .buttonBgColorTertiary
            configuration.baseForegroundColor = isOn ? .buttonTextColorPrimary : .buttonTextColorSecondary
            
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
                isOn ? .buttonIconColorPrimary : .iconColorActive
            }
            
            button.configuration = configuration
        }
    }

    private func bindControllerCallbacks() {
        visibilityController.onDataChanged = { [weak self] in self?.submitCards() }
        scheduleController.onDataChanged = { [weak self] in self?.refreshScheduleCardOnly() }
    }

    private func buildHeaderTypeText(_ obj: SkyObject) -> String {
        let typeName = localizedString(obj.type.titleKey)
        let parentGroup: String
        if obj.type == .MOON {
            parentGroup = localizedString("astro_type_earth")
        } else if obj.type.isSunSystem() {
            parentGroup = localizedString("astro_solar_system")
        } else if obj.type == .STAR,
                  let constellation = dependencies.constellations().first(where: { constellation in
                      constellation.lines.contains { segment in segment.0 == obj.hip || segment.1 == obj.hip }
                  }) {
            parentGroup = constellation.localizedName?.isEmpty == false ? constellation.localizedName ?? constellation.name : constellation.name
        } else {
            parentGroup = localizedString("astro_deep_sky")
        }
        return "\(typeName) • \(parentGroup)"
    }

    private func updateButtons(_ obj: SkyObject) {
        bindActionButton(saveButton,
                         title: localizedString("shared_string_save"),
                         image: obj.isFavorite ? "ic_custom_bookmark" : "ic_custom_bookmark_outlined") { [weak self] in
            guard let self else { return }
            obj.isFavorite.toggle()
            dependencies.onFavoriteChanged(obj, obj.isFavorite)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(locationButton,
                         title: localizedString("astro_locate"),
                         image: "ic_custom_location_marker_outlined") { [weak self] in
            guard let self else { return }
            dependencies.onCenterObject(obj)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(directionButton,
                         title: localizedString("astro_direction"),
                         image: obj.showDirection ? "ic_custom_target_direction_on" : "ic_custom_target_direction_off") { [weak self] in
            guard let self else { return }
            obj.showDirection.toggle()
            if obj.showDirection {
                obj.colorIndex = dependencies.onDirectionChanged(obj, true)
            } else {
                _ = dependencies.onDirectionChanged(obj, false)
            }
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(pathButton,
                         title: localizedString("astro_path"),
                         image: obj.showCelestialPath ? "ic_custom_target_path_on" : "ic_custom_target_path_off") { [weak self] in
            guard let self else { return }
            obj.showCelestialPath.toggle()
            dependencies.onCelestialPathChanged(obj, obj.showCelestialPath)
            dependencies.onSetObjectPinned(obj, obj.showCelestialPath, true)
            bindActionButtonsForCurrentObject()
        }
    }

    private func bindActionButtonsForCurrentObject() {
        guard let skyObject else {
            return
        }
        updateButtons(skyObject)
    }

    private func bindActionButton(_ button: UIButton, title: String, image: String, action: @escaping () -> Void) {
        var config = button.configuration ?? UIButton.Configuration.filled()
        config.title = title
        config.image = actionButtonImage(named: image)
        button.configuration = config
        let identifier = UIAction.Identifier("astro.context.action")
        button.removeAction(identifiedBy: identifier, for: .touchUpInside)
        button.addAction(UIAction(identifier: identifier) { _ in action() }, for: .touchUpInside)
    }

    private func actionButtonImage(named imageName: String) -> UIImage? {
        return AstroIcon.template(imageName)
    }

    private func updateMetrics(_ obj: SkyObject, useTargetCoordinates: Bool = false) {
        if !useTargetCoordinates {
            _ = AstroUtils.horizontalPosition(for: obj,
                                              time: AstroUtils.astronomyTime(from: dependencies.currentDate()),
                                              observer: dependencies.observer())
        }
        let azimuth = useTargetCoordinates ? obj.targetAzimuth : obj.azimuth
        let altitude = useTargetCoordinates ? obj.targetAltitude : obj.altitude
        var metrics: [MetricsAdapter.MetricUi] = [
            MetricsAdapter.MetricUi(value: String(format: "%.1f°", azimuth),
                                    label: localizedString("shared_string_azimuth")),
            MetricsAdapter.MetricUi(value: String(format: "%.1f°", altitude),
                                    label: localizedString("altitude")),
            MetricsAdapter.MetricUi(value: String(format: "%.2f", obj.magnitude),
                                    label: localizedString("shared_string_magnitude"))
        ]
        
        if let distanceMetric = makeDistanceMetric(for: obj) {
            metrics.append(distanceMetric)
        }

        let currentDate = dependencies.currentDate()
        let startLocal = noon(on: normalizedDay(currentDate))
        let endLocal = startLocal.addingTimeInterval(24 * 60 * 60)
        let riseSet = AstroUtils.nextRiseSet(object: obj,
                                             startSearch: startLocal,
                                             observer: dependencies.observer(),
                                             windowStart: startLocal,
                                             windowEnd: endLocal)
        let formatter = createUiTimeFormatter()
        if let rise = riseSet.rise {
            metrics.append(MetricsAdapter.MetricUi(value: formatter.string(from: rise),
                                                   label: localizedString("astro_rise")))
        }
        if let set = riseSet.set {
            metrics.append(MetricsAdapter.MetricUi(value: formatter.string(from: set),
                                                   label: localizedString("astro_set")))
        }

        metricsAdapter.submit(metrics)
        metricsContainer.subviews.forEach { $0.removeFromSuperview() }
        let metricsView = metricsAdapter.makeMetricsView()
        metricsView.translatesAutoresizingMaskIntoConstraints = false
        metricsContainer.addSubview(metricsView)
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            metricsView.topAnchor.constraint(equalTo: metricsContainer.topAnchor),
            metricsView.bottomAnchor.constraint(equalTo: metricsContainer.bottomAnchor)
        ])
    }
    
    private func makeDistanceMetric(for obj: SkyObject) -> MetricsAdapter.MetricUi? {
        if obj.type.isSunSystem() {
            guard obj.distAu > 0 else { return nil }
            return MetricsAdapter.MetricUi(
                value: String(format: "%.3f AU", obj.distAu),
                label: localizedString("shared_string_distance")
            )
        }

        guard let lightYears = obj.distance, lightYears > 0 else { return nil }

        let value = lightYears >= 100
            ? String(format: "%.0f ly", lightYears)
            : String(format: "%.1f ly", lightYears)

        return MetricsAdapter.MetricUi(
            value: value,
            label: localizedString("shared_string_distance")
        )
    }

    private func updateVisibilityCard(_ obj: SkyObject) {
        let currentTime = dependencies.currentDate()
        let graphDate = uiState.selectedVisibilityDateOverride ?? normalizedDay(currentTime)
        let isTodayVisibility = normalizedDay(graphDate) == normalizedDay(currentTime)
        let cursorReferenceTimeMillis = uiState.visibilityCursorReferenceTimeMillis ?? millis(currentTime)
        visibilityController.update(skyObject: obj,
                                    observer: dependencies.observer(),
                                    date: graphDate,
                                    timeZone: .current,
                                    cursorReferenceTimeMillis: cursorReferenceTimeMillis,
                                    isTodayVisibility: isTodayVisibility)
    }

    private func onVisibilityCursorChanged(_ referenceTimeMillis: Int64) {
        uiState.visibilityCursorReferenceTimeMillis = referenceTimeMillis
    }

    private func updateScheduleCard(_ obj: SkyObject, periodStartOverride: Date? = nil) {
        let currentTime = dependencies.currentDate()
        let defaultStartDate = normalizedDay(currentTime)
        let periodStart = periodStartOverride ?? uiState.schedulePeriodStart ?? scheduleController.periodStart
        uiState.schedulePeriodStart = periodStart
        uiState.currentLocalDate = defaultStartDate
        scheduleController.update(skyObject: obj,
                                  observer: dependencies.observer(),
                                  periodStart: periodStart,
                                  timeZone: .current,
                                  showResetPeriodButton: normalizedDay(periodStart) != defaultStartDate)
    }

    private func shiftSchedulePeriod(daysDelta: Int) {
        guard let obj = skyObject else {
            return
        }
        let currentStart = uiState.schedulePeriodStart ?? scheduleController.periodStart
        let nextStart = Calendar.current.date(byAdding: .day, value: daysDelta, to: currentStart) ?? currentStart
        updateScheduleCard(obj, periodStartOverride: nextStart)
        refreshScheduleCardOnly()
    }

    private func resetScheduleToCurrentPeriod() {
        guard let obj = skyObject else {
            return
        }
        updateScheduleCard(obj, periodStartOverride: normalizedDay(dependencies.currentDate()))
        refreshScheduleCardOnly()
    }
    
    private func refreshScheduleCardOnly() {
        guard isViewLoaded,
              let item = scheduleController.buildItem(),
              let oldView = cardViewsByKey[.schedule],
              let stackIndex = cardsStack.arrangedSubviews.firstIndex(of: oldView) else {
            return
        }

        if let index = adapter.currentList.firstIndex(where: { $0.key == .schedule }) {
            var list = adapter.currentList
            list[index] = item
            adapter.submitItems(list)
        }

        let newView = adapter.makeScheduleCardView(item: item)
        cardsStack.insertArrangedSubview(newView, at: stackIndex)
        cardsStack.removeArrangedSubview(oldView)
        oldView.removeFromSuperview()
        cardViewsByKey[.schedule] = newView
    }

    private func selectVisibilityDate(_ date: Date) {
        let currentDate = normalizedDay(dependencies.currentDate())
        uiState.selectedVisibilityDateOverride = normalizedDay(date) == currentDate ? nil : normalizedDay(date)
        if let skyObject {
            updateVisibilityCard(skyObject)
        }
        submitCards()
        selectTab(.visibility, scrollToSection: true)
    }

    private func resetVisibilityToToday() {
        guard uiState.selectedVisibilityDateOverride != nil else {
            return
        }
        uiState.selectedVisibilityDateOverride = nil
        if let skyObject {
            updateVisibilityCard(skyObject)
        }
        submitCards()
    }

    private func submitCards() {
        let items = cardFactory.buildCards(skyObject: skyObject,
                                           article: article,
                                           uiState: uiState,
                                           knowledgeItem: buildKnowledgeCardItem(),
                                           visibilityItem: visibilityController.buildItem(),
                                           scheduleItem: scheduleController.buildItem())
        adapter.submitItems(items)
        rebuildCardsStack()
    }

    private func rebuildCardsStack() {
        cardsStack.arrangedSubviews.forEach {
            cardsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        cardViewsByKey.removeAll()
        let views = adapter.makeCardViews()
        for (index, view) in views.enumerated() {
            if adapter.currentList.indices.contains(index) {
                cardViewsByKey[adapter.currentList[index].key] = view
            }
            cardsStack.addArrangedSubview(view)
        }
        syncDisplayedKnowledgeCardState()
        updateSelectedTabControls()
    }

    private func syncDisplayedKnowledgeCardState() {
        let item = adapter.currentList.compactMap { $0 as? AstroKnowledgeCardItem }.first
        displayedKnowledgeDownloadActive = item?.isDownloading == true
        lastRenderedKnowledgeDownloadButtonTitle = item?.buttonTitle
    }

    private func toggleCatalogsExpanded() {
        uiState.catalogsExpanded.toggle()
        submitCards()
    }

    private func onGalleryToggle(_ wid: String) {
        switch uiState.galleryState {
        case .collapsed:
            loadGallery(wid)
        case .ready:
            uiState.galleryState = .collapsed
            submitCards()
        case .loading:
            break
        }
    }

    private func loadGallery(_ wid: String) {
        guard !wid.isEmpty else {
            uiState.galleryState = .ready([])
            submitCards()
            return
        }
        uiState.galleryState = .loading
        submitCards()
        galleryLoader.startLoading(wid)
    }

    private func onGalleryStateChanged(wid: String, state: AstroGalleryState) {
        guard skyObject?.wid == wid else {
            return
        }
        uiState.galleryState = state
        submitCards()
    }

    private func openDescriptionCard(_ item: AstroDescriptionCardItem) {
        if item.hasOfflineArticle, showOfflineArticle() {
            return
        }
        if let uri = item.readMoreUri {
            UIApplication.shared.open(uri)
        }
    }

    private func showOfflineArticle() -> Bool {
        guard let article,
              article.hasOfflineContent(),
              let mobileHtml = article.getMobileHtmlString() else {
            return false
        }
        let body = extractBody(from: mobileHtml)
        let locale = article.lang == "en" ? "" : article.lang
        let onlineURL = article.getOnlineArticleUrl().flatMap { URL(string: $0) }
        let vc = OAWikiWebViewController(
            astroWikiHtml: body,
            title: article.title,
            locale: locale,
            onlineURL: onlineURL
        )
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .fullScreen
        
        navigationController?.present(navController, animated: true)
        return true
    }
    
    private func extractBody(from html: String) -> String {
        let bodyContentRegex = try? NSRegularExpression(
            pattern: "<body[^>]*>([\\s\\S]*?)</body>",
            options: [.caseInsensitive]
        )
        guard let regex = bodyContentRegex else { return html }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1,
              let bodyRange = Range(match.range(at: 1), in: html) else {
            return html
        }
        return String(html[bodyRange])
    }

    private func buildKnowledgeCardItem() -> AstroKnowledgeCardItem? {
        knowledgeBaseController.buildCardItem()
    }

    private func ensureKnowledgeCardPrerequisites() {
        if knowledgeBaseController.currentState() == .download {
            knowledgeBaseController.ensureIndexesLoaded()
        }
    }

    private func onKnowledgeCardAction() {
        switch knowledgeBaseController.currentState() {
        case .upsell:
            if let navigation = navigationController ?? OARootViewController.instance().navigationController {
                OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.astronomy(), navController: navigation)
            }
        case .download:
            guard let item = knowledgeBaseController.findDownloadItem() else {
                knowledgeBaseController.ensureIndexesLoaded()
                OAResourcesUISwiftHelper.prepareResourcesData()
                guard let item = knowledgeBaseController.findDownloadItem() else {
                    OAUtilities.showToast(localizedString("no_index_file_to_download"),
                                          details: nil,
                                          duration: 4,
                                          in: view)
                    submitCards()
                    return
                }
                startKnowledgeBaseDownload(item)
                return
            }
            if knowledgeBaseController.findActiveDownload(resourceItem: item) != nil {
                cancelKnowledgeBaseDownload(item)
            } else {
                startKnowledgeBaseDownload(item)
            }
        case nil:
            break
        }
    }

    private func startKnowledgeBaseDownload(_ item: OAResourceSwiftItem) {
        item.refreshDownloadTask()
        if item.isOutdatedItem() {
            OAResourcesUISwiftHelper.offerDownloadAndUpdate(of: item, onTaskCreated: { [weak self] task in
                self?.onKnowledgeDownloadTaskStarted(task)
            }, onTaskResumed: { [weak self] task in
                self?.onKnowledgeDownloadTaskStarted(task)
            })
        } else {
            OAResourcesUISwiftHelper.offerDownloadAndInstall(of: item, onTaskCreated: { [weak self] task in
                self?.onKnowledgeDownloadTaskStarted(task)
            }, onTaskResumed: { [weak self] task in
                self?.onKnowledgeDownloadTaskStarted(task)
            }, completionHandler: { [weak self] alert in
                self?.presentKnowledgeDownloadAlert(alert)
            })
        }
    }

    private func onKnowledgeDownloadTaskStarted(_ task: OADownloadTask?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            latestKnowledgeDownloadProgress = task?.progressCompleted
            guard !displayedKnowledgeDownloadActive else {
                scheduleKnowledgeDownloadProgressRender()
                return
            }
            submitCards()
        }
    }

    private func cancelKnowledgeBaseDownload(_ item: OAResourceSwiftItem) {
        guard let task = knowledgeBaseController.findActiveDownload(resourceItem: item) else {
            submitCards()
            return
        }
        let rawTitle = item.title() ?? ""
        let itemTitle = rawTitle.isEmpty ? localizedString("astronomy_map") : rawTitle
        let message = [
            String(format: localizedString("res_cancel_inst_q"), itemTitle),
            localizedString("data_will_be_lost"),
            localizedString("proceed_q")
        ].joined(separator: " ")
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_no"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_yes"), style: .default) { [weak self] _ in
            task.stop()
            DispatchQueue.main.async { [weak self] in
                self?.latestKnowledgeDownloadProgress = nil
                self?.knowledgeDownloadProgressRenderScheduled = false
                self?.submitCards()
            }
        })
        presentKnowledgeDownloadAlert(alert)
    }

    private func presentKnowledgeDownloadAlert(_ alert: UIAlertController?) {
        guard let alert else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.isViewLoaded,
                  self.view.window != nil else {
                return
            }
            self.present(alert, animated: true)
        }
    }

    private func setupDownloadObservers() {
        guard let app = OsmAndApp.swiftInstance() else {
            return
        }
        downloadTaskProgressObserver = OAAutoObserverProxy(self,
                                                           withHandler: #selector(onKnowledgeDownloadTaskProgressChanged),
                                                           andObserve: app.downloadsManager.progressCompletedObservable)
        downloadTaskCompletedObserver = OAAutoObserverProxy(self,
                                                            withHandler: #selector(onKnowledgeDownloadTaskFinished),
                                                            andObserve: app.downloadsManager.completedObservable)
        localResourcesChangedObserver = OAAutoObserverProxy(self,
                                                            withHandler: #selector(onLocalResourcesChanged),
                                                            andObserve: app.localResourcesChangedObservable)
    }

    private func detachDownloadObservers() {
        downloadTaskProgressObserver?.detach()
        downloadTaskProgressObserver = nil
        downloadTaskCompletedObserver?.detach()
        downloadTaskCompletedObserver = nil
        localResourcesChangedObserver?.detach()
        localResourcesChangedObserver = nil
    }

    @objc private func onKnowledgeDownloadTaskProgressChanged(observer: Any, key: Any, value: Any) {
        guard isKnowledgeDownloadNotification(key: key),
              let progress = knowledgeDownloadProgressValue(from: value) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.latestKnowledgeDownloadProgress = progress
            self?.scheduleKnowledgeDownloadProgressRender()
        }
    }

    @objc private func onKnowledgeDownloadTaskFinished(observer: Any, key: Any, value: Any) {
        guard isKnowledgeDownloadNotification(key: key) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onKnowledgeBaseResourceChanged()
        }
    }

    @objc private func onLocalResourcesChanged(observer: Any, key: Any, value: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.isViewLoaded,
                  self.view.window != nil else {
                return
            }
            self.onKnowledgeBaseResourceChanged()
        }
    }

    private func isKnowledgeDownloadNotification(key: Any) -> Bool {
        guard let task = key as? OADownloadTask,
              let taskKey = task.key else {
            return false
        }
        return taskKey == AstroKnowledgeBaseController.resourceTaskKey
    }

    private func onKnowledgeBaseResourceChanged() {
        latestKnowledgeDownloadProgress = nil
        knowledgeDownloadProgressRenderScheduled = false
        OAResourcesUISwiftHelper.onDownldedResourceInstalled()
        if knowledgeBaseController.isDownloaded() {
            knowledgeBaseController.resetIndexesReloadFlag()
            (OAPluginsHelper.getPlugin(AstronomyPlugin.self) as? AstronomyPlugin)?.clearCachedData()
            dependencies.onRefreshObjects()
            if let skyObject {
                article = dependencies.dataProvider?.getAstroArticle(wikidataId: skyObject.wid, lang: dependencies.preferredLocale())
            }
        }
        submitCards()
    }

    private func knowledgeDownloadProgressValue(from value: Any) -> Float? {
        if let number = value as? NSNumber {
            return number.floatValue
        }
        if let progress = value as? Float {
            return progress
        }
        if let progress = value as? Double {
            return Float(progress)
        }
        return nil
    }

    private func scheduleKnowledgeDownloadProgressRender() {
        guard isViewLoaded,
              view.window != nil else {
            return
        }
        guard !knowledgeDownloadProgressRenderScheduled else {
            return
        }
        knowledgeDownloadProgressRenderScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + knowledgeDownloadButtonRefreshInterval) { [weak self] in
            guard let self else {
                return
            }
            knowledgeDownloadProgressRenderScheduled = false
            updateKnowledgeDownloadButton(progressOverride: latestKnowledgeDownloadProgress)
        }
    }

    private func updateKnowledgeDownloadButton(progressOverride: Float? = nil) {
        guard let knowledgeView = cardViewsByKey[.knowledge] as? AstroKnowledgeCardView,
              let item = knowledgeBaseController.buildCardItem(progressOverride: progressOverride),
              lastRenderedKnowledgeDownloadButtonTitle != item.buttonTitle else {
            return
        }
        lastRenderedKnowledgeDownloadButtonTitle = item.buttonTitle
        knowledgeView.update(item: item)
    }
    
    private func updateHeaderCompactState(scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        let shouldCompact: Bool
        if isHeaderCompact {
            shouldCompact = y > expandThreshold
        } else {
            shouldCompact = y > compactThreshold
        }
        guard shouldCompact != isHeaderCompact else { return }
        isHeaderCompact = shouldCompact
        animateHeader(toCompact: shouldCompact)
    }
    
    private func animateHeader(toCompact compact: Bool) {
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.sheetHeaderBlurView.alpha = compact ? 1 : 0
            
            let scale: CGFloat = compact ? (28 / 34) : (34 / 28)
            self.applyTitleScale(scale)
            
            self.view.layoutIfNeeded()
        } completion: { isFinished in
            guard isFinished else { return }
            self.titleLabel.transform = .identity
            self.titleLabel.font = compact
            ? UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
            : UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        }
    }
    
    private func applyTitleScale(_ scale: CGFloat) {
        let width = titleLabel.bounds.width
        let height = titleLabel.bounds.height
        guard width > 0 else { return }
        
        let offsetX = width * (1 - scale) / 2
        let offsetY = height * (1 - scale) / 2
        titleLabel.transform = CGAffineTransform(translationX: -offsetX, y: -offsetY).scaledBy(x: scale, y: scale)
    }

    private func openCatalogSearch(_ catalog: Catalog) {
        dependencies.onCatalogClick(catalog)
    }

    private func selectTab(_ tab: Tab, scrollToSection: Bool) {
        selectedTab = tab
        updateSelectedTabControls()
        if scrollToSection {
            scrollToTab(tab, animated: true)
        }
    }

    private func scrollToTab(_ tab: Tab, animated: Bool = true) {
        isProgrammaticTabScroll = animated
        guard tab != .overview else {
            setScrollViewContentOffset(.zero, animated: animated)
            return
        }
        let key: AstroContextCardKey?
        switch tab {
        case .overview:
            key = nil
        case .visibility:
            key = .visibility
        case .schedule:
            key = .schedule
        }
        guard let key,
              let target = cardViewsByKey[key] else {
            isProgrammaticTabScroll = false
            return
        }
        let targetFrame = target.convert(target.bounds, to: scrollView)
        let maxOffsetY = max(0, scrollView.contentSize.height
                             + scrollView.adjustedContentInset.bottom
                             - scrollView.bounds.height)
        let targetY = min(maxOffsetY, max(0, targetFrame.minY - 8))
        setScrollViewContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
    }

    private func setScrollViewContentOffset(_ offset: CGPoint, animated: Bool) {
        guard abs(scrollView.contentOffset.y - offset.y) > 0.5 else {
            isProgrammaticTabScroll = false
            return
        }
        scrollView.setContentOffset(offset, animated: animated)
        if !animated {
            isProgrammaticTabScroll = false
        }
    }

    private func updateSelectedTabControls() {
        let item = tabItem(for: selectedTab)
        guard tabBar.selectedItem?.tag != item.tag else {
            return
        }
        UIView.performWithoutAnimation {
            tabBar.selectedItem = item
        }
    }

    private func tabItem(for tab: Tab) -> UITabBarItem {
        switch tab {
        case .overview:
            return overviewTabItem
        case .visibility:
            return visibilityTabItem
        case .schedule:
            return scheduleTabItem
        }
    }

    private func resetOverviewStateForNewObject() {
        selectedTab = .overview
        updateSelectedTabControls()
        scrollView.setContentOffset(.zero, animated: false)
        uiState.catalogsExpanded = false
        uiState.galleryState = .collapsed
    }

    private func setTitle(_ name: String) {
        title = nil
        navigationItem.title = nil
        titleLabel.text = name
    }

    private func createUiTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    private func normalizedDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func noon(on date: Date) -> Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date.addingTimeInterval(12 * 60 * 60)
    }

    private func millis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    deinit {
        detachDownloadObservers()
        galleryLoader.cancel()
        visibilityController.cancelPendingWork()
        scheduleController.cancelPendingWork()
    }
}

// MARK: - UISheetPresentationControllerDelegate

extension AstroContextMenuViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        guard sheetPresentationController === navigationController?.sheetPresentationController else {
            return
        }
        setTabBarVisible(sheetPresentationController.selectedDetentIdentifier == .large, animated: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dependencies.onDismissed()
    }
}

// MARK: - UIScrollViewDelegate

extension AstroContextMenuViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderCompactState(scrollView: scrollView)
        
        guard !isProgrammaticTabScroll,
              scrollView.isDragging || scrollView.isDecelerating else {
            return
        }
        let y = scrollView.contentOffset.y + 16
        let visibilityY = cardViewsByKey[.visibility].map { $0.convert($0.bounds, to: scrollView).minY }
        let scheduleY = cardViewsByKey[.schedule].map { $0.convert($0.bounds, to: scrollView).minY }
        let nextTab: Tab
        if let scheduleY, y >= scheduleY - scrollView.bounds.height / 3 {
            nextTab = .schedule
        } else if let visibilityY, y >= visibilityY - 24 {
            nextTab = .visibility
        } else {
            nextTab = .overview
        }
        if nextTab != selectedTab {
            selectedTab = nextTab
            updateSelectedTabControls()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isProgrammaticTabScroll = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticTabScroll = false
        updateSelectedTabControls()
    }
}

// MARK: - UITabBarDelegate

extension AstroContextMenuViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tab = Tab(rawValue: item.tag) else {
            return
        }
        selectTab(tab, scrollToSection: true)
    }
}
