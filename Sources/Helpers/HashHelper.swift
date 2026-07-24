//
//  HashHelper.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CryptoKit

@objcMembers
final class HashHelper: NSObject {
    static func md5Hex(_ string: String?) -> String? {
        guard let string = string, let data = string.data(using: .utf8) else {
            return nil
        }
        return Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func fileMD5Hex(_ path: String?) -> String {
        guard let path, let handle = FileHandle(forReadingAtPath: path) else {
            return ""
        }

        defer {
            try? handle.close()
        }

        var hasher = Insecure.MD5()
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1_000_000)
            guard !data.isEmpty else {
                return false
            }
            hasher.update(data: data)
            return true
        }) {}

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
