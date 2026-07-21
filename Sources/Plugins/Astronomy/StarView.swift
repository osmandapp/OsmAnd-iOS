//
//  StarView.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import OsmAndShared
import UIKit

protocol StarViewDelegate: AnyObject {
    func starView(_ starView: StarView, didSelect object: SkyObject?)
}

final class StarView: UIView {
    private struct CelestialPathData {
        let azimuths: [Double]
        let altitudes: [Double]
        let labels: [String?]
        let lastTime: Double
        let lastLat: Double
        let lastLon: Double
    }

    private struct ConstellationCenter {
        let ra: Double
        let dec: Double
        var azimuth: Double
        var altitude: Double
        var startAzimuth: Double = 0
        var startAltitude: Double = 0
        var targetAzimuth: Double
        var targetAltitude: Double
    }

    private struct FocusAnimation {
        let startAzimuth: Double
        let targetAzimuth: Double
        let startAltitude: Double
        let targetAltitude: Double
        let startRoll: Double
        let targetRoll: Double
        let startViewAngle: Double
        let targetViewAngle: Double
        let startPan: CGPoint
        let targetPan: CGPoint?
    }

    private enum ViewAngleBounds {
        static let min = 10.0
        static let max = 150.0
        static let max2D = 220.0
    }

    var isCameraMode = false
    var isGyroTrackingEnabled = false
    var onAnimationFinished: (() -> Void)?
    var onAzimuthManualChangeListener: ((Double) -> Void)?
    var onViewAngleChangeListener: ((Double) -> Void)?

    private(set) var panX: CGFloat = 0
    private(set) var panY: CGFloat = 0
    private(set) var centerAzimuth = 180.0
    private(set) var centerAltitude = 45.0
    private(set) var viewAngle = 60.0
    var roll = 0.0
    
    weak var delegate: StarViewDelegate?
    
    var viewModel: StarObjectsViewModel? {
        didSet {
            rebuildObjectMap()
            setNeedsDisplay()
        }
    }

    var settings = AstronomyPluginSettings() {
        didSet {
            if oldValue.starMap.is2DMode != settings.starMap.is2DMode {
                if settings.starMap.is2DMode {
                    roll = 0
                } else {
                    panX = 0
                    panY = 0
                }
            }
            updateRedFilter()
            setNeedsDisplay()
        }
    }

    var showAzimuthalGrid: Bool {
        get { settings.starMap.showAzimuthalGrid }
        set { settings.starMap.showAzimuthalGrid = newValue; setNeedsDisplay() }
    }

    var showEquatorialGrid: Bool {
        get { settings.starMap.showEquatorialGrid }
        set { settings.starMap.showEquatorialGrid = newValue; setNeedsDisplay() }
    }

    var showEclipticLine: Bool {
        get { settings.starMap.showEclipticLine }
        set { settings.starMap.showEclipticLine = newValue; setNeedsDisplay() }
    }

    var showMeridianLine: Bool {
        get { settings.starMap.showMeridianLine }
        set { settings.starMap.showMeridianLine = newValue; setNeedsDisplay() }
    }

    var showEquatorLine: Bool {
        get { settings.starMap.showEquatorLine }
        set { settings.starMap.showEquatorLine = newValue; setNeedsDisplay() }
    }

    var showGalacticLine: Bool {
        get { settings.starMap.showGalacticLine }
        set { settings.starMap.showGalacticLine = newValue; setNeedsDisplay() }
    }

    var showFavorites: Bool {
        get { settings.starMap.showFavorites }
        set { settings.starMap.showFavorites = newValue; setNeedsDisplay() }
    }

    var showDirections: Bool {
        get { settings.starMap.showDirections }
        set { settings.starMap.showDirections = newValue; setNeedsDisplay() }
    }

    var showCelestialPaths: Bool {
        get { settings.starMap.showCelestialPaths }
        set { settings.starMap.showCelestialPaths = newValue; setNeedsDisplay() }
    }

    var showRedFilter: Bool {
        get { settings.starMap.showRedFilter }
        set { settings.starMap.showRedFilter = newValue; updateRedFilter() }
    }

    var showStars: Bool {
        get { settings.starMap.showStars }
        set { settings.starMap.showStars = newValue; setNeedsDisplay() }
    }

    var showConstellations: Bool {
        get { settings.starMap.showConstellations }
        set { settings.starMap.showConstellations = newValue; setNeedsDisplay() }
    }

    var showGalaxies: Bool {
        get { settings.starMap.showGalaxies }
        set { settings.starMap.showGalaxies = newValue; setNeedsDisplay() }
    }

    var showBlackHoles: Bool {
        get { settings.starMap.showBlackHoles }
        set { settings.starMap.showBlackHoles = newValue; setNeedsDisplay() }
    }

    var showNebulae: Bool {
        get { settings.starMap.showNebulae }
        set { settings.starMap.showNebulae = newValue; setNeedsDisplay() }
    }

    var showOpenClusters: Bool {
        get { settings.starMap.showOpenClusters }
        set { settings.starMap.showOpenClusters = newValue; setNeedsDisplay() }
    }

    var showGlobularClusters: Bool {
        get { settings.starMap.showGlobularClusters }
        set { settings.starMap.showGlobularClusters = newValue; setNeedsDisplay() }
    }

    var showGalaxyClusters: Bool {
        get { settings.starMap.showGalaxyClusters }
        set { settings.starMap.showGalaxyClusters = newValue; setNeedsDisplay() }
    }

    var showSun: Bool {
        get { settings.starMap.showSun }
        set { settings.starMap.showSun = newValue; setNeedsDisplay() }
    }

    var showMoon: Bool {
        get { settings.starMap.showMoon }
        set { settings.starMap.showMoon = newValue; setNeedsDisplay() }
    }

    var showPlanets: Bool {
        get { settings.starMap.showPlanets }
        set { settings.starMap.showPlanets = newValue; setNeedsDisplay() }
    }

    var magnitudeFilter: Double? {
        get { settings.starMap.magnitudeFilter }
        set { settings.starMap.magnitudeFilter = newValue; setNeedsDisplay() }
    }

    var showMagnitudeFilter: Bool {
        get { settings.starMap.showMagnitudeFilter }
        set { settings.starMap.showMagnitudeFilter = newValue; setNeedsDisplay() }
    }

    var is2DMode: Bool {
        get { settings.starMap.is2DMode }
        set { settings.starMap.is2DMode = newValue; setNeedsDisplay() }
    }
    
    var currentTime: Time {
        get {
            explicitCurrentTime ?? AstroUtils.astronomyTime(from: Date())
        }
        set {
            explicitCurrentTime = newValue
        }
    }

    var observer: Observer {
        get {
            explicitObserver ?? AstroUtils.observer(from: nil)
        }
        set {
            explicitObserver = newValue
        }
    }

    private var skyObjects: [SkyObject] {
        (manualSkyObjects ?? viewModel?.skyObjects ?? [])
            .filter { $0.type != .CONSTELLATION }
            .sorted { $0.magnitude < $1.magnitude }
    }

    private var constellations: [Constellation] {
        manualConstellations ?? viewModel?.constellations ?? []
    }

    private var trackableObjects: [SkyObject] {
        skyObjects + constellations.map { $0 as SkyObject }
    }

    private var screenScale: CGFloat {
        window?.screen.scale ?? UIScreen.main.scale
    }
    
    private let timeAnimationDuration: CFTimeInterval = 0.4
    private let focusAnimationDuration: CFTimeInterval = 0.5
    private let eclipticStep = 10
    private let equatorStep = 2
    private let galacticStep = 5
    private let inertialDecelerationRate: CGFloat = 0.998
    private let inertialStopSpeed: CGFloat = 5
    private let inertialMinStartSpeed: CGFloat = 80
    private let gyroSnapBackDelay: TimeInterval = 0.5

    private var lastTouchPoint = CGPoint.zero
    private var isPanning = false

    private var projectionSinAltCenter = 0.0
    private var projectionCosAltCenter = 1.0
    private var projectionScale = 1.0
    private var projectionHalfWidth = 0.0
    private var projectionHalfHeight = 0.0
    private var minCosCVisible = -1.0

    private var skyObjectMap: [String: SkyObject] = [:]
    private var occupiedRects: [CGRect] = []
    private var pathCache: [String: CelestialPathData] = [:]
    private var selectedConstellationId: String?
    private var selectedObject: SkyObject?
    private var selectedConstellationStarIds = Set<Int>()
    private var pinnedObjects = Set<SkyObject>()
    private var manualSkyObjects: [SkyObject]?
    private var manualConstellations: [Constellation]?
    private var constellationCenterCache: [String: ConstellationCenter] = [:]
    private var maxViewAngle: Double {
        settings.starMap.is2DMode ? ViewAngleBounds.max2D : ViewAngleBounds.max
    }
    private var explicitCurrentTime: Time?
    private var explicitObserver: Observer?
    private var timeAnimationDisplayLink: CADisplayLink?
    private var timeAnimationStartTime: CFTimeInterval = 0
    private var focusAnimationDisplayLink: CADisplayLink?
    private var focusAnimationStartTime: CFTimeInterval = 0
    private var focusAnimation: FocusAnimation?
    private var onObjectClickListener: ((SkyObject?) -> Void)?
    private var onConstellationClickListener: ((Constellation?) -> Void)?

    private var eclipticAzimuths: [Double] = []
    private var eclipticAltitudes: [Double] = []
    private var lastEclipticTimeT = -1.0
    private var lastEclipticLat = -999.0
    private var lastEclipticLon = -999.0
    
    private var equatorAzimuths: [Double] = []
    private var equatorAltitudes: [Double] = []
    private var lastEquatorTimeT = -1.0
    private var lastEquatorLat = -999.0
    private var lastEquatorLon = -999.0

