//
//  AstroGalleryLoader.swift
//  OsmAnd Maps
//
//  Ported from Android AstroGalleryLoader.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class AstroGalleryLoader {
    private var getAstroImagesTask: GetAstroImagesTask?
    private var requestWid: String?
    private let onStateChanged: (String, AstroGalleryState) -> Void

    init(onStateChanged: @escaping (String, AstroGalleryState) -> Void) {
        self.onStateChanged = onStateChanged
    }

    func startLoading(_ wikidataId: String) {
        requestWid = wikidataId
        cancelTaskOnly()
        let task = GetAstroImagesTask(wikidataId: wikidataId, getImageCardsListener: self)
        getAstroImagesTask = task
        task.execute()
    }

    func cancel() {
        requestWid = nil
        cancelTaskOnly()
    }

    private func cancelTaskOnly() {
        getAstroImagesTask?.cancel()
        getAstroImagesTask = nil
    }

    private func publishReadyState(wikidataId: String, galleryItems: [AbstractCard]) {
        onStateChanged(wikidataId, .ready(galleryItems))
    }

    private func buildCards(images: [OsmAndShared.WikiImage]) -> [AbstractCard] {
        images.map { image in
            let wikiImage = WikiImage(wikiMediaTag: image.wikiMediaTag,
                                      imageName: image.imageName,
                                      imageStubUrl: image.imageStubUrl,
                                      imageHiResUrl: image.imageHiResUrl)
            wikiImage.mediaId = Int(image.getMediaId())
            wikiImage.metadata = Metadata(date: image.metadata.date,
                                          author: image.metadata.author,
                                          license: image.metadata.license,
                                          description: image.metadata.getDescription(preferredLanguage: Locale.current.languageCode))
            return WikiImageCard(wikiImage: wikiImage, type: "wikimedia-photo")
        }
    }
}

extension AstroGalleryLoader: GetAstroImagesTask.GetImageCardsListener {
    func onTaskStarted() {
    }

    func onFinish(wikidataId: String, images: [OsmAndShared.WikiImage]?) {
        getAstroImagesTask = nil
        guard requestWid == wikidataId else {
            return
        }
        publishReadyState(wikidataId: wikidataId, galleryItems: buildCards(images: images ?? []))
    }
}
