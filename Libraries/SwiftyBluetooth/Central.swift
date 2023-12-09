//
//  Central.swift
//
//  Copyright (c) 2016 Jordane Belanger
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import CoreBluetooth

/**
    The different results returned in the closure of the Central scanWithTimeout(...) function.

    - ScanStarted: The scan just started.
    - ScanResult: A Peripheral found result. `RSSI` will be nil if it could not be read.
    - ScanStopped: The scan ended.
 
*/
public enum PeripheralScanResult {
    case scanStarted
    case scanResult(peripheral: Peripheral, advertisementData: [String: Any], RSSI: Int?)
    case scanStopped(peripherals: [Peripheral], error: SBError?)
}

/**
    An enum type whoses rawValues mirror the CBCentralManagerState enum owns Integer values but without the ".Resetting" and ".Unknown" temporary values.

    - Unsupported: CBCentralManagerState.Unsupported
    - Unauthorized: CBCentralManagerState.Unauthorized
    - PoweredOff: CBCentralManagerState.PoweredOff
    - PoweredOn: CBCentralManagerState.PoweredOn

*/
public enum AsyncCentralState: Int {
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
    case unknown = -1
}

public typealias AsyncCentralStateCallback = (AsyncCentralState) -> Void
public typealias BluetoothStateCallback = (CBManagerState) -> Void
public typealias PeripheralScanCallback = (PeripheralScanResult) -> Void
public typealias ConnectPeripheralCallback = (Result<Void, Error>) -> Void
public typealias DisconnectPeripheralCallback = (Result<Void, Error>) -> Void

/// A singleton wrapping a CBCentralManager instance to run CBCentralManager related functions with closures based callbacks instead of the usual CBCentralManagerDelegate interface.
public final class Central {
    private static var _sharedInstance: Central?
    
    /// The name of a `Notification` posted by the Central sharedInstance when the app comes back from the background and restores the
    /// underlying CBCentralManager state after the centralManager:willRestoreState: delegate method is called.
    /// The userInfo contains an Array of `Peripheral` that were restored.
    /// Unwrap the peripherals with `notification.userInfo?["peripherals"] as? [Peripheral]`
    public static let CentralManagerWillRestoreState = Notification.Name("SwiftyBluetooth_CentralManagerWillRestoreStateNotification")
    
    /// The name of a `Notification` posted by the Central sharedInstance when its underlying CBCentralManager state changes. Take note that if the `CBCentralManager` state
    /// goes from poweredOn to something lower, all your peripherals will be invalidated and need to be discovered again.
    /// The new `CBCentralManagerState` can be found in the notification's userInfo.
    /// Unwrap with `notification.userInfo?["state"] as? CBCentralManagerState`
    public static let CentralStateChange = Notification.Name("SwiftyBluetooth_CentralStateChange")
    
    static let CentralCBPeripheralDisconnected = Notification.Name("SwiftyBluetooth_CentralCBPeripheralDisconnected")
    
    /// The sharedInstance Singleton, you can instantiate it yourself by
    /// calling `setSharedInstanceWith(restoreIdentifier: )` which will allow you
    /// to pass in a state preservation identifier. Otherwise, this sharedInstance
    /// be lazily initialized the first time you call this getter.
    public static var sharedInstance: Central {
        if let sharedInstance = _sharedInstance {
            return sharedInstance
        }
        _sharedInstance = Central()
        return _sharedInstance!
    }
    
    /// Allows you to initially set the sharedInstance and use the restore
    /// identifier string of your choice for state preservation between app
    /// launches.
    @discardableResult
    public static func setSharedInstanceWith(restoreIdentifier: String) -> Central {
        assert(_sharedInstance == nil, "You can only set the sharedInstance of the Central once and you must do so before calling any other SwiftyBluetooth functions.")
        _sharedInstance = Central(stateRestoreIdentifier: restoreIdentifier)
        return _sharedInstance!
    }
    
    fileprivate let centralProxy: CentralProxy
    
    private init() {
        self.centralProxy = CentralProxy()
    }
    
    private init(stateRestoreIdentifier: String) {
        self.centralProxy = CentralProxy(stateRestoreIdentifier: stateRestoreIdentifier)
    }
}

// MARK: Internal
typealias InitializeBluetoothCallback = (_ error: SBError?) -> Void

