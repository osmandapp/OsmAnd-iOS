//
//  AstroVisibilityGraphView.swift
//  OsmAnd Maps
//
//  Ported from Android AstroVisibilityGraphView.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroVisibilityGraphView: UIView {
    private struct PlotArea {
        let left: CGFloat
        let top: CGFloat
        let right: CGFloat
        let bottom: CGFloat

        var width: CGFloat { right - left }
        var height: CGFloat { bottom - top }
    }

    private var model: AstroVisibilityGraphSnapshot?
    private let palette = AstroChartColorPalette()
    private var isTouchTracking = false
    private var cursorVisible = false
    private var cursorX: CGFloat = 0
    private var cursorReferenceTimeMillis: Int64?

    var onCursorTimeChanged: ((Int64) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func submitGraph(_ graph: AstroVisibilityGraphSnapshot?, cursorReferenceTimeMillis: Int64) {
        model = graph
        self.cursorReferenceTimeMillis = cursorReferenceTimeMillis
        if let graph {
            syncCursorToReference(graph)
        } else {
            cursorVisible = false
        }
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        model.map(syncCursorToReference)
    }

    override func draw(_ rect: CGRect) {
        guard let model,
              model.size >= 2,
              let area = getPlotArea() else {
            return
        }
        drawDynamicBackground(area: area, model: model)
        drawObjectFill(area: area, model: model)
        drawYAxisGridAndLabels(area: area)
        drawXAxisTicksAndLabels(area: area, model: model)
        drawTrajectory(area: area, model: model)
        if cursorVisible {
            drawCursor(area: area, model: model)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let area = getPlotArea(),
              areaContains(touch.location(in: self), area: area) else {
            return
        }
        isTouchTracking = true
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchTracking,
              let touch = touches.first,
              let area = getPlotArea() else {
            return
        }
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchTracking,
              let touch = touches.first,
              let area = getPlotArea() else {
            return
        }
        isTouchTracking = false
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchTracking = false
        if let model {
            syncCursorToReference(model)
        } else {
            cursorVisible = false
        }
        setNeedsDisplay()
    }

    private func drawDynamicBackground(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.saveGState()
        context.addPath(UIBezierPath(roundedRect: CGRect(x: area.left, y: area.top, width: area.width, height: area.height), cornerRadius: 4).cgPath)
        context.clip()

        let drawStep: CGFloat = bounds.width > 256 ? 2 : 1
        var x = area.left
        while x < area.right {
            let nextX = min(area.right, x + drawStep)
            let fraction = area.width <= 1 ? 0 : (x - area.left) / area.width
            let altitude = interpolate(model.sunAltitudes, fraction: Double(fraction))
            palette.colorForSunAltitude(altitude).setFill()
            context.fill(CGRect(x: x, y: area.top, width: nextX - x, height: area.height))
            x = nextX
        }
        context.restoreGState()
    }

    private func drawObjectFill(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let path = UIBezierPath()
        var hasVisible = false
        for index in model.objectAltitudes.indices {
            let altitude = model.objectAltitudes[index]
            guard altitude > 0 else {
                continue
            }
            let point = pointFor(index: index, altitude: altitude, area: area, count: model.objectAltitudes.count)
            if !hasVisible {
                path.move(to: CGPoint(x: point.x, y: yForAltitude(0, area: area)))
                hasVisible = true
            }
            path.addLine(to: point)
        }
        guard hasVisible else {
            return
        }
        path.addLine(to: CGPoint(x: area.right, y: yForAltitude(0, area: area)))
        path.close()
        palette.fill0To15.withAlphaComponent(0.28).setFill()
        path.fill()
    }

    private func drawTrajectory(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let path = UIBezierPath()
        for index in model.objectAltitudes.indices {
            let point = pointFor(index: index,
                                 altitude: model.objectAltitudes[index],
                                 area: area,
                                 count: model.objectAltitudes.count)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        UIColor.white.withAlphaComponent(0.92).setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func drawYAxisGridAndLabels(area: PlotArea) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor(red: 0.32, green: 0.58, blue: 0.88, alpha: 1),
            .paragraphStyle: paragraph
        ]
        for altitude in stride(from: -45, through: 90, by: 45) {
            let y = yForAltitude(Double(altitude), area: area)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: area.left, y: y))
            path.addLine(to: CGPoint(x: area.right, y: y))
            (altitude == 0 ? UIColor(white: 1, alpha: 0.36) : UIColor(white: 1, alpha: 0.16)).setStroke()
            path.lineWidth = altitude == 0 ? 1 : 0.5
            path.stroke()
            let text = "\(altitude)°" as NSString
            text.draw(in: CGRect(x: 0, y: y - 7, width: area.left - 8, height: 14), withAttributes: attributes)
        }
    }

    private func drawXAxisTicksAndLabels(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let formatter = DateFormatter()
        formatter.timeZone = model.timeZone
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? "HH"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor(white: 0.76, alpha: 1)
        ]
        for hour in stride(from: 0, through: 24, by: 6) {
            let fraction = CGFloat(hour) / 24.0
            let x = area.left + area.width * fraction
            UIColor(white: 1, alpha: 0.22).setStroke()
            let tick = UIBezierPath()
            tick.move(to: CGPoint(x: x, y: area.bottom))
            tick.addLine(to: CGPoint(x: x, y: area.bottom + 5))
            tick.lineWidth = 1
            tick.stroke()

            let millis = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * Double(fraction))
            let text = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0)) as NSString
            text.draw(in: CGRect(x: x - 24, y: area.bottom + 8, width: 48, height: 16), withAttributes: attributes)
        }
    }

    private func drawCursor(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let clampedX = min(area.right, max(area.left, cursorX))
        let fraction = area.width <= 0 ? 0 : Double((clampedX - area.left) / area.width)
        let altitude = interpolate(model.objectAltitudes, fraction: fraction)
        let azimuth = interpolate(model.objectAzimuths, fraction: fraction)
        let point = CGPoint(x: clampedX, y: yForAltitude(altitude, area: area))

        UIColor.white.withAlphaComponent(0.8).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: clampedX, y: area.top))
        line.addLine(to: CGPoint(x: clampedX, y: area.bottom))
        line.lineWidth = 1
        line.stroke()

        UIColor.systemBlue.setFill()
        UIColor.white.setStroke()
        let dot = UIBezierPath(ovalIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
        dot.fill()
        dot.lineWidth = 1.5
        dot.stroke()

        let millis = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * fraction)
        let formatter = DateFormatter()
        formatter.timeZone = model.timeZone
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let text = "\(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0)))  \(String(format: "%.1f°", altitude))  \(AstroContextMenuLocalizer.label("astro_az_short", fallback: "Az")) \(String(format: "%.0f°", azimuth))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let markerX = min(area.right - size.width - 12, max(area.left + 6, clampedX - size.width / 2 - 6))
        let rect = CGRect(x: markerX, y: area.top + 8, width: size.width + 12, height: 24)
        UIColor.black.withAlphaComponent(0.42).setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()
        (text as NSString).draw(in: rect.insetBy(dx: 6, dy: 5), withAttributes: attributes)
    }

    private func syncCursorToReference(_ graph: AstroVisibilityGraphSnapshot) {
        guard let area = getPlotArea() else {
            return
        }
        let reference = cursorReferenceTimeMillis ?? graph.startMillis
        let span = max(1, graph.endMillis - graph.startMillis)
        let fraction = CGFloat(Double(reference - graph.startMillis) / Double(span))
        cursorX = area.left + area.width * min(1, max(0, fraction))
        cursorVisible = true
    }

    private func updateCursor(_ x: CGFloat, area: PlotArea, notifyCallback: Bool) {
        guard let model else {
            return
        }
        cursorX = min(area.right, max(area.left, x))
        cursorVisible = true
        if notifyCallback {
            let fraction = area.width <= 0 ? 0 : Double((cursorX - area.left) / area.width)
            let reference = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * fraction)
            cursorReferenceTimeMillis = reference
            onCursorTimeChanged?(reference)
        }
        setNeedsDisplay()
    }

    private func pointFor(index: Int, altitude: Double, area: PlotArea, count: Int) -> CGPoint {
        let x = area.left + area.width * CGFloat(index) / CGFloat(max(1, count - 1))
        return CGPoint(x: x, y: yForAltitude(altitude, area: area))
    }

    private func yForAltitude(_ altitude: Double, area: PlotArea) -> CGFloat {
        let clamped = max(-90.0, min(90.0, altitude))
        let fraction = CGFloat((90.0 - clamped) / 180.0)
        return area.top + area.height * fraction
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

    private func getPlotArea() -> PlotArea? {
        guard bounds.width > 90, bounds.height > 90 else {
            return nil
        }
        return PlotArea(left: 42, top: 12, right: bounds.width - 12, bottom: bounds.height - 28)
    }

    private func areaContains(_ point: CGPoint, area: PlotArea) -> Bool {
        point.x >= area.left && point.x <= area.right && point.y >= area.top && point.y <= area.bottom
    }
}

