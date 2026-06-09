//
//  GradientEditorAlgorithms.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

final class GradientEditorAlgorithms: NSObject {
    
    // Technical tolerance to handle float precision issues (e.g. 50.0 vs 49.9999).
    private static let floatTolerance: Float = 0.005
    private static let defaultStepIncrement: Float = 10
    
    static func addStep(_ currentState: EditorDataState) -> EditorDataState? {
        let draft = currentState.draft
        let selectedIndex = currentState.selectedIndex
        let points = draft.points
        let fileType = draft.fileType
        let minLimit = fileType.minLimit?.floatValue ?? -.infinity
        let maxLimit = fileType.maxLimit?.floatValue ?? .infinity
        guard points.indices.contains(selectedIndex) else { return nil }
        let currentPoint = points[selectedIndex]
        var newValue: Float
        if selectedIndex < points.count - 1 {
            let nextPoint = points[selectedIndex + 1]
            newValue = (currentPoint.value + nextPoint.value) / 2
        } else {
            let prevPoint = selectedIndex > 0 ? points[selectedIndex - 1] : nil
            let step = prevPoint.map { currentPoint.value - $0.value } ?? defaultStepIncrement
            newValue = currentPoint.value + step
        }
        
        if newValue > maxLimit {
            newValue = maxLimit
        }
        
        if newValue < minLimit {
            newValue = minLimit
        }
        
        let isDuplicate = points.contains { abs($0.value - newValue) < floatTolerance }
        guard !isDuplicate else { return nil }
        let baseColor = currentPoint.color
        let newPoint = OsmAndShared.GradientPoint(value: newValue, color: baseColor)
        let newDraft = draft.withPointAdded(newPoint)
        guard let newIndex = newDraft.points.firstIndex(where: { $0.isEqual(newPoint) }) else { return nil }
        return EditorDataState(draft: newDraft, selectedIndex: newIndex)
    }
    
    static func removeStep(_ currentState: EditorDataState, behaviour: GradientEditorBehaviour) -> EditorDataState? {
        let draft = currentState.draft
        let selectedIndex = currentState.selectedIndex
        let points = draft.points
        guard points.indices.contains(selectedIndex), points.count > 2 else { return nil }
        let pointToRemove = points[selectedIndex]
        guard !behaviour.isMandatoryPoint(pointToRemove) else { return nil }
        let newDraft = draft.withPointRemoved(pointToRemove)
        let newIndex = newDraft.points.isEmpty ? -1 : max(0, selectedIndex - 1)
        return EditorDataState(draft: newDraft, selectedIndex: newIndex)
    }
    
    static func updateValue(_ currentState: EditorDataState, text: String, behaviour: GradientEditorBehaviour) -> GradientUpdateResult {
        let draft = currentState.draft
        let selectedIndex = currentState.selectedIndex
        let points = draft.points
        let fileType = draft.fileType
        let context = PlatformUtil.shared.getOsmAndContext()
        let displayUnits = fileType.displayUnitsType.getUnit(mc: context.getMetricSystem(), am: context.getAltitudeMetric(), sc: context.getSpeedSystem(), ac: context.getAngularSystem(), tu: context.getTemperatureUnits())
        guard points.indices.contains(selectedIndex) else { return .error(message: localizedString("unexpected_error_occurred_warn")) }
        let currentPoint = points[selectedIndex]
        guard behaviour.isValueEditable(currentPoint) else { return .success(newState: currentState) }
        guard let inputDisplayValue = Float(text) else { return .error(message: localizedString("gradient_input_invalid_value_warn")) }
        let newValueBase = Float(fileType.baseUnits.from(value: Double(inputDisplayValue), sourceUnit: displayUnits))
        let minLimitBase = fileType.minLimit?.floatValue
        let maxLimitBase = fileType.maxLimit?.floatValue
        if let minLimitBase, newValueBase < minLimitBase {
            let minLimitDisplay = Float(displayUnits.from(value: Double(minLimitBase), sourceUnit: fileType.baseUnits))
            return .error(message: String(format: localizedString("gradient_input_value_too_low_warn"), formatNumber(minLimitDisplay)))
        }
        
        if let maxLimitBase, newValueBase > maxLimitBase {
            let maxLimitDisplay = Float(displayUnits.from(value: Double(maxLimitBase), sourceUnit: fileType.baseUnits))
            return .error(message: String(format: localizedString("gradient_input_value_too_high_warn"), formatNumber(maxLimitDisplay)))
        }
        
        let isDuplicate = points.contains { $0 !== currentPoint && abs($0.value - newValueBase) < floatTolerance }
        if isDuplicate {
            return .error(message: localizedString("gradient_input_value_duplicate_warn"))
        }
        
        guard abs(currentPoint.value - newValueBase) >= floatTolerance else { return .success(newState: currentState) }
        let newPoint = currentPoint.doCopy(value: newValueBase, color: currentPoint.color)
        let newDraft = draft.withPointUpdated(currentPoint, newPoint)
        let newIndex = newDraft.points.firstIndex(where: { $0.value == newPoint.value && $0.color == newPoint.color }) ?? -1
        return .success(newState: EditorDataState(draft: newDraft, selectedIndex: newIndex))
    }
    
    static func updateColor(_ currentState: EditorDataState, newColor: Int32) -> EditorDataState? {
        let draft = currentState.draft
        let selectedIndex = currentState.selectedIndex
        let points = draft.points
        if selectedIndex == points.count {
            let currentColor = draft.noDataColor ?? OsmAndShared.ColorPalette.companion.LIGHT_GREY
            guard currentColor != newColor else { return nil }
            let newDraft = GradientDraft(originalId: draft.originalId, fileType: draft.fileType, points: draft.points, noDataColor: newColor)
            return EditorDataState(draft: newDraft, selectedIndex: selectedIndex, validationError: currentState.validationError)
        }
        
        guard points.indices.contains(selectedIndex) else { return nil }
        let currentPoint = points[selectedIndex]
        guard currentPoint.color != newColor else { return nil }
        let newPoint = currentPoint.doCopy(value: currentPoint.value, color: newColor)
        let newDraft = draft.withPointUpdated(currentPoint, newPoint)
        return EditorDataState(draft: newDraft, selectedIndex: selectedIndex)
    }
    
    private static func formatNumber(_ value: Float) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}
