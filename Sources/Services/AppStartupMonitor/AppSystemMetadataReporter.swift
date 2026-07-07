//
//  AppSystemMetadataReporter.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class AppSystemMetadataReporter {
    static func makeLaunchContextLines(launchOptions: NSDictionary?) -> [String] {
        makeAppInfoLines()
            + makeDeviceInfoLines()
            + makeRuntimeInfoLines()
            + makeStorageInfoLines()
            + ["Launch options: \(summarizeLaunchOptions(launchOptions))"]
    }
    
    private static func makeAppInfoLines() -> [String] {
        let bundle = Bundle.main
        let displayName = stringInfo(for: "CFBundleDisplayName") ?? stringInfo(for: "CFBundleName") ?? "unknown"
        let bundleIdentifier = bundle.bundleIdentifier ?? "unknown"
        let version = stringInfo(for: "CFBundleShortVersionString") ?? "unknown"
        let build = stringInfo(for: "CFBundleVersion") ?? "unknown"
        
        return [
            "App: \(displayName) (\(bundleIdentifier))",
            "Version: \(version) (\(build))"
        ]
    }
    
    private static func makeDeviceInfoLines() -> [String] {
        let device = UIDevice.current
        let hardwareIdentifier = deviceHardwareIdentifier()
        let screen = UIScreen.main
        let bounds = screen.bounds
        let nativeBounds = screen.nativeBounds
        let preferredLanguages = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
        let timeZone = TimeZone.current.identifier
        
        return [
            "Device: \(hardwareIdentifier) (\(device.model)), \(device.systemName) \(device.systemVersion), \(ProcessInfo.processInfo.processorCount) CPU cores",
            "Screen: \(formatSize(bounds.size)) pt @\(screen.scale)x, native \(formatSize(nativeBounds.size)) px",
            "Locale: \(Locale.current.identifier), preferred: \(preferredLanguages.isEmpty ? "none" : preferredLanguages), timezone: \(timeZone)"
        ]
    }
    
    private static func makeRuntimeInfoLines() -> [String] {
        let processInfo = ProcessInfo.processInfo
        let application = UIApplication.shared
        let protectedDataAvailable = application.isProtectedDataAvailable ? "yes" : "no"
        let backgroundRefresh = UIApplication.backgroundRefreshStatusDescription(application.backgroundRefreshStatus)
        let thermalState = ProcessInfo.thermalStateDescription(processInfo.thermalState)
        let lowPowerMode = processInfo.isLowPowerModeEnabled ? "enabled" : "disabled"
        let memory = ByteCountFormatter.string(fromByteCount: Int64(processInfo.physicalMemory), countStyle: .memory)
        
        return [
            "State: application \(UIApplication.stateDescription(application.applicationState)), protected data: \(protectedDataAvailable), background refresh: \(backgroundRefresh)",
            "System: physical memory \(memory), thermal state: \(thermalState), low power mode: \(lowPowerMode)"
        ]
    }
    
    private static func makeStorageInfoLines() -> [String] {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let totalSize = attributes[.systemSize] as? NSNumber
            let freeSize = attributes[.systemFreeSize] as? NSNumber
            let total = totalSize.map { ByteCountFormatter.string(fromByteCount: $0.int64Value, countStyle: .file) } ?? "unknown"
            let free = freeSize.map { ByteCountFormatter.string(fromByteCount: $0.int64Value, countStyle: .file) } ?? "unknown"
            return ["Storage: free \(free), total \(total)"]
        } catch {
            return ["Storage: unavailable (\(error.localizedDescription))"]
        }
    }
    
    private static func summarizeLaunchOptions(_ launchOptions: NSDictionary?) -> String {
        guard let launchOptions, launchOptions.count > 0 else {
            return "none"
        }
        
        var summaries: [String] = []
        for key in launchOptions.allKeys {
            let keyDescription = describeLaunchOptionKey(key)
            let value = launchOptions[key]
            summaries.append("\(keyDescription)=\(describeLaunchOptionValue(value, for: key))")
        }
        return summaries.sorted().joined(separator: ", ")
    }
    
    private static func describeLaunchOptionKey(_ key: Any) -> String {
        guard let rawKey = key as? String else {
            return String(describing: key)
        }
        
        switch rawKey {
        case UIApplication.LaunchOptionsKey.url.rawValue:
            return "url"
        case UIApplication.LaunchOptionsKey.sourceApplication.rawValue:
            return "sourceApplication"
        case UIApplication.LaunchOptionsKey.remoteNotification.rawValue:
            return "remoteNotification"
        case "UIApplicationLaunchOptionsLocalNotificationKey":
            return "localNotification"
        case UIApplication.LaunchOptionsKey.location.rawValue:
            return "location"
        case UIApplication.LaunchOptionsKey.newsstandDownloads.rawValue:
            return "newsstandDownloads"
        case UIApplication.LaunchOptionsKey.bluetoothCentrals.rawValue:
            return "bluetoothCentrals"
        case UIApplication.LaunchOptionsKey.bluetoothPeripherals.rawValue:
            return "bluetoothPeripherals"
        case UIApplication.LaunchOptionsKey.shortcutItem.rawValue:
            return "shortcutItem"
        case UIApplication.LaunchOptionsKey.userActivityDictionary.rawValue:
            return "userActivityDictionary"
        case UIApplication.LaunchOptionsKey.userActivityType.rawValue:
            return "userActivityType"
        case UIApplication.LaunchOptionsKey.cloudKitShareMetadata.rawValue:
            return "cloudKitShareMetadata"
        default:
            return rawKey
        }
    }
    
    private static func describeLaunchOptionValue(_ value: Any?, for key: Any) -> String {
        guard let value else {
            return "nil"
        }
        
        if let url = value as? URL {
            return sanitizedURLDescription(url)
        }
        
        if let string = value as? String {
            return string
        }
        
        if let dictionary = value as? NSDictionary {
            return "dictionary(keys: \(dictionary.allKeys.map { String(describing: $0) }.sorted().joined(separator: ",")))"
        }
        
        if let array = value as? NSArray {
            return "array(count: \(array.count))"
        }
        
        if describeLaunchOptionKey(key) == "shortcutItem", let shortcutItem = value as? UIApplicationShortcutItem {
            return "type: \(shortcutItem.type)"
        }
        
        return String(describing: type(of: value))
    }
    
    private static func sanitizedURLDescription(_ url: URL) -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme ?? url.scheme ?? "unknown"
        let host = components?.host ?? "none"
        return "present(scheme: \(scheme), host: \(host))"
    }
    
    private static func deviceHardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "unknown" : identifier
    }
    
    private static func stringInfo(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
    
    private static func formatSize(_ size: CGSize) -> String {
        "\(Int(size.width))x\(Int(size.height))"
    }
}

private extension UIApplication {
    static func stateDescription(_ state: UIApplication.State) -> String {
        switch state {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
    
    static func backgroundRefreshStatusDescription(_ status: UIBackgroundRefreshStatus) -> String {
        switch status {
        case .available:
            return "available"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        @unknown default:
            return "unknown"
        }
    }
}

private extension ProcessInfo {
    static func thermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "unknown"
        }
    }
}
