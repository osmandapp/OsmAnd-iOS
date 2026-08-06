//
//  AisDataManager.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

@objcMembers
final class AisDataManager: NSObject {
    private static let objectLimit = 20000

    var objects: [AisObject] {
        Array(objectsByMmsi.values)
    }
    
    private var objectsByMmsi: [Int: AisObject] = [:]
    private var cleanupTimer: Timer?
    private var memoryWarningObserver: NSObjectProtocol?
    
    private weak var plugin: AisTrackerPlugin?
    
    init(plugin: AisTrackerPlugin) {
        self.plugin = plugin
        super.init()
        memoryWarningObserver = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                                                       object: nil,
                                                                       queue: .main) { [weak self] _ in
            self?.removeAllObjectsOnMemoryWarning()
        }
    }

    func startUpdates() {
        stopUpdates()
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.removeLostObjects()
        }
        RunLoop.main.add(timer, forMode: .common)
        cleanupTimer = timer
    }

    func stopUpdates() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    func cleanupResources() {
        stopUpdates()
        removeAllObjects(reason: "cleanup")
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
        if AisLogger.shared.isEnabled {
            AisObjectHelper.debugLog("[AisDataManager] data \(event) total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(object))")
        }
        plugin?.onAisObjectReceived(object)
    }

    func removeLostObjects() {
        guard let plugin else { return }
        let maxAge = plugin.maxObjectAgeInMinutes()
        let removed = objectsByMmsi.values.filter { $0.isLost(maxAgeInMin: Int32(maxAge)) }
        for object in removed {
            objectsByMmsi.removeValue(forKey: Int(object.mmsi))
            if AisLogger.shared.isEnabled {
                AisObjectHelper.debugLog("[AisDataManager] data remove-lost maxAge=\(maxAge)m total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(object))")
            }
            plugin.onAisObjectRemoved(object)
        }
    }

    private func removeOldestObject() {
        guard let oldest = objectsByMmsi.values.min(by: { $0.lastUpdate < $1.lastUpdate }) else { return }
        objectsByMmsi.removeValue(forKey: Int(oldest.mmsi))
        if AisLogger.shared.isEnabled {
            AisObjectHelper.debugLog("[AisDataManager] data remove-oldest limit=\(Self.objectLimit) total=\(objectsByMmsi.count) \(AisObjectHelper.debugSummary(oldest))")
        }
        plugin?.onAisObjectRemoved(oldest)
    }

    private func removeAllObjectsOnMemoryWarning() {
        guard let plugin, plugin.isEnabled() else {
            objectsByMmsi.removeAll()
            return
        }
        removeAllObjects(reason: "memory-warning")
    }

    private func removeAllObjects(reason: String) {
        let removedCount = objectsByMmsi.count
        guard removedCount > 0 else { return }

        objectsByMmsi.removeAll()

        if AisLogger.shared.isEnabled {
            AisObjectHelper.debugLog("[AisDataManager] data remove-all reason=\(reason) removed=\(removedCount)")
        }

        plugin?.onAisObjectsChanged()
    }

    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }
}
