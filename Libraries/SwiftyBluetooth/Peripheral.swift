//
//  Peripheral.swift
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
    The Peripheral notifications sent through the default 'NotificationCenter' by Peripherals.
 
    Use the PeripheralEvent enum rawValue as the notification string when registering for notifications.
 
    - peripheralModifedServices: Update to a peripheral's CBPeripheral services, userInfo: ["invalidatedServices": [CBService]]
    - characteristicValueUpdate: An update to the value of a characteristic you're peripherals is subscribed for updates from, userInfo: ["characteristic": CBCharacteristic, "error": SBError?]
*/

public typealias rssi = Int
public typealias isNotifying = Bool

public typealias ReadRSSIRequestCallback = (_ result: Result<rssi, Error>) -> Void
public typealias ServiceRequestCallback = (_ result: Result<[CBService], Error>) -> Void
public typealias CharacteristicRequestCallback = (_ result: Result<[CBCharacteristic], Error>) -> Void
public typealias DescriptorRequestCallback = (_ result: Result<[CBDescriptor], Error>) -> Void
public typealias ReadCharacRequestCallback = (_ result: Result<Data, Error>) -> Void
public typealias ReadDescriptorRequestCallback = (_ result: Result<DescriptorValue, Error>) -> Void
public typealias WriteRequestCallback = (_ result: Result<Void, Error>) -> Void
public typealias UpdateNotificationStateCallback = (_ result: Result<isNotifying, Error>) -> Void

/// An interface on top of a CBPeripheral instance used to run CBPeripheral related functions with closures based callbacks instead of the usual CBPeripheralDelegate interface.
public final class Peripheral {
    fileprivate var peripheralProxy: PeripheralProxy!
    
    init(peripheral: CBPeripheral) {
        self.peripheralProxy = PeripheralProxy(cbPeripheral: peripheral, peripheral: self)
    }
}

// MARK: Public
extension Peripheral {
    /// The name of a `Notification` posted by a `Peripheral` instance when its `CBPeripheral` name value changes.
    /// Unwrap the new name if available with `notification.userInfo?["name"] as? String`
    public static let PeripheralNameUpdate = Notification.Name(rawValue: "SwiftyBluetooth_PeripheralNameUpdate")
    
    /// The name of a `Notification` posted by a `Peripheral` instance when some of its `CBPeripheral` services are invalidated.
    /// Unwrap the invalidated services with `notification.userInfo?["invalidatedServices"] as? [CBSErvice]`
    public static let PeripheralModifedServices = Notification.Name(rawValue: "SwiftyBluetooth_PeripheralModifedServices")
    
    /// The name of a `Notification` posted by a `Peripheral` instance when one of the characteristic you have subcribed for update from
    /// changes its value.
    /// Unwrap the new charac value with `notification.userInfo?["characteristic"] as? CBCharacteristic`
    /// Unwrap the error if any with `notification.userInfo?["error"] as? SBError`
    public static let PeripheralCharacteristicValueUpdate = Notification.Name(rawValue: "SwiftyBluetooth_PharacteristicValueUpdate")
    
    /// The name of a `Notification` posted by a `Peripheral` instance when it becomes disconnected
    /// Unwrap the new charac value with `notification.userInfo?["characteristic"] as? CBCharacteristic`
    /// Unwrap the error if any with `notification.userInfo?["error"] as? SBError`
    public static let PeripheralDisconnected = Notification.Name(rawValue: "SwiftyBluetooth_PeripheralDisconnected")
    
    /// The underlying CBPeripheral identifier
    public var identifier: UUID {
        return self.peripheralProxy.cbPeripheral.identifier
    }
    
    /// The underlying CBPeripheral name
    public var name: String? {
        return self.peripheralProxy.cbPeripheral.name
    }
    
    /// The underlying CBPeripheral state
    public var state: CBPeripheralState {
        return self.peripheralProxy.cbPeripheral.state
    }
    
