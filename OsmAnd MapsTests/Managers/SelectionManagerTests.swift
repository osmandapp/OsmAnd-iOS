//
//  SelectionManagerTests.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import XCTest

final class SelectionManagerTests: XCTestCase {
    
    // MARK: - Int Tests

    func testInitWithValidSelectionSetsSelectedItems() {
        let manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [2])
        XCTAssertEqual(manager.selectedItems, [2])
        XCTAssertFalse(manager.isEmpty)
        XCTAssertFalse(manager.areAllSelected)
        XCTAssertFalse(manager.hasChanges)
    }

    func testInitWithInvalidSelectionResultsInEmptySelection() {
        let manager = SelectionManager(allItems: [1, 2], initiallySelected: [3])
        XCTAssertEqual(manager.selectedItems, [])
        XCTAssertTrue(manager.isEmpty)
        XCTAssertFalse(manager.hasChanges)
    }

    func testToggleSelectedItemRemovesFromSelection() {
        var manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [2])
        manager.toggle(2)
        XCTAssertEqual(manager.selectedItems, [])
        XCTAssertTrue(manager.hasChanges)
    }

    func testToggleUnselectedItemAddsToSelection() {
        var manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [2])
        manager.toggle(3)
        XCTAssertEqual(manager.selectedItems, [2, 3])
        XCTAssertTrue(manager.hasChanges)
    }

    func testSelectAll() {
        var manager = SelectionManager(allItems: [1, 2, 3])
        manager.selectAll()
        XCTAssertEqual(manager.selectedItems, [1, 2, 3])
        XCTAssertTrue(manager.areAllSelected)
        XCTAssertTrue(manager.hasChanges)
    }

    func testDeselectAll() {
        var manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [1])
        manager.deselectAll()
        XCTAssertTrue(manager.selectedItems.isEmpty)
        XCTAssertTrue(manager.isEmpty)
        XCTAssertTrue(manager.hasChanges)
    }

    func testSelectAllThenDeselectAllResultsInEmptySelection() {
        var manager = SelectionManager(allItems: [1, 2])
        manager.selectAll()
        manager.deselectAll()
        XCTAssertTrue(manager.isEmpty)
        XCTAssertFalse(manager.hasChanges)
    }

    func testHasChangesIsFalseAfterRevertingToInitialSelection() {
        var manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [2])
        manager.toggle(2) // remove
        manager.toggle(3) // add
        XCTAssertTrue(manager.hasChanges)

        manager.toggle(2) // add back
        manager.toggle(3) // remove
        XCTAssertEqual(manager.selectedItems, [2])
        XCTAssertFalse(manager.hasChanges)
    }

    // MARK: - String Tests

    func testStringSelectionBehavior() {
        var manager = SelectionManager(allItems: ["a", "b", "c"], initiallySelected: ["b"])
        XCTAssertEqual(manager.selectedItems, ["b"])
        XCTAssertFalse(manager.hasChanges)

        manager.toggle("c")
        XCTAssertEqual(manager.selectedItems, ["b", "c"])
        XCTAssertTrue(manager.hasChanges)

        manager.deselectAll()
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - Custom Struct Tests

    struct Fruit: Hashable {
        let name: String
    }

    func testCustomStructSelectionBehavior() {
        let apple = Fruit(name: "apple")
        let banana = Fruit(name: "banana")
        let cherry = Fruit(name: "cherry")

        var manager = SelectionManager(allItems: [apple, banana, cherry], initiallySelected: [banana])
        XCTAssertEqual(manager.selectedItems, [banana])
        XCTAssertFalse(manager.hasChanges)

        manager.toggle(cherry)
        XCTAssertEqual(manager.selectedItems, [banana, cherry])
        XCTAssertTrue(manager.hasChanges)

        manager.deselectAll()
        XCTAssertTrue(manager.isEmpty)
        XCTAssertTrue(manager.hasChanges)
    }
}
