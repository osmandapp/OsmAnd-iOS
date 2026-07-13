//
//  PlanRouteAnalyzeViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import DGCharts
import OsmAndShared

private struct AnalyzeRenderState: Equatable {
    let state: AnalyzeState
    let hasOverviewData: Bool
    let statusSignature: String
    let graphSignature: String?
    let statsSignature: String?
    let roadAttributeSignatures: [String]

    var roadAttributesSectionStart: Int {
        hasOverviewData ? PlanRouteAnalyzeViewController.roadAttributesBase : 1
    }

    var sectionCount: Int {
        switch state {
        case .noData, .elevationCalculating, .routeCalculating:
            return 1
        case .hasData:
            return roadAttributesSectionStart + roadAttributeSignatures.count
        }
    }
}

private final class AnalyzeChartDelegateProxy: NSObject, ChartViewDelegate {
    var onNothingSelected: (() -> Void)?
    var onValueSelected: (() -> Void)?
    var onTranslated: (() -> Void)?

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        onNothingSelected?()
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        onValueSelected?()
    }

    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        onTranslated?()
    }
}

final class PlanRouteAnalyzeViewController: UIViewController, PlanRouteTabContent {

    let planRouteTab: PlanRouteTab = .analyze

    private var selectedYAxisTypes: [NSNumber] = [
        NSNumber(value: GPXDataSetType.altitude.rawValue),
        NSNumber(value: GPXDataSetType.slope.rawValue)
    ]
    private var selectedXAxisType: GPXDataSetAxisType = .distance
    private var expandedStatIndexes: Set<Int> = []
    private var calculatingWithNearbyRoads: Bool = true
    private var allowsTerrainFallbackSteepness = false
    private var wasCalculatingElevation = false
    private var hasCompletedElevationCalculation = false
    private var cachedState: AnalyzeState = .noData
    private var cachedHasOverviewData = false
    private var cachedRoadAttributeStatistics: [OARouteStatistics] = []
    private var cachedSyntheticSteepness: OARouteStatistics?
    private var cachedSyntheticSteepnessSignature: Double = -1
    private var pendingSteepnessSignature: Double = -1
    private var lastRenderState: AnalyzeRenderState?
    private var trackChartFilePath: String?
    private var trackChartHelper: TrackChartHelper?
    private var highlightDrawX: CGFloat = -1
    private var lastTranslation: CGPoint = .zero
    private let tableView = CancelableTableView(frame: .zero, style: .plain)
    private weak var dataSource: PlanRouteAnalyzeDataSource?
    private weak var chartView: ElevationChart?
    private weak var yAxisButton: UIButton?
    private weak var xAxisButton: UIButton?
    private lazy var chartDelegateProxy: AnalyzeChartDelegateProxy = {
        let proxy = AnalyzeChartDelegateProxy()
        proxy.onNothingSelected = { [weak self] in
            self?.hideChartLocation()
        }
        proxy.onValueSelected = { [weak self] in
            self?.refreshChartOnMap()
        }
        proxy.onTranslated = { [weak self] in
            self?.handleChartTranslated()
        }
        return proxy
    }()

    private var currentState: AnalyzeState {
        cachedState
    }

