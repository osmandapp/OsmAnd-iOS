//
//  OBDService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 21.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class OBDService {
    static let shared = OBDService()
        
    private init() {
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
    
    @objc private func handleDeviceDisconnected() {
        stopDispatcher()
    }
}
