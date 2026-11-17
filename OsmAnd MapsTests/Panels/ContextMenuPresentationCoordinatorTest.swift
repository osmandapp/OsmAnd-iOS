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
        var pendingDismissalCompletion: ((Bool) -> Void)?
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

        pendingDismissalCompletion?(true)

        XCTAssertEqual(presentedMenus, ["second"])
        XCTAssertFalse(coordinator.isTransitionInProgress)
    }

    func testDismissesMenusOneAtATimeBeforePresenting() {
        let coordinator = ContextMenuPresentationCoordinator()
        var remainingMenus = 2
        var pendingDismissalCompletion: ((Bool) -> Void)?
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

        pendingDismissalCompletion?(true)

        XCTAssertEqual(remainingMenus, 0)
        XCTAssertEqual(presentationCount, 0)

        pendingDismissalCompletion?(true)

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
                completion(true)
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

    func testCancelledDismissalDiscardsPendingPresentationAndAllowsNextRequest() {
        let coordinator = ContextMenuPresentationCoordinator()
        var pendingDismissalCompletion: ((Bool) -> Void)?
        var presentedMenus: [String] = []
        let dismissHandler = ContextMenuDismissHandler(handler: { completion in
            pendingDismissalCompletion = completion
            return true
        })

        coordinator.enqueuePresentation { presentedMenus.append("cancelled") }
        coordinator.processPendingPresentation(with: [dismissHandler])
        XCTAssertTrue(coordinator.isTransitionInProgress)

        pendingDismissalCompletion?(false)
        XCTAssertFalse(coordinator.isTransitionInProgress)
        coordinator.processPendingPresentation(with: [])
        XCTAssertTrue(presentedMenus.isEmpty)

        coordinator.enqueuePresentation { presentedMenus.append("next") }
        coordinator.processPendingPresentation(with: [])
        XCTAssertEqual(presentedMenus, ["next"])
    }

    func testHandlesSynchronousDismissalCancellation() {
        let coordinator = ContextMenuPresentationCoordinator()
        let dismissHandler = ContextMenuDismissHandler(handler: { completion in
            completion(false)
            return true
        })

        coordinator.enqueuePresentation { XCTFail("Cancelled presentation must not run") }
        coordinator.processPendingPresentation(with: [dismissHandler])
        XCTAssertFalse(coordinator.isTransitionInProgress)
        coordinator.processPendingPresentation(with: [])

        var presented = false
        coordinator.enqueuePresentation { presented = true }
        coordinator.processPendingPresentation(with: [])
        XCTAssertTrue(presented)
    }
}
