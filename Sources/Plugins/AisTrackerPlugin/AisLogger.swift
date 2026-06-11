//
//  AisLogger.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//


final class AisLogger {
    
    static let shared = AisLogger()
    
    var isEnabled = true
    
    private init() {}
    
    func log(_ message: String,
             file: String = #fileID,
             function: String = #function,
             line: Int = #line) {
        guard isEnabled else { return }
        
        print("[AIS] \(message) (\(file):\(line) \(function))")
    }
}