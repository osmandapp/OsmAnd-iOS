import CoreLocation
import UIKit

@objcMembers
final class AisTrackerPlugin: OAPlugin {
    static let pluginId = "osmand.aistracker"
    static let protocolPrefId = "ais_nmea_protocol"
    static let hostPrefId = "ais_address_nmea_server"
    static let tcpPortPrefId = "ais_port_nmea_server"
    static let udpPortPrefId = "ais_port_nmea_local"
    static let overrideLocationPrefId = "ais_use_nmea_location"
    static let objectLostTimeoutPrefId = "ais_object_lost_timeout"
    static let shipLostTimeoutPrefId = "ais_ship_lost_timeout"
    static let cpaWarningTimePrefId = "ais_cpa_warning_time"
    static let cpaWarningDistancePrefId = "ais_cpa_warning_distance"
    static let aisConnectLoggingPrefId = "ais_connect_logging"
    static let layerDebugLoggingPrefId = "ais_layer_debug_logging"

    let protocolPref: OACommonInteger
    let hostPref: OACommonString
    let tcpPortPref: OACommonInteger
    let udpPortPref: OACommonInteger
    let overrideLocationPref: OACommonBoolean
    let objectLostTimeoutPref: OACommonInteger
    let shipLostTimeoutPref: OACommonInteger
    let cpaWarningTimePref: OACommonInteger
    let cpaWarningDistancePref: OACommonDouble
    let aisConnectLoggingPref: OACommonBoolean
    let layerDebugLoggingPref: OACommonBoolean

    private let connection = AisNmeaConnection()
    private let decoder = AisMessageDecoder()
    private let aisDecoderQueue = DispatchQueue(label: "com.app.ais.decoder", qos: .userInitiated)
    
    private var applicationModeObserver: OAAutoObserverProxy?
    
    private lazy var simulationProvider = AisSimulationProvider(plugin: self)
    private lazy var aisDataManager = AisDataManager(plugin: self)
    
    private(set) var connectionState: AisNmeaConnectionState = .disconnected
    private(set) var lastLocation: CLLocation?
    private(set) var fakeOwnLocation: CLLocation?
    private(set) var simulationFileName: String?
    private(set) var simulationStatusText: String?
    private(set) var lastMessageReceived = Date.distantPast
    
    private var simulationSentences = 0
    private var simulationDecoded = 0
    private var simulationObjects = 0
    private var simulationReceivedObjects = 0
    private var simulationRenderedObjects = 0

    override init() {
        protocolPref = OAAppSettings.sharedManager().registerIntPreference(Self.protocolPrefId, defValue: Int32(AisNmeaProtocol.udp.rawValue))
        hostPref = OAAppSettings.sharedManager().registerStringPreference(Self.hostPrefId, defValue: "192.168.200.16")
        tcpPortPref = OAAppSettings.sharedManager().registerIntPreference(Self.tcpPortPrefId, defValue: 4001)
        udpPortPref = OAAppSettings.sharedManager().registerIntPreference(Self.udpPortPrefId, defValue: 10110)
        overrideLocationPref = OAAppSettings.sharedManager().registerBooleanPreference(Self.overrideLocationPrefId, defValue: false)
        objectLostTimeoutPref = OAAppSettings.sharedManager().registerIntPreference(Self.objectLostTimeoutPrefId, defValue: 7)
        shipLostTimeoutPref = OAAppSettings.sharedManager().registerIntPreference(Self.shipLostTimeoutPrefId, defValue: 4)
        cpaWarningTimePref = OAAppSettings.sharedManager().registerIntPreference(Self.cpaWarningTimePrefId, defValue: 0)
        cpaWarningDistancePref = OAAppSettings.sharedManager().registerFloatPreference(Self.cpaWarningDistancePrefId, defValue: 1.0)
        aisConnectLoggingPref = OAAppSettings.sharedManager().registerBooleanPreference(Self.aisConnectLoggingPrefId, defValue: false)
        layerDebugLoggingPref = OAAppSettings.sharedManager().registerBooleanPreference(Self.layerDebugLoggingPrefId, defValue: false)
        super.init()

        connection.isConnectLoggingEnabled = { [weak self] in
            self?.isConnectLoggingEnabled() ?? false
        }
        connection.onStateChanged = { [weak self] state in
            self?.connectionState = state
            NotificationCenter.default.post(name: .aisNmeaConnectionStateChanged, object: self)
        }
        connection.onLocation = { [weak self] location in
            self?.handle(location)
        }
        connection.onSentence = { [weak self] sentence in
            self?.handleAisSentence(sentence)
        }
        applicationModeObserver = OAAutoObserverProxy(self,
                                                      withHandler: #selector(onApplicationModeChanged),
                                                      andObserve: OsmAndApp.swiftInstance().applicationModeChangedObservable)
    }

