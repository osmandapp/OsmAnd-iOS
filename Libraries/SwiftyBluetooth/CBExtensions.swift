//
//  CBExtensions.swift
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

extension CBPeripheral {
    public func serviceWithUUID(_ uuid: CBUUID) -> CBService? {
        guard let services = self.services else {
            return nil
        }
        
        return services.filter { $0.uuid == uuid }.first
    }
    
    public func servicesWithUUIDs(_ servicesUUIDs: [CBUUID]) -> (foundServices: [CBService], missingServicesUUIDs: [CBUUID]) {
        assert(servicesUUIDs.count > 0)
        
        guard let currentServices = self.services , currentServices.count > 0 else {
            return (foundServices: [], missingServicesUUIDs: servicesUUIDs)
        }
        
        let currentServicesUUIDs = currentServices.map { $0.uuid }
        
        let currentServicesUUIDsSet = Set(currentServicesUUIDs)
        let requestedServicesUUIDsSet = Set(servicesUUIDs)
        
        let foundServicesUUIDsSet = requestedServicesUUIDsSet.intersection(currentServicesUUIDsSet)
        let missingServicesUUIDsSet = requestedServicesUUIDsSet.subtracting(currentServicesUUIDsSet)
        
        let foundServices = currentServices.filter { foundServicesUUIDsSet.contains($0.uuid) }
        
        return (foundServices: foundServices, missingServicesUUIDs: Array(missingServicesUUIDsSet))
    }
    
}

extension CBService {
    public func characteristicWithUUID(_ uuid: CBUUID) -> CBCharacteristic? {
        guard let characteristics = self.characteristics else {
            return nil
        }
        
        return characteristics.filter { $0.uuid == uuid }.first
    }
    
    public func characteristicsWithUUIDs(_ characteristicsUUIDs: [CBUUID]) -> (foundCharacteristics: [CBCharacteristic], missingCharacteristicsUUIDs: [CBUUID]) {
        assert(characteristicsUUIDs.count > 0)
        
        guard let currentCharacteristics = self.characteristics , currentCharacteristics.count > 0 else {
            return (foundCharacteristics: [], missingCharacteristicsUUIDs: characteristicsUUIDs)
        }
        
        let currentCharacteristicsUUID = currentCharacteristics.map { $0.uuid }
        
        let currentCharacteristicsUUIDSet = Set(currentCharacteristicsUUID)
        let requestedCharacteristicsUUIDSet = Set(characteristicsUUIDs)
        
        let foundCharacteristicsUUIDSet = requestedCharacteristicsUUIDSet.intersection(currentCharacteristicsUUIDSet)
        let missingCharacteristicsUUIDSet = requestedCharacteristicsUUIDSet.subtracting(currentCharacteristicsUUIDSet)
        
        let foundCharacteristics = currentCharacteristics.filter { foundCharacteristicsUUIDSet.contains($0.uuid) }
        
        return (foundCharacteristics: foundCharacteristics, missingCharacteristicsUUIDs: Array(missingCharacteristicsUUIDSet))
    }
}

extension CBCharacteristic {
    public func descriptorWithUUID(_ uuid: CBUUID) -> CBDescriptor? {
        guard let descriptors = self.descriptors else {
            return nil
        }
        
        return descriptors.filter { $0.uuid == uuid }.first
    }
    
    public func descriptorsWithUUIDs(_ descriptorsUUIDs: [CBUUID]) -> (foundDescriptors: [CBDescriptor], missingDescriptorsUUIDs: [CBUUID]) {
        assert(descriptorsUUIDs.count > 0)
        
        guard let currentDescriptors = self.descriptors , currentDescriptors.count > 0 else {
            return (foundDescriptors: [], missingDescriptorsUUIDs: descriptorsUUIDs)
        }
        
        let currentDescriptorsUUIDs = currentDescriptors.map { $0.uuid }
        
        let currentDescriptorsUUIDsSet = Set(currentDescriptorsUUIDs)
        let requestedDescriptorsUUIDsSet = Set(descriptorsUUIDs)
        
        let foundDescriptorsUUIDsSet = requestedDescriptorsUUIDsSet.intersection(currentDescriptorsUUIDsSet)
        let missingDescriptorsUUIDsSet = requestedDescriptorsUUIDsSet.subtracting(currentDescriptorsUUIDsSet)
        
        let foundDescriptors = currentDescriptors.filter { foundDescriptorsUUIDsSet.contains($0.uuid) }
        
        return (foundDescriptors: foundDescriptors, missingDescriptorsUUIDs: Array(missingDescriptorsUUIDsSet))
    }
}