    private var galacticAzimuths: [Double] = []
    private var galacticAltitudes: [Double] = []
    private var lastGalacticTimeT = -1.0
    private var lastGalacticLat = -999.0
    private var lastGalacticLon = -999.0

    private var gridDensityLevel = -1
    private var equRaStepMin = 120
    private var equDecStep = 20
    private var equLineResStep = 5
    private var equRaAzimuths: [[Double]] = []
    private var equRaAltitudes: [[Double]] = []
    private var equDecAzimuths: [[Double]] = []
    private var equDecAltitudes: [[Double]] = []
    private var lastEquGridTimeT = -1.0
    private var lastEquGridLat = -999.0
    private var lastEquGridLon = -999.0
    
    private var inertialDisplayLink: CADisplayLink?
    private var inertialVelocity: CGPoint = .zero
    private var lastInertialTimestamp: CFTimeInterval = 0
    private var didPanThisGesture = false
    
    private var gyroTargetAzimuth = 0.0
    private var gyroTargetAltitude = 45.0
    private var gyroTargetRoll = 0.0
    private var isGyroPanOverride = false
    private var gyroSnapBackWorkItem: DispatchWorkItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        updateProjectionCache()
        rebuildObjectMap()
        occupiedRects.removeAll(keepingCapacity: true)

        context.saveGState()
        drawBackground(in: context)
        if settings.starMap.showEquatorialGrid {
            drawEquatorialGrid(in: context)
        }
        if settings.starMap.showAzimuthalGrid {
            drawAzimuthalGrid(in: context)
        }
        if settings.starMap.showEclipticLine {
            drawEclipticLine(in: context)
        }
        if settings.starMap.showMeridianLine {
            drawMeridianLine(in: context)
        }
        if settings.starMap.showEquatorLine {
            drawEquatorLine(in: context)
        }
        if settings.starMap.showGalacticLine {
            drawGalacticLine(in: context)
        }
        drawConstellationLines(in: context)
        drawHorizon(in: context)
        drawCelestialPaths(in: context)
        drawConstellationLabels(in: context)
        drawSkyObjects(in: context)
        drawHighlights(in: context)
        drawDirectionArrows(in: context)

