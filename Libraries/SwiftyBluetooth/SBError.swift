//
//  SBError.swift
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

public enum SBError: Error {
    
    public enum SBBluetoothUnavailbleFailureReason {
        case unsupported
        case unauthorized
        case poweredOff
        case unknown
    }
    
    public enum SBOperation: String {
        case connectPeripheral = "Connect peripheral"
        case disconnectPeripheral = "Disconnect peripheral"
        case readRSSI = "Read RSSI"
        case discoverServices = "Discover services"
        case discoverIncludedServices = "Discover included services"
        case discoverCharacteristics = "Discover characteristics"
        case discoverDescriptors = "Discover descriptors"
        case readCharacteristic = "Read characteristic"
        case readDescriptor = "Read descriptor"
        case writeCharacteristic = "Write characteristic"
        case writeDescriptor = "Write descriptor"
        case updateNotificationStatus = "Update notification status"
    }
    
    case bluetoothUnavailable(reason: SBBluetoothUnavailbleFailureReason)
    case scanningEndedUnexpectedly
    case operationTimedOut(operation: SBOperation)
    case invalidPeripheral
    case peripheralFailedToConnectReasonUnknown
    case peripheralServiceNotFound(missingServicesUUIDs: [CBUUID])
    case peripheralCharacteristicNotFound(missingCharacteristicsUUIDs: [CBUUID])
    case peripheralDescriptorsNotFound(missingDescriptorsUUIDs: [CBUUID])
    case invalidDescriptorValue(descriptor: CBDescriptor)
}

extension SBError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable(let reason):
            return reason.localizedDescription
        case .scanningEndedUnexpectedly:
            return "Your peripheral scan ended unexpectedly."
        case .operationTimedOut(let operation):
            return "Bluetooth operation timed out: \(operation.rawValue)"
        case .invalidPeripheral:
            return "Invalid Bluetooth peripheral, you must rediscover this peripheral to use it again."
        case .peripheralFailedToConnectReasonUnknown:
            return "Failed to connect to your peripheral for an unknown reason."
        case .peripheralServiceNotFound(let missingUUIDs):
            let missingUUIDsString = missingUUIDs.map { $0.uuidString }.joined(separator: ",")
            return "Peripheral service(s) not found: \(missingUUIDsString)"
        case .peripheralCharacteristicNotFound(let missingUUIDs):
            let missingUUIDsString = missingUUIDs.map { $0.uuidString }.joined(separator: ",")
            return "Peripheral charac(s) not found: \(missingUUIDsString)"
        case .peripheralDescriptorsNotFound(let missingUUIDs):
            let missingUUIDsString = missingUUIDs.map { $0.uuidString }.joined(separator: ",")
            return "Peripheral descriptor(s) not found: \(missingUUIDsString)"
        case .invalidDescriptorValue(let descriptor):
            return "Failed to parse value for descriptor with uuid: \(descriptor.uuid.uuidString)"
        }
    }
}

extension SBError.SBBluetoothUnavailbleFailureReason {
    public var localizedDescription: String {
        switch self {
        case .unsupported:
            return "Your iOS device does not support Bluetooth."
        case .unauthorized:
            return "Unauthorized to use Bluetooth."
        case .poweredOff:
            return "Bluetooth is disabled, enable bluetooth and try again."
        case .unknown:
            return "Bluetooth is currently unavailable (unknown reason)."
        }
    }
}
