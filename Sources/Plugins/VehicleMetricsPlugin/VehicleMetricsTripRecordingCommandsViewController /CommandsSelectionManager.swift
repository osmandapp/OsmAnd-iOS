//
//  SelectionManager.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 18.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class SelectionManager<T: Hashable> {
    let allItems: Set<T>
    private(set) var selectedItems: Set<T> = []

    var areAllSelected: Bool {
        selectedItems == allItems
    }

    var isEmpty: Bool {
        selectedItems.isEmpty
    }

    init(allItems: [T], initiallySelected: [T] = []) {
        self.allItems = Set(allItems)
        let validInitialSelection = initiallySelected.filter { allItems.contains($0) }
        self.selectedItems = Set(validInitialSelection)
    }

    func toggle(_ item: T) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }

    func selectAll() {
        selectedItems = allItems
    }

    func deselectAll() {
        selectedItems.removeAll()
    }
}


//final class CommandsSelectionManager {
//    let allCommands: Set<String>
//    private(set) var selectedCommands: Set<String> = []
//    
//    var areAllSelected: Bool {
//        selectedCommands == allCommands
//    }
//    
//    var isEmpty: Bool {
//        selectedCommands.isEmpty
//    }
//
//    init(allCommands: [String]) {
//        self.allCommands = Set(allCommands)
//        if let plugin = OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin,
//           let commands = plugin.TRIP_RECORDING_VEHICLE_METRICS.get(), !commands.isEmpty {
//            selectedCommands = Set(commands)
//        }
//    }
//
//    func toggleCommand(_ command: String) {
//        if selectedCommands.contains(command) {
//            selectedCommands.remove(command)
//        } else {
//            selectedCommands.insert(command)
//        }
//    }
//
//    func selectAll() {
//        selectedCommands = allCommands
//    }
//
//    func deselectAll() {
//        selectedCommands.removeAll()
//    }
//}
