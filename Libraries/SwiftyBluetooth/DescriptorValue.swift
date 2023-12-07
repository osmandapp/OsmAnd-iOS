//
//  DescriptorValue.swift
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
    Wrapper around common GATT descriptor values. Automatically unwrap and cast your descriptor values for
    standard GATT descriptor UUIDs.

    - CharacteristicExtendedProperties: Case for Descriptor with UUID CBUUIDCharacteristicExtendedPropertiesString
    - CharacteristicUserDescription: Case for Descriptor with UUID CBUUIDCharacteristicUserDescriptionString
    - ClientCharacteristicConfigurationString: Case for Descriptor with UUID CBUUIDClientCharacteristicConfigurationString
    - ServerCharacteristicConfigurationString: Case for Descriptor with UUID CBUUIDServerCharacteristicConfigurationString
    - CharacteristicFormatString: Case for Descriptor with UUID CBUUIDCharacteristicFormatString
    - CharacteristicAggregateFormatString: Case for Descriptor with UUID CBUUIDCharacteristicAggregateFormatString
    - CustomValue: Case for descriptor with a non standard UUID
*/
public enum DescriptorValue {
    case characteristicExtendedProperties(value: UInt16)
    case characteristicUserDescription(value: String)
    case clientCharacteristicConfigurationString(value: UInt16)
    case serverCharacteristicConfigurationString(value: UInt16)
    case characteristicFormatString(value: Data)
    case characteristicAggregateFormatString(value: UInt16)
    case customValue(value: AnyObject)
    
    init(descriptor: CBDescriptor) throws {
        guard let value = descriptor.value else {
            throw SBError.invalidDescriptorValue(descriptor: descriptor)
        }
        
        switch descriptor.CBUUIDRepresentation.uuidString {
        case CBUUIDCharacteristicExtendedPropertiesString:
            guard let value = UInt16(uncastedUnwrappedNSNumber: descriptor.value as AnyObject?) else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .characteristicExtendedProperties(value: value)
            
        case CBUUIDCharacteristicUserDescriptionString:
            guard let value = descriptor.value as? String else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .characteristicUserDescription(value: value)
            
        case CBUUIDClientCharacteristicConfigurationString:
            guard let value = UInt16(uncastedUnwrappedNSNumber: descriptor.value as AnyObject?) else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .clientCharacteristicConfigurationString(value: value)
            
        case CBUUIDServerCharacteristicConfigurationString:
            guard let value = UInt16(uncastedUnwrappedNSNumber: descriptor.value as AnyObject?) else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .serverCharacteristicConfigurationString(value: value)
            
        case CBUUIDCharacteristicFormatString:
            guard let value = descriptor.value as? Data else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .characteristicFormatString(value: value)
            
        case CBUUIDCharacteristicAggregateFormatString:
            guard let value = UInt16(uncastedUnwrappedNSNumber: descriptor.value as AnyObject?) else {
                throw SBError.invalidDescriptorValue(descriptor: descriptor)
            }
            self = .characteristicAggregateFormatString(value: value)
            
        default:
            self = .customValue(value: value as AnyObject)
        }
    }
}