    init(dataSource: PlanRouteAnalyzeDataSource?) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideChartLocation()
    }

    func reloadData() {
        guard isViewLoaded else { return }
        let isElevationCalculating = dataSource?.isCalculatingElevation ?? false
        let isRouteCalculating = dataSource?.isCalculatingRoute ?? false
        if wasCalculatingElevation && !isElevationCalculating {
            hasCompletedElevationCalculation = true
        }
        wasCalculatingElevation = isElevationCalculating
        let analysisData = dataSource?.analysisData
        cachedHasOverviewData = analysisData?.hasElevationData == true
        scheduleSteepnessComputationIfNeeded(analysisData: analysisData)
        cachedRoadAttributeStatistics = buildRoadAttributeStatistics(from: analysisData)
        expandedStatIndexes = Set(expandedStatIndexes.filter { $0 < cachedRoadAttributeStatistics.count })
        cachedState = resolveState(isRouteCalculating: isRouteCalculating,
                                   isElevationCalculating: isElevationCalculating,
                                   hasOverviewData: cachedHasOverviewData,
                                   roadAttributeStatistics: cachedRoadAttributeStatistics)
        let renderState = makeRenderState(analysisData: analysisData)
        if renderState.graphSignature == nil {
            hideChartLocation()
        }
        applyRenderState(renderState)
    }

    private func setupTableView() {
        view.backgroundColor = .viewBg
        tableView.backgroundColor = .viewBg
        tableView.separatorStyle = .none
        tableView.canCancelContentTouches = true
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 72, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AnalyzeRouteAttributeHeaderView.self, forHeaderFooterViewReuseIdentifier: AnalyzeRouteAttributeHeaderView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func showGetElevationSheet() {
        let presenter = parent ?? self
        let sheet = GetElevationDataViewController()
        sheet.onSelectMethod = { [weak self] useNearbyRoads in
            guard let self else { return }
            calculatingWithNearbyRoads = useNearbyRoads
            allowsTerrainFallbackSteepness = !useNearbyRoads
            if useNearbyRoads == false {
                reloadData()
            }
            dataSource?.startElevationCalculation(useNearbyRoads: useNearbyRoads)
        }
        presenter.showMediumSheetViewController(viewController: sheet, isLargeAvailable: false)
    }

    private func showAxisPicker(startingOnYAxis: Bool) {
        guard let analysis = dataSource?.analysisData?.gpxAnalysis else { return }
        let sheet = StatisticsSelectionBottomSheetViewController(
            types: selectedYAxisTypes,
            selectedXAxisMode: selectedXAxisType,
            analysis: analysis,
            isYAxisMode: startingOnYAxis
        )
        sheet.delegate = self
        showMediumSheetViewController(viewController: sheet, isLargeAvailable: true)
    }

    private func refreshChart() {
        guard let data = dataSource?.analysisData,
              let analysis = data.gpxAnalysis,
              let gpxFile = data.gpxFile,
              let chart = chartView else { return }
        let gpxItem = OAGPXDatabase.sharedDb().getGPXItem(OAUtilities.getGpxShortPath(gpxFile.path))
        let (firstType, secondType) = resolvedYAxisTypes()
        GpxUIHelper.refreshLineChart(chartView: chart,
                                     analysis: analysis,
                                     firstType: firstType,
                                     secondType: secondType,
                                     axisType: selectedXAxisType,
                                     calcWithoutGaps: GpxUtils.calcWithoutGaps(gpxFile, gpxDataItem: gpxItem, overrideIsGeneralTrack: true))
        if !chart.highlighted.isEmpty {
            refreshChartOnMap()
        }
    }

    private func refreshChartOnMap() {
        guard let chart = chartView,
              let data = dataSource?.analysisData,
              let analysis = data.gpxAnalysis,
              let gpxFile = data.gpxFile,
              let segment = chartSegment(for: analysis, gpxFile: gpxFile) else {
            return
        }
        let helper = trackChartHelper(for: gpxFile)
        helper.refreshChart(chart,
                            fitTrack: false,
                            forceFit: false,
                            recalculateXAxis: false,
                            analysis: analysis,
                            segment: segment)
    }

    private func bindChartGestures(_ chart: ElevationChart) {
        chart.delegate = chartDelegateProxy
        chart.gestureRecognizers?.forEach { recognizer in
            if recognizer is UIPanGestureRecognizer {
                recognizer.addTarget(self, action: #selector(onChartScrolled(_:)))
            }
            recognizer.addTarget(self, action: #selector(onChartGesture(_:)))
        }
    }

    private func chartSegment(for analysis: GpxTrackAnalysis, gpxFile: GpxFile) -> TrkSegment? {
        if let segment = TrackChartHelper.getTrackSegment(analysis, gpxItem: gpxFile) {
            return segment
        }

        for trackObject in gpxFile.tracks {
            guard let track = trackObject as? Track else { continue }
            for segmentObject in track.segments {
                guard let segment = segmentObject as? TrkSegment, segment.points.count > 0 else { continue }
                return segment
            }
        }
        return nil
    }

    private func trackChartHelper(for gpxFile: GpxFile) -> TrackChartHelper {
        if trackChartFilePath == gpxFile.path, let trackChartHelper {
            return trackChartHelper
        }
        let helper = TrackChartHelper(gpxDoc: gpxFile)
        helper.delegate = self
        trackChartHelper = helper
        trackChartFilePath = gpxFile.path
        return helper
    }

    private func hideChartLocation() {
        dataSource?.hideChartHighlight()
    }

    @objc private func onChartScrolled(_ recognizer: UIPanGestureRecognizer) {
        guard let chart = recognizer.view as? ElevationChart else { return }

        if recognizer.state == .changed {
            if chart.lowestVisibleX > 0.1,
               roundedChartValue(chart.highestVisibleX) != roundedChartValue(chart.chartXMax) {
                lastTranslation = recognizer.translation(in: chart)
                return
            }

            let touchPoint = recognizer.location(in: chart)
            let translation = recognizer.translation(in: chart)
            let highlightX = chart.isFullyZoomedOut
                ? touchPoint.x
                : highlightDrawX + (lastTranslation.x - translation.x)
            guard let highlight = chart.getHighlightByTouchPoint(CGPoint(x: highlightX, y: 0)) else { return }
            chart.lastHighlighted = highlight
            chart.highlightValue(highlight, callDelegate: true)
        } else if recognizer.state == .ended {
            lastTranslation = .zero
            if let highlight = chart.highlighted.first {
                highlightDrawX = highlight.drawX
            }
        }
    }

    @objc private func onChartGesture(_ recognizer: UIGestureRecognizer) {
        guard let chart = recognizer.view as? ElevationChart else { return }

        if recognizer.state == .began {
            if let highlight = chart.highlighted.first {
                highlightDrawX = highlight.drawX
            } else {
                highlightDrawX = -1
            }
        } else if (recognizer is UIPinchGestureRecognizer
                    || (recognizer is UITapGestureRecognizer
                        && (recognizer as? UITapGestureRecognizer)?.numberOfTapsRequired == 2))
                    && recognizer.state == .ended {
            refreshChartOnMap()
        }
    }

    private func roundedChartValue(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private func handleChartTranslated() {
        guard let chart = self.chartView, highlightDrawX != -1 else { return }
        guard let highlight = chart.getHighlightByTouchPoint(CGPoint(x: highlightDrawX, y: 0)) else { return }
        chart.highlightValue(highlight, callDelegate: true)
    }

    private func resolvedYAxisTypes() -> (GPXDataSetType, GPXDataSetType) {
        let first = selectedYAxisTypes.first.flatMap { GPXDataSetType(rawValue: $0.intValue) } ?? .altitude
        let second = selectedYAxisTypes.count > 1
            ? (GPXDataSetType(rawValue: selectedYAxisTypes[1].intValue) ?? .none)
            : .none
        return (first, second)
    }

    private func resolveState(isRouteCalculating: Bool,
                              isElevationCalculating: Bool,
                              hasOverviewData: Bool,
                              roadAttributeStatistics: [OARouteStatistics]) -> AnalyzeState {
        if isRouteCalculating { return .routeCalculating }
        if isElevationCalculating {
            return !calculatingWithNearbyRoads && !roadAttributeStatistics.isEmpty ? .hasData : .elevationCalculating
        }
        if hasOverviewData || !roadAttributeStatistics.isEmpty { return .hasData }
        return .noData
    }

    private func yAxisButtonTitle() -> String {
        let titles = selectedYAxisTypes.compactMap { GPXDataSetType(rawValue: $0.intValue)?.getTitle() }
        guard let firstTitle = titles.first else { return "" }
        guard titles.count > 1, let secondTitle = titles.last else { return firstTitle }
        return String(format: localizedString("ltr_or_rtl_combine_via_slash"), firstTitle, secondTitle)
    }

    private func updateAxisButtons() {
        updateAxisButton(yAxisButton, title: yAxisButtonTitle())
        updateAxisButton(xAxisButton, title: selectedXAxisType.getName())
    }

    private func updateAxisButton(_ button: UIButton?, title: String) {
        guard let button else { return }
        var configuration = button.configuration ?? UIButton.Configuration.plain()
        configuration.title = title
        button.configuration = configuration
    }

    private func makeRenderState(analysisData: PlanRouteAnalysisData?) -> AnalyzeRenderState {
        AnalyzeRenderState(
            state: cachedState,
            hasOverviewData: cachedHasOverviewData,
            statusSignature: statusSignature(for: cachedState),
            graphSignature: graphSignature(for: analysisData),
            statsSignature: statsSignature(for: analysisData),
            roadAttributeSignatures: cachedRoadAttributeStatistics.map(roadAttributeSignature(for:))
        )
    }

    private func statusSignature(for state: AnalyzeState) -> String {
        switch state {
        case .noData:
            return "noData"
        case .elevationCalculating:
            return "elevationCalculating:\(calculatingWithNearbyRoads)"
        case .routeCalculating:
            return "routeCalculating"
        case .hasData:
            return "hasData:\(cachedHasOverviewData)"
        }
    }

    private func graphSignature(for analysisData: PlanRouteAnalysisData?) -> String? {
        guard cachedHasOverviewData,
              let analysis = analysisData?.gpxAnalysis,
              let gpxFile = analysisData?.gpxFile else {
            return nil
        }
        let yTypes = selectedYAxisTypes.map(\.stringValue).joined(separator: ",")
        return [
            gpxFile.path,
            String(analysis.totalDistance),
            String(analysis.timeSpan),
            String(analysis.startTime),
            selectedXAxisType.getName(),
            yTypes
        ].joined(separator: "|")
    }

    private func statsSignature(for analysisData: PlanRouteAnalysisData?) -> String? {
        guard cachedHasOverviewData, let analysisData else { return nil }
        return [
            String(analysisData.uphill),
            String(analysisData.downhill),
            String(analysisData.altMin ?? .nan),
            String(analysisData.altMax ?? .nan),
            String(analysisData.avgSpeed ?? .nan),
            String(analysisData.maxSpeed ?? .nan),
            String(analysisData.timeInMotion ?? .nan)
        ].joined(separator: "|")
    }

    private func roadAttributeSignature(for stat: OARouteStatistics) -> String {
        let elementsSignature = stat.elements.enumerated().map { index, element in
            let propertyName = element.getUserPropertyName() ?? element.propertyName ?? ""
            let distance = stat.partition[propertyName]?.distance ?? element.distance
            return [
                String(index),
                propertyName,
                String(Int(distance.rounded())),
                String(element.color)
            ].joined(separator: ":")
        }.joined(separator: ";")
        return "\(stat.name ?? "")|\(elementsSignature)"
    }

    private func applyRenderState(_ renderState: AnalyzeRenderState) {
        let previousState = lastRenderState
        lastRenderState = renderState
        guard let previousState else {
            tableView.reloadData()
            return
        }
        guard previousState.state == renderState.state,
              previousState.hasOverviewData == renderState.hasOverviewData,
              previousState.sectionCount == renderState.sectionCount else {
            tableView.reloadData()
            return
        }

        var changedSections = IndexSet()
        switch renderState.state {
        case .noData, .elevationCalculating, .routeCalculating:
            if previousState.statusSignature != renderState.statusSignature {
                changedSections.insert(0)
            }
        case .hasData:
            if renderState.hasOverviewData {
                if previousState.graphSignature != renderState.graphSignature {
                    changedSections.insert(Self.graphSection)
                }
                if previousState.statsSignature != renderState.statsSignature {
                    changedSections.insert(Self.statsSection)
                }
            }
            for (index, signature) in renderState.roadAttributeSignatures.enumerated()
            where previousState.roadAttributeSignatures[index] != signature {
                changedSections.insert(index + renderState.roadAttributesSectionStart)
            }
        }

        guard !changedSections.isEmpty else { return }
        tableView.reloadSections(changedSections, with: .none)
    }
}

// MARK: - State

private enum AnalyzeState: Equatable {
    case noData
    case elevationCalculating
    case routeCalculating
    case hasData
}

// MARK: - Section indices

private extension PlanRouteAnalyzeViewController {
    static let graphSection = 0
    static let statsSection = 1
    static let roadAttributesBase = 2
    static let cardHorizontalInset: CGFloat = 16
    static let cardCornerRadius: CGFloat = 24
    static let statusCardCornerRadius: CGFloat = 24
    static let steepnessAttributeName = "routeInfo_steepness"
    static let routeAttributeNames = [
        "routeInfo_roadClass",
        steepnessAttributeName,
        "routeInfo_surface",
        "routeInfo_smoothness"
    ]
    static let minIncline = -101
    static let minDividedIncline = -20
    static let maxIncline = 100
    static let maxDividedIncline = 21
    static let steepnessBoundaryStep = 4
    static let steepnessDistanceStep = 5.0
    static let steepnessApproxDistance = 100.0
    static let steepnessBoundaryValues: [Int] = {
        var values = [minIncline]
        var current = minDividedIncline
        while current <= 20 {
            values.append(current)
            current += steepnessBoundaryStep
        }
        values.append(maxIncline)
        return values
    }()
    static let steepnessBoundaryClasses: [String] = {
        var classes = ["steepness=-100_-20"]
        for index in 1..<(steepnessBoundaryValues.count - 1) {
            let lowerBound = steepnessBoundaryValues[index - 1] + 1
            let upperBound = steepnessBoundaryValues[index]
            classes.append("steepness=\(lowerBound)_\(upperBound)")
        }
        classes.append("steepness=\(maxDividedIncline)_\(maxIncline)")
        return classes
    }()
}

// MARK: - UITableViewDataSource

extension PlanRouteAnalyzeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        lastRenderState?.sectionCount ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState {
        case .noData:
            return makeNoElevationStatusCardCell()
        case .elevationCalculating:
            return makeElevationCalculatingStatusCardCell()
        case .routeCalculating:
            let routeCalculatingTexts = routeCalculatingTexts()
            return makeStatusCardCell(
                icon: nil,
                iconTint: .clear,
                title: routeCalculatingTexts.title,
                description: routeCalculatingTexts.description,
                actionTitle: nil,
                isSpinner: true,
                action: nil
            )
        case .hasData:
            if hasOverviewData {
                switch indexPath.section {
                case Self.graphSection:  return makeChartSectionCell()
                case Self.statsSection:  return makeStatsSectionCell()
                default:
                    let statIndex = indexPath.section - roadAttributesSectionStart
                    return makeRoadAttrCard(statIndex: statIndex)
                }
            } else if indexPath.section == 0 {
                return makeNoElevationStatusCardCell()
            } else {
                let statIndex = indexPath.section - roadAttributesSectionStart
                return makeRoadAttrCard(statIndex: statIndex)
            }
        }
    }

    // MARK: - Card helper

    private func makeCardView() -> UIView {
        makeCardView(cornerRadius: Self.cardCornerRadius)
    }

    private func makeCardView(cornerRadius: CGFloat) -> UIView {
        let card = UIView()
        card.backgroundColor = .groupBg
        card.layer.cornerRadius = cornerRadius
        card.clipsToBounds = true
        return card
    }

    private func wrapInCard(_ content: UIView, insets: UIEdgeInsets = .zero) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let card = makeCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.cardHorizontalInset),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.cardHorizontalInset),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: insets.top),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -insets.right),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -insets.bottom)
        ])
        return cell
    }

    // MARK: - Chart section card

    private func makeChartSectionCell() -> UITableViewCell {
        guard let data = dataSource?.analysisData,
              let analysis = data.gpxAnalysis,
              let gpxFile = data.gpxFile else { return UITableViewCell() }

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let card = makeCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.cardHorizontalInset),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.cardHorizontalInset),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        let yBtn = axisPickerButton(title: yAxisButtonTitle()) { [weak self] in
            self?.showAxisPicker(startingOnYAxis: true)
        }
        yAxisButton = yBtn
        let xBtn = axisPickerButton(title: selectedXAxisType.getName()) { [weak self] in
            self?.showAxisPicker(startingOnYAxis: false)
        }
        xAxisButton = xBtn
        let buttonStack = UIStackView(arrangedSubviews: [yBtn, xBtn])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let chart = ElevationChart(frame: .zero)
        chart.translatesAutoresizingMaskIntoConstraints = false
        chartView = chart
        bindChartGestures(chart)

        let gpxItem = OAGPXDatabase.sharedDb().getGPXItem(OAUtilities.getGpxShortPath(gpxFile.path))
        let useHours = (analysis.timeSpan / 3_600_000) > 0
        GpxUIHelper.setupElevationChart(chartView: chart,
                                        topOffset: 20,
                                        bottomOffset: 4,
                                        useGesturesAndScale: true,
                                        showXInMarker: false,
                                        startTime: analysis.startTime,
                                        useHours: useHours)
        let (firstType, secondType) = resolvedYAxisTypes()
        GpxUIHelper.refreshLineChart(chartView: chart,
                                     analysis: analysis,
                                     firstType: firstType,
                                     secondType: secondType,
                                     axisType: selectedXAxisType,
                                     calcWithoutGaps: GpxUtils.calcWithoutGaps(gpxFile, gpxDataItem: gpxItem, overrideIsGeneralTrack: true))

        let recalcSeparator = UIView()
        recalcSeparator.backgroundColor = .customSeparator
        recalcSeparator.translatesAutoresizingMaskIntoConstraints = false

        let recalcBtn = UIButton(type: .system)
        recalcBtn.setTitle(localizedString("recalculate_elevation"), for: .normal)
        recalcBtn.setTitleColor(.textColorActive, for: .normal)
        recalcBtn.titleLabel?.font = .preferredFont(forTextStyle: .body)
        recalcBtn.contentHorizontalAlignment = .left
        recalcBtn.addTarget(self, action: #selector(onRecalculateTapped), for: .touchUpInside)
        recalcBtn.translatesAutoresizingMaskIntoConstraints = false

        [buttonStack, chart, recalcSeparator, recalcBtn].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 36),

            chart.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            chart.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            chart.heightAnchor.constraint(equalToConstant: 130),

            recalcSeparator.topAnchor.constraint(equalTo: chart.bottomAnchor, constant: 10),
            recalcSeparator.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            recalcSeparator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            recalcSeparator.heightAnchor.constraint(equalToConstant: 0.5),

            recalcBtn.topAnchor.constraint(equalTo: recalcSeparator.bottomAnchor),
            recalcBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            recalcBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            recalcBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            recalcBtn.heightAnchor.constraint(equalToConstant: 50)
        ])

        return cell
    }

    private func axisPickerButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .cellButtonBg
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.contentHorizontalAlignment = .fill
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .textColorActive
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = UIFont.scaledSystemFont(ofSize: 15, weight: .regular)
            return out
        }
        config.image = UIImage(systemName: "chevron.up.chevron.down",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = config
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    // MARK: - Stats section card

    private func makeStatsSectionCell() -> UITableViewCell {
        guard let data = dataSource?.analysisData else { return UITableViewCell() }

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let card = makeCardView(cornerRadius: Self.statusCardCornerRadius)
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.cardHorizontalInset),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.cardHorizontalInset),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        let altRange: String
        if let min = data.altMin, let max = data.altMax {
            let minStr = OAOsmAndFormatter.getFormattedAlt(min) ?? "–"
            let maxStr = OAOsmAndFormatter.getFormattedAlt(max) ?? "–"
            altRange = "\(minStr), \(maxStr)"
        } else {
            altRange = "–"
        }
        let items: [(String, String)] = [
            (fmtAlt(data.uphill), localizedString("shared_string_uphill")),
            (fmtAlt(data.downhill), localizedString("shared_string_downhill")),
            (altRange, localizedString("altitude_range")),
            (fmtSpeed(data.avgSpeed), localizedString("average_speed")),
            (fmtSpeed(data.maxSpeed), localizedString("shared_string_max_speed")),
            (fmtTime(data.timeInMotion), localizedString("moving_time"))
        ]

        let row0 = makeGridRow(items: Array(items[0...2]))
        row0.translatesAutoresizingMaskIntoConstraints = false

        let hDivider = UIView()
        hDivider.backgroundColor = .customSeparator
        hDivider.translatesAutoresizingMaskIntoConstraints = false

        let row1 = makeGridRow(items: Array(items[3...5]))
        row1.translatesAutoresizingMaskIntoConstraints = false

        [row0, hDivider, row1].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            row0.topAnchor.constraint(equalTo: card.topAnchor),
            row0.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row0.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            hDivider.topAnchor.constraint(equalTo: row0.bottomAnchor),
            hDivider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hDivider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hDivider.heightAnchor.constraint(equalToConstant: 0.5),

            row1.topAnchor.constraint(equalTo: hDivider.bottomAnchor),
            row1.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row1.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row1.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return cell
    }

    private func makeGridRow(items: [(String, String)]) -> UIStackView {
        let itemViews = items.map { statItemView(value: $0.0, label: $0.1) }
        var arranged: [UIView] = []
        for (i, view) in itemViews.enumerated() {
            arranged.append(view)
            if i < itemViews.count - 1 {
                arranged.append(makeVerticalDivider())
            }
        }
        let row = UIStackView(arrangedSubviews: arranged)
        row.axis = .horizontal
        row.spacing = 0
        row.distribution = .fill
        row.alignment = .fill
        for i in 1..<itemViews.count {
            itemViews[i].widthAnchor.constraint(equalTo: itemViews[0].widthAnchor).isActive = true
        }
        return row
    }

    private func makeVerticalDivider() -> UIView {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.widthAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        let line = UIView()
        line.backgroundColor = .customSeparator
        line.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            line.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
            line.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -9)
        ])
        return wrapper
    }

    private func statItemView(value: String, label: String) -> UIView {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .preferredFont(forTextStyle: .footnote)
        valueLabel.textColor = .textColorActive
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = .preferredFont(forTextStyle: .caption2)
        nameLabel.textColor = .textColorSecondary

        let stack = UIStackView(arrangedSubviews: [valueLabel, nameLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 9, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }

    // MARK: - Road attribute card

    private func makeRoadAttrCard(statIndex: Int) -> UITableViewCell {
        guard statIndex < roadAttributeStatistics.count,
              let analysis = dataSource?.analysisData?.gpxAnalysis else { return UITableViewCell() }

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let card = makeCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.cardHorizontalInset),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.cardHorizontalInset),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        let stat = roadAttributeStatistics[statIndex]
        let isExpanded = expandedStatIndexes.contains(statIndex)

        let barChart = HorizontalBarChartView(frame: .zero)
        barChart.isUserInteractionEnabled = false
        barChart.translatesAutoresizingMaskIntoConstraints = false
        GpxUIHelper.refreshBarChart(chartView: barChart,
                                    statistics: stat,
                                    analysis: analysis,
                                    nightMode: OAAppSettings.sharedManager().nightMode)

        let legendView = isExpanded ? makeExpandedRoadAttrLegend(stat: stat) : makeCompactRoadAttrLegend(stat: stat)
        legendView.isUserInteractionEnabled = false
        legendView.translatesAutoresizingMaskIntoConstraints = false

        [barChart, legendView].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            barChart.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            barChart.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            barChart.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            barChart.heightAnchor.constraint(equalToConstant: 54),

            legendView.topAnchor.constraint(equalTo: barChart.bottomAnchor),
            legendView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            legendView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            legendView.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return cell
    }

    private func makeCompactRoadAttrLegend(stat: OARouteStatistics) -> UIView {
        let items = routeAttributeLegendItems(for: stat)
        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 12, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let maxWidth = tableView.bounds.width - (Self.cardHorizontalInset * 2) - 32
        for rowItems in compactLegendRows(items: items, maxWidth: maxWidth) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.spacing = 16
            rowItems.forEach { rowStack.addArrangedSubview(compactLegendItem(title: $0.title, color: $0.color)) }
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            rowStack.addArrangedSubview(spacer)
            stack.addArrangedSubview(rowStack)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeExpandedRoadAttrLegend(stat: OARouteStatistics) -> UIView {
        let items = routeAttributeLegendItems(for: stat)
        let container = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        for (index, item) in items.enumerated() {
            let rowView = OARouteInfoLegendItemView(title: item.title, color: item.color, distance: item.distance)
            stack.addArrangedSubview(rowView)

            guard index < items.count - 1 else { continue }
            let separatorContainer = UIView()
            separatorContainer.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

            let separator = UIView()
            separator.backgroundColor = .customSeparator
            separator.translatesAutoresizingMaskIntoConstraints = false
            separatorContainer.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: separatorContainer.leadingAnchor, constant: 56),
                separator.trailingAnchor.constraint(equalTo: separatorContainer.trailingAnchor),
                separator.topAnchor.constraint(equalTo: separatorContainer.topAnchor),
                separator.bottomAnchor.constraint(equalTo: separatorContainer.bottomAnchor)
            ])

            stack.addArrangedSubview(separatorContainer)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func compactLegendItem(title: String, color: UIColor) -> UIView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .textColorPrimary
        label.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [dot, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.setContentHuggingPriority(.required, for: .horizontal)
        return stack
    }

    // MARK: - Status card cell (no data / calculating)

    private func makeNoElevationStatusCardCell() -> UITableViewCell {
        makeStatusCardCell(
            icon: .icCustomDesert,
            iconTint: .iconColorDefault,
            title: localizedString("no_elevation_data"),
            description: localizedString("no_elevation_data_description"),
            actionTitle: localizedString("get_elevation_data"),
            isSpinner: false,
            action: { [weak self] in self?.showGetElevationSheet() }
        )
    }

    private func makeElevationCalculatingStatusCardCell() -> UITableViewCell {
        let calcDescKey = calculatingWithNearbyRoads
            ? "calculating_elevation_nearby_roads_description"
            : "calculating_elevation_terrain_maps_description"
        return makeStatusCardCell(
            icon: nil,
            iconTint: .clear,
            title: localizedString("route_is_being_calculated"),
            description: localizedString(calcDescKey),
            actionTitle: localizedString("shared_string_cancel"),
            isSpinner: true,
            action: { [weak self] in
                self?.dataSource?.cancelElevationCalculation()
            }
        )
    }

    private func routeCalculatingTexts() -> (title: String, description: String) {
        let message = localizedString("message_graph_will_be_available_after_recalculation")
        let parts = message.components(separatedBy: "\n")
        let description = parts.count > 1
            ? parts.dropFirst().joined(separator: "\n")
            : localizedString("plan_route_graph_available_after_recalculation")
        return (localizedString("route_is_being_calculated"), description)
    }

    private func makeStatusCardCell(icon: UIImage?,
                                    iconTint: UIColor,
                                    title: String,
                                    description: String,
                                    actionTitle: String?,
                                    isSpinner: Bool,
                                    action: (() -> Void)?) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let card = makeCardView(cornerRadius: Self.statusCardCornerRadius)
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: Self.cardHorizontalInset),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -Self.cardHorizontalInset),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .preferredFont(forTextStyle: .subheadline)
        descLabel.textColor = .textColorSecondary
        descLabel.numberOfLines = 0

        var trailingView: UIView
        if isSpinner {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            trailingView = spinner
        } else {
            let iconView = UIImageView(image: icon?.withRenderingMode(.alwaysTemplate))
            iconView.tintColor = iconTint
            iconView.contentMode = .scaleAspectFit
            trailingView = iconView
        }

        [titleLabel, descLabel, trailingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        var constraints = [
            trailingView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            trailingView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            trailingView.widthAnchor.constraint(equalToConstant: 30),
            trailingView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingView.leadingAnchor, constant: -8),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: trailingView.leadingAnchor, constant: -8)
        ]

        if let actionTitle, let action {
            let separator = UIView()
            separator.backgroundColor = .customSeparator

            let actionBtn = ElevationActionRow()
            actionBtn.configure(title: actionTitle)
            actionBtn.action = {
                action()
            }

            [separator, actionBtn].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview($0)
            }

            constraints.append(contentsOf: [
                separator.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
                separator.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                separator.heightAnchor.constraint(equalToConstant: 0.5),

                actionBtn.topAnchor.constraint(equalTo: separator.bottomAnchor),
                actionBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                actionBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                actionBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor),
                actionBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
        } else {
            constraints.append(descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16))
        }

        NSLayoutConstraint.activate(constraints)
        return cell
    }

    // MARK: - Formatters

    private func fmtAlt(_ value: Double) -> String {
        OAOsmAndFormatter.getFormattedAlt(value) ?? "–"
    }

    private func fmtSpeed(_ value: Double?) -> String {
        guard let value, value > 0 else { return "–" }
        return OAOsmAndFormatter.getFormattedSpeed(Float(value)) ?? "–"
    }

    private func fmtTime(_ interval: TimeInterval?) -> String {
        guard let interval, interval > 0 else { return "–" }
        return OAOsmAndFormatter.getFormattedDuration(interval) ?? "–"
    }
}