    /// The underlying CBPeripheral services
    public var services: [CBService]? {
        return self.peripheralProxy.cbPeripheral.services
    }
    
    /// Returns the service requested if it exists and has been discovered
    public func service(withUUID serviceUUID: CBUUIDConvertible) -> CBService? {
        return self.peripheralProxy.cbPeripheral
            .serviceWithUUID(serviceUUID.CBUUIDRepresentation)
    }
    
    /// Returns the characteristic requested if it exists and has been discovered
    public func characteristic(withUUID characteristicUUID: CBUUIDConvertible,
                               ofServiceWithUUID serviceUUID: CBUUIDConvertible) -> CBCharacteristic? {
        return self.peripheralProxy.cbPeripheral
            .serviceWithUUID(serviceUUID.CBUUIDRepresentation)?
            .characteristicWithUUID(characteristicUUID.CBUUIDRepresentation)
    }
    
    /// Returns the descriptor requested if it exists and has been discovered
    public func descriptor(withUUID descriptorUUID: CBUUIDConvertible,
                           ofCharacWithUUID characUUID: CBUUIDConvertible,
                           fromServiceWithUUID serviceUUID: CBUUIDConvertible) -> CBDescriptor? {
        return self.peripheralProxy.cbPeripheral
            .serviceWithUUID(serviceUUID.CBUUIDRepresentation)?
            .characteristicWithUUID(characUUID.CBUUIDRepresentation)?
            .descriptorWithUUID(descriptorUUID.CBUUIDRepresentation)
    }
    
    /// Connect to the peripheral through Ble to our Central sharedInstance
    public func connect(withTimeout timeout: TimeInterval?, completion: @escaping ConnectPeripheralCallback) {
        if let timeout = timeout {
            self.peripheralProxy.connect(timeout: timeout, completion)
        } else {
            self.peripheralProxy.connect(timeout: TimeInterval.infinity, completion)
        }
    }
    
    /// Disconnect the peripheral from our Central sharedInstance
    public func disconnect(completion: @escaping DisconnectPeripheralCallback) {
        self.peripheralProxy.disconnect(completion)
    }
    
    /// Connects to the peripheral and update the Peripheral's RSSI through a 'CBPeripheral' readRSSI() function call
    ///
    /// - Parameter completion: A closure containing the integer value of the updated RSSI or an error.
    public func readRSSI(completion: @escaping ReadRSSIRequestCallback) {
        self.peripheralProxy.readRSSI(completion)
    }
    
    /// Connects to the peripheral and discover the requested services through a 'CBPeripheral' discoverServices(...) function call
    ///
    /// - Parameter serviceUUIDs: The UUIDs of the services you want to discover or nil if you want to discover all services.
    /// - Parameter completion: A closures containing an array of the services found or an error.
    public func discoverServices(withUUIDs serviceUUIDs: [CBUUIDConvertible]? = nil,
                                 completion: @escaping ServiceRequestCallback) {
        // Passing in an empty array will act the same as if you passed nil and discover all the services.
        // But it is recommended to pass in nil for those cases similarly to how the CoreBluetooth discoverServices method works
        assert(serviceUUIDs == nil || serviceUUIDs!.count > 0)
        self.peripheralProxy.discoverServices(ExtractCBUUIDs(serviceUUIDs), completion: completion)
    }
    
    /// Connects to the peripheral and discover the requested included services of a service through a 'CBPeripheral' discoverIncludedServices(...) function call
    ///
    /// - Parameter serviceUUIDs: The UUIDs of the included services you want to discover or nil if you want to discover all included services.
    /// - Parameter serviceUUID: The service to request included services from.
    /// - Parameter completion: A closures containing an array of the services found or an error.
    public func discoverIncludedServices(withUUIDs includedServiceUUIDs: [CBUUIDConvertible]? = nil,
                                         ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                                         completion: @escaping ServiceRequestCallback) {
        // Passing in an empty array will act the same as if you passed nil and discover all the services.
        // But it is recommended to pass in nil for those cases similarly to how the CoreBluetooth discoverServices method works
        assert(includedServiceUUIDs == nil || includedServiceUUIDs!.count > 0)
        self.peripheralProxy.discoverIncludedServices(ExtractCBUUIDs(includedServiceUUIDs),
                                                      forService: serviceUUID.CBUUIDRepresentation,
                                                      completion: completion)
    }
    
