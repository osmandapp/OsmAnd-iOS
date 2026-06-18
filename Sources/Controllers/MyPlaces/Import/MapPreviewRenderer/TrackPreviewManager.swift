//
//  TrackPreviewManager.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class TrackPreviewManager {
    private var listeners: [ImportTrackItem: TrackPreviewDrawerDelegate] = [:]

    func startPreviews(
        for items: [ImportTrackItem],
        params: MapDrawParams,
        onUpdate: @escaping (ImportTrackItem) -> Void
    ) {
        for item in items {
            guard item.previewImage == nil, item.bitmapDrawer == nil else { continue }

            let drawer = TrackBitmapDrawer(params: params, gpxFile: item.selectedGpxFile)
            drawer.defaultTrackColor = TrackPreviewColorHelper.appDefaultTrackColor()

            let listener = TrackPreviewDrawerDelegate(item: item, onUpdate: onUpdate)
            listeners[item] = listener
            drawer.addListener(listener)

            item.bitmapDrawer = drawer
            item.isPreviewLoading = true
            drawer.initAndDraw()
        }
    }

    func cancelAll(_ items: [ImportTrackItem]) {
        OATrackPreviewMapRenderer.shared().cancelAll()
        TrackStubPreviewRenderer.shared.cancelAll()

        for item in items {
            item.bitmapDrawer?.isDrawingAllowed = false
            item.bitmapDrawer = nil
            listeners[item] = nil
        }
    }
}

private final class TrackPreviewDrawerDelegate: MapBitmapDrawerDelegate {
    private let onUpdate: (ImportTrackItem) -> Void
    
    private weak var item: ImportTrackItem?

    init(item: ImportTrackItem, onUpdate: @escaping (ImportTrackItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
    }

    func onBitmapDrawn(image: UIImage) {
        guard let item else { return }
        item.previewImage = image
        item.isPreviewLoading = false
        onUpdate(item)
    }
}
