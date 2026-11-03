//
//  Device.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 25.09.2023.
//

import CoreBluetooth
import UIKit

extension Notification.Name {
    static let deviceRSSIUpdated = Notification.Name("DeviceRSSIUpdated")
    static let deviceDisconnected = Notification.Name("DeviceDisconnected")
    static let deviceSensorDataUpdated = Notification.Name("DeviceSensorDataUpdated")
}

enum DeviceState: Int {
    case disconnected, connecting, connected, disconnecting

    var description: String {
        switch self {
        case .disconnected: return localizedString("external_device_status_disconnect")
        case .connecting: return localizedString("external_device_status_connecting")
        case .connected: return localizedString("external_device_status_connect")
        case .disconnecting: return localizedString("external_device_status_disconnecting")
        }
    }
}

@objc(OADevice)
@objcMembers
class Device: NSObject {
    // swiftlint:disable all
    static let identifier = "identifier"

    class var getServiceUUID: String { "" }

    var deviceType: DeviceType!
    var rssi = -1
    var deviceName: String = ""
    var didChangeCharacteristic: (() -> Void)?
    var didDisconnect: (() -> Void)?
    var isSelected = false
    var isSimulator = false

    var sensors = [Sensor]()
    var sections = [String: Any]()

    var deviceServiceName: String {
        ""
    }

    var id: String {
        peripheral.identifier.uuidString
    }

    var isConnected: Bool {
        peripheral.state == .connected
    }

    var isConnecting: Bool {
        peripheral.state == .connecting
    }

    var isDisconnected: Bool {
        peripheral.state == .disconnected
    }

    var state: DeviceState {
        DeviceState(rawValue: peripheral.state.rawValue) ?? .disconnected
    }

    var getServiceConnectedImage: UIImage? {
        nil
    }

    var getServiceDisconnectedImage: UIImage? {
        nil
    }

    var getDataFields: [[String: String]]? {
        let result = sensors.compactMap { $0.dataFields }.flatMap { $0 }
        return result.isEmpty ? nil : result
    }

    var getSettingsFields: [String: Any]? {
        nil
    }

    private(set) var peripheral: Peripheral!

    private var RSSIUpdateTimer: Timer?
    private var characteristicObserver: NSObjectProtocol?
    private var disconnectedObserver: NSObjectProtocol?

    // swiftlint:enable all

    // MARK: - Initializer

    init(deviceType: DeviceType!,
         rssi: Int = 1,
         deviceName: String = "",
         didChangeCharacteristic: (() -> Void)? = nil,
         RSSIUpdateTimer: Timer? = nil) {
        super.init()
        self.deviceType = deviceType
        self.rssi = rssi
        self.deviceName = deviceName
        self.didChangeCharacteristic = didChangeCharacteristic
        self.RSSIUpdateTimer = RSSIUpdateTimer
        self.sensors = [BLEBatterySensor(device: self, sensorId: "battery_level")]
    }

