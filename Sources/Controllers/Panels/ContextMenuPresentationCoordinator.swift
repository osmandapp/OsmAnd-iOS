//
//  ContextMenuPresentationCoordinator.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 02.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class ContextMenuDismissHandler: NSObject {

    typealias Completion = @convention(block) (Bool) -> Void
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

    typealias Presentation = @convention(block) () -> Void

    var isTransitionInProgress: Bool {
        transitionInProgressValue
    }
    
    private var pendingPresentation: Presentation?
    private var transitionInProgressValue = false

    func enqueuePresentation(_ presentation: @escaping Presentation) {
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
            var synchronousResult: Bool?
            let completion: ContextMenuDismissHandler.Completion = { [weak self] dismissed in
                guard let self else {
                    return
                }

                guard self.transitionInProgressValue else {
                    synchronousResult = dismissed
                    return
                }

                self.finishDismissal(dismissed, with: dismissHandlers)
            }

            if dismissHandler.dismiss(completion: completion) {
                transitionInProgressValue = true
                if let synchronousResult {
                    finishDismissal(synchronousResult, with: dismissHandlers)
                }
                return
            }
        }

        self.pendingPresentation = nil
        pendingPresentation()
    }

    private func finishDismissal(_ dismissed: Bool, with dismissHandlers: [ContextMenuDismissHandler]) {
        transitionInProgressValue = false
        if dismissed {
            processPendingPresentation(withDismissHandlers: dismissHandlers)
        } else {
            // A newer show or hide superseded the dismissal and its pending presentation.
            pendingPresentation = nil
        }
    }
}
