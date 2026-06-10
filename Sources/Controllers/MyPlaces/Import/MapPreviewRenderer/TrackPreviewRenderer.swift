//
//  TrackPreviewRenderer.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

@objcMembers
final class OATrackPreviewRenderer: NSObject {

    static let shared = OATrackPreviewRenderer()

    private let queue = DispatchQueue(label: "net.osmand.track-preview", qos: .userInitiated)
    private var cancelled = false

    func renderGpxFile(_ gpxFile: GpxFile,
                       params: MapDrawParams,
                       trackColor: Int32,
                       completion: @escaping (UIImage?) -> Void) {
        cancelled = false
        queue.async { [weak self] in
            guard let self, !self.cancelled else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let image = Self.renderImage(gpxFile: gpxFile, params: params, trackColor: trackColor)
            DispatchQueue.main.async {
                completion(self.cancelled ? nil : image)
            }
        }
    }

    func cancelAll() {
        cancelled = true
    }

    private static func renderImage(gpxFile: GpxFile, params: MapDrawParams, trackColor: Int32) -> UIImage? {
        let width = max(1, params.widthPixels)
        let height = max(1, params.heightPixels)
        let bounds = gpxFile.getRect()

        if bounds.left == 0, bounds.right == 0, bounds.top == 0, bounds.bottom == 0 {
            return nil
        }

        let points = collectTrackPoints(from: gpxFile)
        guard points.count >= 2 else { return nil }

        let size = CGSize(width: width, height: height)
        let padding: CGFloat = 8
        let argb: Int32 = trackColor == 0
            ? Int32(bitPattern: UInt32(truncatingIfNeeded: kDefaultTrackColor))
            : trackColor
        let lineColor = colorFromARGB(argb)

        let format = UIGraphicsImageRendererFormat()
        format.scale = CGFloat(params.density)
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.groupBg.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let path = UIBezierPath()
            for (index, point) in points.enumerated() {
                let mapped = mapPoint(
                    lat: point.lat,
                    lon: point.lon,
                    bounds: bounds,
                    size: size,
                    padding: padding
                )
                if index == 0 {
                    path.move(to: mapped)
                } else {
                    path.addLine(to: mapped)
                }
            }

            lineColor.setStroke()
            path.lineWidth = 3
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func collectTrackPoints(from gpxFile: GpxFile) -> [WptPt] {
        var result: [WptPt] = []
        guard let tracks = gpxFile.tracks as? [Track] else { return result }

        for track in tracks {
            guard let segments = track.segments as? [TrkSegment] else { continue }
            for segment in segments {
                guard let pts = segment.points as? [WptPt] else { continue }
                result.append(contentsOf: pts)
            }
        }
        return result
    }

    private static func mapPoint(lat: Double, lon: Double, bounds: KQuadRect, size: CGSize, padding: CGFloat) -> CGPoint {
        let drawW = size.width - padding * 2
        let drawH = size.height - padding * 2
        let lonSpan = bounds.right - bounds.left
        let latSpan = bounds.top - bounds.bottom

        guard lonSpan > 0, latSpan > 0 else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let x = padding + CGFloat((lon - bounds.left) / lonSpan) * drawW
        let y = padding + CGFloat((bounds.top - lat) / latSpan) * drawH
        return CGPoint(x: x, y: y)
    }

    private static func colorFromARGB(_ argb: Int32) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255
        let r = CGFloat((argb >> 16) & 0xFF) / 255
        let g = CGFloat((argb >> 8) & 0xFF) / 255
        let b = CGFloat(argb & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a > 0 ? a : 1)
    }
}