    func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        var result = [WidgetType]()
        for sensor in sensors {
            for widgetType in sensor.getSupportedWidgetDataFieldTypes() ?? [] where !result.contains(widgetType) {
                result.append(widgetType)
            }
        }
        return result.isEmpty ? nil : result
    }

    func update(with characteristic: CBCharacteristic, result: @escaping (Result<Void, Error>) -> Void) { }

    func configure() {}

    func addObservers() {
        removeObservers()

        characteristicObserver = NotificationCenter.default.addObserver(forName: Peripheral.PeripheralCharacteristicValueUpdate,
                                                                        object: peripheral,
                                                                        queue: nil) { [weak self] notification in
            self?.peripheralCharacteristicValueUpdate(notification: notification as NSNotification)
        }

        disconnectedObserver = NotificationCenter.default.addObserver(forName: Peripheral.PeripheralDisconnected,
                                                                      object: peripheral,
                                                                      queue: nil) { [weak self] notification in
            guard let self else { return }
            if let identifier = notification.userInfo?["identifier"] as? UUID,
               identifier.uuidString == self.id {
                DeviceHelper.shared.removeDisconnected(device: self)
                didDisconnectDevice()
            }
        }
    }

    /*
     Printing description of advertisementData:
     ▿ 6 elements
     ▿ 0 : 2 elements
     - key : "kCBAdvDataTimestamp"
     - value : 717078802.347859
     ▿ 1 : 2 elements
     - key : "kCBAdvDataRxSecondaryPHY"
     - value : 0
     ▿ 2 : 2 elements
     - key : "kCBAdvDataIsConnectable"
     - value : 1
     ▿ 3 : 2 elements
     - key : "kCBAdvDataRxPrimaryPHY"
     - value : 1
     ▿ 4 : 2 elements
     - key : "kCBAdvDataLocalName"
     - value : Heart Rate
     ▿ 5 : 2 elements
     - key : "kCBAdvDataServiceUUIDs"
     ▿ value : 2 elements
     - 0 : Device Information
     - 1 : Heart Rate
     */

    func writeSensorDataToJson(json: NSMutableData, widgetDataFieldType: WidgetType) {
        for sensor in sensors {
            if let widgetTypes = sensor.getSupportedWidgetDataFieldTypes(),
               widgetTypes.contains(widgetDataFieldType),
               sensor.hasActualData(for: widgetDataFieldType) {
                sensor.writeSensorDataToJson(json: json, widgetDataFieldType: widgetDataFieldType)
            }
        }
    }

    func discoverCharacteristics(withUUIDs characteristicUUIDs: [CBUUIDConvertible]? = nil,
                                 ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                                 completion: @escaping CharacteristicRequestCallback) {
        peripheral.discoverCharacteristics(withUUIDs: characteristicUUIDs,
                                           ofServiceWithUUID: serviceUUID,
                                           completion: completion)
    }

    func disconnect(completion: @escaping DisconnectPeripheralCallback) {
        peripheral.disconnect(completion: completion)
    }

    func didDisconnectDevice() {
        debugPrint("didDisconnectDevice | \(deviceServiceName) | \(deviceName)")
        NotificationCenter.default.post(name: .deviceDisconnected,
                                        object: nil,
                                        userInfo: [Self.identifier: self.id])
        didDisconnect?()
    }

    func connect(withTimeout timeout: TimeInterval?, completion: @escaping ConnectPeripheralCallback) {
        peripheral.connect(withTimeout: timeout, completion: completion)
    }

    private func peripheralCharacteristicValueUpdate(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              notification.userInfo?["error"] as? SBError == nil else {
            return
        }
        guard let characteristic = userInfo["characteristic"] as? CBCharacteristic else {
            return
        }
        update(with: characteristic) { [weak self] result in
            guard case .success = result, let self else { return }
            NotificationCenter.default.post(name: .deviceSensorDataUpdated, object: self)
            didChangeCharacteristic?()
        }
    }

    private func removeObservers() {
        if let obs = characteristicObserver {
            NotificationCenter.default.removeObserver(obs)
            characteristicObserver = nil
        }
        if let obs = disconnectedObserver {
            NotificationCenter.default.removeObserver(obs)
            disconnectedObserver = nil
        }
    }

    deinit {
        removeObservers()
    }
}

extension Device {

    func setPeripheral(peripheral: Peripheral) {
        self.peripheral = peripheral
    }

    func discoverServices(withUUIDs serviceUUIDs: [CBUUIDConvertible]? = nil,
                          completion: @escaping ServiceRequestCallback) {
        peripheral.discoverServices(withUUIDs: serviceUUIDs,
                                    completion: completion)
    }

    func setNotifyValue(toEnabled enabled: Bool,
                        ofCharac charac: CBCharacteristic,
                        completion: @escaping UpdateNotificationStateCallback) {
        peripheral.setNotifyValue(toEnabled: enabled,
                                  forCharacWithUUID: charac,
                                  ofServiceWithUUID: charac.service!,
                                  completion: completion)
    }

