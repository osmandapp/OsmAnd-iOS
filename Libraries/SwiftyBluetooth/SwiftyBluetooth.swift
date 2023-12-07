//
//  SwiftyBluetooth.swift
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

final class SwiftyBluetooth: NSObject {
    
    // MARK: Shorthands for the Central singleton instance interface

    /// Allows you to initially set the Central sharedInstance and use the restore
    /// identifier string of your choice for state preservation between app
    /// launches. Must be called before anything else from the library and can only be called once.
    @discardableResult
    static func setSharedCentralInstanceWith(restoreIdentifier: String) -> Central {
        Central.setSharedInstanceWith(restoreIdentifier: restoreIdentifier)
    }

    /// Scans for Peripherals through a CBCentralManager scanForPeripheralsWithServices(...) function call.
    ///
    /// - Parameter timeout: The scanning time in seconds before the scan is stopped and the completion closure is called with a scanStopped result.
    /// - Parameter serviceUUIDs: The service UUIDs to search peripherals for or nil if looking for all peripherals.
    /// - Parameter completion: The closures, called multiple times throughout a scan.
    static func scanForPeripherals(withServiceUUIDs serviceUUIDs: [CBUUIDConvertible]? = nil,
                                   options: [String : Any]? = nil,
                                   timeoutAfter timeout: TimeInterval,
                                   completion: @escaping PeripheralScanCallback)
    {
        Central.sharedInstance.scanForPeripherals(withServiceUUIDs: serviceUUIDs,
                                                  options: options,
                                                  timeoutAfter: timeout,
                                                  completion: completion)
    }

    /// Will stop the current scan through a CBCentralManager stopScan() function call and invokes the completion
    /// closures of the original scanWithTimeout function call with a scanStopped result containing an error if something went wrong.
    static func stopScan() {
        Central.sharedInstance.stopScan()
    }

    /// Sometimes, the bluetooth state of your iOS Device/CBCentralManagerState is in an inbetween state of either
    /// ".Unknown" or ".Reseting". This function will wait until the bluetooth state is stable and return a subset
    /// of the CBCentralManager state value which does not includes these values in its completion closure.
    static func asyncState(completion: @escaping AsyncCentralStateCallback) {
        Central.sharedInstance.asyncState(completion: completion)
    }

    /// The Central singleton CBCentralManager isScanning value
    static var isScanning: Bool {
         Central.sharedInstance.isScanning
    }

    /// Attempts to return the periperals from a list of identifier "UUID"s
    static func retrievePeripherals(withUUIDs uuids: [UUID]) -> [Peripheral] {
        Central.sharedInstance.retrievePeripherals(withUUIDs: uuids)
    }

    /// Attempts to return the connected peripheral having the specific service CBUUIDs
    static func retrieveConnectedPeripherals(withServiceUUIDs uuids: [CBUUIDConvertible]) -> [Peripheral] {
        Central.sharedInstance.retrieveConnectedPeripherals(withServiceUUIDs: uuids)
    }
}
