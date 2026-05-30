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

final class AstroContextMenuViewController: UIViewController, UIScrollViewDelegate, UITabBarDelegate, UISheetPresentationControllerDelegate {
    enum Tab: Int {
        case overview = 0
        case visibility = 1
        case schedule = 2
    }

    private let dependencies: AstroContextMenuDependencies
    private var skyObject: SkyObject?
    private var article: AstroArticle?
    private var uiState = AstroContextUiState()

    private let visibilityController = AstroVisibilityCardController()
    private let scheduleController = AstroScheduleCardController()
    private let knowledgeBaseController = AstroKnowledgeBaseController()
    private let cardFactory = AstroContextCardFactory()
    private let metricsAdapter = MetricsAdapter()
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

    private let headerType = UILabel()
    private let metricsContainer = UIView()
    private let actionsStack = UIStackView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let cardsStack = UIStackView()
    private let tabBarContainer = UIView()
    private let tabBar = UITabBar()
    private lazy var overviewTabItem = makeTabBarItem(title: localizedString("shared_string_overview"),
                                                      iconName: overviewTabIconName(for: skyObject?.type),
                                                      tag: Tab.overview.rawValue)
    private lazy var visibilityTabItem = makeTabBarItem(title: localizedString("gpx_visibility_txt"),
                                                        iconName: "ic_action_telescope_colored",
                                                        tag: Tab.visibility.rawValue)
    private lazy var scheduleTabItem = makeTabBarItem(title: localizedString("astronomy_schedule"),
                                                      iconName: "ic_action_date_start",
                                                      tag: Tab.schedule.rawValue)
    private var cardViewsByKey: [AstroContextCardKey: UIView] = [:]
    private var selectedTab: Tab = .overview
    private var isProgrammaticTabScroll = false

    private let saveButton = UIButton(type: .system)
    private let locationButton = UIButton(type: .system)
    private let directionButton = UIButton(type: .system)
    private let pathButton = UIButton(type: .system)