    func writeValue(ofDescriptorWithUUID descriptorUUID: CBUUIDConvertible,
                    fromCharacWithUUID characUUID: CBUUIDConvertible,
                    ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                    value: Data,
                    completion: @escaping WriteRequestCallback) {
        peripheral.writeValue(ofCharacWithUUID: characUUID,
                              fromServiceWithUUID: serviceUUID,
                              value: value,
                              completion: completion)
    }
}

// MARK: - RSSI
extension Device {
    func notifyRSSI() {
        disableRSSI()
        RSSIUpdateTimer = .scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            readRSSI()
        })
    }

    func disableRSSI() {
        RSSIUpdateTimer?.invalidate()
        RSSIUpdateTimer = nil
    }

    private func readRSSI() {
        peripheral.readRSSI { [weak self] result in
            guard let self else { return }
            if case .success(let RSSI) = result {
                if rssi != RSSI {
                    rssi = RSSI
                    NotificationCenter.default.post(name: .deviceRSSIUpdated, object: nil)
                }
                debugPrint(self.rssi)
            }
        }
    }
}

// MARK: - Sensors of several services
extension Device {
    // Supported sensor services in the order of priority for the device type
    static let sensorServiceUUIDs = [GattAttributes.SERVICE_HEART_RATE,
                                     GattAttributes.SERVICE_TEMPERATURE,
                                     GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE,
                                     GattAttributes.SERVICE_RUNNING_SPEED_AND_CADENCE]

    // CoreBluetooth gives standard 16-bit UUIDs in the short form, e.g. "180D"
    static func isService(_ serviceUUID: String, matching uuid: String) -> Bool {
        fullUUID(serviceUUID) == fullUUID(uuid)
    }

    private static func fullUUID(_ uuid: String) -> String {
        let lowercased = uuid.lowercased()
        return lowercased.count == 4 ? "0000\(lowercased)-0000-1000-8000-00805f9b34fb" : lowercased
    }

    // A sensor can have several services (Garmin HRM 600: running speed and cadence + heart rate).
    // Adds a sensor for every supported service that has no sensor yet, returns true if one was added.
    @discardableResult
    func addSensors(forServices uuids: [String]) -> Bool {
        var added = false
        for serviceUUID in Device.sensorServiceUUIDs where !hasSensor(forService: serviceUUID) {
            guard uuids.contains(where: { Device.isService(serviceUUID, matching: $0) }),
                  let sensor = makeSensor(forService: serviceUUID) else { continue }
            sensors.append(sensor)
            added = true
        }
        return added
    }

    func getSensorServiceUUIDs() -> [String] {
        Device.sensorServiceUUIDs.filter { hasSensor(forService: $0) }
    }

    private func hasSensor(forService serviceUUID: String) -> Bool {
        sensors.contains { Device.serviceUUID(of: $0) == serviceUUID }
    }

    private static func serviceUUID(of sensor: Sensor) -> String? {
        switch sensor {
        case is BLEHeartRateSensor: return GattAttributes.SERVICE_HEART_RATE
        case is BLETemperatureSensor: return GattAttributes.SERVICE_TEMPERATURE
        case is BLEBikeSensor: return GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE
        case is BLERunningSensor: return GattAttributes.SERVICE_RUNNING_SPEED_AND_CADENCE
        default: return nil
        }
    }

    private func makeSensor(forService serviceUUID: String) -> Sensor? {
        switch serviceUUID {
        case GattAttributes.SERVICE_HEART_RATE: return BLEHeartRateSensor(device: self, sensorId: "heart_rate")
        case GattAttributes.SERVICE_TEMPERATURE: return BLETemperatureSensor(device: self, sensorId: "temperature")
        case GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE: return BLEBikeSensor(device: self, sensorId: "bike_scd")
        case GattAttributes.SERVICE_RUNNING_SPEED_AND_CADENCE: return BLERunningSensor(device: self, sensorId: "running")
        default: return nil
        }
    }
}

extension Result where Success == Void {
    static var success: Result { .success(()) }
}