// MARK: - UITableViewDelegate

extension PlanRouteAnalyzeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch currentState {
        case .noData:
            showGetElevationSheet()
        case .elevationCalculating, .routeCalculating:
            break
        case .hasData:
            if !hasOverviewData, indexPath.section == 0 {
                showGetElevationSheet()
                return
            }
            guard indexPath.section >= roadAttributesSectionStart else { return }
            toggleRoadAttribute(at: indexPath.section - roadAttributesSectionStart)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard case .hasData = currentState,
              section >= roadAttributesSectionStart,
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: AnalyzeRouteAttributeHeaderView.reuseIdentifier) as? AnalyzeRouteAttributeHeaderView,
              let stat = roadAttributeStatistic(for: section) else { return nil }

        let statIndex = section - roadAttributesSectionStart
        header.configure(
            title: roadAttributeTitle(for: stat),
            isExpanded: expandedStatIndexes.contains(statIndex),
            onTap: { [weak self] in
                self?.toggleRoadAttribute(at: statIndex)
            }
        )
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard case .hasData = currentState, section >= roadAttributesSectionStart else {
            return .leastNormalMagnitude
        }
        return 48
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 12 }
}

// MARK: - StatisticsSelectionDelegate

extension PlanRouteAnalyzeViewController: StatisticsSelectionDelegate {

