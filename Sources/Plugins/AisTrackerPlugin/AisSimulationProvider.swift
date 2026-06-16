//
//  AisSimulationProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared

final class AisMessageSimulationListener {
    private let fileURL: URL
    private let latency: TimeInterval
    private let queue = DispatchQueue(label: "net.osmand.ais.simulation.listener")
    private let lock = NSLock()
    
    private var cancelled = false
    
    private weak var plugin: AisTrackerPlugin?

    private var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    init(plugin: AisTrackerPlugin, fileURL: URL, latency: TimeInterval) {
        self.plugin = plugin
        self.fileURL = fileURL
        self.latency = latency
    }

    func start() {
        setCancelled(false)
        queue.async { [weak self] in
            guard let self else { return }
            let hasSecurityScopedAccess = self.fileURL.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScopedAccess {
                    self.fileURL.stopAccessingSecurityScopedResource()
                }
            }
            guard let text = try? String(contentsOf: self.fileURL, encoding: .utf8) else {
                self.postStatus(sentences: 0, decoded: 0, objects: 0, error: "Failed to read AIS simulation file")
                return
            }
            let sentences = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let stats = self.collectStats(sentences: sentences)
            self.postStatus(sentences: stats.sentences, decoded: stats.decoded, objects: stats.objects, error: nil)
            for sentence in sentences {
                if self.isCancelled {
                    return
                }
                Thread.sleep(forTimeInterval: self.latency)
                if self.isCancelled {
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let plugin = self?.plugin, plugin.isEnabled() else { return }
                    plugin.handleSimulatedNmeaSentence(sentence)
                }
            }
        }
    }

    func stop() {
        setCancelled(true)
    }

    private func setCancelled(_ cancelled: Bool) {
        lock.lock()
        self.cancelled = cancelled
        lock.unlock()
    }

    private func collectStats(sentences: [String]) -> (sentences: Int, decoded: Int, objects: Int) {
        let decoder = AisMessageDecoder()
        var decoded = 0
        var mmsi = Set<Int>()
        for sentence in sentences {
            guard let object = decoder.decode(sentence: sentence), object.position != nil else {
                continue
            }
            decoded += 1
            mmsi.insert(Int(object.mmsi))
        }
        return (sentences.count, decoded, mmsi.count)
    }

    private func postStatus(sentences: Int, decoded: Int, objects: Int, error: String?) {
        DispatchQueue.main.async {
            self.plugin?.updateSimulationStatus(sentences: sentences, decoded: decoded, objects: objects, error: error)
            var userInfo: [String: Any] = [
                "sentences": sentences,
                "decoded": decoded,
                "objects": objects
            ]
            if let error {
                userInfo["error"] = error
            }
            NotificationCenter.default.post(name: .aisSimulationStatusChanged,
                                            object: self.plugin,
                                            userInfo: userInfo)
        }
    }
}

@objcMembers
final class AisSimulationProvider: NSObject {
    private static let simulatedLatency: TimeInterval = 0.1

    private var listener: AisMessageSimulationListener?
    
    private weak var plugin: AisTrackerPlugin?

    init(plugin: AisTrackerPlugin) {
        self.plugin = plugin
        super.init()
    }

    func startAisSimulation(_ fileURL: URL) {
        stopAisSimulation()
        guard let plugin, plugin.isEnabled() else { return }
        plugin.prepareAisSimulation()
        let listener = AisMessageSimulationListener(plugin: plugin,
                                                    fileURL: fileURL,
                                                    latency: Self.simulatedLatency)
        self.listener = listener
        listener.start()
    }

    func stopAisSimulation() {
        listener?.stop()
        listener = nil
    }

