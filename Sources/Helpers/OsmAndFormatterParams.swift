//
//  OsmAndFormatterParams.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class OsmAndFormatterParams: NSObject {
    static let defaultForceTrailing: Bool = true
    static let defaultExtraDecimalPrecision: Int = 1
    var forceTrailingZerosInDecimalMainUnit: Bool = defaultForceTrailing
    var extraDecimalPrecision: Int = defaultExtraDecimalPrecision
    var useLowerBound: Bool = false
    var isUseLowerBound: Bool {
        return useLowerBound
    }
    
    static let `default`: OsmAndFormatterParams = OsmAndFormatterParams()
    
    static let useLowerBounds: OsmAndFormatterParams = {
        let params = OsmAndFormatterParams()
        params.useLowerBound = true
        params.extraDecimalPrecision = 0
        params.forceTrailingZerosInDecimalMainUnit = true
        return params
    }()
    
    static let noTrailingZeros: OsmAndFormatterParams = {
        let params = OsmAndFormatterParams()
        params.setTrailingZerosForMainUnit(false)
        return params
    }()
    
    @discardableResult
    func setTrailingZerosForMainUnit(_ forceTrailingZeros: Bool) -> OsmAndFormatterParams {
        forceTrailingZerosInDecimalMainUnit = forceTrailingZeros
        return self
    }
}
