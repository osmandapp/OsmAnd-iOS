//
//  GradientEditorBehavior.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

protocol GradientEditorBehaviour {
    func isMandatoryPoint(_ point: OsmAndShared.GradientPoint) -> Bool
    func isValueEditable(_ point: OsmAndShared.GradientPoint) -> Bool
    func isRemoveEnabled(_ draft: GradientDraft, selectedIndex: Int) -> Bool
    func stepLabel(for point: OsmAndShared.GradientPoint, fileType: GradientFileType, useFullName: Bool) -> String
    func summary(for point: OsmAndShared.GradientPoint) -> String?
}

final class FixedGradientBehaviour: GradientEditorBehaviour {
    func isMandatoryPoint(_ point: OsmAndShared.GradientPoint) -> Bool {
        false
    }
}

final class RelativeGradientBehaviour: GradientEditorBehaviour {
    func isMandatoryPoint(_ point: OsmAndShared.GradientPoint) -> Bool {
        RelativeConstants.valueOfRatio(point.value) != nil
    }

    func isRemoveEnabled(_ draft: GradientDraft, selectedIndex: Int) -> Bool {
        guard draft.points.indices.contains(selectedIndex) else { return false }
        let point = draft.points[selectedIndex]
        return !isMandatoryPoint(point) && draft.points.count > 2 && selectedIndex != -1
    }

    func stepLabel(for point: OsmAndShared.GradientPoint, fileType: GradientFileType, useFullName: Bool) -> String {
        RelativeConstants.valueOfRatio(point.value)?.name(useFullName: useFullName) ?? GradientFormatter.formatValue(value: point.value, fileType: fileType, showUnits: false)
    }

    func summary(for point: OsmAndShared.GradientPoint) -> String? {
        RelativeConstants.valueOfRatio(point.value)?.summary()
    }
}

final class SymmetricRelativeGradientBehaviour: GradientEditorBehaviour {
    private let mandatoryValues = Set([-100, 0, 100])

    func isMandatoryPoint(_ point: OsmAndShared.GradientPoint) -> Bool {
        let value = Int(floor(Double(point.value * 100) + 0.5))
        return mandatoryValues.contains(value)
    }
}

extension GradientEditorBehaviour {
    func isValueEditable(_ point: OsmAndShared.GradientPoint) -> Bool {
        !isMandatoryPoint(point)
    }

    func isRemoveEnabled(_ draft: GradientDraft, selectedIndex: Int) -> Bool {
        guard draft.points.indices.contains(selectedIndex) else { return false }
        let point = draft.points[selectedIndex]
        return !isMandatoryPoint(point) && draft.points.count > 2 && selectedIndex != -1
    }

    func stepLabel(for point: OsmAndShared.GradientPoint, fileType: GradientFileType) -> String {
        stepLabel(for: point, fileType: fileType, useFullName: false)
    }

    func stepLabel(for point: OsmAndShared.GradientPoint, fileType: GradientFileType, useFullName: Bool) -> String {
        GradientFormatter.formatValue(value: point.value, fileType: fileType, showUnits: false)
    }

    func summary(for point: OsmAndShared.GradientPoint) -> String? {
        nil
    }
}