    func onGraphModeChanged(_ selectedXAxisMode: GPXDataSetAxisType, types: [NSNumber]) {
        selectedYAxisTypes = types
        selectedXAxisType = selectedXAxisMode
        updateAxisButtons()
        refreshChart()
        lastRenderState = makeRenderState(analysisData: dataSource?.analysisData)
    }
}

// MARK: - ChartHelperDelegate

extension PlanRouteAnalyzeViewController: ChartHelperDelegate {

    func showCurrentHighlitedLocation(_ trackChartPoints: TrackChartPoints) {
        dataSource?.showChartHighlightedLocation(trackChartPoints)
    }

    func showCurrentStatisticsLocation(_ trackChartPoints: TrackChartPoints) {
        dataSource?.showChartStatisticsLocation(trackChartPoints)
    }
}

// MARK: - Actions

private extension PlanRouteAnalyzeViewController {
    var hasOverviewData: Bool {
        cachedHasOverviewData
    }

    var roadAttributesSectionStart: Int {
        hasOverviewData ? Self.roadAttributesBase : 1
    }

    var roadAttributeStatistics: [OARouteStatistics] {
        cachedRoadAttributeStatistics
    }

    func scheduleSteepnessComputationIfNeeded(analysisData: PlanRouteAnalysisData?) {
        guard let analysisData,
              let gpxAnalysis = analysisData.gpxAnalysis,
              !analysisData.routeStatistics.contains(where: { $0.name == Self.steepnessAttributeName }) else {
            return
        }
        let sig = Double(gpxAnalysis.totalDistance)
        guard sig > 0, cachedSyntheticSteepnessSignature != sig, pendingSteepnessSignature != sig else { return }
        pendingSteepnessSignature = sig
        var renderingCache = [String: (propertyName: String, color: Int)]()
        for boundaryClass in Self.steepnessBoundaryClasses {
            if let rendering = steepnessRendering(for: boundaryClass) {
                renderingCache[boundaryClass] = rendering
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = self.buildSyntheticSteepnessStatistics(from: gpxAnalysis, renderingCache: renderingCache)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.pendingSteepnessSignature == sig else { return }
                self.cachedSyntheticSteepness = result
                self.cachedSyntheticSteepnessSignature = sig
                self.pendingSteepnessSignature = -1
                self.reloadData()
            }
        }
    }

