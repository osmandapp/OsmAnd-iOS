//
//  Algorithms.swift
//  OsmAnd Maps
//
//  Created by Skalii on 21.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAAlgorithms)
@objcMembers
class Algorithms: NSObject {

    static let zipFileSignature: Int = 1347093252
    static let gzipFileSignature: Int = 8075

    static func readSmallInt(from inputStream: InputStream) throws -> Int {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 2)
        defer { buffer.deallocate() }
        
//        guard inputStream.read(buffer, maxLength: 2) == 2 else {
//            throw EOFException()
//        }
        
        let ch1 = Int(buffer[0])
        let ch2 = Int(buffer[1])
        return (ch1 << 8) + ch2
    }

    static func readInt(from inputStream: InputStream) throws -> Int {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        defer { buffer.deallocate() }
        
//        guard inputStream.read(buffer, maxLength: 4) == 4 else {
//            throw EOFException()
//        }
        
        let ch1 = Int(buffer[0])
        let ch2 = Int(buffer[1])
        let ch3 = Int(buffer[2])
        let ch4 = Int(buffer[3])
        return (ch1 << 24) + (ch2 << 16) + (ch3 << 8) + ch4
    }

    static func isSmallFileSignature(_ fileSignature: Int) -> Bool {
        return fileSignature == 16986 || fileSignature == 8075
    }

    static func checkFileSignature(_ inputStream: InputStream?, _ fileSignature: Int) throws -> Bool {
        guard let inputStream = inputStream else {
            return false
        }
        
        let bufferSize = 1024 // Set an appropriate buffer size
        
        // Create a buffer to read the bytes
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        // Read the first bytes into the buffer
        let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        
        guard bytesRead > 0 else {
            return false
        }
        
        // Check if the first bytes match the file signature
        let firstBytes: Int
        if isSmallFileSignature(fileSignature) {
            firstBytes = try readSmallInt(from: inputStream)
        } else {
            firstBytes = try readInt(from: inputStream)
        }
        
        return firstBytes == fileSignature
    }

    static func streamCopy(from inStream: InputStream, to outStream: OutputStream) throws {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        while inStream.hasBytesAvailable {
            let bytesRead = inStream.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                outStream.write(buffer, maxLength: bytesRead)
            }
        }
    }

    static func createByteArrayIS(from inStream: InputStream) throws -> Data {
        let outStream = OutputStream.toMemory()
        try streamCopy(from: inStream, to: outStream)
        inStream.close()
        outStream.close()
        return outStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data ?? Data()
    }

    static private func getInputStream(from inputStream: InputStream) throws -> InputStream {
        let localIS = try InputStream(data: createByteArrayIS(from: inputStream))
        
//        if checkFileSignature(localIS, OnlineRoutingHelper.zipFileSignature) {
//            let zipIS = try ZipInputStream(data: localIS)
//            zipIS.getNextEntry() // set position to reading for the first item
//            return zipIS
//        } else if checkFileSignature(localIS, OnlineRoutingHelper.gzipFileSignature) {
//            let gzipIS = try GZIPInputStream(data: localIS)
//            return gzipIS
//        }
        
        return localIS
    }

}
