//
//  GetAstroImagesTask.swift
//  OsmAnd Maps
//
//  Ported from Android GetAstroImagesTask.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class GetAstroImagesTask {
    static let getImageCardThreadId = 10105

    protocol GetImageCardsListener: AnyObject {
        func onTaskStarted()
        func onFinish(wikidataId: String, images: [OsmAndShared.WikiImage]?)
    }

    let wikidataId: String
    weak var getImageCardsListener: GetImageCardsListener?
    private var workItem: DispatchWorkItem?

    init(wikidataId: String, getImageCardsListener: GetImageCardsListener?) {
        self.wikidataId = wikidataId
        self.getImageCardsListener = getImageCardsListener
    }

    func execute() {
        getImageCardsListener?.onTaskStarted()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            let images = WikiCoreHelper.shared.getAstroImageList(wikidataId: self.wikidataId, listener: nil)
            DispatchQueue.main.async { [weak self] in
                guard let self, !(self.workItem?.isCancelled ?? true) else {
                    return
                }
                self.getImageCardsListener?.onFinish(wikidataId: self.wikidataId, images: images)
            }
        }
        self.workItem = workItem
        DispatchQueue.global(qos: .utility).async(execute: workItem)
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