    func buildRoadAttributeStatistics(from analysisData: PlanRouteAnalysisData?) -> [OARouteStatistics] {
        guard let analysisData else {
            guard let fallback = buildImmediateTerrainFallbackSteepnessStatistics() else { return [] }
            return Self.routeAttributeNames.compactMap { $0 == Self.steepnessAttributeName ? fallback : nil }
        }
        let routeStatistics = analysisData.routeStatistics
        let groupedStatistics = Dictionary(grouping: routeStatistics) { $0.name }
        let syntheticSteepness: OARouteStatistics?
        if groupedStatistics[Self.steepnessAttributeName]?.first == nil {
            let sig = Double(analysisData.gpxAnalysis?.totalDistance ?? 0)
            if cachedSyntheticSteepnessSignature == sig {
                syntheticSteepness = cachedSyntheticSteepness
            } else {
                syntheticSteepness = buildFallbackSteepnessStatistics(from: analysisData)
            }
        } else {
            syntheticSteepness = nil
        }
        return Self.routeAttributeNames.compactMap { attributeName in
            if attributeName == Self.steepnessAttributeName {
                return groupedStatistics[attributeName]?.first ?? syntheticSteepness
            }
            return groupedStatistics[attributeName]?.first
        }
    }

    func buildImmediateTerrainFallbackSteepnessStatistics() -> OARouteStatistics? {
        guard allowsTerrainFallbackSteepness, !hasOverviewData else { return nil }
        let totalDistance = dataSource?.routeInfo.totalDistance ?? 0
        return buildFlatSteepnessStatistics(totalDistance: totalDistance)
    }

