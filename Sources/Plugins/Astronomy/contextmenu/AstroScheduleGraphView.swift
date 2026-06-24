//
//  AstroScheduleGraphView.swift
//  OsmAnd Maps
//
//  Ported from Android AstroScheduleGraphView.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroScheduleGraphView: UIView {
    private var model: AstroScheduleDayGraphSnapshot?
    private let palette = AstroChartColorPalette()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func submitModel(_ model: AstroScheduleDayGraphSnapshot?) {
        self.model = model
        setNeedsDisplay()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let model,
              bounds.width > 0,
              bounds.height > 0 else {
            return
        }
        let clip = UIBezierPath(roundedRect: bounds, cornerRadius: 2)
        clip.addClip()
        drawSunBackground(model)
        drawObjectVisibilityOverlay(model)
    }

    private func drawSunBackground(_ model: AstroScheduleDayGraphSnapshot) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let drawStep: CGFloat = bounds.width > 256 ? 2 : 1
        var x: CGFloat = 0
        while x < bounds.width {
            let nextX = min(bounds.width, x + drawStep)
            let fraction = bounds.width <= 1 ? 0 : Double(x / (bounds.width - 1))
            palette.colorForSunAltitude(interpolate(model.sunAltitudes, fraction: fraction)).setFill()
            context.fill(CGRect(x: x, y: 0, width: nextX - x, height: bounds.height))
            x = nextX
        }
    }

    private func drawObjectVisibilityOverlay(_ model: AstroScheduleDayGraphSnapshot) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let objectBandHeight = min(CGFloat(16), bounds.height)
        let objectBandTop = (bounds.height - objectBandHeight) / 2
        let objectBandBottom = objectBandTop + objectBandHeight
        let sourceAltitudes = model.objectAltitudes
        guard sourceAltitudes.count >= 2 else {
            return
        }

        let renderSampleCount = min(sourceAltitudes.count, max(2, Int(bounds.width)))
        let renderAltitudes = (0..<renderSampleCount).map { index in
            let fraction = Double(index) / Double(renderSampleCount - 1)
            return interpolate(sourceAltitudes, fraction: fraction)
        }
        let colors = renderAltitudes.map { palette.colorForPositiveObjectAltitude($0).cgColor } as CFArray
        let positions = (0..<renderSampleCount).map { CGFloat($0) / CGFloat(renderSampleCount - 1) }
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors,
                                  locations: positions)

        var segmentStart = -1
        for index in 0..<renderSampleCount {
            let altitude = renderAltitudes[index]
            let isVisible = altitude > 0
            if isVisible && segmentStart == -1 {
                segmentStart = index
            }
            let isSegmentEnd = segmentStart != -1 && (!isVisible || index == renderSampleCount - 1)
            guard isSegmentEnd else {
                continue
            }
            let segmentEnd = isVisible && index == renderSampleCount - 1 ? index : index - 1
            let left = sampleToX(segmentStart, sampleCount: renderSampleCount)
            let rightRaw = sampleToX(segmentEnd, sampleCount: renderSampleCount)
            let right = rightRaw <= left ? min(bounds.width, left + 1) : rightRaw
            if right > left {
                let segmentRect = CGRect(x: left,
                                         y: objectBandTop,
                                         width: right - left,
                                         height: objectBandBottom - objectBandTop)
                if let gradient {
                    context.saveGState()
                    context.clip(to: segmentRect)
                    context.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: objectBandTop),
                                               end: CGPoint(x: bounds.width, y: objectBandTop),
                                               options: [])
                    context.restoreGState()
                } else {
                    palette.colorForPositiveObjectAltitude(altitude).setFill()
                    UIBezierPath(rect: segmentRect).fill()
                }
            }
            segmentStart = -1
        }
    }

    private func sampleToX(_ index: Int, sampleCount: Int) -> CGFloat {
        guard sampleCount > 1, bounds.width > 0 else {
            return 0
        }
        let clampedIndex = max(0, min(sampleCount - 1, index))
        return CGFloat(clampedIndex) / CGFloat(sampleCount - 1) * bounds.width
    }

    private func interpolate(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        guard values.count > 1 else {
            return values[0]
        }
        let index = min(1.0, max(0.0, fraction)) * Double(values.count - 1)
        let startIndex = min(values.count - 1, max(0, Int(floor(index))))
        let endIndex = min(values.count - 1, startIndex + 1)
        let t = index - Double(startIndex)
        return values[startIndex] + (values[endIndex] - values[startIndex]) * t
    }
}
