//
//  TrackBitmapDrawer.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

protocol MapBitmapDrawerDelegate: AnyObject {
    func onBitmapDrawing()
    func onBitmapDrawn(_ success: Bool)
    func onBitmapDrawn(image: UIImage)
}

extension MapBitmapDrawerDelegate {
    func onBitmapDrawing() {}
    func onBitmapDrawn(_ success: Bool) {}
}

@objcMembers
final class MapDrawParams: NSObject {
    let density: Float
    let widthPixels: Int
    let heightPixels: Int

    init(density: Float, widthPixels: Int, heightPixels: Int) {
        self.density = density
        self.widthPixels = widthPixels
        self.heightPixels = heightPixels
    }

    static func importTrackPreviewParams(size: CGSize) -> MapDrawParams {
        MapDrawParams(
            density: Float(UIScreen.main.scale),
            widthPixels: max(1, Int(size.width)),
            heightPixels: max(1, Int(size.height))
        )
    }
}

class MapBitmapDrawer {
    let params: MapDrawParams
    var isDrawingAllowed = true

    private var listeners: [MapBitmapDrawerDelegate] = []

    init(params: MapDrawParams) {
        self.params = params
    }

    func addListener(_ listener: MapBitmapDrawerDelegate) {
        guard !listeners.contains(where: { $0 === listener }) else { return }
        listeners.append(listener)
    }

    func removeListener(_ listener: MapBitmapDrawerDelegate) {
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

        let trackColor = resolvedTrackColor()
        OATrackPreviewMapRenderer.shared().renderGpxFile(
            gpxFile,
            widthPx: params.widthPixels,
            heightPx: params.heightPixels,
            density: params.density,
            trackColor: trackColor
        ) { [weak self] image in
            guard let self, self.isDrawingAllowed else { return }
            if let image {
                self.notifyDrawn(true)
                self.notifyDrawn(image: image)
            } else {
                self.drawStubPreview(trackColor: trackColor)
            }
        }
    }

    private func resolvedTrackColor() -> Int32 {
        defaultTrackColor != 0 ? defaultTrackColor : TrackPreviewColorHelper.appDefaultTrackColor()
    }

    private func drawStubPreview(trackColor: Int32) {
        TrackStubPreviewRenderer.shared.renderGpxFile(gpxFile, params: params, trackColor: trackColor) { [weak self] image in
            guard let self, self.isDrawingAllowed else { return }
            self.notifyDrawn(image != nil)
            if let image {
                self.notifyDrawn(image: image)
            }
        }
    }
}
