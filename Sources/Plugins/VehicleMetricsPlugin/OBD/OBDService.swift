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
    
    var bufferResponse: Data? {
        DeviceHelper.shared.getOBDDevice()?.sensors.compactMap({ $0 as? OBDVehicleMetricsSensor }).first?.buffer
    }
    
    var isReadyBufferResponse: Bool {
        DeviceHelper.shared.getOBDDevice()?.sensors.compactMap({ $0 as? OBDVehicleMetricsSensor }).first?.isReadyBufferResponse ?? false
    }
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceDisconnected),
                                               name: .DeviceDisconnected,
                                               object: nil)
    }
    
    func startDispatcher() {
        NSLog("[OBDService] -> startDispatcher")
        let dispatch = OBDDispatcher(debug: false)
        OBDDataComputer.shared.obdDispatcher = dispatch
        
        OBDDataComputer.OBDTypeWidget.entries.forEach {
            OBDDataComputer.shared.registerWidget(type: $0, averageTimeSeconds: 0)
        }
        
        if let connector = OAOBDConnector() as? OBDConnector {
            dispatch.connect(connector: connector)
        }
    }
    
    func stopDispatcher() {
        OBDDataComputer.shared.obdDispatcher?.stopReading()
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
    
    func clearBuffer() {
        DeviceHelper.shared.getOBDDevice()?.sensors.compactMap({ $0 as? OBDVehicleMetricsSensor }).first?.clearBuffer()
    }
    
    @objc private func handleDeviceDisconnected() {
        stopDispatcher()
    }
}