    init(object: SkyObject, dependencies: AstroContextMenuDependencies) {
        self.skyObject = object
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        galleryLoader.cancel()
        visibilityController.cancelPendingWork()
        scheduleController.cancelPendingWork()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        applyTheme()
        configureNavigationBar()
        bindControllerCallbacks()
        if let skyObject {
            updateObjectInfo(skyObject)
        }
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
        }
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
            self.tabBarContainer.alpha = visible ? 1 : 0
            self.tabBarContainer.isUserInteractionEnabled = visible
            self.scrollView.contentInset.bottom = visible ? 96 : 16
            self.scrollView.verticalScrollIndicatorInsets.bottom = visible ? 96 : 16
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: updates)
        } else {
            updates()
        }
    }

    private func syncTabBarVisibilityWithSheetDetent(animated: Bool) {
        setTabBarVisible(navigationController?.sheetPresentationController?.selectedDetentIdentifier == .large,
                         animated: animated)
    }

    private func setupView() {
        view.backgroundColor = AstroContextMenuTheme.pageBackground

        headerType.translatesAutoresizingMaskIntoConstraints = false
        headerType.font = .systemFont(ofSize: 17)
        headerType.numberOfLines = 2

        metricsContainer.translatesAutoresizingMaskIntoConstraints = false

        actionsStack.axis = .horizontal
        actionsStack.alignment = .fill
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 8
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

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(headerType)
        contentStack.addArrangedSubview(metricsContainer)
        contentStack.addArrangedSubview(actionsStack)

        cardsStack.axis = .vertical
        cardsStack.spacing = 12
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(cardsStack)

        setupTabBar()
        view.addSubview(tabBarContainer)
        tabBarContainer.addSubview(tabBar)

        NSLayoutConstraint.activate([
            metricsContainer.heightAnchor.constraint(equalToConstant: 62),
            actionsStack.heightAnchor.constraint(equalToConstant: 66),

            tabBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarContainer.topAnchor.constraint(equalTo: tabBar.topAnchor),

            tabBar.leadingAnchor.constraint(equalTo: tabBarContainer.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: tabBarContainer.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func setupTabBar() {
        tabBarContainer.translatesAutoresizingMaskIntoConstraints = false
        tabBarContainer.backgroundColor = .clear
        tabBarContainer.isOpaque = false
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.delegate = self
        tabBar.isTranslucent = true
        tabBar.isOpaque = false
        tabBar.setContentCompressionResistancePriority(.required, for: .vertical)
        tabBar.items = [overviewTabItem, visibilityTabItem, scheduleTabItem]
        tabBar.selectedItem = overviewTabItem
        tabBarContainer.alpha = 0
        tabBarContainer.isUserInteractionEnabled = false
        scrollView.contentInset.bottom = 16
        scrollView.verticalScrollIndicatorInsets.bottom = 16
    }

    private func applyTheme() {
        view.backgroundColor = AstroContextMenuTheme.pageBackground
        headerType.textColor = AstroContextMenuTheme.secondaryText
        metricsContainer.backgroundColor = .clear
        configureTabBarAppearance()
        configureNavigationBar()
        [saveButton, locationButton, directionButton, pathButton].forEach { button in
            var config = button.configuration ?? UIButton.Configuration.filled()
            config.baseBackgroundColor = AstroContextMenuTheme.actionBackground
            config.baseForegroundColor = AstroContextMenuTheme.activeIcon
            button.configuration = config
        }
    }

    private func configureNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: AstroIcon.template("ic_action_close"),
                                                            primaryAction: UIAction { [weak self] _ in
                                                                self?.dependencies.onClose()
                                                            },
                                                            menu: nil)
        navigationController?.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.foregroundColor: AstroContextMenuTheme.primaryText]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = AstroContextMenuTheme.activeIcon
    }

    private func configureTabBarAppearance() {
        tabBar.tintColor = AstroContextMenuTheme.activeIcon
        tabBar.unselectedItemTintColor = AstroContextMenuTheme.secondaryIcon
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
            return "ic_action_planet_outlined"
        }
        switch type {
        case .SUN, .MOON, .PLANET:
            return "ic_action_planet_outlined"
        case .CONSTELLATION:
            return "ic_action_constellations"
        case .STAR:
            return "ic_action_stars"
        case .NEBULA:
            return "ic_action_nebulas"
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return "ic_action_star_clusters"
        case .GALAXY, .GALAXY_CLUSTER, .BLACK_HOLE:
            return "ic_action_galaxy"
        }
    }

    private func configureActionButton(_ button: UIButton) {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .top
        config.imagePadding = 3
        config.baseBackgroundColor = AstroContextMenuTheme.actionBackground
        config.baseForegroundColor = AstroContextMenuTheme.activeIcon
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 7, trailing: 4)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .regular)
            return outgoing
        }
        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.65
    }

    private func bindControllerCallbacks() {
        visibilityController.onDataChanged = { [weak self] in self?.submitCards() }
        scheduleController.onDataChanged = { [weak self] in self?.submitCards() }
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
                         image: obj.isFavorite ? "ic_action_bookmark_filled" : "ic_action_bookmark") { [weak self] in
            guard let self else { return }
            obj.isFavorite.toggle()
            dependencies.onFavoriteChanged(obj, obj.isFavorite)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(locationButton,
                         title: localizedString("astro_locate"),
                         image: "ic_action_location_16") { [weak self] in
            guard let self else { return }
            dependencies.onCenterObject(obj)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(directionButton,
                         title: localizedString("astro_direction"),
                         image: obj.showDirection ? "ic_action_target_direction_on" : "ic_action_target_direction_off") { [weak self] in
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
                         image: obj.showCelestialPath ? "ic_action_target_path_on" : "ic_action_target_path_off") { [weak self] in
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
        if imageName == "ic_action_location_16" {
            return AstroIcon.template(imageName, size: CGSize(width: 24, height: 24))
        }
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
        submitCards()
    }

    private func resetScheduleToCurrentPeriod() {
        guard let obj = skyObject else {
            return
        }
        updateScheduleCard(obj, periodStartOverride: normalizedDay(dependencies.currentDate()))
        submitCards()
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
        updateSelectedTabControls()
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
              article.hasOfflineContent() else {
            return false
        }
        return AstroArticleDialogFragment.showInstance(from: self, article: article)
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
                OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.wikipedia(), navController: navigation)
            }
        case .download:
            OAUtilities.showToast(localizedString("no_index_file_to_download"),
                                  details: nil,
                                  duration: 4,
                                  in: view)
        case nil:
            break
        }
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
        view.layoutIfNeeded()
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
        let maxOffsetY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
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
            tabBar.layoutIfNeeded()
        }
    }

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let tab = Tab(rawValue: item.tag) else {
            return
        }
        selectTab(tab, scrollToSection: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isProgrammaticTabScroll,
              scrollView.isDragging || scrollView.isDecelerating else {
            return
        }
        let y = scrollView.contentOffset.y + 16
        let visibilityY = cardViewsByKey[.visibility].map { $0.convert($0.bounds, to: scrollView).minY }
        let scheduleY = cardViewsByKey[.schedule].map { $0.convert($0.bounds, to: scrollView).minY }
        let nextTab: Tab
        if let scheduleY, y >= scheduleY - 24 {
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

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        guard sheetPresentationController === navigationController?.sheetPresentationController else {
            return
        }
        setTabBarVisible(sheetPresentationController.selectedDetentIdentifier == .large, animated: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dependencies.onDismissed()
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
        title = name
        navigationItem.title = name
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
}
