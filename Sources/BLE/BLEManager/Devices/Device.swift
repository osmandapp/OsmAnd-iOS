//
//  Device.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 25.09.2023.
//

import SwiftyBluetooth
import CoreBluetooth
import UIKit

extension Notification.Name {
    static let DeviceRSSIUpdated = NSNotification.Name("DeviceRSSIUpdated")
}

class Device {
    var deviceType: DeviceType!
    var peripheral: Peripheral!
    var rssi = -1
    var deviceName: String = ""
    var didChangeCharacteristic: (() -> Void)? = nil
    private var RSSIUpdateTimer: Timer?
    
    var id: String {
        peripheral.identifier.uuidString
    }
    
    var sensors: [Sensor] = [BLEBatterySensor()]
    
    var sections: Dictionary<String, Any> = [:]
    
    class var getServiceUUID: String {
        ""
    }
    
    var getServiceConnectedImage: UIImage {
        UIImage()
    }
    
    var getDataFields: Dictionary<String, String>? {
        return nil
    }
    
    var getSettingsFields: Dictionary<String, Any>? {
        return nil
    }
    
    
    func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(forName: Peripheral.PeripheralCharacteristicValueUpdate,
                                               object: peripheral,
                                               queue: nil) { [weak self] notification in
            self?.peripheralCharacteristicValueUpdate(notification: notification as NSNotification)
        }
    }
    
    func peripheralCharacteristicValueUpdate(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              notification.userInfo?["error"] as? SBError == nil else {
            return
        }
        guard let characteristic = userInfo["characteristic"] as? CBCharacteristic else {
            return
        }
        update(with: characteristic) { [weak self] result in
            if case .success = result {
                self?.didChangeCharacteristic?()
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
         - value : Heart Rate Test Alex
       ▿ 5 : 2 elements
         - key : "kCBAdvDataServiceUUIDs"
         ▿ value : 2 elements
           - 0 : Device Information
           - 1 : Heart Rate
     */
}

// RSSI
extension Device {
    func notifyRSSI() {
        RSSIUpdateTimer?.invalidate()
        RSSIUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] timer in
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
                    NotificationCenter.default.post(name: .DeviceRSSIUpdated, object: nil)
                }
                debugPrint(self.rssi)
            }
        }
    }
}

extension Result where Success == Void {
    static var success: Result { .success(()) }
}