    deinit {
        applicationModeObserver?.detach()
    }

    override func getId() -> String {
        kInAppId_Addon_Ais_Tracker
    }

    override func getName() -> String {
        localizedString("plugin_ais_tracker_name")
    }

    override func getDescription() -> String {
        localizedString("plugin_ais_tracker_description") + "\n\n" + localizedString("plugin_ais_tracker_disclaimer")
    }

    override func getLogoResourceId() -> String? {
        "ic_plugin_nautical"
    }

    override func getAddedAppModes() -> [OAApplicationMode] {
        [OAApplicationMode.boat()]
    }

    override func initPlugin() -> Bool {
        let result = super.initPlugin()
        updateConnectionForCurrentProfile()
        return result
    }

    override func setEnabled(_ enabled: Bool) {
        super.setEnabled(enabled)
        if enabled {
            updateConnectionForCurrentProfile()
        } else {
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
        connection.stop()
        super.disable()
    }

    override func getSettingsController() -> UIViewController? {
        AisTrackerSettingsViewController(plugin: self)
    }

    func getSimulationProvider() -> AisSimulationProvider {
        simulationProvider
    }

    func isActiveForCurrentProfile() -> Bool {
        isEnabled() && OAAppSettings.sharedManager().applicationMode.get().isDerivedRouting(from: .boat())
    }

    func isConnectLoggingEnabled() -> Bool {
        aisConnectLoggingPref.get()
    }

    func isLayerDebugLoggingEnabled() -> Bool {
        layerDebugLoggingPref.get()
    }

    func startAisSimulation(_ fileURL: URL) {
        simulationFileName = fileURL.lastPathComponent
        simulationSentences = 0
        simulationDecoded = 0
        simulationObjects = 0
        simulationReceivedObjects = 0
        simulationRenderedObjects = 0
        simulationStatusText = localizedString("shared_string_loading")
        aisDebugLog("simulation start file=\(fileURL.lastPathComponent)")
        simulationProvider.startAisSimulation(fileURL)
    }

    func updateSimulationStatus(sentences: Int, decoded: Int, objects: Int, error: String?) {
        if let error, !error.isEmpty {
            simulationStatusText = error
            aisDebugLog("simulation status error=\(error)")
        } else {
            simulationSentences = sentences
            simulationDecoded = decoded
            simulationObjects = objects
            updateSimulationStatusText()
            aisDebugLog("simulation stats sentences=\(sentences) decoded=\(decoded) objects=\(objects)")
        }
        postSimulationStatusChanged()
    }

    func updateSimulationRenderedObjects(_ count: Int) {
        guard simulationFileName != nil else { return }
        guard simulationRenderedObjects != count else { return }
        simulationRenderedObjects = count
        updateSimulationStatusText()
        postSimulationStatusChanged()
    }

    func prepareAisSimulation() {
        connection.stop()
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
        aisDebugLog("simulation clear")
        fakeOwnLocation = nil
        simulationFileName = nil
        simulationStatusText = nil
        simulationSentences = 0
        simulationDecoded = 0
        simulationObjects = 0
        simulationReceivedObjects = 0
        simulationRenderedObjects = 0
        aisDataManager.cleanupResources()
    }

    func restartConnection() {
        guard isActiveForCurrentProfile() else {
            stopAisNetworkListener()
            return
        }
        aisDataManager.startUpdates()
        let proto = AisNmeaProtocol(rawValue: Int(protocolPref.get())) ?? .udp
        switch proto {
        case .udp:
            connection.startUDP(port: UInt16(max(1, udpPortPref.get())))
        case .tcp:
            connection.startTCP(host: hostPref.get(), port: UInt16(max(1, tcpPortPref.get())))
        }
    }

    func stopAisNetworkListener() {
        connection.stop()
        aisDataManager.stopUpdates()
    }

    private func updateConnectionForCurrentProfile() {
        if isActiveForCurrentProfile() {
            if !connection.isRunning {
                restartConnection()
            }
        } else {
            stopAisNetworkListener()
        }
    }

    func fakeOwnPosition(_ location: CLLocation?) {
        fakeOwnLocation = location
    }

    func handleSimulatedNmeaSentence(_ sentence: String) {
        handleAisSentence(sentence)
        if let location = AisNmeaParser.parseLocation(from: sentence) {
            handleSimulatedLocation(location)
        }
    }

    func handleSimulatedLocation(_ location: CLLocation) {
        handle(location)
    }

    func handleSimulatedAisObject(_ object: AisObject) {
        aisDataManager.onAisObjectReceived(object)
    }

    func getAisObjects() -> [AisObject] {
        aisDataManager.objects
    }
    // FIXME: cache for objectLostTimeoutPref shipLostTimeoutPref cpaWarningTimePref cpaWarningDistancePref
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
        lastMessageReceived = object.lastUpdate
        if simulationFileName != nil {
            let receivedObjects = getAisObjects().filter(\.hasPosition).count
            if simulationReceivedObjects != receivedObjects {
                simulationReceivedObjects = receivedObjects
                updateSimulationStatusText()
                postSimulationStatusChanged()
            }
        }
        aisDebugLog("plugin received withPosition=\(getAisObjects().filter(\.hasPosition).count) \(object.debugSummary)")
        NotificationCenter.default.post(name: .aisObjectReceived, object: self, userInfo: ["object": object])
    }

