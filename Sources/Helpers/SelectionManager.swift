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
        let validSelection = initiallySelected.filter { allItems.contains($0) }
        self.selectedItems = Set(validSelection)
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
