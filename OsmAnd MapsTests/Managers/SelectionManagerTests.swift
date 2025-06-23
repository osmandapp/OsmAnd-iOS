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

    func testInitialization_withValidSelection() {
        let manager = SelectionManager(allItems: [1, 2, 3], initiallySelected: [2, 3])
        XCTAssertEqual(manager.selectedItems, [2, 3])
        XCTAssertFalse(manager.isEmpty)
        XCTAssertFalse(manager.areAllSelected)
    }

    func testInitialization_withInvalidSelection() {
        let manager = SelectionManager(allItems: [1, 2], initiallySelected: [3])
        XCTAssertEqual(manager.selectedItems, [])
        XCTAssertTrue(manager.isEmpty)
    }

    func testToggle_addAndRemove() {
        let manager = SelectionManager(allItems: [1, 2, 3])
        manager.toggle(2)
        XCTAssertEqual(manager.selectedItems, [2])
        manager.toggle(2)
        XCTAssertTrue(manager.selectedItems.isEmpty)
    }

    func testSelectAllAndDeselectAll() {
        let manager = SelectionManager(allItems: [1, 2, 3])
        manager.selectAll()
        XCTAssertEqual(manager.selectedItems, [1, 2, 3])
        XCTAssertTrue(manager.areAllSelected)

        manager.deselectAll()
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - String Tests

    func testStringSelectionManager() {
        let manager = SelectionManager(allItems: ["apple", "banana", "orange"], initiallySelected: ["banana"])
        XCTAssertEqual(manager.selectedItems, ["banana"])

        let mutable = manager
        mutable.toggle("orange")
        XCTAssertEqual(mutable.selectedItems, ["banana", "orange"])

        mutable.selectAll()
        XCTAssertTrue(mutable.areAllSelected)

        mutable.deselectAll()
        XCTAssertTrue(mutable.isEmpty)
    }

    // MARK: - Custom Struct Tests

    struct Fruit: Hashable {
        let name: String
    }

    func testCustomStructSelectionManager() {
        let apple = Fruit(name: "Apple")
        let banana = Fruit(name: "Banana")
        let cherry = Fruit(name: "Cherry")

        let manager = SelectionManager(allItems: [apple, banana, cherry], initiallySelected: [banana])
        XCTAssertEqual(manager.selectedItems, [banana])

        let mutable = manager
        mutable.toggle(cherry)
        XCTAssertEqual(mutable.selectedItems, [banana, cherry])

        mutable.selectAll()
        XCTAssertTrue(mutable.areAllSelected)

        mutable.deselectAll()
        XCTAssertTrue(mutable.isEmpty)
    }
}
