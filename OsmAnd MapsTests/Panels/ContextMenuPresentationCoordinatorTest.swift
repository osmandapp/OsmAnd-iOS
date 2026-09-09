//
//  ContextMenuPresentationCoordinatorTest.swift
//  OsmAnd MapsTests
//
//  Created by Oleksandr Panchenko on 01.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import XCTest

final class ContextMenuPresentationCoordinatorTest: XCTestCase {

    func testRunsPresentationImmediatelyWhenNoMenuNeedsDismissal() {
        let coordinator = ContextMenuPresentationCoordinator()
        var presentationCount = 0

        coordinator.enqueuePresentation {
            presentationCount += 1
        }
        coordinator.processPendingPresentation(with: [])

        XCTAssertEqual(presentationCount, 1)
        XCTAssertFalse(coordinator.isTransitionInProgress)
    }

    func testKeepsOnlyLatestPresentationWhileDismissalIsInProgress() {
        let coordinator = ContextMenuPresentationCoordinator()
        var pendingDismissalCompletion: (() -> Void)?
        var dismissCount = 0
        var presentedMenus: [String] = []

        let dismissHandler = ContextMenuDismissHandler(handler: { completion in
            if dismissCount == 0 {
                dismissCount += 1
                pendingDismissalCompletion = completion
                return true
            }
            return false
        })

        coordinator.enqueuePresentation {
            presentedMenus.append("first")
        }
        coordinator.processPendingPresentation(with: [dismissHandler])

        XCTAssertEqual(dismissCount, 1)
        XCTAssertTrue(coordinator.isTransitionInProgress)
        XCTAssertEqual(presentedMenus, [])

        coordinator.enqueuePresentation {
            presentedMenus.append("second")
        }
        coordinator.processPendingPresentation(with: [dismissHandler])

        XCTAssertEqual(dismissCount, 1)
        XCTAssertEqual(presentedMenus, [])

        pendingDismissalCompletion?()

        XCTAssertEqual(presentedMenus, ["second"])
        XCTAssertFalse(coordinator.isTransitionInProgress)
    }

    func testDismissesMenusOneAtATimeBeforePresenting() {
        let coordinator = ContextMenuPresentationCoordinator()
        var remainingMenus = 2
        var pendingDismissalCompletion: (() -> Void)?
        var presentationCount = 0

        let dismissHandler = ContextMenuDismissHandler(handler: { completion in
            if remainingMenus > 0 {
                remainingMenus -= 1
                pendingDismissalCompletion = completion
                return true
            }
            return false
        })

        coordinator.enqueuePresentation {
            presentationCount += 1
        }
        coordinator.processPendingPresentation(with: [dismissHandler])

        XCTAssertEqual(remainingMenus, 1)
        XCTAssertEqual(presentationCount, 0)

        pendingDismissalCompletion?()

        XCTAssertEqual(remainingMenus, 0)
        XCTAssertEqual(presentationCount, 0)

        pendingDismissalCompletion?()

        XCTAssertEqual(presentationCount, 1)
        XCTAssertFalse(coordinator.isTransitionInProgress)
    }

    func testHandlesSynchronousDismissalCompletion() {
        let coordinator = ContextMenuPresentationCoordinator()
        var remainingMenus = 1
        var presentationCount = 0

        let dismissHandler = ContextMenuDismissHandler(handler: { completion in
            if remainingMenus > 0 {
                remainingMenus -= 1
                completion()
                return true
            }
            return false
        })

        coordinator.enqueuePresentation {
            presentationCount += 1
        }
        coordinator.processPendingPresentation(with: [dismissHandler])

        XCTAssertEqual(remainingMenus, 0)
        XCTAssertEqual(presentationCount, 1)
        XCTAssertFalse(coordinator.isTransitionInProgress)
    }
}
