//
//  AisTrackerPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared

extension Notification.Name {
    static let aisNmeaConnectionStateChanged = Notification.Name("OAAisNmeaConnectionStateChanged")
}

@objc enum AisNmeaProtocol: Int {
    case udp = 0
    case tcp = 1
}

@objc enum AisNmeaConnectionState: Int {
    case disconnected
    case connecting
    case connected
    case failed
}

extension AisNmeaConnectionState: CustomStringConvertible {
    var description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .failed:
            return "failed"
        }
    }
}

private struct AisNmeaConnectionConfig: Equatable {
    let proto: AisNmeaProtocol
    let host: String
    let port: Int

    var debugDescription: String {
        switch proto {
        case .udp:
            return "UDP port=\(port)"
        case .tcp:
            return "TCP host=\(host) port=\(port)"
        }
    }

    var isConnectable: Bool {
        switch proto {
        case .udp:
            return port > 0
        case .tcp:
            return !host.isEmpty && port > 0
        }
    }
}

@objcMembers
final class AisTrackerPlugin: OAPlugin {
    static let pluginId = "osmand.aistracker"
    static let protocolPrefId = "ais_nmea_protocol"
    static let hostPrefId = "ais_address_nmea_server"
    static let tcpPortPrefId = "ais_port_nmea_server"
    static let udpPortPrefId = "ais_port_nmea_local"
    static let useNmeaLocationPrefId = "ais_use_nmea_location"
    static let objectLostTimeoutPrefId = "ais_object_lost_timeout"
    static let shipLostTimeoutPrefId = "ais_ship_lost_timeout"
    static let cpaWarningTimePrefId = "ais_cpa_warning_time"
    static let cpaWarningDistancePrefId = "ais_cpa_warning_distance"

    private static let nmeaLocationTimeout: TimeInterval = 10

    let protocolPref: OACommonInteger
    let hostPref: OACommonString
    let tcpPortPref: OACommonInteger
    let udpPortPref: OACommonInteger
    let useNmeaLocationPref: OACommonBoolean
    let objectLostTimeoutPref: OACommonInteger
    let shipLostTimeoutPref: OACommonInteger
    let cpaWarningTimePref: OACommonInteger
    let cpaWarningDistancePref: OACommonDouble

    private(set) var connectionState: AisNmeaConnectionState = .disconnected
    private(set) var fakeOwnLocation: CLLocation?
    private(set) var simulationFileName: String?
    private(set) var lastMessageReceived = Date.distantPast

    private let decoder = AisMessageDecoder()
    private let aisDecoderQueue = DispatchQueue(label: "com.app.ais.decoder", qos: .userInitiated)

    private var networkListener: AisMessageListener?
    private var activeConnectionConfig: AisNmeaConnectionConfig?
    private var nmeaLocationWatchdogWorkItem: DispatchWorkItem?
    private var applicationModeObserver: OAAutoObserverProxy?

    private lazy var networkDataListener = AisNetworkDataListener(plugin: self)
    private lazy var simulationProvider = AisSimulationProvider(plugin: self)
    private lazy var aisDataManager = AisDataManager(plugin: self)

    override init() {
        protocolPref = OAAppSettings.sharedManager().registerIntPreference(Self.protocolPrefId, defValue: Int32(AisNmeaProtocol.udp.rawValue)).makeProfile()
        hostPref = OAAppSettings.sharedManager().registerStringPreference(Self.hostPrefId, defValue: "192.168.200.16").makeProfile()
        tcpPortPref = OAAppSettings.sharedManager().registerIntPreference(Self.tcpPortPrefId, defValue: 4001).makeProfile()
        udpPortPref = OAAppSettings.sharedManager().registerIntPreference(Self.udpPortPrefId, defValue: 10110).makeProfile()
        useNmeaLocationPref = OAAppSettings.sharedManager().registerBooleanPreference(Self.useNmeaLocationPrefId, defValue: false).makeProfile()
        objectLostTimeoutPref = OAAppSettings.sharedManager().registerIntPreference(Self.objectLostTimeoutPrefId, defValue: 7).makeProfile()
        shipLostTimeoutPref = OAAppSettings.sharedManager().registerIntPreference(Self.shipLostTimeoutPrefId, defValue: 4).makeProfile()
        cpaWarningTimePref = OAAppSettings.sharedManager().registerIntPreference(Self.cpaWarningTimePrefId, defValue: 0).makeProfile()
        cpaWarningDistancePref = OAAppSettings.sharedManager().registerFloatPreference(Self.cpaWarningDistancePrefId, defValue: 1.0).makeProfile()
        super.init()

        applicationModeObserver = OAAutoObserverProxy(self,
                                                      withHandler: #selector(onApplicationModeChanged),
                                                      andObserve: OsmAndApp.swiftInstance().applicationModeChangedObservable)
    }

