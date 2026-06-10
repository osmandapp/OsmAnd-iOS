//
//  TrackBitmapDrawer.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

class MapBitmapDrawer {
    let params: MapDrawParams
    var isDrawingAllowed = true

    private var listeners: [MapBitmapDrawerListener] = []

    init(params: MapDrawParams) {
        self.params = params
    }

    func addListener(_ listener: MapBitmapDrawerListener) {
        if !listeners.contains(where: { $0 === listener }) {
            listeners.append(listener)
        }
    }

    func removeListener(_ listener: MapBitmapDrawerListener) {
        listeners.removeAll { $0 === listener }
    }

    func notifyDrawing() {
        listeners.forEach { $0.onBitmapDrawing() }
    }

    func notifyDrawn(_ success: Bool) {
        listeners.forEach { $0.onBitmapDrawn(success) }
    }

    func notifyDrawn(image: UIImage) {
        listeners.forEach { $0.onBitmapDrawn(image: image) }
    }
}

final class TrackBitmapDrawer: MapBitmapDrawer {
    private let gpxFile: GpxFile
    var defaultTrackColor: Int32 = 0

    init(params: MapDrawParams, gpxFile: GpxFile) {
        self.gpxFile = gpxFile
        super.init(params: params)
    }

    func initAndDraw() {
        notifyDrawing()
        guard isDrawingAllowed else { return }

        var color = defaultTrackColor
        if color == 0 {
            color = Int32(bitPattern: UInt32(truncatingIfNeeded: kDefaultTrackColor))
        }

        OATrackPreviewMapRenderer.shared().renderGpxFile(
            gpxFile,
            widthPx: params.widthPixels,
            heightPx: params.heightPixels,
            density: params.density,
            trackColor: color
        ) { [weak self] image in
            guard let self, self.isDrawingAllowed else { return }
            if let image {
                self.notifyDrawn(true)
                self.notifyDrawn(image: image)
            } else {
                self.renderStub(color: color)
            }
        }
    }

    private func renderStub(color: Int32) {
        OATrackPreviewRenderer.shared.renderGpxFile(gpxFile, params: params, trackColor: color) { [weak self] image in
            guard let self, self.isDrawingAllowed else { return }
            self.notifyDrawn(image != nil)
            if let image {
                self.notifyDrawn(image: image)
            }
        }
    }
}
