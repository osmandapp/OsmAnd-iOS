//
//  CBUUIDConvertible.swift
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

/// Instead of directly using CBUUIDs in the Central and Peripheral class function parameters, you can use class/struct
/// implementing the CBUUIDConvertible protocol. The protocol is used to give any object a way of converting itself to a CBUUID object.
/// An implementation of the protocol is already provided for the following class: String, NSUUID, CBUUID, CBAttribute
///
/// Using this, you could call discoverServices(...) using multiple different kind of parameters for the "servicesUUIDs" array:
///
/// - discoverServices(["01AF"], ...)
/// - discoverServices(["CBUUID(string: 01AF)"], ...)
/// - discoverServices([CBService], ...)
///
/// See also the list of object already implementing the protocol
public protocol CBUUIDConvertible {
    var CBUUIDRepresentation: CBUUID { get }
}

extension String: CBUUIDConvertible {
    public var CBUUIDRepresentation: CBUUID {
        return CBUUID(string: self)
    }
}

extension UUID: CBUUIDConvertible {
    public var CBUUIDRepresentation: CBUUID {
        return CBUUID(nsuuid: self)
    }
}

extension CBUUID: CBUUIDConvertible {
    public var CBUUIDRepresentation: CBUUID {
        return self
    }
}

extension CBAttribute: CBUUIDConvertible {
    public var CBUUIDRepresentation: CBUUID {
        return self.uuid
    }
}

func ExtractCBUUIDs(_ CBUUIDConvertibles: [CBUUIDConvertible]?) -> [CBUUID]? {
    if let CBUUIDConvertibles = CBUUIDConvertibles, CBUUIDConvertibles.count > 0 {
        return CBUUIDConvertibles.map { $0.CBUUIDRepresentation }
    } else {
        return nil
    }
}