    func roadAttributeStatistic(for section: Int) -> OARouteStatistics? {
        let statIndex = section - roadAttributesSectionStart
        guard statIndex >= 0, statIndex < roadAttributeStatistics.count else { return nil }
        return roadAttributeStatistics[statIndex]
    }

    func roadAttributeTitle(for stat: OARouteStatistics) -> String {
        if stat.name == "routeInfo_roadClass" {
            return localizedString("routeInfo_road_types_name")
        }
        return OAUtilities.getLocalizedRouteInfoProperty(stat.name)
    }

    func routeAttributeLegendItems(for stat: OARouteStatistics) -> [RoadAttributeLegendItem] {
        var seen = Set<String>()
        return stat.elements.compactMap { element in
            let key = element.getUserPropertyName() ?? element.propertyName ?? ""
            guard seen.insert(key).inserted, let segment = stat.partition[key] else { return nil }
            let title = localizedLegendTitle(for: segment, statName: stat.name)
            let distance = OAOsmAndFormatter.getFormattedDistance(segment.distance) ?? ""
            let color = UIColor(argbValue: UInt32(truncatingIfNeeded: segment.color))
            return RoadAttributeLegendItem(title: title, color: color, distance: distance)
        }
    }

    func localizedLegendTitle(for segment: OARouteSegmentAttribute, statName: String) -> String {
        let propertyName = segment.getUserPropertyName() ?? segment.propertyName ?? ""
        if statName == "routeInfo_steepness", propertyName != "undefined" {
            return propertyName
        }
        let localizedKey = "rendering_attr_\(propertyName)_name"
        let localizedTitle = localizedString(localizedKey)
        return localizedTitle == localizedKey ? propertyName : localizedTitle
    }

