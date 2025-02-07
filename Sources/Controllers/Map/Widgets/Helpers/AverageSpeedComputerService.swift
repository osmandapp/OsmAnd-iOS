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
    
    private var computersById: [String: OAAverageSpeedComputer] = [:]
    
    func getComputer(for id: String) -> OAAverageSpeedComputer? {
        computersById[id]
    }
    
    func addComputer(for id: String) {
        if !id.isEmpty && computersById[id] == nil {
            computersById[id] = OAAverageSpeedComputer()
        }
    }
    
    func removeComputer(for id: String) {
        computersById.removeValue(forKey: id)
    }
    
    func updateLocation(_ location: CLLocation) {
        for comp in computersById.values {
            comp.update(location)
        }
    }
    
    func resetComputer(for id: String) {
        guard let computer = computersById[id] else { return }
        computer.reset()
    }
}
