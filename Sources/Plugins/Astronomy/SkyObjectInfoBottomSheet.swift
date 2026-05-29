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
    let onCenterObject: (SkyObject) -> Void
    let onFavoriteChanged: (SkyObject, Bool) -> Void
    let onDirectionChanged: (SkyObject, Bool) -> Int
    let onCelestialPathChanged: (SkyObject, Bool) -> Void
    let onSetObjectPinned: (SkyObject, Bool, Bool) -> Void
    let onRefreshObjects: () -> Void
    let onCatalogClick: (Catalog) -> Void
}

final class AstroContextMenuViewController: UIViewController {
    private enum Tab: Int {
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

    private let headerTitle = UILabel()
    private let headerType = UILabel()
    private let closeButton = UIButton(type: .system)
    private let metricsContainer = UIView()
    private let actionsStack = UIStackView()
    private let segmentedControl = UISegmentedControl(items: [
        AstroContextMenuLocalizer.label("shared_string_overview", fallback: "Overview"),
        AstroContextMenuLocalizer.label("gpx_visibility_txt", fallback: "Visibility"),
        AstroContextMenuLocalizer.label("astronomy_schedule", fallback: "Schedule")
    ])
    private let scrollView = UIScrollView()
    private let cardsStack = UIStackView()
    private var cardViewsByKey: [AstroContextCardKey: UIView] = [:]

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
        bindControllerCallbacks()
        if let skyObject {
            updateObjectInfo(skyObject)
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

    private func setupView() {
        view.backgroundColor = UIColor(white: 0.03, alpha: 0.98)

        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.textColor = .white
        headerTitle.font = .systemFont(ofSize: 21, weight: .bold)
        headerTitle.numberOfLines = 2
        header.addSubview(headerTitle)

        headerType.translatesAutoresizingMaskIntoConstraints = false
        headerType.textColor = UIColor(white: 0.72, alpha: 1)
        headerType.font = .systemFont(ofSize: 14)
        headerType.numberOfLines = 2
        header.addSubview(headerType)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor(white: 1, alpha: 0.10)
        closeButton.layer.cornerRadius = 16
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dependencies.onClose()
        }, for: .touchUpInside)
        header.addSubview(closeButton)

        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metricsContainer)

        actionsStack.axis = .horizontal
        actionsStack.alignment = .fill
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 8
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        [saveButton, locationButton, directionButton, pathButton].forEach {
            configureActionButton($0)
            actionsStack.addArrangedSubview($0)
        }
        view.addSubview(actionsStack)

