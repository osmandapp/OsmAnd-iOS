//
//  ContextMenuPresentationCoordinator.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class ContextMenuPresentationCoordinator: NSObject {

    typealias DismissCompletion = @convention(block) () -> Void
    typealias DismissHandler = @convention(block) (@escaping DismissCompletion) -> Bool

    var isTransitionInProgress: Bool {
        transitionInProgressValue
    }
    
    private var pendingPresentation: DismissCompletion?
    private var transitionInProgressValue = false

    func enqueuePresentation(_ presentation: @escaping DismissCompletion) {
        pendingPresentation = presentation
    }

    @nonobjc
    func processPendingPresentation(with dismissHandlers: [DismissHandler]) {
        processPendingPresentation(withDismissHandlers: dismissHandlers)
    }

    @objc(processPendingPresentationWithDismissHandlers:)
    func processPendingPresentation(withDismissHandlers dismissHandlers: NSArray) {
        let handlers = dismissHandlers.map { unsafeBitCast($0 as AnyObject, to: DismissHandler.self) }
        processPendingPresentation(withDismissHandlers: handlers)
    }

    private func processPendingPresentation(withDismissHandlers dismissHandlers: [DismissHandler]) {
        guard !transitionInProgressValue, let pendingPresentation else {
            return
        }

        for dismissHandler in dismissHandlers {
            var completedSynchronously = false
            let completion: DismissCompletion = { [weak self] in
                guard let self else {
                    return
                }

                guard self.transitionInProgressValue else {
                    completedSynchronously = true
                    return
                }

                self.transitionInProgressValue = false
                self.processPendingPresentation(withDismissHandlers: dismissHandlers)
            }

            if dismissHandler(completion) {
                transitionInProgressValue = true
                if completedSynchronously {
                    transitionInProgressValue = false
                    processPendingPresentation(withDismissHandlers: dismissHandlers)
                }
                return
            }
        }

        self.pendingPresentation = nil
        pendingPresentation()
    }
}