    func compactLegendRows(items: [RoadAttributeLegendItem], maxWidth: CGFloat) -> [[RoadAttributeLegendItem]] {
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let itemSpacing: CGFloat = 16
        return items.reduce(into: [[RoadAttributeLegendItem]]()) { rows, item in
            let itemWidth = compactLegendItemWidth(title: item.title, font: font)
            if var lastRow = rows.last {
                let lastRowWidth = rowWidth(for: lastRow, font: font, itemSpacing: itemSpacing)
                let newWidth = lastRowWidth + itemSpacing + itemWidth
                if newWidth <= maxWidth {
                    lastRow.append(item)
                    rows[rows.count - 1] = lastRow
                    return
                }
            }
            rows.append([item])
        }
    }

    func compactLegendItemWidth(title: String, font: UIFont) -> CGFloat {
        let dotWidth: CGFloat = 12
        let innerSpacing: CGFloat = 6
        let titleWidth = ceil((title as NSString).size(withAttributes: [.font: font]).width)
        return dotWidth + innerSpacing + titleWidth
    }

    func rowWidth(for items: [RoadAttributeLegendItem], font: UIFont, itemSpacing: CGFloat) -> CGFloat {
        let widths = items.map { compactLegendItemWidth(title: $0.title, font: font) }
        let totalWidths = widths.reduce(0, +)
        let totalSpacing = CGFloat(max(items.count - 1, 0)) * itemSpacing
        return totalWidths + totalSpacing
    }

    func toggleRoadAttribute(at index: Int) {
        if expandedStatIndexes.contains(index) {
            expandedStatIndexes.remove(index)
        } else {
            expandedStatIndexes.insert(index)
        }

        let section = IndexSet(integer: index + roadAttributesSectionStart)
        tableView.reloadSections(section, with: .automatic)
    }

    func buildSyntheticSteepnessStatistics(
        from analysis: GpxTrackAnalysis?,
        renderingCache: [String: (propertyName: String, color: Int)]? = nil
    ) -> OARouteStatistics? {
        guard let analysis else { return nil }
        let totalDistance = Double(analysis.totalDistance)
        guard totalDistance > 0 else { return nil }

        let elevationSamples = elevationSamples(for: analysis)
        guard elevationSamples.count > 1 else { return nil }

        let interpolator = GPXInterpolator(
            pointsCount: elevationSamples.count,
            totalLength: totalDistance,
            step: Self.steepnessDistanceStep,
            getX: { elevationSamples[$0].x },
            getY: { elevationSamples[$0].elevation }
        )
        interpolator.interpolate()

        let calculatedDistances = interpolator.getCalculatedX()
        let calculatedHeights = interpolator.getCalculatedY()
        guard !calculatedDistances.isEmpty, calculatedDistances.count == calculatedHeights.count else { return nil }

        let threshold = max(2, Int((Self.steepnessApproxDistance / Self.steepnessDistanceStep) / 2))
        guard calculatedDistances.count > threshold * 2 else { return nil }

        var minSlope = Int.max
        var maxSlope = Int.min
        var slopeClasses = [Int]()
        slopeClasses.reserveCapacity(calculatedDistances.count)

        for index in 0..<calculatedDistances.count {
            let slope: Double
            if index < threshold {
                slope = (-1.5 * calculatedHeights[index]
                    + 2.0 * calculatedHeights[index + 1]
                    - 0.5 * calculatedHeights[index + 2]) * 100 / Self.steepnessDistanceStep
            } else if index >= calculatedDistances.count - threshold {
                slope = (0.5 * calculatedHeights[index - 2]
                    - 2.0 * calculatedHeights[index - 1]
                    + 1.5 * calculatedHeights[index]) * 100 / Self.steepnessDistanceStep
            } else {
                slope = (calculatedHeights[index + threshold] - calculatedHeights[index - threshold]) * 100 / Self.steepnessApproxDistance
            }

            let normalizedSlope = slope.isNaN ? 0 : Int(slope)
            minSlope = min(minSlope, normalizedSlope)
            maxSlope = max(maxSlope, normalizedSlope)
            slopeClasses.append(steepnessClassIndex(for: normalizedSlope))
        }

        guard minSlope != Int.max, maxSlope != Int.min else { return nil }

        let classTitles = steepnessClassTitles(minSlope: minSlope, maxSlope: maxSlope)
        let syntheticSegments = syntheticSteepnessSegments(
            totalDistance: totalDistance,
            slopeClasses: slopeClasses
        )
        guard !syntheticSegments.isEmpty else { return nil }

        var elements = [OARouteSegmentAttribute]()
        var partition = [String: OARouteSegmentAttribute]()

        for segment in syntheticSegments {
            let title = classTitles[segment.classIndex]
            let boundaryClass = Self.steepnessBoundaryClasses[segment.classIndex]
            let rendering = renderingCache?[boundaryClass] ?? steepnessRendering(for: boundaryClass)
            let propertyName = rendering?.propertyName ?? boundaryClass
            let color = rendering?.color ?? Int(UIColor.lightGray.toARGBNumber())
            guard let attribute = OARouteSegmentAttribute(
                propertyName: propertyName,
                color: color,
                slopeIndex: segment.classIndex,
                boundariesClass: Self.steepnessBoundaryClasses
            ) else {
                continue
            }
            attribute.distance = Float(segment.distance)
            attribute.userPropertyName = title
            elements.append(attribute)

            if let existing = partition[title] {
                existing.distance += Float(segment.distance)
            } else {
                guard let aggregated = OARouteSegmentAttribute(segmentAttribute: attribute) else {
                    continue
                }
                aggregated.distance = Float(segment.distance)
                aggregated.userPropertyName = title
                partition[title] = aggregated
            }
        }

        guard !elements.isEmpty else { return nil }
        return OARouteStatistics(
            name: Self.steepnessAttributeName,
            elements: elements,
            partition: partition,
            totalDistance: Float(totalDistance)
        )
    }

