//
//  AisDataManager.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

extension Notification.Name {
    static let aisSimulationStatusChanged = Notification.Name("OAAisSimulationStatusChanged")
}

@objcMembers
final class AisDataManager: NSObject {
    private static let objectLimit = 200

    var objects: [AisObject] {
        Array(objectsByMmsi.values)
    }
    
    private var objectsByMmsi: [Int: AisObject] = [:]
    private var cleanupTimer: Timer?
    
    private weak var plugin: AisTrackerPlugin?
    
    init(plugin: AisTrackerPlugin) {
        self.plugin = plugin
        super.init()
    }

    func startUpdates() {
        stopUpdates()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.removeLostObjects()
        }
    }

    func stopUpdates() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    func cleanupResources() {
        stopUpdates()
        objectsByMmsi.removeAll()
        plugin?.onAisObjectsChanged()
    }

    func onAisObjectReceived(_ ais: AisObject) {
        let object: AisObject
        let event: String
        let mmsi = Int(ais.mmsi)
        if let existing = objectsByMmsi[mmsi] {
            existing.set(ais: ais)
            object = existing
            event = "merge"
        } else {
            object = AisObject(ais: ais)
            objectsByMmsi[mmsi] = object
            event = "new"
        }
        if objectsByMmsi.count > Self.objectLimit {
            removeOldestObject()
        }
        guard let storedObject = objectsByMmsi[Int(object.mmsi)], storedObject === object else { return }
        AisObjectHelper.debugLog("[AisDataManager] data \(event) total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(object))")
        plugin?.onAisObjectReceived(object)
    }

    func removeLostObjects() {
        guard let plugin else { return }
        let maxAge = plugin.maxObjectAgeInMinutes()
        let removed = objectsByMmsi.values.filter { $0.isLost(maxAgeInMin: Int32(maxAge)) }
        for object in removed {
            objectsByMmsi.removeValue(forKey: Int(object.mmsi))
            AisObjectHelper.debugLog("[AisDataManager] data remove-lost maxAge=\(maxAge)m total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(object))")
            plugin.onAisObjectRemoved(object)
        }
    }

    private func removeOldestObject() {
        guard let oldest = objectsByMmsi.values.min(by: { $0.lastUpdate < $1.lastUpdate }) else { return }
        objectsByMmsi.removeValue(forKey: Int(oldest.mmsi))
        AisObjectHelper.debugLog("[AisDataManager] data remove-oldest limit=\(Self.objectLimit) total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(oldest))")
        plugin?.onAisObjectRemoved(oldest)
    }
}
