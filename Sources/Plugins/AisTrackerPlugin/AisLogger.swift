//
//  AisLogger.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//


final class AisLogger: NSObject {
    
    static let shared = AisLogger()
    static let debugLoggingPrefId = "ais_debug_logging"
    
    var isEnabled = true
    
    private let debugLoggingPref: OACommonBoolean
    
    override private init() {
        debugLoggingPref = OAAppSettings.sharedManager().registerBooleanPreference(Self.debugLoggingPrefId, defValue: false)
        isEnabled = debugLoggingPref.get()
    }
    
    func log(_ message: String,
             file: String = #fileID,
             function: String = #function,
             line: Int = #line) {
        guard isEnabled else { return }
        
        print("[AIS] \(message) (\(file):\(line) \(function))")
    }
}