    func onAisObjectRemoved(_ object: AisObject) {
        aisDebugLog("plugin removed \(object.debugSummary)")
        NotificationCenter.default.post(name: .aisObjectRemoved, object: self, userInfo: ["object": object])
    }

    func hasCpaWarning(for object: AisObject) -> Bool {
        let warningTime = cpaWarningTimeInMinutes()
        let warningDistance = cpaWarningDistanceInNauticalMiles()
        guard object.isMovable,
              object.objectClass != .airplane,
              warningTime > 0,
              object.sog > 0,
              let ownPosition = ownPosition(),
              let aisPosition = object.location else {
            return false
        }
        AisTrackerHelper.getCpa(ownPosition, aisPosition, result: object.cpa)
        guard object.cpa.valid, object.cpa.tcpa > 0 else { return false }
        return Double(object.cpa.cpaDistance) <= warningDistance
            && object.cpa.tcpa * 60.0 <= Double(warningTime)
            && object.cpa.crossingTime1 >= 0
            && object.cpa.crossingTime2 >= 0
    }

    func updateCpa(for object: AisObject) {
        guard let ownPosition = ownPosition(),
              let aisPosition = object.currentLocation ?? object.location else {
            object.cpa.reset()
            return
        }
        AisTrackerHelper.getCpa(ownPosition, aisPosition, result: object.cpa)
    }

    func distanceInNauticalMiles(to object: AisObject) -> Double {
        guard let ownPosition = ownPosition(),
              let aisPosition = object.currentLocation ?? object.location else {
            return -1
        }
        return ownPosition.distance(from: aisPosition) / 1852.0
    }

    func bearing(to object: AisObject) -> Double {
        guard let ownPosition = ownPosition(),
              let aisPosition = object.currentLocation ?? object.location else {
            return -1
        }
        return Self.bearing(from: ownPosition.coordinate, to: aisPosition.coordinate)
    }

    func connectionDescription() -> String {
        let proto = AisNmeaProtocol(rawValue: Int(protocolPref.get())) ?? .udp
        switch proto {
        case .udp:
            return "UDP • \(udpPortPref.get())"
        case .tcp:
            return "TCP • \(hostPref.get()):\(tcpPortPref.get())"
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

    private func handle(_ location: CLLocation) {
        lastLocation = location
        NotificationCenter.default.post(name: .aisNmeaLocationReceived, object: self)
        if overrideLocationPref.get() {
            OsmAndApp.swiftInstance().locationServices?.setLocationFromNMEA(location)
        }
    }
    
//    private func handleAisSentence(_ sentence: String) {
//        Task {
//            guard let object = await decoder.decode(sentence: sentence) else { return }
//            
//            await MainActor.run {
//                self.aisDataManager.onAisObjectReceived(object)
//            }
//        }
//    }

//    private func handleAisSentence(_ sentence: String) {
//        guard let object = decoder.decode(sentence: sentence) else { return }
//        aisDataManager.onAisObjectReceived(object)
//    }
    
    private func handleAisSentence(_ sentence: String) {
        aisDecoderQueue.async { [weak self] in
            guard let self else { return }
            
            guard let object = decoder.decode(sentence: sentence) else { return }
            
            DispatchQueue.main.async {
                self.aisDataManager.onAisObjectReceived(object)
            }
        }
    }

    @objc private func onApplicationModeChanged() {
        updateConnectionForCurrentProfile()
       // updateLayers()
    }

    private func updateSimulationStatusText() {
        var parts = [
            "sentences \(simulationSentences)",
            "decoded \(simulationDecoded)",
            "objects \(simulationObjects)"
        ]
        if simulationReceivedObjects > 0 || simulationRenderedObjects > 0 {
            parts.append("received \(simulationReceivedObjects)")
            parts.append("rendered \(simulationRenderedObjects)")
        }
        simulationStatusText = parts.joined(separator: ", ")
    }

    private func postSimulationStatusChanged() {
        NotificationCenter.default.post(name: .aisSimulationStatusChanged, object: self)
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
}

extension Notification.Name {
    static let aisNmeaConnectionStateChanged = Notification.Name("OAAisNmeaConnectionStateChanged")
    static let aisNmeaLocationReceived = Notification.Name("OAAisNmeaLocationReceived")
}