extension Central {
    func initializeBluetooth(completion: @escaping InitializeBluetoothCallback) {
        centralProxy.initializeBluetooth(completion)
    }
    
    func connect(peripheral: CBPeripheral,
                 timeout: TimeInterval = 10,
                 completion: @escaping ConnectPeripheralCallback) {
        centralProxy.connect(peripheral: peripheral, timeout: timeout, completion)
    }
    
    func disconnect(peripheral: CBPeripheral,
                    timeout: TimeInterval = 10,
                    completion: @escaping DisconnectPeripheralCallback) {
        centralProxy.disconnect(peripheral: peripheral, timeout: timeout, completion)
    }
}

// MARK: Public
extension Central {
    
    /// The underlying CBCentralManager CBManagerState
    public var state: CBManagerState {
        switch self.centralProxy.centralManager.state.rawValue {
        case 0:
            return .unknown
        case 1:
            return .resetting
        case 2:
            return .unsupported
        case 3:
            return .unauthorized
        case 4:
            return .poweredOff
        case 5:
            return .poweredOn
        default:
            assertionFailure("Unhandlable bluetooth state")
            return .unknown
        }
    }
    
    /// The underlying CBCentralManager isScanning value
    public var isScanning: Bool {
        return self.centralProxy.centralManager.isScanning
    }
    
    /// Attempts to return the periperals from a list of identifier "UUID"s
    public func retrievePeripherals(withUUIDs uuids: [CBUUIDConvertible]) -> [Peripheral] {
        let uuids = uuids.compactMap { UUID(uuidString: $0.CBUUIDRepresentation.uuidString)  }
        let cbPeripherals = self.centralProxy.centralManager.retrievePeripherals(withIdentifiers: uuids)
        let peripherals = cbPeripherals.map { cbPeripheral -> Peripheral in
            return Peripheral(peripheral: cbPeripheral)
        }
        return peripherals
    }
    
    /// Attempts to return the connected peripheral having the specific service CBUUIDs
    public func retrieveConnectedPeripherals(withServiceUUIDs uuids: [CBUUIDConvertible]) -> [Peripheral] {
        let cbUUIDs = ExtractCBUUIDs(uuids) ?? []
        let cbPeripherals = self.centralProxy.centralManager.retrieveConnectedPeripherals(withServices: cbUUIDs)
        let peripherals = cbPeripherals.map { cbPeripheral -> Peripheral in
            return Peripheral(peripheral: cbPeripheral)
        }
        return peripherals
    }
    
    /// Scans for Peripherals through a CBCentralManager scanForPeripheralsWithServices(...) function call.
    ///
    /// - Parameter timeout: The scanning time in seconds before the scan is stopped and the completion closure is called with a scanStopped result.
    /// - Parameter serviceUUIDs: The service UUIDs to search peripherals for or nil if looking for all peripherals.
    /// - Parameter completion: The closures, called multiple times throughout a scan.
    public func scanForPeripherals(withServiceUUIDs serviceUUIDs: [CBUUIDConvertible]? = nil,
                                   options: [String : Any]? = nil,
                                   timeoutAfter timeout: TimeInterval,
                                   completion: @escaping PeripheralScanCallback) {
        // Passing in an empty array will act the same as if you passed nil and discover all peripherals but
        // it is recommended to pass in nil for those cases similarly to how the CoreBluetooth scan method works
        assert(serviceUUIDs == nil || serviceUUIDs!.count > 0)
        centralProxy.scanWithTimeout(timeout, serviceUUIDs: ExtractCBUUIDs(serviceUUIDs), options: options, completion)
    }
    
    /// Will stop the current scan through a CBCentralManager stopScan() function call and invokes the completion
    /// closures of the original scanWithTimeout function call with a scanStopped result containing an error if something went wrong.
    public func stopScan() {
        centralProxy.stopScan()
    }
    
    /// Sometime, the bluetooth state of your iOS Device/CBCentralManagerState is in an inbetween state of either
    /// ".Unknown" or ".Reseting". This function will wait until the bluetooth state is stable and return a subset
    /// of the CBCentralManager state value which does not includes these values in its completion closure.
    public func asyncState(completion: @escaping AsyncCentralStateCallback) {
        self.centralProxy.asyncState(completion)
    }
}