    func buildFallbackSteepnessStatistics(from analysisData: PlanRouteAnalysisData) -> OARouteStatistics? {
        guard hasCompletedElevationCalculation || allowsTerrainFallbackSteepness, !hasOverviewData else { return nil }

        let totalDistance = max(Double(analysisData.gpxAnalysis?.totalDistance ?? 0), dataSource?.routeInfo.totalDistance ?? 0)
        return buildFlatSteepnessStatistics(totalDistance: totalDistance)
    }

    func buildFlatSteepnessStatistics(totalDistance: Double) -> OARouteStatistics? {
        guard totalDistance > 0 else { return nil }

        let classIndex = steepnessClassIndex(for: 0)
        let classTitles = steepnessClassTitles(minSlope: 0, maxSlope: 0)
        let title = classTitles[classIndex]
        let boundaryClass = Self.steepnessBoundaryClasses[classIndex]
        let rendering = steepnessRendering(for: boundaryClass)
        let propertyName = rendering?.propertyName ?? boundaryClass
        let color = rendering?.color ?? Int(UIColor.lightGray.toARGBNumber())

        guard let attribute = OARouteSegmentAttribute(
            propertyName: propertyName,
            color: color,
            slopeIndex: classIndex,
            boundariesClass: Self.steepnessBoundaryClasses
        ) else {
            return nil
        }

        attribute.distance = Float(totalDistance)
        attribute.userPropertyName = title

        guard let aggregated = OARouteSegmentAttribute(segmentAttribute: attribute) else { return nil }
        aggregated.distance = Float(totalDistance)
        aggregated.userPropertyName = title

        return OARouteStatistics(
            name: Self.steepnessAttributeName,
            elements: [attribute],
            partition: [title: aggregated],
            totalDistance: Float(totalDistance)
        )
    }

    func elevationSamples(for analysis: GpxTrackAnalysis) -> [(x: Double, elevation: Double)] {
        var samples: [(x: Double, elevation: Double)] = []
        var nextX = 0.0
        var previousElevation = -80000.0
        var previousNormalizedElevation = 0.0
        var index = -1
        let lastIndex = analysis.pointAttributes.count - 1
        var lastSample: (x: Double, elevation: Double)?
        var lastXSameY = -1.0
        var hasSameElevation = false

        for case let pointAttribute as OsmAndShared.PointAttributes in analysis.pointAttributes {
            index += 1
            let distance = Double(pointAttribute.distance)
            if distance < 0 {
                continue
            }

            nextX += distance
            if pointAttribute.elevation.isNaN {
                continue
            }

            let elevation = Double(pointAttribute.elevation)
            if previousElevation != -80000.0 {
                if previousElevation == elevation && index < lastIndex {
                    hasSameElevation = true
                    lastXSameY = nextX
                    continue
                }
                if previousNormalizedElevation == elevation && index < lastIndex {
                    hasSameElevation = true
                    lastXSameY = nextX
                    continue
                }
                if hasSameElevation, let lastSample {
                    samples.append((x: lastXSameY, elevation: lastSample.elevation))
                }
                hasSameElevation = false
            }

            previousElevation = elevation
            previousNormalizedElevation = elevation
            let sample = (x: nextX, elevation: elevation)
            lastSample = sample
            samples.append(sample)
        }

        return samples
    }

    func syntheticSteepnessSegments(totalDistance: Double, slopeClasses: [Int]) -> [SyntheticSteepnessSegment] {
        guard !slopeClasses.isEmpty else { return [] }

        var segments = [SyntheticSteepnessSegment]()
        for (index, slopeClass) in slopeClasses.enumerated() {
            let distance = index == 0
                ? max(totalDistance - Self.steepnessDistanceStep * Double(slopeClasses.count - 1), 0)
                : Self.steepnessDistanceStep
            guard distance > 0 else { continue }

            if let lastIndex = segments.indices.last, segments[lastIndex].classIndex == slopeClass {
                let lastSegment = segments[lastIndex]
                segments[lastIndex] = SyntheticSteepnessSegment(
                    classIndex: lastSegment.classIndex,
                    distance: lastSegment.distance + distance
                )
            } else {
                segments.append(SyntheticSteepnessSegment(classIndex: slopeClass, distance: distance))
            }
        }
        return segments
    }

    func steepnessClassIndex(for slope: Int) -> Int {
        for (index, boundaryValue) in Self.steepnessBoundaryValues.enumerated() where slope <= boundaryValue {
            return index
        }
        return Self.steepnessBoundaryValues.count - 1
    }

    func steepnessClassTitles(minSlope: Int, maxSlope: Int) -> [String] {
        var titles = Array(repeating: "", count: Self.steepnessBoundaryValues.count)
        titles[0] = slopeTitle(minSlope, Self.minDividedIncline)
        titles[1] = slopeTitle(minSlope, Self.minDividedIncline)

        guard Self.steepnessBoundaryValues.count > 3 else {
            titles[Self.steepnessBoundaryValues.count - 1] = slopeTitle(Self.maxDividedIncline, maxSlope)
            return titles
        }

        for index in 2..<(Self.steepnessBoundaryValues.count - 1) {
            titles[index] = slopeTitle(Self.steepnessBoundaryValues[index - 1], Self.steepnessBoundaryValues[index])
        }
        titles[Self.steepnessBoundaryValues.count - 1] = slopeTitle(Self.maxDividedIncline, maxSlope)
        return titles
    }

    func slopeTitle(_ from: Int, _ to: Int) -> String {
        let fromText = NumberFormatter.percentFormatter.string(from: (Double(from) / 100.0) as NSNumber) ?? "\(from)%"
        let toText = NumberFormatter.percentFormatter.string(from: (Double(to) / 100.0) as NSNumber) ?? "\(to)%"
        return "\(fromText) → \(toText)"
    }

    func steepnessRendering(for boundaryClass: String) -> (propertyName: String, color: Int)? {
        guard let mapViewController = OARootViewController.instance()?.mapPanel?.mapViewController else {
            return nil
        }
        let renderingAttributes = mapViewController.getRoadRenderingAttributes(
            Self.steepnessAttributeName,
            additionalSettings: ["additional": boundaryClass]
        )
        guard let propertyName = renderingAttributes.keys.first,
              let color = renderingAttributes[propertyName]?.intValue else {
            return nil
        }
        return (propertyName, color)
    }
}

private extension PlanRouteAnalyzeViewController {

    @objc func onRecalculateTapped() {
        showGetElevationSheet()
    }
}
