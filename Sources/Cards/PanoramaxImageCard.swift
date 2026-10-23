//
//  PanoramaxImageCard.swift
//  OsmAnd
//
//  Created by Eugene on 23.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

/// A gallery card for a picture referenced by the OSM `panoramax=*` tag.
/// The picture is resolved through the Panoramax meta-catalog, see `PanoramaxOsmTagHelper`.
@objcMembers
final class PanoramaxImageCard: ImageCard {
    static let cardType = "panoramax-photo"

    private(set) var metadata: Metadata?
    /// Full definition picture, used for downloads. Falls back to the standard size.
    private(set) var downloadUrl: String
    private(set) var is360: Bool

    override var hash: Int {
        key.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PanoramaxImageCard else { return false }
        return key == other.key
    }

    init(mediaItem: MediaItem.Remote) {
        let standardSize = mediaItem.previewUris.fullSizeUri ?? mediaItem.mediaUri
        downloadUrl = mediaItem.downloadUri ?? standardSize
        is360 = mediaItem.metadata.is360
        super.init(data: [:])

        type = Self.cardType
        key = mediaItem.id
        title = mediaItem.title
        userName = mediaItem.metadata.userName
        url = mediaItem.externalUri ?? PanoramaxApi.shared.getViewerUrl(id: mediaItem.id)
        imageUrl = mediaItem.previewUris.thumbnailUri ?? standardSize
        imageHiresUrl = standardSize
        latitude = mediaItem.metadata.latitude?.doubleValue ?? 0.0
        longitude = mediaItem.metadata.longitude?.doubleValue ?? 0.0
        ca = mediaItem.metadata.cameraAngle.isNaN ? 0.0 : mediaItem.metadata.cameraAngle
        if let timestamp = mediaItem.metadata.timestamp {
            self.timestamp = String(timestamp.int64Value)
        }
        topIcon = "ic_custom_logo_panoramax"

        if let details = mediaItem.details {
            var metadata = Metadata()
            metadata.date = details.date
            metadata.author = details.author
            metadata.license = details.license
            self.metadata = metadata.isEmpty ? nil : metadata
        }
    }

    /// Panoramax asset links point straight at a member instance file, so no width parameter is appended.
    override func getGalleryFullSizeUrl() -> String? {
        imageHiresUrl.isEmpty ? imageUrl : imageHiresUrl
    }
}
