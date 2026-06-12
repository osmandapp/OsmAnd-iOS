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
final class TrackStubPreviewRenderer: NSObject {

    static let shared = TrackStubPreviewRenderer()

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
            let image = renderImage(gpxFile: gpxFile, params: params, trackColor: trackColor)
            DispatchQueue.main.async {
                completion(self.cancelled ? nil : image)
            }
        }
    }

    func cancelAll() {
        cancelled = true
    }

    private func renderImage(gpxFile: GpxFile, params: MapDrawParams, trackColor: Int32) -> UIImage? {
        let width = max(1, params.widthPixels)
        let height = max(1, params.heightPixels)
        let bounds = gpxFile.getRect()
        
        if bounds.left == 0, bounds.right == 0, bounds.top == 0, bounds.bottom == 0 { return nil }
        let segments = TrackPreviewColorHelper.previewSegments(for: gpxFile)
        guard !segments.isEmpty else { return nil }
        
        let size = CGSize(width: width, height: height)
        let padding: CGFloat = 8
        
        func buildSegmentPath(segment: TrkSegment, bounds: KQuadRect, size: CGSize, padding: CGFloat, lineWidth: CGFloat) -> UIBezierPath? {
            guard let pts = segment.points as? [WptPt], pts.count >= 2 else { return nil }
            let path = UIBezierPath()
            path.lineWidth = lineWidth
            path.lineJoinStyle = .round
            path.lineCapStyle = .round
            let step = max(1, pts.count / 250)
            for i in Swift.stride(from: 0, to: pts.count, by: step) {
                let p = Self.mapPoint(lat: pts[i].lat, lon: pts[i].lon, bounds: bounds, size: size, padding: padding)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            if (pts.count - 1) % step != 0 {
                let last = pts[pts.count - 1]
                path.addLine(to: Self.mapPoint(lat: last.lat, lon: last.lon, bounds: bounds, size: size, padding: padding))
            }
            return path
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = CGFloat(params.density)
        format.opaque = true
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.groupBg.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            
            let lineWidth = 3 * CGFloat(params.density)
            for segment in segments {
                guard !cancelled else { return }
                guard let path = buildSegmentPath(segment: segment, bounds: bounds, size: size, padding: padding, lineWidth: lineWidth) else { continue }

                let argb = TrackPreviewColorHelper.resolvedColor(gpxFile: gpxFile, segment: segment, defaultColor: trackColor)
                Self.colorFromARGB(argb).setStroke()
                path.stroke()
            }
        }
    }

    private static func mapPoint(lat: Double, lon: Double, bounds: KQuadRect, size: CGSize, padding: CGFloat) -> CGPoint {
        let drawW = size.width - padding * 2
        let drawH = size.height - padding * 2
        let lonSpan = bounds.right - bounds.left
        let latSpan = bounds.top - bounds.bottom
        guard lonSpan > 0, latSpan > 0 else { return CGPoint(x: size.width / 2, y: size.height / 2) }

        let s = min(drawW / lonSpan, drawH / latSpan)
        let ox = padding + (drawW - lonSpan * s) / 2
        let oy = padding + (drawH - latSpan * s) / 2
        return CGPoint(x: ox + CGFloat((lon - bounds.left) * s),
                       y: oy + CGFloat((bounds.top - lat) * s))
    }

    private static func colorFromARGB(_ argb: Int32) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255
        let r = CGFloat((argb >> 16) & 0xFF) / 255
        let g = CGFloat((argb >> 8) & 0xFF) / 255
        let b = CGFloat(argb & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a > 0 ? a : 1)
    }
}
