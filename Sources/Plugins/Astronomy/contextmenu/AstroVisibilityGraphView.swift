//
//  AstroVisibilityGraphView.swift
//  OsmAnd Maps
//
//  Ported from Android AstroVisibilityGraphView.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AstroVisibilityGraphView: UIView {
    private enum ZeroCrossingType {
        case sunrise
        case sunset
    }

    private struct PlotArea {
        let left: CGFloat
        let top: CGFloat
        let right: CGFloat
        let bottom: CGFloat

        var width: CGFloat { right - left }
        var height: CGFloat { bottom - top }
    }

    private struct ZeroCrossing {
        let x: CGFloat
        let type: ZeroCrossingType
    }

    private enum Constants {
        static let minAltitudeRender = -40.0
        static let maxAltitudeRender = 95.0

        static let outerLeftPadding: CGFloat = 16
        static let outerRightPadding: CGFloat = 16
        static let outerTopPadding: CGFloat = 1
        static let outerBottomPadding: CGFloat = 1
        static let rightAxisOutset: CGFloat = 30

        static let yGridStroke: CGFloat = 1
        static let yGridDash: CGFloat = 6
        static let yGridGap: CGFloat = 6
        static let yLabelTextSize: CGFloat = 10
        static let yLabelToLineGap: CGFloat = 2

        static let xLabelTextSize: CGFloat = 10
        static let xTickStroke: CGFloat = 1
        static let xTickHeight: CGFloat = 7
        static let xLabelToGraphGap: CGFloat = 2
        static let labelEdgeMin: CGFloat = 0

        static let sunIconSize: CGFloat = 12
        static let sunIconRaise: CGFloat = 2

        static let cursorLineStroke: CGFloat = 2
        static let cursorSideOffset: CGFloat = 2
        static let cursorDotRadius: CGFloat = 5
        static let cursorDotStroke: CGFloat = 2

        static let markerTextSize: CGFloat = 14
        static let markerBorderStroke: CGFloat = 1
        static let markerSeparatorStroke: CGFloat = 1
        static let markerCorner: CGFloat = 6
        static let markerHorizontalPadding: CGFloat = 10
        static let markerHeight: CGFloat = 24
        static let markerSeparatorInset: CGFloat = 2
        static let markerToGraphGap: CGFloat = 3
    }

    private enum GraphColors {
        static let xTick = UIColor(rgbValue: 0xBEBCC2)
        static let xLabel = UIColor(rgbValue: 0x7D738C)
        static let yLabel = UIColor(rgbValue: 0x2183F4)
        static let yGrid = UIColor(rgbValue: 0xD8D7DB).withAlphaComponent(0.5)
        static let yZero = UIColor(rgbValue: 0xD8D7DB)
        static let markerBorder = UIColor(rgbValue: 0xAEB4C2)
        static let markerAzimuth = UIColor(rgbValue: 0x14CC9E)
        static let cursorLineCenter = UIColor(rgbValue: 0xE6EBF9)
        static let cursorLineSide = UIColor.white.withAlphaComponent(0.2)
        static let cursorDotFill = UIColor(rgbValue: 0x1852FF)
        static let cursorDotStroke = UIColor.white
    }

    private var model: AstroVisibilityGraphSnapshot?
    private let palette = AstroChartColorPalette()
    private var isTouchTracking = false
    private var cursorVisible = false
    private var cursorX: CGFloat = 0
    private var cursorReferenceTimeMillis: Int64?
    private weak var disabledParentScrollView: UIScrollView?

    var onCursorTimeChanged: ((Int64) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let model,
              model.size >= 2,
              let area = getPlotArea(),
              let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawDynamicBackground(context: context, area: area, model: model)
        if let trajectory = buildTrajectoryPath(area: area, model: model) {
            drawObjectFill(context: context, area: area, trajectory: trajectory)
        }
        drawYAxisGridAndLabels(context: context, area: area)
        drawXAxisTicksAndLabels(context: context, area: area, model: model)
        drawSunriseSunsetIcons(area: area, model: model)
        if cursorVisible {
            drawCursor(context: context, area: area, model: model)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let area = getPlotArea(),
              areaContains(touch.location(in: self), area: area) else {
            super.touchesBegan(touches, with: event)
            return
        }
        setParentScrollEnabled(false)
        isTouchTracking = true
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchTracking,
              let touch = touches.first,
              let area = getPlotArea() else {
            super.touchesMoved(touches, with: event)
            return
        }
        setParentScrollEnabled(false)
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            isTouchTracking = false
            setParentScrollEnabled(true)
        }
        guard isTouchTracking,
              let touch = touches.first,
              let area = getPlotArea() else {
            super.touchesEnded(touches, with: event)
            return
        }
        updateCursor(touch.location(in: self).x, area: area, notifyCallback: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchTracking = false
        setParentScrollEnabled(true)
        if let model {
            syncCursorToReference(model)
        } else {
            cursorVisible = false
        }
        setNeedsDisplay()
    }

    private func drawDynamicBackground(context: CGContext, area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let drawStep: CGFloat = 2
        var x = area.left
        while x < area.right {
            let nextX = min(area.right, x + drawStep)
            let centerFraction = Double((((x + nextX) * 0.5 - area.left) / area.width).clamped(to: 0...1))
            let altitude = interpolate(model.sunAltitudes, fraction: centerFraction)
            context.setFillColor(palette.colorForSunAltitude(altitude).cgColor)
            context.fill(CGRect(x: x, y: area.top, width: nextX - x, height: area.height))
            x = nextX
        }
    }

    private func drawObjectFill(context: CGContext, area: PlotArea, trajectory: UIBezierPath) {
        let fillPath = UIBezierPath(cgPath: trajectory.cgPath)
        fillPath.addLine(to: CGPoint(x: area.right, y: area.bottom))
        fillPath.addLine(to: CGPoint(x: area.left, y: area.bottom))
        fillPath.close()

        guard let gradient = buildObjectFillGradient(area: area) else {
            return
        }
        context.saveGState()
        context.addPath(fillPath.cgPath)
        context.clip()
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: area.top),
                                   end: CGPoint(x: 0, y: area.bottom),
                                   options: [])
        context.restoreGState()
    }

    private func buildObjectFillGradient(area: PlotArea) -> CGGradient? {
        let transitionHalf = AstroChartColorPalette.objectGradientTransitionDegrees / 2.0
        let yRange = max(1, area.height)
        func position(for altitude: Double) -> CGFloat {
            ((yForAltitude(altitude, area: area) - area.top) / yRange).clamped(to: 0...1)
        }
        let colors = [
            palette.fillGt45.cgColor,
            palette.fillGt45.cgColor,
            palette.fill15To45.cgColor,
            palette.fill15To45.cgColor,
            palette.fill0To15.cgColor,
            palette.fill0To15.cgColor,
            palette.fillLt0.cgColor,
            palette.fillLt0.cgColor
        ] as CFArray
        let locations: [CGFloat] = [
            0,
            position(for: 45.0 + transitionHalf),
            position(for: 45.0 - transitionHalf),
            position(for: 15.0 + transitionHalf),
            position(for: 15.0 - transitionHalf),
            position(for: 0.0 + transitionHalf),
            position(for: 0.0 - transitionHalf),
            1
        ]
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
    }

    private func drawYAxisGridAndLabels(context: CGContext, area: PlotArea) {
        let axisEndX = area.right + Constants.rightAxisOutset
        let labelFont = UIFont.systemFont(ofSize: Constants.yLabelTextSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: GraphColors.yLabel
        ]
        for altitude in stride(from: -30, through: 90, by: 15) {
            let y = yForAltitude(Double(altitude), area: area)
            context.saveGState()
            context.setLineWidth(Constants.yGridStroke)
            context.setLineDash(phase: 0, lengths: [Constants.yGridDash, Constants.yGridGap])
            context.setStrokeColor((altitude == 0 ? GraphColors.yZero : GraphColors.yGrid).cgColor)
            context.move(to: CGPoint(x: area.left, y: y))
            context.addLine(to: CGPoint(x: axisEndX, y: y))
            context.strokePath()
            context.restoreGState()

            let text = "\(altitude)°" as NSString
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: axisEndX - size.width,
                                  y: y + Constants.yLabelToLineGap),
                      withAttributes: attributes)
        }
    }

    private func drawXAxisTicksAndLabels(context: CGContext, area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let formatter = createAxisTimeFormatter(timeZone: model.timeZone)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: Constants.xLabelTextSize),
            .foregroundColor: GraphColors.xLabel
        ]
        for step in 0...6 {
            let fraction = CGFloat(step) / 6.0
            let millis = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * Double(fraction))
            let x = timeToX(millis, area: area, model: model)
            context.saveGState()
            context.setStrokeColor(GraphColors.xTick.cgColor)
            context.setLineWidth(Constants.xTickStroke)
            context.move(to: CGPoint(x: x, y: area.bottom - Constants.xTickHeight))
            context.addLine(to: CGPoint(x: x, y: area.bottom))
            context.strokePath()
            context.restoreGState()

            let label = formatter.string(from: date(fromMillis: millis)) as NSString
            let size = label.size(withAttributes: attributes)
            let half = size.width / 2
            let clampedX = x.clamped(to: (Constants.labelEdgeMin + half)...(bounds.width - Constants.labelEdgeMin - half))
            label.draw(at: CGPoint(x: clampedX - half,
                                   y: area.bottom + Constants.xLabelToGraphGap),
                       withAttributes: attributes)
        }
    }

    private func drawSunriseSunsetIcons(area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let crossings = findZeroCrossings(model: model, area: area)
        guard !crossings.isEmpty else {
            return
        }
        let y = yForAltitude(0.0, area: area) - Constants.sunIconRaise
        for crossing in crossings {
            let imageName = crossing.type == .sunrise ? "ic_action_sunrise_12" : "ic_action_sunset_12"
            guard let image = AstroIcon.original(imageName) ?? AstroIcon.template(imageName) else {
                continue
            }
            image.draw(in: CGRect(x: crossing.x - Constants.sunIconSize / 2,
                                  y: y - Constants.sunIconSize / 2,
                                  width: Constants.sunIconSize,
                                  height: Constants.sunIconSize))
        }
    }

    private func drawCursor(context: CGContext, area: PlotArea, model: AstroVisibilityGraphSnapshot) {
        let x = cursorX.clamped(to: area.left...area.right)
        let fraction = Double(((x - area.left) / area.width).clamped(to: 0...1))
        let altitude = interpolate(model.objectAltitudes, fraction: fraction)
        let azimuth = interpolateAzimuth(model.objectAzimuths, fraction: fraction)
        let millis = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * fraction)
        let y = yForAltitude(altitude, area: area)
        let lineTop = area.top - Constants.markerToGraphGap
        let sideOffset = Constants.cursorSideOffset

        context.saveGState()
        context.setLineWidth(Constants.cursorLineStroke)
        context.setStrokeColor(GraphColors.cursorLineSide.cgColor)
        context.move(to: CGPoint(x: x - sideOffset, y: lineTop))
        context.addLine(to: CGPoint(x: x - sideOffset, y: area.bottom))
        context.move(to: CGPoint(x: x + sideOffset, y: lineTop))
        context.addLine(to: CGPoint(x: x + sideOffset, y: area.bottom))
        context.strokePath()
        context.setStrokeColor(GraphColors.cursorLineCenter.cgColor)
        context.move(to: CGPoint(x: x, y: lineTop))
        context.addLine(to: CGPoint(x: x, y: area.bottom))
        context.strokePath()
        context.restoreGState()

        GraphColors.cursorDotFill.setFill()
        GraphColors.cursorDotStroke.setStroke()
        let dot = UIBezierPath(ovalIn: CGRect(x: x - Constants.cursorDotRadius,
                                              y: y - Constants.cursorDotRadius,
                                              width: Constants.cursorDotRadius * 2,
                                              height: Constants.cursorDotRadius * 2))
        dot.fill()
        dot.lineWidth = Constants.cursorDotStroke
        dot.stroke()

        let timeLabel = createMarkerTimeFormatter(timeZone: model.timeZone).string(from: date(fromMillis: millis))
        let altitudeLabel = "\(Int(altitude.rounded()))° \(localizedString("astro_alt_short"))"
        let azimuthLabel = "\(Int(azimuth.rounded()))° \(localizedString("astro_az_short")) (\(cardinalDirection(for: azimuth)))"
        drawCursorMarker(context: context,
                         area: area,
                         anchorX: x,
                         timeLabel: timeLabel,
                         altitudeLabel: altitudeLabel,
                         azimuthLabel: azimuthLabel,
                         lineTop: lineTop)
    }

    private func drawCursorMarker(context: CGContext,
                                  area: PlotArea,
                                  anchorX: CGFloat,
                                  timeLabel: String,
                                  altitudeLabel: String,
                                  azimuthLabel: String,
                                  lineTop: CGFloat) {
        let font = UIFont.systemFont(ofSize: Constants.markerTextSize)
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: AstroContextMenuTheme.primaryText.currentMapThemeColor
        ]
        let altitudeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: GraphColors.yLabel
        ]
        let azimuthAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: GraphColors.markerAzimuth
        ]
        let timeSize = (timeLabel as NSString).size(withAttributes: timeAttributes)
        let altitudeSize = (altitudeLabel as NSString).size(withAttributes: altitudeAttributes)
        let azimuthSize = (azimuthLabel as NSString).size(withAttributes: azimuthAttributes)
        let section1 = timeSize.width + Constants.markerHorizontalPadding * 2
        let section2 = altitudeSize.width + Constants.markerHorizontalPadding * 2
        let section3 = azimuthSize.width + Constants.markerHorizontalPadding * 2
        let totalWidth = section1 + section2 + section3
        let left = (anchorX - totalWidth / 2).clamped(to: area.left...max(area.left, area.right - totalWidth))
        let rect = CGRect(x: left,
                          y: lineTop - Constants.markerHeight,
                          width: totalWidth,
                          height: Constants.markerHeight)

        context.saveGState()
        context.setStrokeColor(GraphColors.markerBorder.cgColor)
        context.setLineWidth(Constants.markerBorderStroke)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: Constants.markerCorner).cgPath)
        context.strokePath()

        context.setLineWidth(Constants.markerSeparatorStroke)
        let separator1 = rect.minX + section1
        let separator2 = separator1 + section2
        let separatorTop = rect.minY + Constants.markerSeparatorInset
        let separatorBottom = rect.maxY - Constants.markerSeparatorInset
        context.move(to: CGPoint(x: separator1, y: separatorTop))
        context.addLine(to: CGPoint(x: separator1, y: separatorBottom))
        context.move(to: CGPoint(x: separator2, y: separatorTop))
        context.addLine(to: CGPoint(x: separator2, y: separatorBottom))
        context.strokePath()
        context.restoreGState()

        let textY = rect.minY + (rect.height - font.lineHeight) / 2
        (timeLabel as NSString).draw(at: CGPoint(x: rect.minX + Constants.markerHorizontalPadding, y: textY),
                                     withAttributes: timeAttributes)
        (altitudeLabel as NSString).draw(at: CGPoint(x: separator1 + Constants.markerHorizontalPadding, y: textY),
                                         withAttributes: altitudeAttributes)
        (azimuthLabel as NSString).draw(at: CGPoint(x: separator2 + Constants.markerHorizontalPadding, y: textY),
                                        withAttributes: azimuthAttributes)
    }

    private func buildTrajectoryPath(area: PlotArea, model: AstroVisibilityGraphSnapshot) -> UIBezierPath? {
        guard model.size >= 2 else {
            return nil
        }
        let renderSampleCount = min(model.size, max(2, Int(area.width.rounded())))
        guard renderSampleCount >= 2 else {
            return nil
        }
        let path = UIBezierPath()
        for index in 0..<renderSampleCount {
            let fraction = Double(index) / Double(renderSampleCount - 1)
            let x = area.left + CGFloat(fraction) * area.width
            let y = yForAltitude(interpolate(model.objectAltitudes, fraction: fraction), area: area)
            index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    private func findZeroCrossings(model: AstroVisibilityGraphSnapshot, area: PlotArea) -> [ZeroCrossing] {
        let altitudes = model.objectAltitudes
        guard altitudes.count > 1 else {
            return []
        }
        var result: [ZeroCrossing] = []
        for index in 1..<altitudes.count {
            let previous = altitudes[index - 1]
            let current = altitudes[index]
            if (previous > 0 && current > 0) || (previous < 0 && current < 0) {
                continue
            }
            let delta = current - previous
            if delta == 0 {
                continue
            }
            let t = ((0 - previous) / delta).clamped(to: 0...1)
            let sampleIndex = Double(index - 1) + t
            let fraction = sampleIndex / Double(altitudes.count - 1)
            result.append(ZeroCrossing(x: area.left + area.width * CGFloat(fraction),
                                       type: delta > 0 ? .sunrise : .sunset))
        }
        return result
    }

    private func syncCursorToReference(_ graph: AstroVisibilityGraphSnapshot) {
        guard let area = getPlotArea(),
              let referenceMillis = cursorReferenceTimeMillis else {
            cursorVisible = false
            return
        }
        let cursorMillis = resolveCursorMillis(referenceMillis, graph: graph)
        cursorX = timeToX(cursorMillis, area: area, model: graph)
        cursorVisible = true
    }

    private func resolveCursorMillis(_ referenceMillis: Int64, graph: AstroVisibilityGraphSnapshot) -> Int64 {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = graph.timeZone
        let startDate = date(fromMillis: graph.startMillis)
        let endDate = date(fromMillis: graph.endMillis)
        let referenceDate = date(fromMillis: referenceMillis)
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        let referenceComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: referenceDate)
        components.hour = referenceComponents.hour
        components.minute = referenceComponents.minute
        components.second = referenceComponents.second
        components.nanosecond = referenceComponents.nanosecond
        var candidate = calendar.date(from: components) ?? startDate
        if candidate < startDate,
           let nextDay = calendar.date(byAdding: .day, value: 1, to: candidate) {
            candidate = nextDay
        }
        if candidate > endDate {
            candidate = endDate
        }
        return min(graph.endMillis, max(graph.startMillis, millis(from: candidate)))
    }

    private func updateCursor(_ x: CGFloat, area: PlotArea, notifyCallback: Bool) {
        guard let model else {
            return
        }
        cursorX = x.clamped(to: area.left...area.right)
        cursorVisible = true
        if notifyCallback {
            let fraction = Double(((cursorX - area.left) / area.width).clamped(to: 0...1))
            let reference = model.startMillis + Int64(Double(model.endMillis - model.startMillis) * fraction)
            cursorReferenceTimeMillis = reference
            onCursorTimeChanged?(reference)
        }
        setNeedsDisplay()
    }

    private func yForAltitude(_ altitude: Double, area: PlotArea) -> CGFloat {
        let clamped = altitude.clamped(to: Constants.minAltitudeRender...Constants.maxAltitudeRender)
        let fraction = (clamped - Constants.minAltitudeRender) / (Constants.maxAltitudeRender - Constants.minAltitudeRender)
        return area.bottom - area.height * CGFloat(fraction)
    }

    private func timeToX(_ millis: Int64, area: PlotArea, model: AstroVisibilityGraphSnapshot) -> CGFloat {
        let total = max(1, model.endMillis - model.startMillis)
        let passed = min(total, max(0, millis - model.startMillis))
        return area.left + area.width * CGFloat(Double(passed) / Double(total))
    }

    private func interpolate(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        guard values.count > 1 else {
            return values[0]
        }
        let index = fraction.clamped(to: 0...1) * Double(values.count - 1)
        let start = min(values.count - 1, max(0, Int(floor(index))))
        let end = min(values.count - 1, start + 1)
        let t = index - Double(start)
        return values[start] + (values[end] - values[start]) * t
    }

    private func interpolateAzimuth(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        guard values.count > 1 else {
            return normalizeAzimuth(values[0])
        }
        let index = fraction.clamped(to: 0...1) * Double(values.count - 1)
        let start = min(values.count - 1, max(0, Int(floor(index))))
        let end = min(values.count - 1, start + 1)
        let t = index - Double(start)
        let delta = fmod(values[end] - values[start] + 540.0, 360.0) - 180.0
        return normalizeAzimuth(values[start] + delta * t)
    }

    private func normalizeAzimuth(_ value: Double) -> Double {
        var azimuth = value.truncatingRemainder(dividingBy: 360)
        if azimuth < 0 {
            azimuth += 360
        }
        return azimuth
    }

    private func getPlotArea() -> PlotArea? {
        guard bounds.width > 90, bounds.height > 90 else {
            return nil
        }
        let left = Constants.outerLeftPadding
        let right = bounds.width - Constants.rightAxisOutset - Constants.outerRightPadding
        let top = Constants.outerTopPadding + Constants.markerHeight + Constants.markerToGraphGap
        let bottom = bounds.height - xAxisReservedHeight() - Constants.outerBottomPadding
        guard right > left, bottom > top else {
            return nil
        }
        return PlotArea(left: left, top: top, right: right, bottom: bottom)
    }

    private func xAxisReservedHeight() -> CGFloat {
        Constants.xLabelToGraphGap + UIFont.systemFont(ofSize: Constants.xLabelTextSize).lineHeight
    }

    private func areaContains(_ point: CGPoint, area: PlotArea) -> Bool {
        point.x >= area.left && point.x <= area.right && point.y >= area.top && point.y <= area.bottom
    }

    private func createAxisTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = OAUtilities.is12HourTimeFormat() ? "h a" : "HH:mm"
        return formatter
    }

    private func createMarkerTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = OAUtilities.is12HourTimeFormat() ? "h:mm a" : "HH:mm"
        return formatter
    }

    private func cardinalDirection(for azimuth: Double) -> String {
        let north = localizedString("north_abbreviation")
        let east = localizedString("east_abbreviation")
        let south = localizedString("south_abbreviation")
        let west = localizedString("west_abbreviation")
        let directions = [north, "\(north)\(east)", east, "\(south)\(east)", south, "\(south)\(west)", west, "\(north)\(west)"]
        let index = Int(((normalizeAzimuth(azimuth) + 22.5) / 45.0).rounded(.down)) % directions.count
        return directions[index]
    }

    private func date(fromMillis millis: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0)
    }

    private func millis(from date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    private func setParentScrollEnabled(_ enabled: Bool) {
        if enabled {
            disabledParentScrollView?.isScrollEnabled = true
            disabledParentScrollView = nil
            return
        }
        if disabledParentScrollView == nil {
            var parent = superview
            while let current = parent {
                if let scrollView = current as? UIScrollView {
                    disabledParentScrollView = scrollView
                    break
                }
                parent = current.superview
            }
        }
        disabledParentScrollView?.isScrollEnabled = false
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