    /// Connects to the peripheral and discover the requested characteristics through a 'CBPeripheral' discoverCharacteristics(...) function call.
    /// Will first discover the service of the requested characteristics if necessary.
    ///
    /// - Parameter serviceUUID: The UUID of the service of the characteristics requested.
    /// - Parameter characteristicUUIDs: The UUIDs of the characteristics you want to discover or nil if you want to discover all characteristics.
    /// - Parameter completion: A closures containing an array of the characteristics found or an error.
    public func discoverCharacteristics(withUUIDs characteristicUUIDs: [CBUUIDConvertible]? = nil,
                                        ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                                        completion: @escaping CharacteristicRequestCallback) {
        // Passing in an empty array will act the same as if you passed nil and discover all the characteristics.
        // But it is recommended to pass in nil for those cases similarly to how the CoreBluetooth discoverCharacteristics method works
        assert(characteristicUUIDs == nil || characteristicUUIDs!.count > 0)
        self.peripheralProxy.discoverCharacteristics(ExtractCBUUIDs(characteristicUUIDs),
                                                     forService: serviceUUID.CBUUIDRepresentation,
                                                     completion: completion)
    }
    
    /// Connects to the peripheral and discover the requested descriptors through a 'CBPeripheral' discoverDescriptorsForCharacteristic(...) function call.
    /// Will first discover the service and characteristic for which you want to discover descriptors from.
    ///
    /// - Parameter characteristicUUID: The UUID of the characteristic you want to discover descriptors from.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter completion: A closures containing an array of the descriptors found or an error.
    public func discoverDescriptors(ofCharacWithUUID characUUID: CBUUIDConvertible,
                                    fromServiceWithUUID serviceUUID: CBUUIDConvertible,
                                    completion: @escaping DescriptorRequestCallback) {
        self.peripheralProxy.discoverDescriptorsForCharacteristic(characUUID.CBUUIDRepresentation,
                                                                  serviceUUID: serviceUUID.CBUUIDRepresentation,
                                                                  completion: completion)
    }
    
    /// Connects to the peripheral and discover the requested descriptors through a 'CBPeripheral' discoverDescriptorsForCharacteristic(...) function call.
    /// Will first discover the service and characteristic for which you want to discover descriptors from.
    ///
    /// - Parameter charac: The characteristic to discover descriptors from.
    /// - Parameter completion: A closures containing an array of the descriptors found or an error.
    public func discoverDescriptors(ofCharac charac: CBCharacteristic,
                                    completion: @escaping DescriptorRequestCallback) {
        self.discoverDescriptors(ofCharacWithUUID: charac,
                                 fromServiceWithUUID: charac.service!,
                                 completion: completion)
    }
    
    /// Connect to the peripheral and read the value of the characteristic requested through a 'CBPeripheral' readValueForCharacteristic(...) function call.
    /// Will first discover the service and characteristic you want to read from if necessary.
    ///
    /// - Parameter characteristicUUID: The UUID of the characteristic you want to read from.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter completion: A closures containing the data read or an error.
    public func readValue(ofCharacWithUUID characUUID: CBUUIDConvertible,
                          fromServiceWithUUID serviceUUID: CBUUIDConvertible,
                          completion: @escaping ReadCharacRequestCallback) {
        self.peripheralProxy.readCharacteristic(characUUID.CBUUIDRepresentation,
                                                serviceUUID: serviceUUID.CBUUIDRepresentation,
                                                completion: completion)
    }
    
