//
//  TrackStubPreviewRenderer.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

@objcMembers
final class TrackStubPreviewRenderer: NSObject {

    static let shared = TrackStubPreviewRenderer()

    private let queue = DispatchQueue(label: "net.osmand.track-preview", qos: .userInitiated)
    private var cancelled = false
    
    private var isCancelled: Bool { cancelled }
    
    // MARK: - Helpers
    
    private static func segmentPath(
        segment: TrkSegment,
        bounds: KQuadRect,
        size: CGSize,
        padding: CGFloat,
        lineWidth: CGFloat
    ) -> UIBezierPath? {
        guard let points = segment.points as? [WptPt], points.count >= 2 else { return nil }

        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineJoinStyle = .round
        path.lineCapStyle = .round

        let step = max(1, points.count / 250)
        for index in Swift.stride(from: 0, to: points.count, by: step) {
            let mappedPoint = mapPoint(
                lat: points[index].lat,
                lon: points[index].lon,
                bounds: bounds,
                size: size,
                padding: padding
            )
            if index == 0 {
                path.move(to: mappedPoint)
            } else {
                path.addLine(to: mappedPoint)
            }
        }

        if !(points.count - 1).isMultiple(of: step), let last = points.last {
            path.addLine(to: mapPoint(lat: last.lat, lon: last.lon, bounds: bounds, size: size, padding: padding))
        }

        return path
    }
    
    private static func mapPoint(
        lat: Double,
        lon: Double,
        bounds: KQuadRect,
        size: CGSize,
        padding: CGFloat
    ) -> CGPoint {
        let drawWidth = size.width - padding * 2
        let drawHeight = size.height - padding * 2
        let lonSpan = bounds.right - bounds.left
        let latSpan = bounds.top - bounds.bottom
        guard lonSpan > 0, latSpan > 0 else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let scale = min(drawWidth / lonSpan, drawHeight / latSpan)
        let originX = padding + (drawWidth - lonSpan * scale) / 2
        let originY = padding + (drawHeight - latSpan * scale) / 2
        return CGPoint(
            x: originX + CGFloat((lon - bounds.left) * scale),
            y: originY + CGFloat((bounds.top - lat) * scale)
        )
    }

    private static func color(fromARGB argb: Int32) -> UIColor {
        let alpha = CGFloat((argb >> 24) & 0xFF) / 255
        let red = CGFloat((argb >> 16) & 0xFF) / 255
        let green = CGFloat((argb >> 8) & 0xFF) / 255
        let blue = CGFloat(argb & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha > 0 ? alpha : 1)
    }
    
    // MARK: - Public API

    func renderGpxFile(
        _ gpxFile: GpxFile,
        params: MapDrawParams,
        trackColor: Int32,
        completion: @escaping (UIImage?) -> Void
    ) {
        cancelled = false
        queue.async { [weak self] in
            guard let self, !self.isCancelled else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let image = self.renderImage(gpxFile: gpxFile, params: params, trackColor: trackColor)
            DispatchQueue.main.async {
                completion(self.isCancelled ? nil : image)
            }
        }
    }

    func cancelAll() {
        cancelled = true
    }

    // MARK: - Rendering

    private func renderImage(gpxFile: GpxFile, params: MapDrawParams, trackColor: Int32) -> UIImage? {
        let width = max(1, params.widthPixels)
        let height = max(1, params.heightPixels)
        let bounds = gpxFile.getRect()

        guard !bounds.hasInitialState() else { return nil }

        let segments = TrackPreviewColorHelper.previewSegments(for: gpxFile)
        guard !segments.isEmpty else { return nil }

        let size = CGSize(width: width, height: height)
        let padding: CGFloat = 8
        let lineWidth = 3 * CGFloat(params.density)

        let format = UIGraphicsImageRendererFormat()
        format.scale = CGFloat(params.density)
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.groupBg.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            for segment in segments {
                guard !self.isCancelled else { return }
                guard let path = Self.segmentPath(
                    segment: segment,
                    bounds: bounds,
                    size: size,
                    padding: padding,
                    lineWidth: lineWidth
                ) else { continue }

                let color = TrackPreviewColorHelper.resolvedColor(
                    gpxFile: gpxFile,
                    segment: segment,
                    defaultColor: trackColor
                )
                Self.color(fromARGB: color).setStroke()
                path.stroke()
            }
        }
    }
}
