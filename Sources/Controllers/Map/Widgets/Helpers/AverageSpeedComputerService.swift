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
    
    func getComputer(for customId: String) -> OAAverageSpeedComputer {
        if let computer = computersById[customId] {
            return computer
        } else {
            let newComputer = OAAverageSpeedComputer()
            computersById[customId] = newComputer
            return newComputer
        }
    }
    
    func addComputer(for customId: String) {
        if computersById[customId] == nil {
            computersById[customId] = OAAverageSpeedComputer()
        }
    }
    
    func removeComputer(for customId: String) {
        computersById.removeValue(forKey: customId)
    }
    
    func updateLocation(_ location: CLLocation) {
        for comp in computersById.values {
            comp.update(location)
        }
    }
    
    func resetComputer(for customId: String) {
        guard let computer = computersById[customId] else { return }
        computer.reset()
    }
}