        segmentedControl.selectedSegmentIndex = Tab.overview.rawValue
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addAction(UIAction { [weak self] _ in
            self?.scrollToSelectedTab()
        }, for: .valueChanged)
        view.addSubview(segmentedControl)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        cardsStack.axis = .vertical
        cardsStack.spacing = 12
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(cardsStack)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),

            closeButton.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            closeButton.topAnchor.constraint(equalTo: header.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            headerTitle.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerTitle.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            headerTitle.topAnchor.constraint(equalTo: header.topAnchor),

            headerType.leadingAnchor.constraint(equalTo: headerTitle.leadingAnchor),
            headerType.trailingAnchor.constraint(equalTo: headerTitle.trailingAnchor),
            headerType.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 4),
            headerType.bottomAnchor.constraint(equalTo: header.bottomAnchor),

            metricsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            metricsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            metricsContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            metricsContainer.heightAnchor.constraint(equalToConstant: 62),

            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionsStack.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: 8),
            actionsStack.heightAnchor.constraint(equalToConstant: 54),

            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: 12),
            segmentedControl.heightAnchor.constraint(equalToConstant: 34),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            cardsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            cardsStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func configureActionButton(_ button: UIButton) {
        var config = UIButton.Configuration.filled()
        config.imagePlacement = .top
        config.imagePadding = 3
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.10)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)
        button.configuration = config
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.65
    }

    private func bindControllerCallbacks() {
        visibilityController.onDataChanged = { [weak self] in self?.submitCards() }
        scheduleController.onDataChanged = { [weak self] in self?.submitCards() }
    }

    private func buildHeaderTypeText(_ obj: SkyObject) -> String {
        let typeName = AstroContextMenuLocalizer.label(obj.type.titleKey, fallback: obj.type.localizedName)
        let parentGroup: String
        if obj.type == .MOON {
            parentGroup = AstroContextMenuLocalizer.label("astro_type_earth", fallback: "Earth")
        } else if obj.type.isSunSystem() {
            parentGroup = AstroContextMenuLocalizer.label("astro_solar_system", fallback: "Solar system")
        } else if obj.type == .STAR,
                  let constellation = dependencies.constellations().first(where: { constellation in
                      constellation.lines.contains { segment in segment.0 == obj.hip || segment.1 == obj.hip }
                  }) {
            parentGroup = constellation.localizedName?.isEmpty == false ? constellation.localizedName ?? constellation.name : constellation.name
        } else {
            parentGroup = AstroContextMenuLocalizer.label("astro_deep_sky", fallback: "Deep sky")
        }
        return "\(typeName) • \(parentGroup)"
    }

    private func updateButtons(_ obj: SkyObject) {
        bindActionButton(saveButton,
                         title: AstroContextMenuLocalizer.label("shared_string_save", fallback: "Save"),
                         image: obj.isFavorite ? "bookmark.fill" : "bookmark") { [weak self] in
            guard let self else { return }
            obj.isFavorite.toggle()
            dependencies.onFavoriteChanged(obj, obj.isFavorite)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(locationButton,
                         title: AstroContextMenuLocalizer.label("astro_locate", fallback: "Locate"),
                         image: "location") { [weak self] in
            guard let self else { return }
            dependencies.onCenterObject(obj)
            bindActionButtonsForCurrentObject()
        }
        bindActionButton(directionButton,
                         title: AstroContextMenuLocalizer.label("astro_direction", fallback: "Direction"),
                         image: obj.showDirection ? "target" : "scope") { [weak self] in
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
                         title: AstroContextMenuLocalizer.label("astro_path", fallback: "Path"),
                         image: obj.showCelestialPath ? "point.topleft.down.curvedto.point.bottomright.up" : "point.topleft.down.to.point.bottomright.curvepath") { [weak self] in
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
        config.image = UIImage(systemName: image)
        button.configuration = config
        let identifier = UIAction.Identifier("astro.context.action")
        button.removeAction(identifiedBy: identifier, for: .touchUpInside)
        button.addAction(UIAction(identifier: identifier) { _ in action() }, for: .touchUpInside)
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
                                    label: AstroContextMenuLocalizer.label("shared_string_azimuth", fallback: "Azimuth")),
            MetricsAdapter.MetricUi(value: String(format: "%.1f°", altitude),
                                    label: AstroContextMenuLocalizer.label("altitude", fallback: "Altitude")),
            MetricsAdapter.MetricUi(value: String(format: "%.2f", obj.magnitude),
                                    label: AstroContextMenuLocalizer.label("shared_string_magnitude", fallback: "Magnitude"))
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
                                                   label: AstroContextMenuLocalizer.label("astro_rise", fallback: "Rise")))
        }
        if let set = riseSet.set {
            metrics.append(MetricsAdapter.MetricUi(value: formatter.string(from: set),
                                                   label: AstroContextMenuLocalizer.label("astro_set", fallback: "Set")))
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
        segmentedControl.selectedSegmentIndex = Tab.visibility.rawValue
        scrollToSelectedTab()
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
            OAUtilities.showToast(AstroContextMenuLocalizer.label("no_index_file_to_download", fallback: "No index file to download"),
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

    private func scrollToSelectedTab() {
        guard let tab = Tab(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }
        let key: AstroContextCardKey?
        switch tab {
        case .overview:
            key = adapter.currentList.first?.key
        case .visibility:
            key = .visibility
        case .schedule:
            key = .schedule
        }
        guard let key,
              let target = cardViewsByKey[key] else {
            return
        }
        let targetFrame = target.convert(target.bounds, to: scrollView)
        scrollView.setContentOffset(CGPoint(x: 0, y: max(0, targetFrame.minY - 4)), animated: true)
    }

    private func resetOverviewStateForNewObject() {
        segmentedControl.selectedSegmentIndex = Tab.overview.rawValue
        scrollView.setContentOffset(.zero, animated: false)
        uiState.catalogsExpanded = false
        uiState.galleryState = .collapsed
    }

    private func setTitle(_ name: String) {
        headerTitle.text = name
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