    private static func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let degrees = atan2(y, x) * 180 / .pi
        return fmod(degrees + 360, 360)
    }

    override func getId() -> String {
        kInAppId_Addon_Ais_Tracker
    }

    override func getName() -> String {
        localizedString("plugin_ais_tracker_name")
    }

    override func getDescription() -> String {
        localizedString("plugin_ais_tracker_description")
            + "<br><br>"
            + localizedString("plugin_ais_tracker_disclaimer")
                .replacingOccurrences(of: "\n\n", with: "<br><br>")
    }

    override func getLogoResourceId() -> String? {
        "ic_plugin_nautical"
    }

    override func getAddedAppModes() -> [OAApplicationMode] {
        [OAApplicationMode.boat()]
    }

    override func setEnabled(_ enabled: Bool) {
        super.setEnabled(enabled)
        AisObjectHelper.debugLog("[AisTrackerPlugin] setEnabled=\(enabled)")
        if enabled {
            updateConnectionForCurrentProfileSettings()
        } else {
            clearSimulationObjects()
            stopAisNetworkListener()
        }
    }

    override func updateLayers() {
        DispatchQueue.main.async {
            OsmAndApp.swiftInstance().data.mapLayersConfiguration.setLayer("ais_tracker_layer", visibility: self.isActiveForCurrentProfile())
            OARootViewController.instance().mapPanel.mapViewController.updateLayer("ais_tracker_layer")
        }
    }

    override func disable() {
        clearSimulationObjects()
        stopAisNetworkListener()
        super.disable()
    }

    override func getSettingsController() -> UIViewController? {
        AisTrackerSettingsViewController(plugin: self)
    }

    func getSimulationProvider() -> AisSimulationProvider {
        simulationProvider
    }

    func isActiveForCurrentProfile() -> Bool {
        isEnabled()
    }

    func startAisSimulation(_ fileURL: URL) {
        guard isEnabled() else { return }
        simulationFileName = fileURL.lastPathComponent
        AisObjectHelper.debugLog("simulation start file=\(fileURL.lastPathComponent)")
        simulationProvider.startAisSimulation(fileURL)
    }

    func updateSimulationStatus(sentences: Int, decoded: Int, objects: Int, error: String?) {
        if let error, !error.isEmpty {
            AisObjectHelper.debugLog("simulation status error=\(error)")
        } else {
            AisObjectHelper.debugLog("simulation stats sentences=\(sentences) decoded=\(decoded) objects=\(objects)")
        }
    }

    func prepareAisSimulation() {
        stopAisNetworkListener()
        aisDataManager.cleanupResources()
        aisDataManager.startUpdates()
    }

    func addTestSimulationObjects() {
        simulationProvider.initFakePosition()
        simulationProvider.initTestPassengerShip()
        simulationProvider.initTestSailingBoat()
        simulationProvider.initTestLandStation()
        simulationProvider.initTestAircraft()
        simulationProvider.initTestLawEnforcement()
    }

    func clearSimulationObjects() {
        simulationProvider.stopAisSimulation()
        AisObjectHelper.debugLog("simulation clear")
        fakeOwnLocation = nil
        simulationFileName = nil
        aisDataManager.cleanupResources()
    }

    func restartConnection() {
        updateConnectionForCurrentProfileSettings()
    }

    func stopAisNetworkListener() {
        stopSharedNetworkListener(updateState: true)
        resetNmeaLocationProvider()
        aisDataManager.stopUpdates()
    }

    func resetNmeaLocationProvider() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.resetNmeaLocationProvider()
            }
            return
        }
        cancelNmeaLocationWatchdog()
        OsmAndApp.swiftInstance().locationServices?.resetLocationFromExternalProvider()
    }

    func fakeOwnPosition(_ location: CLLocation?) {
        fakeOwnLocation = location
    }

    func handleSimulatedNmeaSentence(_ sentence: String) {
        handleAisSentence(sentence)
    }

    func handleSimulatedAisObject(_ object: AisObject) {
        aisDataManager.onAisObjectReceived(object)
    }

    func getAisObjects() -> [AisObject] {
        aisDataManager.objects
    }

    func maxObjectAgeInMinutes() -> Int {
        max(1, Int(objectLostTimeoutPref.get()))
    }

    func vesselLostTimeoutInMinutes() -> Int {
        max(0, Int(shipLostTimeoutPref.get()))
    }

    func cpaWarningTimeInMinutes() -> Int {
        max(0, Int(cpaWarningTimePref.get()))
    }

    func cpaWarningDistanceInNauticalMiles() -> Double {
        max(0, cpaWarningDistancePref.get())
    }

    func ownPosition() -> CLLocation? {
        if let fakeOwnLocation {
            return fakeOwnLocation
        }
        return OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
    }

    func onAisObjectReceived(_ object: AisObject) {
        lastMessageReceived = AisObjectHelper.lastUpdateDate(object)
        if AisLogger.shared.isEnabled {
            AisObjectHelper.debugLog("plugin received withPosition=\(getAisObjects().filter { $0.position != nil }.count) \(AisObjectHelper.debugSummary(object))")
        }
        DispatchQueue.main.async {
            OAAisTrackerLayerBridge.onAisObjectReceived(object)
        }
    }

    func onAisObjectRemoved(_ object: AisObject) {
        if AisLogger.shared.isEnabled {
            AisObjectHelper.debugLog("plugin removed \(AisObjectHelper.debugSummary(object))")
        }
        DispatchQueue.main.async {
            OAAisTrackerLayerBridge.onAisObjectRemoved(object)
        }
    }

    func onAisObjectsChanged() {
        DispatchQueue.main.async {
            OAAisTrackerLayerBridge.reloadAisObjects()
        }
    }

    func hasCpaWarning(for object: AisObject) -> Bool {
        let warningTime = cpaWarningTimeInMinutes()
        let warningDistance = cpaWarningDistanceInNauticalMiles()
        guard object.isMovable(),
              object.objectClass != AisObjType.aisAirplane,
              warningTime > 0,
              object.sog > 0,
              let ownPosition = ownPosition(),
              let aisPosition = AisObjectHelper.location(object) else {
            return false
        }
        AisTrackerHelper.getCpa(ownPosition, aisPosition, result: object.cpa)
        guard object.cpa.valid, object.cpa.tcpa > 0 else { return false }
        return Double(object.cpa.cpa) <= warningDistance
            && object.cpa.tcpa * 60.0 <= Double(warningTime)
            && object.cpa.t1 >= 0
            && object.cpa.t2 >= 0
    }

    func updateCpa(for object: AisObject) {
        guard let ownPosition = ownPosition(),
              let aisPosition = AisObjectHelper.currentLocation(object) ?? AisObjectHelper.location(object) else {
            object.cpa.reset()
            return
        }
        AisTrackerHelper.getCpa(ownPosition, aisPosition, result: object.cpa)
    }

    func distanceInNauticalMiles(to object: AisObject) -> Double {
        guard let ownPosition = ownPosition(),
              let aisPosition = AisObjectHelper.currentLocation(object) ?? AisObjectHelper.location(object) else {
            return -1
        }
        return ownPosition.distance(from: aisPosition) / 1852.0
    }

    func bearing(to object: AisObject) -> Double {
        guard let ownPosition = ownPosition(),
              let aisPosition = AisObjectHelper.currentLocation(object) ?? AisObjectHelper.location(object) else {
            return -1
        }
        return Self.bearing(from: ownPosition.coordinate, to: aisPosition.coordinate)
    }

    func connectionDescription() -> String {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        let proto = AisNmeaProtocol(rawValue: Int(protocolPref.get(appMode))) ?? .udp
        switch proto {
        case .udp:
            return "UDP • \(udpPortPref.get(appMode))"
        case .tcp:
            return "TCP • \(hostPref.get(appMode)):\(tcpPortPref.get(appMode))"
        }
    }

    func statusDescription() -> String {
        switch connectionState {
        case .connected:
            return localizedString("ais_connection_connected")
        case .connecting:
            return localizedString("ais_connection_connecting")
        case .failed:
            return localizedString("ais_connection_failed")
        case .disconnected:
            return localizedString("ais_connection_disconnected")
        }
    }

    private func startConnection(with config: AisNmeaConnectionConfig) {
        AisObjectHelper.debugLog("[AisTrackerPlugin] startConnection requested config=\(config.debugDescription) previous=\(activeConnectionConfig?.debugDescription ?? "none") state=\(connectionState)")
        resetNmeaLocationProvider()
        stopSharedNetworkListener(updateState: false)
        updateConnectionState(.connecting)
        activeConnectionConfig = config
        switch config.proto {
        case .udp:
            AisObjectHelper.debugLog("[AisTrackerPlugin] start AIS/NMEA UDP port=\(config.port)")
            networkListener = AisMessageListener(dataListener: networkDataListener, udpPort: Int32(config.port))
        case .tcp:
            AisObjectHelper.debugLog("[AisTrackerPlugin] start AIS/NMEA TCP host=\(config.host) port=\(config.port)")
            networkListener = AisMessageListener(dataListener: networkDataListener, serverIp: config.host, serverPort: Int32(config.port))
        }
    }

    private func updateConnectionForCurrentProfileSettings(clearObjectsOnConnectionChange: Bool = false) {
        guard isEnabled() else {
            AisObjectHelper.debugLog("[AisTrackerPlugin] updateConnection skip: plugin disabled")
            if clearObjectsOnConnectionChange {
                clearSimulationObjects()
            }
            stopAisNetworkListener()
            return
        }

        let config = currentConnectionConfig()
        AisObjectHelper.debugLog("[AisTrackerPlugin] updateConnection config=\(config.debugDescription) active=\(activeConnectionConfig?.debugDescription ?? "none") listener=\(networkListener != nil) state=\(connectionState)")
        guard config.isConnectable else {
            AisObjectHelper.debugLog("[AisTrackerPlugin] updateConnection stop: config is not connectable")
            if clearObjectsOnConnectionChange {
                clearSimulationObjects()
            }
            stopAisNetworkListener()
            return
        }

        if canReuseActiveConnection(for: config) {
            aisDataManager.startUpdates()
            AisObjectHelper.debugLog("[AisTrackerPlugin] updateConnection reuse active connection")
            return
        }
        if clearObjectsOnConnectionChange {
            clearSimulationObjects()
        }
        aisDataManager.startUpdates()
        startConnection(with: config)
    }

    private func currentConnectionConfig() -> AisNmeaConnectionConfig {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        let rawProtocol = Int(protocolPref.get(appMode))
        let host = hostPref.get(appMode).trimmingCharacters(in: .whitespacesAndNewlines)
        let tcpPort = Int(tcpPortPref.get(appMode))
        let udpPort = Int(udpPortPref.get(appMode))
        AisObjectHelper.debugLog("[AisTrackerPlugin] current profile=\(appMode.stringKey ?? "unknown") rawProtocol=\(rawProtocol) host=\(host) tcpPort=\(tcpPort) udpPort=\(udpPort)")
        let proto = AisNmeaProtocol(rawValue: rawProtocol) ?? .udp
        switch proto {
        case .udp:
            return AisNmeaConnectionConfig(proto: .udp, host: "", port: max(1, udpPort))
        case .tcp:
            return AisNmeaConnectionConfig(proto: .tcp, host: host, port: max(1, tcpPort))
        }
    }

    private func canReuseActiveConnection(for config: AisNmeaConnectionConfig) -> Bool {
        networkListener != nil
            && activeConnectionConfig == config
            && (connectionState == .connecting || connectionState == .connected)
    }
    
    private func handleAisSentence(_ sentence: String) {
        aisDecoderQueue.async { [weak self] in
            guard let self else { return }
            
            guard let object = decoder.decode(sentence: sentence) else { return }
            
            DispatchQueue.main.async {
                self.aisDataManager.onAisObjectReceived(object)
            }
        }
    }

    private func stopSharedNetworkListener(updateState: Bool) {
        cancelNmeaLocationWatchdog()
        if networkListener != nil {
            AisObjectHelper.debugLog("[AisTrackerPlugin] stop AIS/NMEA listener config=\(activeConnectionConfig?.debugDescription ?? "none") updateState=\(updateState)")
        }
        networkListener?.stopListener()
        networkListener = nil
        activeConnectionConfig = nil
        if updateState {
            updateConnectionState(.disconnected)
        }
    }

    private func scheduleNmeaLocationWatchdog() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.scheduleNmeaLocationWatchdog()
            }
            return
        }
        cancelNmeaLocationWatchdog()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            nmeaLocationWatchdogWorkItem = nil
            guard useNmeaLocationPref.get(), networkListener != nil else { return }
            AisObjectHelper.debugLog("[AisTrackerPlugin] NMEA location timeout; falling back to CoreLocation")
            resetNmeaLocationProvider()
        }
        nmeaLocationWatchdogWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.nmeaLocationTimeout, execute: workItem)
    }

    private func cancelNmeaLocationWatchdog() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.cancelNmeaLocationWatchdog()
            }
            return
        }
        nmeaLocationWatchdogWorkItem?.cancel()
        nmeaLocationWatchdogWorkItem = nil
    }

    private func updateConnectionState(_ state: AisNmeaConnectionState) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateConnectionState(state)
            }
            return
        }
        guard connectionState != state else {
            return
        }
        connectionState = state
        AisObjectHelper.debugLog("[AisTrackerPlugin] connectionState=\(state)")
        NotificationCenter.default.post(name: .aisNmeaConnectionStateChanged, object: self)
    }

    fileprivate func onNetworkAisObjectReceived(_ object: AisObject) {
        if connectionState != .connected {
            updateConnectionState(.connected)
        }
        DispatchQueue.main.async { [weak self] in
            self?.aisDataManager.onAisObjectReceived(object)
        }
    }

    fileprivate func onNetworkNmeaLocationReceived(_ location: AisLocation) {
        if connectionState != .connected {
            updateConnectionState(.connected)
        }
        let clLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.latitude,
                                                                       longitude: location.longitude),
                                    altitude: 0,
                                    horizontalAccuracy: kCLLocationAccuracyNearestTenMeters,
                                    verticalAccuracy: -1,
                                    course: location.hasBearing ? CLLocationDirection(location.bearing) : -1,
                                    speed: location.hasSpeed ? CLLocationSpeed(location.speed) : -1,
                                    timestamp: Date())
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard useNmeaLocationPref.get() else {
                resetNmeaLocationProvider()
                return
            }
            guard let locationServices = OsmAndApp.swiftInstance().locationServices else { return }
            guard !locationServices.isRouteAnimating() else {
                resetNmeaLocationProvider()
                return
            }
            locationServices.setLocationFromExternalProvider(clLocation)
            scheduleNmeaLocationWatchdog()
            if AisLogger.shared.isEnabled {
                AisObjectHelper.debugLog("[AisTrackerPlugin] location from NMEA lat=\(clLocation.coordinate.latitude) lon=\(clLocation.coordinate.longitude)")
            }
        }
    }

    @objc private func onApplicationModeChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let appMode = OAAppSettings.sharedManager().applicationMode.get()
            AisObjectHelper.debugLog("[AisTrackerPlugin] applicationModeChanged mode=\(appMode.stringKey ?? "unknown")")
            if !useNmeaLocationPref.get(appMode) {
                resetNmeaLocationProvider()
            }
            updateConnectionForCurrentProfileSettings(clearObjectsOnConnectionChange: true)
        }
    }

    deinit {
        nmeaLocationWatchdogWorkItem?.cancel()
        applicationModeObserver?.detach()
    }
}

private final class AisNetworkDataListener: NSObject, AisDataListener {
    private weak var plugin: AisTrackerPlugin?

    init(plugin: AisTrackerPlugin) {
        self.plugin = plugin
    }

    func onAisObjectReceived(ais: AisObject) {
        plugin?.onNetworkAisObjectReceived(ais)
    }

    func onNmeaLocationReceived(location: AisLocation) {
        plugin?.onNetworkNmeaLocationReceived(location)
    }
}
