//
//  ContextMenuPresentationCoordinator.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class ContextMenuDismissHandler: NSObject {

    typealias Completion = @convention(block) () -> Void
    typealias Handler = @convention(block) (@escaping Completion) -> Bool

    private let handler: Handler

    @objc(initWithHandler:) init(handler: @escaping Handler) {
        self.handler = handler
    }

    func dismiss(completion: @escaping Completion) -> Bool {
        handler(completion)
    }
}

@objcMembers
final class ContextMenuPresentationCoordinator: NSObject {

    typealias DismissCompletion = ContextMenuDismissHandler.Completion

    var isTransitionInProgress: Bool {
        transitionInProgressValue
    }
    
    private var pendingPresentation: DismissCompletion?
    private var transitionInProgressValue = false

    func enqueuePresentation(_ presentation: @escaping DismissCompletion) {
        pendingPresentation = presentation
    }

    @nonobjc
    func processPendingPresentation(with dismissHandlers: [ContextMenuDismissHandler]) {
        processPendingPresentation(withDismissHandlers: dismissHandlers)
    }

    func processPendingPresentation(withDismissHandlers dismissHandlers: [ContextMenuDismissHandler]) {
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

            if dismissHandler.dismiss(completion: completion) {
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