        context.restoreGState()
    }
    
    func restoreMapPosition(_ position: AstronomyPluginSettings.MapViewPosition) {
        setCenter(azimuth: position.azimuth, altitude: position.altitude)
        setViewAngle(position.viewAngle)
        roll = position.roll
        panX = CGFloat(position.panX)
        panY = CGFloat(position.panY)
        notifyAzimuthChanged()
        setNeedsDisplay()
    }

    func resetView() {
        cancelFocusAnimation()
        centerAzimuth = 180
        centerAltitude = 45
        viewAngle = 60
        roll = 0
        panX = 0
        panY = 0
        setNeedsDisplay()
    }

    func setObserverLocation(lat: Double, lon: Double, alt: Double) {
        let previousObserver = observer
        observer = Observer(latitude: lat, longitude: lon, height: alt)
        if previousObserver.latitude != lat ||
            previousObserver.longitude != lon ||
            previousObserver.height != alt {
            pathCache.removeAll()
        }
        recalculatePositions(time: currentTime, updateTargets: false, force: true)
        setNeedsDisplay()
    }

    func setCameraOrientation(azimuth: Double, altitude: Double, roll: Double) {
        gyroTargetAzimuth = azimuth
        gyroTargetAltitude = altitude
        gyroTargetRoll = roll
        
        guard !isGyroPanOverride else { return }
        
        setCenter(azimuth: azimuth, altitude: altitude)
        self.roll = roll
        setNeedsDisplay()
        notifyAzimuthChanged()
    }

    func setCenter(azimuth: Double, altitude: Double, animate: Bool = false) {
        if animate {
            animateTo(azimuth: azimuth, altitude: altitude)
            return
        }
        cancelFocusAnimation()
        centerAzimuth = normalizedDegrees(azimuth)
        centerAltitude = max(-90, min(90, altitude))
        setNeedsDisplay()
    }
    
    func altitude() -> Double {
        centerAltitude
    }

    func azimuth() -> Double {
        centerAzimuth
    }

    func viewAngleValue() -> Double {
        viewAngle
    }

    func setAzimuth(_ azimuth: Double, animate: Bool = false, fps: Int? = 30) {
        guard abs(centerAzimuth - azimuth) >= 0.5 else {
            return
        }
        if animate {
            animateTo(azimuth: azimuth, altitude: centerAltitude)
        } else {
            cancelFocusAnimation()
            centerAzimuth = normalizedDegrees(azimuth)
            setNeedsDisplay()
        }
        notifyAzimuthChanged()
    }

    func setSkyObjects(_ objects: [SkyObject]) {
        manualSkyObjects = objects.sorted { $0.magnitude < $1.magnitude }
        rebuildObjectMap()
        rebuildConstellationCenterCache()
        recalculatePositions(time: currentTime, updateTargets: false, force: true)
        let celestialPathObjects = Set(objects.filter { $0.showCelestialPath })
        let staleObjects = pinnedObjects.filter { !($0 is Constellation) && !celestialPathObjects.contains($0) }
        pinnedObjects.subtract(staleObjects)
        for object in staleObjects {
            pathCache.removeValue(forKey: object.id)
        }
        pinnedObjects.formUnion(celestialPathObjects)
        setNeedsDisplay()
    }

    func setConstellations(_ list: [Constellation]) {
        manualConstellations = list
        rebuildObjectMap()
        rebuildConstellationCenterCache()
        recalculatePositions(time: currentTime, updateTargets: false, force: true)
        let celestialPathConstellations = Set<SkyObject>(list.filter { $0.showCelestialPath }.map { $0 as SkyObject })
        let staleConstellations = pinnedObjects.filter { $0 is Constellation && !celestialPathConstellations.contains($0) }
        pinnedObjects.subtract(staleConstellations)
        for constellation in staleConstellations {
            pathCache.removeValue(forKey: constellation.id)
        }
        pinnedObjects.formUnion(celestialPathConstellations)
        setNeedsDisplay()
    }

    func refreshObjects() {
        recalculatePositions(time: currentTime, updateTargets: false)
        setNeedsDisplay()
    }

    func updateRedFilter() {
        AstroRedFilter.apply(settings.starMap.showRedFilter, to: self)
        setNeedsDisplay()
    }

    func setOnObjectClickListener(_ listener: @escaping (SkyObject?) -> Void) {
        onObjectClickListener = listener
    }

    func setOnConstellationClickListener(_ listener: @escaping (Constellation?) -> Void) {
        onConstellationClickListener = listener
    }

    func selectedConstellationItem() -> Constellation? {
        guard let selectedConstellationId else {
            return nil
        }
        return constellations.first { $0.id == selectedConstellationId }
    }

    func setSelectedObject(_ object: SkyObject?, center: Bool = false, animate: Bool = false) {
        if let constellation = object as? Constellation {
            setSelectedConstellation(constellation, center: center, animate: animate)
            return
        }
        selectedConstellationId = nil
        selectedConstellationStarIds.removeAll()
        selectedObject = object
        if let object {
            if object.azimuth == 0 && object.altitude == 0 {
                calculatePosition(object)
            }
            if center {
                setCenter(azimuth: object.azimuth, altitude: object.altitude, animate: animate)
            }
        }
        setNeedsDisplay()
    }

    func setSelectedObject(_ object: SkyObject?, centerAt targetPoint: CGPoint, animate: Bool = false) {
        if let constellation = object as? Constellation {
            setSelectedConstellation(constellation, centerAt: targetPoint, animate: animate)
            return
        }
        selectedConstellationId = nil
        selectedConstellationStarIds.removeAll()
        selectedObject = object
        if let object {
            if object.azimuth == 0 && object.altitude == 0 {
                calculatePosition(object)
            }
            setCenter(azimuth: object.azimuth, altitude: object.altitude, at: targetPoint, animate: animate)
        }
        setNeedsDisplay()
    }

    func setSelectedConstellation(_ constellation: Constellation?, center: Bool = false, animate: Bool = false) {
        selectedConstellationId = constellation?.id
        selectedObject = constellation
        selectedConstellationStarIds.removeAll()
        for (first, second) in constellation?.lines ?? [] {
            selectedConstellationStarIds.insert(first)
            selectedConstellationStarIds.insert(second)
        }
        for object in skyObjects where selectedConstellationStarIds.contains(object.hip) {
            calculatePosition(object, time: currentTime, updateTargets: false)
            object.azimuth = object.targetAzimuth
            object.altitude = object.targetAltitude
        }
        if let constellation, center {
            let centers = constellationCenters()
            if let center = centers[constellation.id] {
                let targetAngle = targetViewAngle(for: constellation, center: center)
                if animate {
                    animateTo(azimuth: center.azimuth, altitude: center.altitude, targetViewAngle: targetAngle)
                } else {
                    setCenter(azimuth: center.azimuth, altitude: center.altitude)
                    setViewAngle(targetAngle)
                }
            }
        }
        setNeedsDisplay()
    }

    func setSelectedConstellation(_ constellation: Constellation?, centerAt targetPoint: CGPoint, animate: Bool = false) {
        selectedConstellationId = constellation?.id
        selectedObject = constellation
        selectedConstellationStarIds.removeAll()
        for (first, second) in constellation?.lines ?? [] {
            selectedConstellationStarIds.insert(first)
            selectedConstellationStarIds.insert(second)
        }
        for object in skyObjects where selectedConstellationStarIds.contains(object.hip) {
            calculatePosition(object, time: currentTime, updateTargets: false)
            object.azimuth = object.targetAzimuth
            object.altitude = object.targetAltitude
        }
        if let constellation {
            let centers = constellationCenters()
            if let center = centers[constellation.id] {
                setCenter(azimuth: center.azimuth,
                          altitude: center.altitude,
                          at: targetPoint,
                          animate: animate,
                          targetViewAngle: targetViewAngle(for: constellation, center: center))
            }
        }
        setNeedsDisplay()
    }
    
    func isObjectPinned(_ object: SkyObject) -> Bool {
        pinnedObjects.contains(object)
    }

    func setObjectPinned(_ object: SkyObject, pinned: Bool, forceUpdate: Bool = false) {
        if pinned {
            pinnedObjects.insert(object)
        } else {
            pinnedObjects.remove(object)
            pathCache.removeValue(forKey: object.id)
        }
        if forceUpdate {
            setNeedsDisplay()
        }
    }

    func setDateTime(_ time: Time, animate: Bool = true) {
        timeAnimationDisplayLink?.invalidate()
        timeAnimationDisplayLink = nil

        if animate {
            for object in skyObjects {
                object.startAzimuth = object.azimuth
                object.startAltitude = object.altitude
            }
            captureConstellationAnimationStarts()
            recalculatePositions(time: time, updateTargets: true, force: true)
            currentTime = time
            timeAnimationStartTime = CACurrentMediaTime()
            let displayLink = CADisplayLink(target: self, selector: #selector(handleTimeAnimationFrame(_:)))
            timeAnimationDisplayLink = displayLink
            displayLink.add(to: .main, forMode: .common)
        } else {
            currentTime = time
            recalculatePositions(time: time, updateTargets: true, force: true)
            for object in skyObjects {
                object.azimuth = object.targetAzimuth
                object.altitude = object.targetAltitude
            }
            var updatedCenters = constellationCenterCache
            for (id, center) in constellationCenterCache {
                var updated = center
                updated.azimuth = center.targetAzimuth
                updated.altitude = center.targetAltitude
                updatedCenters[id] = updated
            }
            constellationCenterCache = updatedCenters
            updateConstellationObjectPositions()
            setNeedsDisplay()
            onAnimationFinished?()
        }
    }
    
    func setViewAngle(_ angle: Double) {
        updateViewAngle(angle)
    }

    func zoomIn() {
        updateViewAngle(viewAngle / 1.5)
    }

    func zoomOut() {
        updateViewAngle(viewAngle * 1.5)
    }
    
    func canZoomIn() -> Bool {
        viewAngle > ViewAngleBounds.min + 0.5
    }
    
    func canZoomOut() -> Bool {
        viewAngle < maxViewAngle - 0.5
    }

    func project(object: SkyObject) -> CGPoint? {
        updateProjectionCache()
        return skyToScreen(azimuth: object.azimuth, altitude: object.altitude)
    }
    
    func calculatePosition(_ object: SkyObject) {
        calculatePosition(object, time: currentTime, updateTargets: false)
    }
    
    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    private func setCenter(azimuth: Double,
                           altitude: Double,
                           at targetPoint: CGPoint,
                           animate: Bool = false,
                           targetViewAngle: Double? = nil) {
        guard bounds.width > 0, bounds.height > 0 else {
            if animate {
                animateTo(azimuth: azimuth, altitude: altitude, targetViewAngle: targetViewAngle)
            } else {
                setCenterState(azimuth: azimuth, altitude: altitude, targetViewAngle: targetViewAngle)
            }
            return
        }

        let finalViewAngle = boundedViewAngle(targetViewAngle ?? viewAngle)
        if settings.starMap.is2DMode {
            let targetPan = CGPoint(x: targetPoint.x - bounds.midX,
                                    y: targetPoint.y - bounds.midY)
            if animate {
                animateTo(azimuth: azimuth,
                          altitude: altitude,
                          targetViewAngle: targetViewAngle,
                          targetPan: targetPan)
            } else {
                setCenterState(azimuth: azimuth, altitude: altitude, targetViewAngle: targetViewAngle)
                panX = targetPan.x
                panY = targetPan.y
                setNeedsDisplay()
            }
            return
        }

        let screenOffsetX = Double(targetPoint.x - bounds.midX)
        let screenOffsetY = Double(targetPoint.y - bounds.midY)
        let rollRad = roll * .pi / 180.0
        let unrotatedX = screenOffsetX * cos(rollRad) + screenOffsetY * sin(rollRad)
        let unrotatedY = -screenOffsetX * sin(rollRad) + screenOffsetY * cos(rollRad)
        let scale = finalViewAngle / Double(max(bounds.width, 1))
        let targetAzimuth = normalizedDegrees(azimuth - unrotatedX * scale)
        let targetAltitude = max(-90, min(90, altitude + unrotatedY * scale))
        if animate {
            animateTo(azimuth: targetAzimuth, altitude: targetAltitude, targetViewAngle: targetViewAngle)
        } else {
            setCenterState(azimuth: targetAzimuth, altitude: targetAltitude, targetViewAngle: targetViewAngle)
        }
    }

    private func setCenterState(azimuth: Double, altitude: Double, targetViewAngle: Double? = nil) {
        cancelFocusAnimation()
        centerAzimuth = normalizedDegrees(azimuth)
        centerAltitude = max(-90, min(90, altitude))
        if let targetViewAngle {
            viewAngle = boundedViewAngle(targetViewAngle)
            onViewAngleChangeListener?(viewAngle)
        }
        setNeedsDisplay()
    }

    private func boundedViewAngle(_ angle: Double) -> Double {
        max(ViewAngleBounds.min, min(maxViewAngle, angle))
    }

    private func animateTo(azimuth: Double,
                           altitude: Double,
                           targetViewAngle: Double? = nil,
                           targetPan: CGPoint? = nil,
                           targetRoll: Double? = nil) {
        cancelFocusAnimation()
        focusAnimation = FocusAnimation(startAzimuth: centerAzimuth,
                                        targetAzimuth: normalizedDegrees(azimuth),
                                        startAltitude: centerAltitude,
                                        targetAltitude: max(-90, min(90, altitude)),
                                        startRoll: roll,
                                        targetRoll: targetRoll ?? roll,
                                        startViewAngle: viewAngle,
                                        targetViewAngle: targetViewAngle.map { boundedViewAngle($0) } ?? viewAngle,
                                        startPan: CGPoint(x: panX, y: panY),
                                        targetPan: targetPan)
        focusAnimationStartTime = CACurrentMediaTime()
        let displayLink = CADisplayLink(target: self, selector: #selector(handleFocusAnimationFrame(_:)))
        focusAnimationDisplayLink = displayLink
        displayLink.add(to: .main, forMode: .common)
    }

    private func cancelFocusAnimation() {
        focusAnimationDisplayLink?.invalidate()
        focusAnimationDisplayLink = nil
        focusAnimation = nil
        
        cancelInertialScroll()
    }
    
    private func cancelGyroSnapBack() {
        gyroSnapBackWorkItem?.cancel()
        gyroSnapBackWorkItem = nil
        cancelFocusAnimation()
    }

    private func scheduleGyroSnapBack() {
        cancelGyroSnapBack()
        isGyroPanOverride = true

        let work = DispatchWorkItem { [weak self] in
            self?.animateSnapBackToGyro()
        }
        gyroSnapBackWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + gyroSnapBackDelay, execute: work)
    }

    private func animateSnapBackToGyro() {
        gyroSnapBackWorkItem = nil
        animateTo(azimuth: gyroTargetAzimuth,
                  altitude: gyroTargetAltitude,
                  targetRoll: gyroTargetRoll)
    }

    @objc private func handleFocusAnimationFrame(_ displayLink: CADisplayLink) {
        guard let animation = focusAnimation else {
            cancelFocusAnimation()
            return
        }

        let rawFraction = min(1.0, max(0.0, (displayLink.timestamp - focusAnimationStartTime) / focusAnimationDuration))
        let fraction = 1.0 - pow(1.0 - rawFraction, 2.0)
        applyFocusAnimation(animation, fraction: fraction)
        if rawFraction >= 1 {
            applyFocusAnimation(animation, fraction: 1)
            isGyroPanOverride = false
            cancelFocusAnimation()
            onAnimationFinished?()
        }
    }

    private func applyFocusAnimation(_ animation: FocusAnimation, fraction: Double) {
        centerAzimuth = interpolateAngle(start: animation.startAzimuth, end: animation.targetAzimuth, fraction: fraction)
        centerAltitude = animation.startAltitude + (animation.targetAltitude - animation.startAltitude) * fraction
        roll = animation.startRoll + (animation.targetRoll - animation.startRoll) * fraction
        viewAngle = animation.startViewAngle + (animation.targetViewAngle - animation.startViewAngle) * fraction
        if let targetPan = animation.targetPan {
            let cgFraction = CGFloat(fraction)
            panX = animation.startPan.x + (targetPan.x - animation.startPan.x) * cgFraction
            panY = animation.startPan.y + (targetPan.y - animation.startPan.y) * cgFraction
        }
        if abs(animation.targetViewAngle - animation.startViewAngle) > 0.001 {
            onViewAngleChangeListener?(viewAngle)
        }
        setNeedsDisplay()
        notifyAzimuthChanged()
    }

    private func targetViewAngle(for constellation: Constellation, center: ConstellationCenter) -> Double {
        var maxDistance = 0.0
        var uniqueStars = Set<Int>()
        for (first, second) in constellation.lines {
            uniqueStars.insert(first)
            uniqueStars.insert(second)
        }
        for id in uniqueStars {
            guard let star = skyObjectMap[String(id)] else {
                continue
            }
            maxDistance = max(maxDistance, angularDistance(ra1: center.ra, dec1: center.dec, ra2: star.ra, dec2: star.dec))
        }
        return maxDistance > 0 ? max(20, min(120, maxDistance * 3.5)) : viewAngle
    }

    private func captureConstellationAnimationStarts() {
        var updatedCenters = constellationCenterCache
        for (id, center) in constellationCenterCache {
            var updated = center
            updated.startAzimuth = center.azimuth
            updated.startAltitude = center.altitude
            updatedCenters[id] = updated
        }
        constellationCenterCache = updatedCenters
    }

    @objc private func handleTimeAnimationFrame(_ displayLink: CADisplayLink) {
        let rawFraction = min(1.0, max(0.0, (displayLink.timestamp - timeAnimationStartTime) / timeAnimationDuration))
        let fraction = 1.0 - pow(1.0 - rawFraction, 2.0)
        for object in skyObjects {
            object.azimuth = interpolateAngle(start: object.startAzimuth, end: object.targetAzimuth, fraction: fraction)
            object.altitude = object.startAltitude + (object.targetAltitude - object.startAltitude) * fraction
        }
        var updatedCenters = constellationCenterCache
        for (id, center) in constellationCenterCache {
            var updated = center
            updated.azimuth = interpolateAngle(start: center.startAzimuth, end: center.targetAzimuth, fraction: fraction)
            updated.altitude = center.startAltitude + (center.targetAltitude - center.startAltitude) * fraction
            updatedCenters[id] = updated
        }
        constellationCenterCache = updatedCenters
        updateConstellationObjectPositions()
        setNeedsDisplay()

        if rawFraction >= 1 {
            displayLink.invalidate()
            timeAnimationDisplayLink = nil
            onAnimationFinished?()
        }
    }
    
    private func notifyAzimuthChanged() {
        onAzimuthManualChangeListener?(centerAzimuth)
    }

    private func rebuildObjectMap() {
        skyObjectMap.removeAll(keepingCapacity: true)
        for object in (manualSkyObjects ?? viewModel?.skyObjects ?? []) {
            skyObjectMap[object.id] = object
            if !object.wid.isEmpty {
                skyObjectMap[object.wid] = object
            }
            let hip = object.hip
            if hip > 0 {
                skyObjectMap[String(hip)] = object
            }
        }
    }

    private func drawBackground(in context: CGContext) {
        if isCameraMode {
            context.clear(bounds)
            UIColor.mapBgZenith.withAlphaComponent(0.20).setFill()
        } else {
            UIColor.mapBgZenith.setFill()
        }
        context.fill(bounds)
    }

    private func drawSkyObjects(in context: CGContext) {
        for object in skyObjects {
            if isObjectVisibleInSettings(object) || object === selectedObject {
                drawSkyObject(object, in: context)
            }
        }
    }

    private func drawSkyObject(_ object: SkyObject, in context: CGContext) {
        guard let point = skyToScreen(azimuth: object.azimuth, altitude: object.altitude),
              bounds.insetBy(dx: -30, dy: -30).contains(point) else {
            return
        }

        let zoomFactor = max(0, min(1, (viewAngle - ViewAngleBounds.min) / (maxViewAngle - ViewAngleBounds.min)))
        var color = object.color
        var baseSize: CGFloat = 15
        if object.type == .STAR && zoomFactor > 0.3 && object.magnitude > 2.5 {
            baseSize = 8
            color = .starDotDimmed
        }

        var radius = max(2, baseSize - CGFloat(object.magnitude) * 2)
        if object.type == .STAR && zoomFactor > 0.5 {
            radius *= 0.7
        }
        if object.type == .SUN || object.type == .MOON {
            radius *= 0.5
        }
        radius = pixelsToPoints(radius)

        color.setFill()
        context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        let objectRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)

        guard shouldShowLabel(for: object, zoomFactor: zoomFactor) else {
            occupiedRects.append(objectRect)
            return
        }

        let text = object.getDisplayName()
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: labelColor(for: object)
        ]
        let size = text.size(withAttributes: attributes)
        let origin = CGPoint(x: point.x + radius + 6, y: point.y - size.height * 0.5)
        let labelPadding = pixelsToPoints(5)
        let labelRect = CGRect(origin: origin, size: size).insetBy(dx: -labelPadding, dy: -labelPadding)
        let overlaps = occupiedRects.contains { $0.intersects(labelRect) }
        if !overlaps || object === selectedObject || object.showCelestialPath {
            text.draw(at: origin, withAttributes: attributes)
            occupiedRects.append(labelRect)
            occupiedRects.append(objectRect)
        }
    }

    private func shouldShowLabel(for object: SkyObject, zoomFactor: Double) -> Bool {
        if object === selectedObject || (settings.starMap.showCelestialPaths && object.showCelestialPath) {
            return true
        }
        if object.type == .STAR {
            if object.getDisplayName().lowercased().hasPrefix("hip") {
                return false
            }
            let threshold = 5.0 - zoomFactor * 3.5
            return object.magnitude <= threshold
        }
        return true
    }

    private func labelColor(for object: SkyObject) -> UIColor {
        if object === selectedObject {
            return .mapTextSelected
        }
        if settings.starMap.showCelestialPaths && object.showCelestialPath {
            return .mapObjectPath
        }
        return .mapTextPrimary
    }

    private func drawHighlights(in context: CGContext) {
        if settings.starMap.showCelestialPaths {
            for object in pinnedObjects where isObjectVisibleInSettings(object) || object === selectedObject {
                if let point = skyToScreen(azimuth: object.azimuth, altitude: object.altitude) {
                    strokeCircle(at: point, radius: pixelsToPoints(25), color: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1), width: pixelsToPoints(4), in: context)
                }
            }
        }

        if let object = selectedObject,
           let point = skyToScreen(azimuth: object.azimuth, altitude: object.altitude) {
            strokeCircle(at: point, radius: pixelsToPoints(25), color: .mapTextSelected, width: pixelsToPoints(3), in: context)
        }

        if settings.starMap.showDirections {
            for object in trackableObjects where object.showDirection && isObjectVisibleInSettings(object) {
                if let point = skyToScreen(azimuth: object.azimuth, altitude: object.altitude) {
                    strokeCircle(at: point, radius: pixelsToPoints(26), color: directionColor(object.colorIndex), width: pixelsToPoints(3), in: context)
                }
            }
        }
    }

    private func pixelsToPoints(_ pixels: CGFloat) -> CGFloat {
        pixels / max(1, screenScale)
    }

    private func strokeCircle(at point: CGPoint, radius: CGFloat, color: UIColor, width: CGFloat, in context: CGContext) {
        color.setStroke()
        context.setLineWidth(width)
        context.strokeEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }

    private func drawHorizon(in context: CGContext) {
        let path = CGMutablePath()
        appendSkyLine(to: path, range: stride(from: 0.0, through: 360.0, by: 2.0)) { azimuth in
            (azimuth, 0.0)
        }
        stroke(path, color: .mapLineHorizon, width: 1.2, in: context)

        drawOutsideLabel("N", azimuth: 0, altitude: 0, color: .mapLineHorizon, offset: 30, in: context)
        drawOutsideLabel("E", azimuth: 90, altitude: 0, color: .mapLineHorizon, offset: 30, in: context)
        drawOutsideLabel("S", azimuth: 180, altitude: 0, color: .mapLineHorizon, offset: 30, in: context)
        drawOutsideLabel("W", azimuth: 270, altitude: 0, color: .mapLineHorizon, offset: 30, in: context)
    }

    private func drawAzimuthalGrid(in context: CGContext) {
        let density: (azStep: Int, altStep: Int, lineStep: Int)
        if viewAngle < 20 {
            density = (10, 5, 1)
        } else if viewAngle < 50 {
            density = (15, 10, 2)
        } else {
            density = (45, 20, 5)
        }

        let path = CGMutablePath()
        var altitudeLabels: [(String, Double, Double)] = []
        var azimuthLabels: [(String, Double)] = []
        
        for altitude in stride(from: -80, through: 80, by: density.altStep) {
            appendSkyLine(to: path, range: stride(from: 0.0, through: 360.0, by: Double(density.lineStep))) { azimuth in
                (azimuth, Double(altitude))
            }
            if altitude != 0 {
                altitudeLabels.append(("\(altitude)°", centerAzimuth, Double(altitude)))
                altitudeLabels.append(("\(altitude)°", centerAzimuth + 180, Double(altitude)))
            }
        }

        for azimuth in stride(from: 0, to: 360, by: density.azStep) {
            appendSkyLine(to: path, range: stride(from: -90.0, through: 90.0, by: Double(density.lineStep))) { altitude in
                (Double(azimuth), altitude)
            }
            if !azimuth.isMultiple(of: 90) {
                azimuthLabels.append(("\(azimuth)°", Double(azimuth)))
            }
        }
        stroke(path, color: .mapGridSecondary, width: 2.0, in: context)
        
        let labelColor = UIColor.mapGridSecondaryText
        
        for (label, az, alt) in altitudeLabels {
            drawGridLabel(label, azimuth: az, altitude: alt, align: .left, color: labelColor, in: context)
        }
        for (label, az) in azimuthLabels {
            drawOutsideLabel(label, azimuth: az, altitude: 0, color: labelColor, offset: 25, in: context)
        }
    }

    private func updateEquatorialGridCache() {
        let newLevel: Int
        if viewAngle < 20 {
            newLevel = 2
        } else if viewAngle < 50 {
            newLevel = 1
        } else {
            newLevel = 0
        }

        if newLevel != gridDensityLevel {
            gridDensityLevel = newLevel
            lastEquGridTimeT = -1
            switch newLevel {
            case 2:
                equRaStepMin = 20
                equDecStep = 5
                equLineResStep = 1
            case 1:
                equRaStepMin = 60
                equDecStep = 10
                equLineResStep = 2
            default:
                equRaStepMin = 120
                equDecStep = 20
                equLineResStep = 5
            }
        }

        let time = currentTime
        let obs = observer
        guard abs(time.tt - lastEquGridTimeT) >= 0.0000001 ||
              obs.latitude != lastEquGridLat ||
              obs.longitude != lastEquGridLon else {
            return
        }

        let raLinesCount = (24 * 60) / equRaStepMin
        let raPointsCount = (180 / equLineResStep) + 1
        equRaAzimuths = Array(repeating: Array(repeating: 0, count: raPointsCount), count: raLinesCount)
        equRaAltitudes = equRaAzimuths
        for i in 0..<raLinesCount {
            let ra = Double(i * equRaStepMin) / 60.0
            for j in 0..<raPointsCount {
                let dec = -90.0 + Double(j * equLineResStep)
                let hor = AstronomyKt.horizon(time: time, observer: obs, ra: ra, dec: dec, refraction: Refraction.normal)
                equRaAzimuths[i][j] = hor.azimuth
                equRaAltitudes[i][j] = hor.altitude
            }
        }

        let decLinesCount = (160 / equDecStep) + 1
        let decPointsCount = (360 / equLineResStep) + 1
        equDecAzimuths = Array(repeating: Array(repeating: 0, count: decPointsCount), count: decLinesCount)
        equDecAltitudes = equDecAzimuths
        for i in 0..<decLinesCount {
            let dec = -80.0 + Double(i * equDecStep)
            for j in 0..<decPointsCount {
                let ra = Double(j * equLineResStep) / 15.0
                let hor = AstronomyKt.horizon(time: time, observer: obs, ra: ra, dec: dec, refraction: Refraction.normal)
                equDecAzimuths[i][j] = hor.azimuth
                equDecAltitudes[i][j] = hor.altitude
            }
        }

        lastEquGridTimeT = time.tt
        lastEquGridLat = obs.latitude
        lastEquGridLon = obs.longitude
    }

    private func drawEquatorialGrid(in context: CGContext) {
        updateEquatorialGridCache()
        let path = CGMutablePath()
        var bestRaIndex = -1
        var minCenterDistSq = CGFloat.greatestFiniteMagnitude
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        var raLabels: [(String, CGPoint)] = []
        var decLabels: [(String, Double, Double)] = []

        for i in 0..<equRaAzimuths.count {
            var first = true
            var currentLineMinDistSq = CGFloat.greatestFiniteMagnitude
            for j in 0..<equRaAzimuths[i].count {
                guard let point = skyToScreen(azimuth: equRaAzimuths[i][j], altitude: equRaAltitudes[i][j]) else {
                    first = true
                    continue
                }
                if first {
                    path.move(to: point)
                    first = false
                } else {
                    path.addLine(to: point)
                }
                let dx = point.x - center.x
                let dy = point.y - center.y
                let distSq = dx * dx + dy * dy
                currentLineMinDistSq = min(currentLineMinDistSq, distSq)
            }
            if currentLineMinDistSq < minCenterDistSq {
                minCenterDistSq = currentLineMinDistSq
                bestRaIndex = i
            }

            let zeroDecIndex = 90 / equLineResStep
            if zeroDecIndex < equRaAzimuths[i].count,
               let point = skyToScreen(azimuth: equRaAzimuths[i][zeroDecIndex], altitude: equRaAltitudes[i][zeroDecIndex]) {
                let totalMinutes = i * equRaStepMin
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                let label = minutes == 0 ? "\(hours)h" : "\(hours)h\(minutes)"
                raLabels.append((label, CGPoint(x: point.x, y: point.y - 18)))
            }
        }

        for i in 0..<equDecAzimuths.count {
            var first = true
            for j in 0..<equDecAzimuths[i].count {
                guard let point = skyToScreen(azimuth: equDecAzimuths[i][j], altitude: equDecAltitudes[i][j]) else {
                    first = true
                    continue
                }
                if first {
                    path.move(to: point)
                    first = false
                } else {
                    path.addLine(to: point)
                }
            }

            if bestRaIndex >= 0 {
                let dec = -80 + i * equDecStep
                if dec != 0 {
                    let ra = Double(bestRaIndex * equRaStepMin) / 60.0
                    let hor = AstronomyKt.horizon(time: currentTime, observer: observer, ra: ra, dec: Double(dec), refraction: Refraction.normal)
                    decLabels.append(("\(dec)°", hor.azimuth, hor.altitude))
                }
            }
        }

        stroke(path, color: .mapGridMain, width: 0.8, in: context)
        
        let labelColor = UIColor.mapGridMainText
        let font = UIFont.systemFont(ofSize: 11)
        
        for (label, point) in raLabels {
            drawText(label, at: point, color: labelColor, font: font, align: .center)
        }
        for (label, az, alt) in decLabels {
            drawGridLabel(label, azimuth: az, altitude: alt, align: .left, color: labelColor, in: context)
        }
    }

    private func updateEclipticCache() {
        let time = currentTime
        let obs = observer
        guard abs(time.tt - lastEclipticTimeT) >= 0.0000001 ||
              obs.latitude != lastEclipticLat ||
              obs.longitude != lastEclipticLon else {
            return
        }

        eclipticAzimuths.removeAll(keepingCapacity: true)
        eclipticAltitudes.removeAll(keepingCapacity: true)
        let rotation = AstronomyKt.rotationEclEqd(time: time)
        for longitude in stride(from: 0, through: 360, by: eclipticStep) {
            let lon = Double(longitude) * .pi / 180.0
            let vecEcl = Vector(x: cos(lon), y: sin(lon), z: 0, t: time)
            let vecEqd = rotation.rotate(vec: vecEcl)
            let equatorial = vecEqd.toEquatorial()
            let hor = AstronomyKt.horizon(time: time, observer: obs, ra: equatorial.ra, dec: equatorial.dec, refraction: Refraction.normal)
            eclipticAzimuths.append(hor.azimuth)
            eclipticAltitudes.append(hor.altitude)
        }
        lastEclipticTimeT = time.tt
        lastEclipticLat = obs.latitude
        lastEclipticLon = obs.longitude
    }

    private func drawEclipticLine(in context: CGContext) {
        updateEclipticCache()
        stroke(cachedLinePath(azimuths: eclipticAzimuths, altitudes: eclipticAltitudes),
               color: .mapLineEcliptic,
               width: 1.2,
               dash: [8, 8],
               in: context)
    }

    private func drawMeridianLine(in context: CGContext) {
        let path = CGMutablePath()
        appendSkyLine(to: path, range: stride(from: -90.0, through: 90.0, by: 2.0)) { altitude in
            (0.0, altitude)
        }
        appendSkyLine(to: path, range: stride(from: -90.0, through: 90.0, by: 2.0)) { altitude in
            (180.0, altitude)
        }
        stroke(path, color: .mapLineMeridian, width: 1.2, dash: [12, 8], in: context)
    }

    private func updateEquatorCache() {
        let time = currentTime
        let obs = observer
        guard abs(time.tt - lastEquatorTimeT) >= 0.0000001 ||
              obs.latitude != lastEquatorLat ||
              obs.longitude != lastEquatorLon else {
            return
        }

        equatorAzimuths.removeAll(keepingCapacity: true)
        equatorAltitudes.removeAll(keepingCapacity: true)
        for raDeg in stride(from: 0, through: 360, by: equatorStep) {
            let hor = AstronomyKt.horizon(time: time, observer: obs, ra: Double(raDeg) / 15.0, dec: 0, refraction: Refraction.normal)
            equatorAzimuths.append(hor.azimuth)
            equatorAltitudes.append(hor.altitude)
        }
        lastEquatorTimeT = time.tt
        lastEquatorLat = obs.latitude
        lastEquatorLon = obs.longitude
    }

    private func drawEquatorLine(in context: CGContext) {
        updateEquatorCache()
        stroke(cachedLinePath(azimuths: equatorAzimuths, altitudes: equatorAltitudes),
               color: .mapLineEquator,
               width: 1.2,
               dash: [12, 8],
               in: context)
    }

    private func updateGalacticCache() {
        let time = currentTime
        let obs = observer
        guard abs(time.tt - lastGalacticTimeT) >= 0.0000001 ||
              obs.latitude != lastGalacticLat ||
              obs.longitude != lastGalacticLon else {
            return
        }

        galacticAzimuths.removeAll(keepingCapacity: true)
        galacticAltitudes.removeAll(keepingCapacity: true)
        let alphaNGP = 192.85948
        let deltaNGP = 27.12825
        let cotDeltaNGP = 1.0 / tan(deltaNGP * .pi / 180.0)
        for raDeg in stride(from: 0, through: 360, by: galacticStep) {
            let alphaDiff = (Double(raDeg) - alphaNGP) * .pi / 180.0
            let dec = atan(-cotDeltaNGP * cos(alphaDiff)) * 180.0 / .pi
            let hor = AstronomyKt.horizon(time: time, observer: obs, ra: Double(raDeg) / 15.0, dec: dec, refraction: Refraction.normal)
            galacticAzimuths.append(hor.azimuth)
            galacticAltitudes.append(hor.altitude)
        }
        lastGalacticTimeT = time.tt
        lastGalacticLat = obs.latitude
        lastGalacticLon = obs.longitude
    }

    private func drawGalacticLine(in context: CGContext) {
        updateGalacticCache()
        stroke(cachedLinePath(azimuths: galacticAzimuths, altitudes: galacticAltitudes),
               color: .mapLineGalactic,
               width: 1.2,
               dash: [8, 8],
               in: context)
    }

    private func drawConstellationLines(in context: CGContext) {
        for constellation in constellations {
            let isSelected = constellation.id == selectedConstellationId
            if !settings.starMap.showConstellations && !isSelected {
                continue
            }

            let path = CGMutablePath()
            for (firstId, secondId) in constellation.lines {
                guard let first = skyObjectMap[String(firstId)],
                      let second = skyObjectMap[String(secondId)],
                      let p1 = skyToScreen(azimuth: first.azimuth, altitude: first.altitude, allowLimitedOffScreen: true),
                      let p2 = skyToScreen(azimuth: second.azimuth, altitude: second.altitude, allowLimitedOffScreen: true) else {
                    continue
                }
                path.move(to: p1)
                path.addLine(to: p2)
            }
            stroke(path,
                   color: isSelected ? .constellationSelected : .constellationLine,
                   width: isSelected ? 1.8 : 0.9,
                   in: context)
        }
    }

    private func drawConstellationLabels(in context: CGContext) {
        let centers = constellationCenters()
        for constellation in constellations {
            let isSelected = constellation.id == selectedConstellationId
            if !settings.starMap.showConstellations && !isSelected {
                continue
            }
            guard let center = centers[constellation.id],
                  let point = skyToScreen(azimuth: center.azimuth, altitude: center.altitude) else {
                continue
            }

            let color = isSelected ? UIColor.constellationSelected : UIColor.constellationText
            let font = UIFont.italicSystemFont(ofSize: 16)
            let text = constellation.getDisplayName()
            let size = text.size(withAttributes: [.font: font])
            let rect = CGRect(x: point.x - size.width / 2 - 10, y: point.y - 10, width: size.width + 20, height: size.height + 20)
            let overlaps = occupiedRects.contains { $0.intersects(rect) }
            if !overlaps || isSelected {
                drawText(text, at: CGPoint(x: point.x, y: point.y + size.height), color: color, font: font, align: .center)
                occupiedRects.append(rect)
            }
        }
    }

    private func constellationCenters() -> [String: ConstellationCenter] {
        if constellationCenterCache.isEmpty && !constellations.isEmpty {
            rebuildConstellationCenterCache()
        }
        return constellationCenterCache
    }

    private func rebuildConstellationCenterCache() {
        guard !constellations.isEmpty else {
            constellationCenterCache.removeAll(keepingCapacity: true)
            return
        }

        var objectMap: [Int: SkyObject] = [:]
        for object in skyObjects where object.hip > 0 {
            objectMap[object.hip] = object
        }

        var centers: [String: ConstellationCenter] = [:]
        for constellation in constellations {
            guard let center = AstroUtils.calculateConstellationCenter(constellation, skyObjectMap: objectMap) else {
                continue
            }
            let ra = center.0
            let dec = center.1
            let hor = AstronomyKt.horizon(time: currentTime, observer: observer, ra: ra, dec: dec, refraction: Refraction.normal)
            constellation.ra = ra
            constellation.dec = dec
            centers[constellation.id] = ConstellationCenter(ra: ra,
                                                            dec: dec,
                                                            azimuth: hor.azimuth,
                                                            altitude: hor.altitude,
                                                            targetAzimuth: hor.azimuth,
                                                            targetAltitude: hor.altitude)
        }
        constellationCenterCache = centers
    }

    private func drawCelestialPaths(in context: CGContext) {
        var objects: [SkyObject] = []
        if let selectedObject {
            objects.append(selectedObject)
        }
        if settings.starMap.showCelestialPaths {
            objects.append(contentsOf: pinnedObjects)
            objects.append(contentsOf: skyObjects.filter { $0.showCelestialPath })
        }

        var seenIds: Set<String> = []
        for object in objects where seenIds.insert(object.id).inserted && isObjectVisibleInSettings(object) {
            drawCelestialPath(for: object, in: context)
        }
    }

    private func drawCelestialPath(for object: SkyObject, in context: CGContext) {
        guard let data = pathData(for: object), data.azimuths.count > 1 else {
            return
        }

        let drawCount = object.type == .MOON ? data.azimuths.count : min(data.azimuths.count, 145)
        let path = CGMutablePath()
        var penDown = false
        var previousPoint: CGPoint?

        for index in 0..<drawCount {
            guard let point = skyToScreen(azimuth: data.azimuths[index], altitude: data.altitudes[index]) else {
                penDown = false
                previousPoint = nil
                continue
            }

            if let previousPoint, hypot(point.x - previousPoint.x, point.y - previousPoint.y) > bounds.width * 0.8 {
                penDown = false
            }

            if penDown {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                penDown = true
            }
            previousPoint = point
        }
        stroke(path, color: .mapTrajectoryLine, width: 1.1, dash: [5, 8], in: context)

        var drawnLabels: Set<String> = []
        for index in 0..<drawCount {
            guard let label = data.labels[index], drawnLabels.insert(label).inserted,
                  let point = skyToScreen(azimuth: data.azimuths[index], altitude: data.altitudes[index]) else {
                continue
            }

            let previousIndex = max(0, index - 1)
            let nextIndex = min(drawCount - 1, index + 1)
            guard previousIndex != nextIndex,
                  let previous = skyToScreen(azimuth: data.azimuths[previousIndex], altitude: data.altitudes[previousIndex]),
                  let next = skyToScreen(azimuth: data.azimuths[nextIndex], altitude: data.altitudes[nextIndex]) else {
                continue
            }

            let distPrevious = hypot(point.x - previous.x, point.y - previous.y)
            let distNext = hypot(next.x - point.x, next.y - point.y)
            if (index > 0 && distPrevious > 200) || (index < drawCount - 1 && distNext > 200) {
                continue
            }

            let angle = atan2(next.y - previous.y, next.x - previous.x)
            let labelAngle = Double(angle - .pi / 2)
            let labelPoint = CGPoint(x: point.x + 30 * CGFloat(cos(labelAngle)),
                                     y: point.y + 30 * CGFloat(sin(labelAngle)) + 8)
            drawText(label, at: labelPoint, color: .mapTrajectoryLine, font: .systemFont(ofSize: 12), align: .center)
            drawArrow(at: point, angle: angle, in: context)
        }
    }

    private func pathData(for object: SkyObject) -> CelestialPathData? {
        let time = currentTime
        let obs = observer
        if let cached = pathCache[object.id],
           abs(time.tt - cached.lastTime) < 0.0000001,
           obs.latitude == cached.lastLat,
           obs.longitude == cached.lastLon {
            return cached
        }

        var azimuths: [Double] = []
        var altitudes: [Double] = []
        var labels: [String?] = []
        let calendar = Calendar.current
        let currentDate = Date(timeIntervalSince1970: TimeInterval(time.toMillisecondsSince1970()) / 1000.0)
        guard let startCandidate = calendar.date(byAdding: .hour, value: -12, to: currentDate),
              let start = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: startCandidate)),
              let maxDate = calendar.date(byAdding: .hour, value: 14, to: currentDate) else {
            return nil
        }

        for step in 0..<(25 * 6 + 1) {
            let stepDate = start.addingTimeInterval(TimeInterval(step * 10 * 60))
            if stepDate > maxDate {
                break
            }
            let stepTime = AstroUtils.astronomyTime(from: stepDate)
            guard let horizontal = horizontalPosition(for: object, time: stepTime, observer: obs) else {
                continue
            }
            azimuths.append(horizontal.azimuth)
            altitudes.append(horizontal.altitude)
            let minute = calendar.component(.minute, from: stepDate)
            let hour = calendar.component(.hour, from: stepDate)
            labels.append(minute == 0 ? String(format: "%02d", hour) : nil)
        }

        let data = CelestialPathData(azimuths: azimuths, altitudes: altitudes, labels: labels, lastTime: time.tt, lastLat: obs.latitude, lastLon: obs.longitude)
        pathCache[object.id] = data
        return data
    }

    private func horizontalPosition(for object: SkyObject, time: Time, observer: Observer) -> Topocentric? {
        if let body = object.body {
            let equatorial = AstronomyKt.equator(body: body, time: time, observer: observer, equdate: EquatorEpoch.ofdate, aberration: Aberration.corrected)
            object.distAu = equatorial.dist
            return AstronomyKt.horizon(time: time, observer: observer, ra: equatorial.ra, dec: equatorial.dec, refraction: Refraction.normal)
        }
        return AstronomyKt.horizon(time: time, observer: observer, ra: object.ra, dec: object.dec, refraction: Refraction.normal)
    }

    private func recalculatePositions(time: Time, updateTargets: Bool, force: Bool = false) {
        for object in skyObjects where shouldRecalculate(object) {
            calculatePosition(object, time: time, updateTargets: updateTargets, force: force)
        }

        if constellationCenterCache.isEmpty && !constellations.isEmpty {
            rebuildConstellationCenterCache()
        }
        for constellation in constellations {
            guard var center = constellationCenterCache[constellation.id] else {
                constellation.azimuth = 0
                constellation.altitude = 0
                constellation.targetAzimuth = 0
                constellation.targetAltitude = 0
                continue
            }
            let horizontal = AstronomyKt.horizon(time: time, observer: observer, ra: center.ra, dec: center.dec, refraction: Refraction.normal)
            constellation.ra = center.ra
            constellation.dec = center.dec
            if updateTargets {
                center.targetAzimuth = horizontal.azimuth
                center.targetAltitude = horizontal.altitude
                constellation.targetAzimuth = horizontal.azimuth
                constellation.targetAltitude = horizontal.altitude
            } else {
                center.azimuth = horizontal.azimuth
                center.altitude = horizontal.altitude
                center.targetAzimuth = horizontal.azimuth
                center.targetAltitude = horizontal.altitude
                constellation.azimuth = horizontal.azimuth
                constellation.altitude = horizontal.altitude
                constellation.targetAzimuth = horizontal.azimuth
                constellation.targetAltitude = horizontal.altitude
            }
            constellationCenterCache[constellation.id] = center
        }
    }

    private func updateConstellationObjectPositions() {
        for constellation in constellations {
            guard let center = constellationCenterCache[constellation.id] else {
                constellation.azimuth = 0
                constellation.altitude = 0
                constellation.targetAzimuth = 0
                constellation.targetAltitude = 0
                continue
            }
            constellation.ra = center.ra
            constellation.dec = center.dec
            constellation.azimuth = center.azimuth
            constellation.altitude = center.altitude
            constellation.targetAzimuth = center.targetAzimuth
            constellation.targetAltitude = center.targetAltitude
        }
    }

    private func calculatePosition(_ object: SkyObject, time: Time, updateTargets: Bool, force: Bool = false) {
        if !force && object.lastUpdateTime == time.tt && !updateTargets {
            return
        }
        guard let horizontal = horizontalPosition(for: object, time: time, observer: observer) else {
            return
        }
        if updateTargets {
            object.targetAzimuth = horizontal.azimuth
            object.targetAltitude = horizontal.altitude
        } else {
            object.azimuth = horizontal.azimuth
            object.altitude = horizontal.altitude
            object.targetAzimuth = horizontal.azimuth
            object.targetAltitude = horizontal.altitude
            object.lastUpdateTime = time.tt
        }
    }

    private func shouldRecalculate(_ object: SkyObject) -> Bool {
        if object === selectedObject {
            return true
        }
        if settings.starMap.showCelestialPaths && pinnedObjects.contains(object) {
            return true
        }
        if settings.starMap.showConstellations {
            return true
        }
        if selectedConstellationStarIds.contains(object.hip) {
            return true
        }
        return isObjectVisibleInSettings(object)
    }

    private func drawDirectionArrows(in context: CGContext) {
        guard settings.starMap.showDirections else {
            return
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * 0.42
        for object in trackableObjects where object.showDirection && isObjectVisibleInSettings(object) {
            guard let projected = skyToScreen(azimuth: object.azimuth, altitude: object.altitude, allowAnyOffScreen: true),
                  !bounds.contains(projected) else {
                continue
            }

            let angle = atan2(projected.y - center.y, projected.x - center.x)
            let point = CGPoint(x: center.x + radius * CGFloat(cos(Double(angle))),
                                y: center.y + radius * CGFloat(sin(Double(angle))))
            drawDirectionArrow(at: point, angle: angle, color: directionColor(object.colorIndex), in: context)
        }
    }

    private func drawArrow(at point: CGPoint, angle: CGFloat, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: angle)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 10, y: 0))
        path.addLine(to: CGPoint(x: -10, y: -6))
        path.addLine(to: CGPoint(x: -10, y: 6))
        path.closeSubpath()
        UIColor.mapTrajectoryLine.setFill()
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    private func drawDirectionArrow(at point: CGPoint, angle: CGFloat, color: UIColor, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        context.rotate(by: angle)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 18, y: 0))
        path.addLine(to: CGPoint(x: -14, y: -12))
        path.addLine(to: CGPoint(x: -7, y: 0))
        path.addLine(to: CGPoint(x: -14, y: 12))
        path.closeSubpath()
        color.setFill()
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    private func appendSkyLine(to path: CGMutablePath,
                               range: StrideThrough<Double>,
                               coordinate: (Double) -> (Double, Double)) {
        var first = true
        for value in range {
            let coord = coordinate(value)
            guard let point = skyToScreen(azimuth: coord.0, altitude: coord.1) else {
                first = true
                continue
            }
            if first {
                path.move(to: point)
                first = false
            } else {
                path.addLine(to: point)
            }
        }
    }

    private func cachedLinePath(azimuths: [Double], altitudes: [Double]) -> CGPath {
        let path = CGMutablePath()
        var first = true
        for index in 0..<min(azimuths.count, altitudes.count) {
            guard let point = skyToScreen(azimuth: azimuths[index], altitude: altitudes[index]) else {
                first = true
                continue
            }
            if first {
                path.move(to: point)
                first = false
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }

    private func stroke(_ path: CGPath, color: UIColor, width: CGFloat, dash: [CGFloat] = [], in context: CGContext) {
        context.saveGState()
        color.setStroke()
        context.setLineWidth(width)
        context.setLineCap(.round)
        if !dash.isEmpty {
            context.setLineDash(phase: 0, lengths: dash)
        }
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }

    private func drawOutsideLabel(_ label: String, azimuth: Double, altitude: Double, color: UIColor, offset: CGFloat, in context: CGContext) {
        guard let point = skyToScreen(azimuth: azimuth, altitude: altitude) else {
            return
        }

        let labelPoint: CGPoint
        if settings.starMap.is2DMode {
            let center = CGPoint(x: CGFloat(projectionHalfWidth + Double(panX)),
                                 y: CGFloat(projectionHalfHeight + Double(panY)))
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = hypot(dx, dy)
            if distance > 0.1 {
                labelPoint = CGPoint(x: center.x + dx * (distance + offset) / distance,
                                     y: center.y + dy * (distance + offset) / distance)
            } else {
                labelPoint = CGPoint(x: point.x, y: point.y - offset)
            }
        } else {
            labelPoint = CGPoint(x: point.x, y: point.y - offset)
        }
        drawText(label, at: labelPoint, color: color, font: .boldSystemFont(ofSize: 20), align: .center)
    }

    private func drawGridLabel(_ label: String, azimuth: Double, altitude: Double, align: NSTextAlignment, color: UIColor, in context: CGContext) {
        guard let point = skyToScreen(azimuth: azimuth, altitude: altitude),
              bounds.contains(point) else {
            return
        }
        drawText(label, at: CGPoint(x: point.x + 5, y: point.y - 12), color: color, font: .systemFont(ofSize: 11), align: align)
    }

    private func drawText(_ text: String, at point: CGPoint, color: UIColor, font: UIFont, align: NSTextAlignment) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = text.size(withAttributes: attributes)
        let origin: CGPoint
        switch align {
        case .center:
            origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        case .right:
            origin = CGPoint(x: point.x - size.width, y: point.y - size.height / 2)
        default:
            origin = CGPoint(x: point.x, y: point.y - size.height / 2)
        }
        text.draw(at: origin, withAttributes: attributes)
    }

    private func isObjectVisibleInSettings(_ object: SkyObject) -> Bool {
        if settings.starMap.showFavorites && object.isFavorite {
            return true
        }
        if object.type == .STAR,
           settings.starMap.showStars,
           let maxMagnitude = settings.starMap.magnitudeFilter,
           object.magnitude > maxMagnitude {
            return false
        }
        switch object.type {
        case .STAR:
            return settings.starMap.showStars
        case .GALAXY:
            return settings.starMap.showGalaxies
        case .BLACK_HOLE:
            return settings.starMap.showBlackHoles
        case .SUN:
            return settings.starMap.showSun
        case .MOON:
            return settings.starMap.showMoon
        case .PLANET:
            return settings.starMap.showPlanets
        case .NEBULA:
            return settings.starMap.showNebulae
        case .OPEN_CLUSTER:
            return settings.starMap.showOpenClusters
        case .GLOBULAR_CLUSTER:
            return settings.starMap.showGlobularClusters
        case .GALAXY_CLUSTER:
            return settings.starMap.showGalaxyClusters
        case .CONSTELLATION:
            return settings.starMap.showConstellations
        }
    }

    private func directionColor(_ index: Int) -> UIColor {
        let colors = AstronomyPluginSettings.DirectionColor.allCases
        return colors[index % colors.count].color
    }

    private func updateProjectionCache() {
        guard bounds.width > 0 && bounds.height > 0 else {
            return
        }

        let altitudeCenterRad = centerAltitude * .pi / 180.0
        projectionSinAltCenter = sin(altitudeCenterRad)
        projectionCosAltCenter = cos(altitudeCenterRad)
        let viewAngleRad = viewAngle * .pi / 180.0
        projectionScale = Double(bounds.width) / (4.0 * tan(viewAngleRad / 4.0))
        projectionHalfWidth = Double(bounds.width) / 2.0
        projectionHalfHeight = Double(bounds.height) / 2.0

        let cx = projectionHalfWidth + Double(panX)
        let cy = projectionHalfHeight + Double(panY)
        let width = Double(bounds.width)
        let height = Double(bounds.height)
        let d1Sq = cx * cx + cy * cy
        let d2Sq = (cx - width) * (cx - width) + cy * cy
        let d3Sq = (cx - width) * (cx - width) + (cy - height) * (cy - height)
        let d4Sq = cx * cx + (cy - height) * (cy - height)
        let maxDistSq = max(d1Sq, max(d2Sq, max(d3Sq, d4Sq)))
        let maxTanHalf = sqrt(maxDistSq) / (2.0 * projectionScale)
        let t2 = maxTanHalf * maxTanHalf
        minCosCVisible = (1.0 - t2) / (1.0 + t2)
    }

    private func skyToScreen(azimuth: Double,
                             altitude: Double,
                             allowLimitedOffScreen: Bool = false,
                             allowAnyOffScreen: Bool = false) -> CGPoint? {
        if abs(altitude - centerAltitude) > viewAngle + 40 && !allowLimitedOffScreen && !allowAnyOffScreen {
            return nil
        }

        let azRad = (azimuth - centerAzimuth) * .pi / 180.0
        let altRad = altitude * .pi / 180.0
        let sinAlt = sin(altRad)
        let cosAlt = cos(altRad)
        let sinAz = sin(azRad)
        let cosAz = cos(azRad)
        let cosC = projectionSinAltCenter * sinAlt + projectionCosAltCenter * cosAlt * cosAz
        if settings.starMap.is2DMode && cosC <= -0.3 {
            return nil
        }
        if !allowLimitedOffScreen && !allowAnyOffScreen && cosC < minCosCVisible {
            return nil
        }
        if allowLimitedOffScreen && !allowAnyOffScreen && cosC <= -0.2 {
            return nil
        }

        let k = 2.0 / (1.0 + cosC)
        let combinedScale = k * projectionScale
        let xRaw = cosAlt * sinAz
        let yRaw = projectionCosAltCenter * sinAlt - projectionSinAltCenter * cosAlt * cosAz
        var xScaled = combinedScale * xRaw
        let yScaled = -combinedScale * yRaw
        if settings.starMap.is2DMode {
            xScaled = -xScaled
        }

        let rollRad = roll * .pi / 180.0
        let xRot = xScaled * cos(rollRad) - yScaled * sin(rollRad)
        let yRot = xScaled * sin(rollRad) + yScaled * cos(rollRad)
        return CGPoint(x: CGFloat(projectionHalfWidth + xRot + Double(panX)),
                       y: CGFloat(projectionHalfHeight + yRot + Double(panY)))
    }

    private func updateViewAngle(_ newAngle: Double, focus: CGPoint? = nil) {
        let finalAngle = max(ViewAngleBounds.min, min(maxViewAngle, newAngle))
        guard abs(viewAngle - finalAngle) > 0.001, bounds.width > 0, bounds.height > 0 else {
            return
        }

        cancelFocusAnimation()
        let focusPoint = focus ?? CGPoint(x: bounds.midX, y: bounds.midY)
        if settings.starMap.is2DMode {
            let oldTan = tan(viewAngle * .pi / 180.0 / 4.0)
            let newTan = tan(finalAngle * .pi / 180.0 / 4.0)
            if oldTan > 0 && newTan > 0 {
                let ratio = CGFloat(oldTan / newTan)
                panX = focusPoint.x - bounds.midX - (focusPoint.x - bounds.midX - panX) * ratio
                panY = focusPoint.y - bounds.midY - (focusPoint.y - bounds.midY - panY) * ratio
            }
        } else {
            let oldScale = viewAngle / Double(bounds.width)
            let newScale = finalAngle / Double(bounds.width)
            let offX = Double(focusPoint.x - bounds.midX)
            let offY = Double(focusPoint.y - bounds.midY)
            centerAzimuth = normalizedDegrees(centerAzimuth + offX * (oldScale - newScale))
            centerAltitude = max(-90, min(90, centerAltitude - offY * (oldScale - newScale)))
        }
        viewAngle = finalAngle
        onViewAngleChangeListener?(viewAngle)
        setNeedsDisplay()
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            if isGyroTrackingEnabled {
                cancelGyroSnapBack()
                isGyroPanOverride = true
            } else {
                cancelFocusAnimation()
            }
            lastTouchPoint = point
            isPanning = false
            didPanThisGesture = false
        case .changed:
            let dx = point.x - lastTouchPoint.x
            let dy = point.y - lastTouchPoint.y

            if hypot(dx, dy) > 0 {
                isPanning = true
                didPanThisGesture = true
                applyPanDelta(dx: dx, dy: dy)
                lastTouchPoint = point
                setNeedsDisplay()
            }
        case .ended, .cancelled:
            if didPanThisGesture && isGyroTrackingEnabled {
                isPanning = false
                scheduleGyroSnapBack()
            } else if didPanThisGesture && !isGyroTrackingEnabled {
                startInertialScroll(velocity: recognizer.velocity(in: self))
            } else if isGyroTrackingEnabled {
                isGyroPanOverride = false
            }
            isPanning = false
            didPanThisGesture = false
        default:
            isPanning = false
        }
    }
    
    private func applyPanDelta(dx: CGFloat, dy: CGFloat) {
        if settings.starMap.is2DMode {
            panX += dx
            panY += dy
        } else {
            let scale = viewAngle / Double(max(bounds.width, 1))
            centerAzimuth = normalizedDegrees(centerAzimuth - Double(dx) * scale)
            centerAltitude = max(-90, min(90, centerAltitude + Double(dy) * scale))
            notifyAzimuthChanged()
        }
        setNeedsDisplay()
    }
    
    private func startInertialScroll(velocity: CGPoint) {
        guard hypot(velocity.x, velocity.y) >= inertialMinStartSpeed else { return }

        cancelInertialScroll()
        cancelFocusAnimation()

        inertialVelocity = velocity
        lastInertialTimestamp = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(handleInertialFrame(_:)))
        inertialDisplayLink = link
        link.add(to: .main, forMode: .common)
    }

    private func cancelInertialScroll() {
        inertialDisplayLink?.invalidate()
        inertialDisplayLink = nil
        inertialVelocity = .zero
    }

    @objc private func handleInertialFrame(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = CGFloat(max(0, min(0.05, now - lastInertialTimestamp)))
        lastInertialTimestamp = now
        guard dt > 0 else { return }

        applyPanDelta(dx: inertialVelocity.x * dt, dy: inertialVelocity.y * dt)

        let decay = pow(inertialDecelerationRate, dt * 1000)
        inertialVelocity.x *= decay
        inertialVelocity.y *= decay

        if hypot(inertialVelocity.x, inertialVelocity.y) < inertialStopSpeed {
            cancelInertialScroll()
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state == .changed || recognizer.state == .ended else {
            return
        }
        cancelFocusAnimation()
        updateViewAngle(viewAngle / Double(recognizer.scale), focus: recognizer.location(in: self))
        recognizer.scale = 1
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard !isPanning else {
            return
        }
        cancelFocusAnimation()
        performClick(at: recognizer.location(in: self))
    }

    private func performClick(at point: CGPoint) {
        let clickRadius = pixelsToPoints(60)
        var bestObject: SkyObject?
        var bestObjectDistance = CGFloat.greatestFiniteMagnitude
        for object in skyObjects where isObjectVisibleInSettings(object) {
            guard let objectPoint = skyToScreen(azimuth: object.azimuth, altitude: object.altitude) else {
                continue
            }
            let distance = hypot(point.x - objectPoint.x, point.y - objectPoint.y)
            if distance < clickRadius && distance < bestObjectDistance {
                bestObject = object
                bestObjectDistance = distance
            }
        }

        if let bestObject {
            setSelectedObject(bestObject)
            delegate?.starView(self, didSelect: bestObject)
            onObjectClickListener?(bestObject)
            onConstellationClickListener?(nil)
            return
        }

        if settings.starMap.showConstellations || selectedConstellationId != nil {
            var bestConstellation: Constellation?
            var bestDistance = CGFloat.greatestFiniteMagnitude
            let centers = constellationCenters()
            for constellation in constellations {
                let isSelected = constellation.id == selectedConstellationId
                if !settings.starMap.showConstellations && !isSelected {
                    continue
                }

                for (firstId, secondId) in constellation.lines {
                    guard let first = skyObjectMap[String(firstId)],
                          let second = skyObjectMap[String(secondId)],
                          let p1 = skyToScreen(azimuth: first.azimuth, altitude: first.altitude),
                          let p2 = skyToScreen(azimuth: second.azimuth, altitude: second.altitude) else {
                        continue
                    }
                    let distance = distanceFrom(point: point, toSegmentStart: p1, end: p2)
                    if distance < clickRadius && distance < bestDistance {
                        bestDistance = distance
                        bestConstellation = constellation
                    }
                }

                if let center = centers[constellation.id],
                   let centerPoint = skyToScreen(azimuth: center.azimuth, altitude: center.altitude) {
                    let distance = hypot(point.x - centerPoint.x, point.y - centerPoint.y)
                    if distance < clickRadius && distance < bestDistance {
                        bestDistance = distance
                        bestConstellation = constellation
                    }
                }
            }

            if let bestConstellation {
                setSelectedConstellation(bestConstellation)
                delegate?.starView(self, didSelect: bestConstellation)
                onObjectClickListener?(nil)
                onConstellationClickListener?(bestConstellation)
                return
            }
        }

        setSelectedObject(nil)
        delegate?.starView(self, didSelect: nil)
        onObjectClickListener?(nil)
        onConstellationClickListener?(nil)
    }

    private func distanceFrom(point: CGPoint, toSegmentStart start: CGPoint, end: CGPoint) -> CGFloat {
        let segmentX = end.x - start.x
        let segmentY = end.y - start.y
        let lenSq = segmentX * segmentX + segmentY * segmentY
        let parameter = lenSq == 0 ? -1 : ((point.x - start.x) * segmentX + (point.y - start.y) * segmentY) / lenSq
        let closest: CGPoint
        if parameter < 0 {
            closest = start
        } else if parameter > 1 {
            closest = end
        } else {
            closest = CGPoint(x: start.x + parameter * segmentX, y: start.y + parameter * segmentY)
        }
        return hypot(point.x - closest.x, point.y - closest.y)
    }

    private func angularDistance(ra1: Double, dec1: Double, ra2: Double, dec2: Double) -> Double {
        let phi1 = dec1 * .pi / 180.0
        let phi2 = dec2 * .pi / 180.0
        let lambda1 = ra1 * 15.0 * .pi / 180.0
        let lambda2 = ra2 * 15.0 * .pi / 180.0
        let cosD = sin(phi1) * sin(phi2) + cos(phi1) * cos(phi2) * cos(lambda1 - lambda2)
        return acos(max(-1, min(1, cosD))) * 180.0 / .pi
    }

    private func interpolateAngle(start: Double, end: Double, fraction: Double) -> Double {
        var diff = end - start
        while diff > 180 {
            diff -= 360
        }
        while diff < -180 {
            diff += 360
        }
        var result = start + diff * fraction
        while result < 0 {
            result += 360
        }
        while result >= 360 {
            result -= 360
        }
        return result
    }

    private func normalizedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360)
        if value < 0 {
            value += 360
        }
        return value
    }
    
    deinit {
        timeAnimationDisplayLink?.invalidate()
        focusAnimationDisplayLink?.invalidate()
        inertialDisplayLink?.invalidate()
    }
}
