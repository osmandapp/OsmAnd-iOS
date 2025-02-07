//
//  AverageSpeedComputerService.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class AverageSpeedComputerService: NSObject {
    static let shared = AverageSpeedComputerService()
    
    private var computers: [String: OAAverageSpeedComputer] = [:]
    
    func getComputer(for id: String) -> OAAverageSpeedComputer? {
        computers[id]
    }
    
    func addComputer(for id: String) {
        if !id.isEmpty && computers[id] == nil {
            computers[id] = OAAverageSpeedComputer()
        }
    }
    
    func removeComputer(for id: String) {
        computers.removeValue(forKey: id)
    }
    
    func updateLocation(_ location: CLLocation) {
        for comp in computers.values {
            comp.update(location)
        }
    }
    
    func resetComputer(for id: String) {
        guard let computer = computers[id] else { return }
        computer.reset()
    }
}
