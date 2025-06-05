//
//  OBDService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 21.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class OBDService: NSObject {
    static let shared = OBDService()
    
    private var obdDispatcher: OBDDispatcher?
    private var cachedObdSensor: OBDVehicleMetricsSensor?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    func startDispatcher() {
        NSLog("[OBDService] -> startDispatcher")
        
        if obdDispatcher != nil {
            stopDispatcher()
        } else {
            OBDDataComputer.OBDTypeWidget.entries.forEach {
                OBDDataComputer.shared.registerWidget(type: $0, averageTimeSeconds: 0)
            }
        }

        let dispatcher = OBDDispatcher(debug: false)
        self.obdDispatcher = dispatcher
        OBDDataComputer.shared.obdDispatcher = dispatcher
        
        let connector = OAOBDConnector()

        connector.disconnectHandler = {
            NSLog("[OBDService] -> disconnectHandler")
        }
        connector.failureHandler = {
            NSLog("[OBDService] -> failureHandler")
            DeviceHelper.shared.getOBDDevice()?.disconnect(completion: { _ in })
        }
        
        if let obdConnector = connector as? OBDConnector {
            dispatcher.connect(connector: obdConnector)
        } else {
            NSLog("[OBDService] -> Failed to cast OAOBDConnector to OBDConnector")
        }
    }
    
    func stopDispatcher() {
        NSLog("[OBDService] -> stopDispatcher")
        self.obdDispatcher?.setReadStatusListener(listener: nil)
        self.obdDispatcher?.stopReading()
        self.obdDispatcher = nil
        
        OBDDataComputer.shared.obdDispatcher?.setReadStatusListener(listener: nil)
        OBDDataComputer.shared.obdDispatcher?.stopReading()
        OBDDataComputer.shared.obdDispatcher = nil
    }
    
    func sendCommand(_ command: String?) -> Bool {
        guard let command, !command.isEmpty else {
            NSLog("[OBDService] -> sendCommand command isEmpty")
            return false
        }
        
        guard let data = command.data(using: .ascii) else {
            NSLog("[OBDService] -> sendCommand data is nil")
            return false
        }
        
        guard let device = DeviceHelper.shared.getOBDDevice() else {
            NSLog("[OBDService] -> device is nil")
            return false
        }
        
        guard let ecuWriteCharacteristic = device.ecuWriteCharacteristic else {
            NSLog("[OBDService] -> ecuWriteCharacteristic is nil")
            return false
        }
        NSLog("[OBDService] -> send command: \(command)")
        device.peripheral.writeValue(ofCharac: ecuWriteCharacteristic, value: data, completion: { result in
            switch result {
            case .success:
                NSLog("[OBDService] -> peripheral writeValue success")
            case .failure(let error):
                NSLog("[OBDService] -> peripheral writeValue failure | \(error.localizedDescription)")
            }
        })
        
        return true
    }
    
    @objc private func handleDeviceDisconnected() {
        NSLog("[OBDService] -> handleDeviceDisconnected")
        stopDispatcher()
        clearBuffer()
        cachedObdSensor = nil
    }
}

// MARK: - Response Sensor
extension OBDService {
    var obdSensor: OBDVehicleMetricsSensor? {
        if let cachedObdSensor {
            return cachedObdSensor
        }
        let sensor = DeviceHelper.shared.getOBDDevice()?.sensors.compactMap({ $0 as? OBDVehicleMetricsSensor }).first
        cachedObdSensor = sensor
        return sensor
    }
    
    var readObdBuffer: String? {
        obdSensor?.readObdBuffer()
    }

    var isBufferReadyForRead: Bool {
        guard let obdSensor else { return false }
        return !obdSensor.isProcessingReading && obdSensor.isReadyBufferResponse
    }
    
    func isProcessingReading(isReading: Bool) {
        obdSensor?.isProcessingReading = isReading
    }
    
    func writeObdBuffer(_ value: String) {
        obdSensor?.writeObdBuffer(string: value)
    }
    
    func clearBuffer() {
        NSLog("[OBDService] -> clearBuffer")
        obdSensor?.clearBuffer()
    }
}