    /// Connect to the peripheral and read the value of the passed characteristic through a 'CBPeripheral' readValueForCharacteristic(...) function call.
    ///
    /// - Parameter charac: The characteristic you want to read from.
    /// - Parameter completion: A closures containing the data read or an error.
    public func readValue(ofCharac charac: CBCharacteristic,
                          completion: @escaping ReadCharacRequestCallback) {
        self.readValue(ofCharacWithUUID: charac,
                       fromServiceWithUUID: charac.service!,
                       completion: completion)
    }
    
    /// Connect to the peripheral and read the value of the descriptor requested through a 'CBPeripheral' readValueForDescriptor(...) function call.
    /// Will first discover the service, characteristic and descriptor you want to read from if necessary.
    ///
    /// - Parameter descriptorUUID: The UUID of the descriptor you want to read from.
    /// - Parameter characteristicUUID: The UUID of the descriptor above.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter completion: A closures containing the data read or an error.
    public func readValue(ofDescriptorWithUUID descriptorUUID: CBUUIDConvertible,
                          fromCharacUUID characUUID: CBUUIDConvertible,
                          ofServiceUUID serviceUUID: CBUUIDConvertible,
                          completion: @escaping ReadDescriptorRequestCallback) {
        self.peripheralProxy.readDescriptor(descriptorUUID.CBUUIDRepresentation,
                                            characteristicUUID: characUUID.CBUUIDRepresentation,
                                            serviceUUID: serviceUUID.CBUUIDRepresentation,
                                            completion: completion)
    }
    
    /// Connect to the peripheral and read the value of the passed descriptor through a 'CBPeripheral' readValueForDescriptor(...) function call.
    ///
    /// - Parameter descriptor: The descriptor you want to read from.
    /// - Parameter characteristicUUID: The UUID of the descriptor above.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter completion: A closures containing the data read or an error.
    public func readValue(ofDescriptor descriptor: CBDescriptor,
                          completion: @escaping ReadDescriptorRequestCallback) {
        self.readValue(ofDescriptorWithUUID: descriptor,
                       fromCharacUUID: descriptor.characteristic!,
                       ofServiceUUID: descriptor.characteristic!.service!,
                       completion: completion)
    }
    
    /// Connect to the peripheral and write a value to the characteristic requested through a 'CBPeripheral' writeValue:forCharacteristic(...) function call.
    /// Will first discover the service and characteristic you want to write to if necessary.
    ///
    /// - Parameter characUUID: The UUID of the characteristic you want to write to.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter value: The data being written to the characteristic
    /// - Parameter type: The type of the CBPeripheral write, wither with or without response in which case the closure is called right away
    /// - Parameter completion: A closures containing an error if something went wrong
    public func writeValue(ofCharacWithUUID characUUID: CBUUIDConvertible,
                           fromServiceWithUUID serviceUUID: CBUUIDConvertible,
                           value: Data,
                           type: CBCharacteristicWriteType = .withResponse,
                           completion: @escaping WriteRequestCallback) {
        self.peripheralProxy.writeCharacteristicValue(characUUID.CBUUIDRepresentation,
                                                      serviceUUID: serviceUUID.CBUUIDRepresentation,
                                                      value: value,
                                                      type: type,
                                                      completion: completion)
    }
    
    /// Connect to the peripheral and write a value to the passed characteristic through a 'CBPeripheral' writeValue:forCharacteristic(...) function call.
    ///
    /// - Parameter charac: The characteristic you want to write to.
    /// - Parameter value: The data being written to the characteristic
    /// - Parameter type: The type of the CBPeripheral write, wither with or without response in which case the closure is called right away
    /// - Parameter completion: A closures containing an error if something went wrong
    public func writeValue(ofCharac charac: CBCharacteristic,
                           value: Data,
                           type: CBCharacteristicWriteType = .withResponse,
                           completion: @escaping WriteRequestCallback) {
        self.writeValue(ofCharacWithUUID: charac,
                        fromServiceWithUUID: charac.service!,
                        value: value,
                        type: type,
                        completion: completion)
    }
    