    func initFakePosition() {
        guard plugin?.isEnabled() == true else { return }
        let fake = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 50.76077, longitude: 7.08747),
                              altitude: 0,
                              horizontalAccuracy: 5,
                              verticalAccuracy: -1,
                              course: 340,
                              speed: 3.0 * 0.514444,
                              timestamp: Date())
        plugin?.fakeOwnPosition(fake)
        let constants = AisObjectConstants.shared
        let position = AisObject(mmsi: 324578,
                                 msgType: 18,
                                 timeStamp: 20,
                                 navStatus: constants.INVALID_NAV_STATUS,
                                 manInd: constants.INVALID_MANEUVER_INDICATOR,
                                 heading: 340,
                                 cog: 340,
                                 sog: 3,
                                 lat: 50.76077,
                                 lon: 7.08747,
                                 rot: constants.INVALID_ROT)
        plugin?.handleSimulatedAisObject(position)

        let data = AisObject(mmsi: 324578,
                             msgType: 24,
                             imo: 0,
                             callSign: "callsign",
                             shipName: "fake",
                             shipType: 60,
                             dimensionToBow: 56,
                             dimensionToStern: 65,
                             dimensionToPort: 8,
                             dimensionToStarboard: 12,
                             draught: constants.INVALID_DRAUGHT,
                             destination: "home",
                             etaMon: constants.INVALID_ETA,
                             etaDay: constants.INVALID_ETA,
                             etaHour: constants.INVALID_ETA_HOUR,
                             etaMin: constants.INVALID_ETA_MIN)
        plugin?.handleSimulatedAisObject(data)
    }

    func initTestPassengerShip() {
        guard plugin?.isEnabled() == true else { return }
        let position = AisObject(mmsi: 34568, msgType: 1, timeStamp: 20, navStatus: 0, manInd: 1, heading: 320, cog: 320, sog: 8.4, lat: 50.738, lon: 7.099, rot: 0)
        plugin?.handleSimulatedAisObject(position)
        let data = AisObject(mmsi: 34568, msgType: 5, imo: 0, callSign: "TEST-CALLSIGN1", shipName: "TEST-Ship", shipType: 60, dimensionToBow: 56, dimensionToStern: 65, dimensionToPort: 8, dimensionToStarboard: 12, draught: 2, destination: "Potsdam", etaMon: 8, etaDay: 15, etaHour: 22, etaMin: 5)
        plugin?.handleSimulatedAisObject(data)
    }

    func initTestSailingBoat() {
        guard plugin?.isEnabled() == true else { return }
        let constants = AisObjectConstants.shared
        let position = AisObject(mmsi: 454011,
                                 msgType: 18,
                                 timeStamp: 20,
                                 navStatus: constants.INVALID_NAV_STATUS,
                                 manInd: constants.INVALID_MANEUVER_INDICATOR,
                                 heading: 125,
                                 cog: 125,
                                 sog: 4.4,
                                 lat: 50.737,
                                 lon: 7.098,
                                 rot: constants.INVALID_ROT)
        plugin?.handleSimulatedAisObject(position)
        let data = AisObject(mmsi: 454011, msgType: 24, imo: 0, callSign: "TEST-CALLSIGN2", shipName: "TEST-Sailor", shipType: 36, dimensionToBow: 0, dimensionToStern: 0, dimensionToPort: 0, dimensionToStarboard: 0, draught: constants.INVALID_DRAUGHT, destination: "home", etaMon: constants.INVALID_ETA, etaDay: constants.INVALID_ETA, etaHour: constants.INVALID_ETA_HOUR, etaMin: constants.INVALID_ETA_MIN)
        plugin?.handleSimulatedAisObject(data)
    }

    func initTestLandStation() {
        guard plugin?.isEnabled() == true else { return }
        let station = AisObject(mmsi: 878121, msgType: 4, lat: 50.736, lon: 7.100)
        plugin?.handleSimulatedAisObject(station)

        let aid = AisObject(mmsi: 521077, msgType: 21, lat: 50.735, lon: 7.101, aidType: 1, dimensionToBow: 0, dimensionToStern: 0, dimensionToPort: 0, dimensionToStarboard: 0)
        plugin?.handleSimulatedAisObject(aid)
    }

    func initTestAircraft() {
        guard plugin?.isEnabled() == true else { return }
        let aircraft = AisObject(mmsi: 910323, msgType: 9, timeStamp: 15, altitude: 65, cog: 180.5, sog: 55.0, lat: 50.734, lon: 7.102)
        plugin?.handleSimulatedAisObject(aircraft)
    }

    func initTestLawEnforcement() {
        guard plugin?.isEnabled() == true else { return }
        let position = AisObject(mmsi: 34569, msgType: 1, timeStamp: 20, navStatus: 5, manInd: 1, heading: 15, cog: 25, sog: 8.4, lat: 50.739, lon: 7.0931, rot: 0)
        plugin?.handleSimulatedAisObject(position)
        let data = AisObject(mmsi: 34569, msgType: 5, imo: 0, callSign: "TEST-CALLSIGN3", shipName: "Mecklenburg Vorpommern", shipType: 55, dimensionToBow: 26, dimensionToStern: 5, dimensionToPort: 8, dimensionToStarboard: 4, draught: 1, destination: "Potsdam", etaMon: 8, etaDay: 15, etaHour: 22, etaMin: 5)
        plugin?.handleSimulatedAisObject(data)
    }
}
