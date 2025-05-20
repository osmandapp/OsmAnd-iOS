//
//  CommProtocol.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 16.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//


protocol CommProtocol {
    func sendCommand(_ command: String, retries: Int) async throws -> [String]
}
