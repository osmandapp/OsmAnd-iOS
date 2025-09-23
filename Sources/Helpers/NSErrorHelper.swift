//
//  NSErrorHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 22.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ErrorHelper: NSObject {
    static func isInternetConnectionError(_ error: NSError?) -> Bool {
        guard let error else { return false }
        return error.domain == NSURLErrorDomain &&
               error.code == NSURLErrorNotConnectedToInternet
    }
}
