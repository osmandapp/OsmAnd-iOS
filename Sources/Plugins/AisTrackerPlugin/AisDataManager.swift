import Foundation

extension Notification.Name {
    static let aisObjectReceived = Notification.Name("OAAisObjectReceived")
    static let aisObjectRemoved = Notification.Name("OAAisObjectRemoved")
    static let aisObjectsChanged = Notification.Name("OAAisObjectsChanged")
    static let aisSimulationStatusChanged = Notification.Name("OAAisSimulationStatusChanged")
}

@objcMembers
final class AisDataManager: NSObject {
    private static let objectLimit = 200

    private weak var plugin: OAAisTrackerPlugin?
    private var objectsByMmsi: [Int: AisObject] = [:]
    private var cleanupTimer: Timer?

    init(plugin: OAAisTrackerPlugin) {
        self.plugin = plugin
        super.init()
    }

    var objects: [AisObject] {
        Array(objectsByMmsi.values)
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
        NotificationCenter.default.post(name: .aisObjectsChanged, object: plugin)
    }

    func onAisObjectReceived(_ ais: AisObject) {
        let object: AisObject
        if let existing = objectsByMmsi[ais.mmsi] {
            existing.merge(ais)
            object = existing
        } else {
            objectsByMmsi[ais.mmsi] = ais
            object = ais
        }
        if objectsByMmsi.count >= Self.objectLimit {
            removeOldestObject()
        }
        plugin?.onAisObjectReceived(object)
        NotificationCenter.default.post(name: .aisObjectsChanged, object: plugin)
    }

    func removeLostObjects() {
        guard let plugin else { return }
        let maxAge = plugin.maxObjectAgeInMinutes()
        let removed = objectsByMmsi.values.filter { $0.isLost(maxAgeMinutes: maxAge) }
        for object in removed {
            objectsByMmsi.removeValue(forKey: object.mmsi)
            plugin.onAisObjectRemoved(object)
        }
        if !removed.isEmpty {
            NotificationCenter.default.post(name: .aisObjectsChanged, object: plugin)
        }
    }

    private func removeOldestObject() {
        guard let oldest = objectsByMmsi.values.min(by: { $0.lastUpdate < $1.lastUpdate }) else { return }
        objectsByMmsi.removeValue(forKey: oldest.mmsi)
        plugin?.onAisObjectRemoved(oldest)
    }
}