    /// Connect to the peripheral and write a value to the descriptor requested through a 'CBPeripheral' writeValue:forDescriptor(...) function call.
    /// Will first discover the service, characteristic and descriptor you want to write to if necessary.
    ///
    /// - Parameter descriptorUUID: The UUID of the descriptor you want to write to.
    /// - Parameter characUUID: The UUID of the characteristic of the descriptor above.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter value: The data being written to the characteristic.
    /// - Parameter completion: A closures containing an error if something went wrong.
    public func writeValue(ofDescriptorWithUUID descriptorUUID: CBUUIDConvertible,
                           fromCharacWithUUID characUUID: CBUUIDConvertible,
                           ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                           value: Data,
                           completion: @escaping WriteRequestCallback) {
        self.peripheralProxy.writeDescriptorValue(descriptorUUID.CBUUIDRepresentation,
                                                  characteristicUUID: characUUID.CBUUIDRepresentation,
                                                  serviceUUID: serviceUUID.CBUUIDRepresentation,
                                                  value: value,
                                                  completion: completion)
    }
    
    /// Connect to the peripheral and write a value to the passed descriptor through a 'CBPeripheral' writeValue:forDescriptor(...) function call.
    ///
    /// - Parameter descriptor: The descriptor you want to write to.
    /// - Parameter value: The data being written to the descriptor.
    /// - Parameter completion: A closures containing an error if something went wrong.
    public func writeValue(ofDescriptor descriptor: CBDescriptor,
                           value: Data,
                           completion: @escaping WriteRequestCallback) {
        self.writeValue(ofDescriptorWithUUID: descriptor,
                        fromCharacWithUUID: descriptor.characteristic!,
                        ofServiceWithUUID: descriptor.characteristic!.service!,
                        value: value,
                        completion: completion)
    }
    
    /// Connect to the peripheral and set the notification value of the characteristic requested through a 'CBPeripheral' setNotifyValueForCharacteristic function call.
    /// Will first discover the service and characteristic you want to either, start, or stop, getting notifcations from.
    ///
    /// - Parameter enabled: If enabled is true, this peripherals will register for change notifcations to the characteristic
    ///      and notify listeners through the default 'NotificationCenter' with a 'PeripheralEvent.characteristicValueUpdate' notification.
    /// - Parameter characUUID: The UUID of the characteristic you want set the notify value of.
    /// - Parameter serviceUUID: The UUID of the service of the characteristic above.
    /// - Parameter completion: A closures containing the updated notification value of the characteristic or an error if something went wrong.
    public func setNotifyValue(toEnabled enabled: Bool,
                               forCharacWithUUID characUUID: CBUUIDConvertible,
                               ofServiceWithUUID serviceUUID: CBUUIDConvertible,
                               completion: @escaping UpdateNotificationStateCallback) {
        self.peripheralProxy.setNotifyValueForCharacteristic(enabled,
                                                             characteristicUUID: characUUID.CBUUIDRepresentation,
                                                             serviceUUID: serviceUUID.CBUUIDRepresentation,
                                                             completion: completion)
    }
    
    /// Connect to the peripheral and set the notification value of the passed characteristic through a 'CBPeripheral' setNotifyValueForCharacteristic function call.
    ///
    /// If set to true, this peripheral will emit characteristic change updates through the default NotificationCenter using the "characteristicValueUpdate" notification.
    ///
    /// - Parameter enabled: The notify state of the charac, set enabled to true to receive change notifications through the default Notification center
    /// - Parameter charac: The characteristic you want set the notify value of.
    /// - Parameter completion: A closures containing the updated notification value of the characteristic or an error if something went wrong.
    public func setNotifyValue(toEnabled enabled: Bool,
                               ofCharac charac: CBCharacteristic,
                               completion: @escaping UpdateNotificationStateCallback) {
        self.setNotifyValue(toEnabled: enabled,
                            forCharacWithUUID: charac,
                            ofServiceWithUUID: charac.service!,
                            completion: completion)
    }
}
