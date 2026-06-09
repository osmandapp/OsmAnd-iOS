//
//  GradientEditorState.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum GradientUpdateResult {
    case success(newState: EditorDataState)
    case error(message: String)
}

struct EditorDataState: Equatable {
    let draft: GradientDraft
    let selectedIndex: Int
    let validationError: String?

    init(draft: GradientDraft, selectedIndex: Int, validationError: String? = nil) {
        self.draft = draft
        self.selectedIndex = selectedIndex
        self.validationError = validationError
    }
}

struct GradientDraft: Equatable {
    let originalId: String?
    let fileType: GradientFileType
    let points: [OsmAndShared.GradientPoint]
    let noDataColor: Int32?

    static func == (lhs: GradientDraft, rhs: GradientDraft) -> Bool {
        lhs.originalId == rhs.originalId && lhs.fileType.isEqual(rhs.fileType) && lhs.noDataColor == rhs.noDataColor && lhs.points.elementsEqual(rhs.points) { $0.isEqual($1) }
    }

    func withPoints(_ newPoints: [OsmAndShared.GradientPoint]) -> GradientDraft {
        GradientDraft(originalId: originalId, fileType: fileType, points: newPoints.sorted { $0.value < $1.value }, noDataColor: noDataColor)
    }

    func withPointAdded(_ point: OsmAndShared.GradientPoint) -> GradientDraft {
        GradientDraft(originalId: originalId, fileType: fileType, points: (points + [point]).sorted { $0.value < $1.value }, noDataColor: noDataColor)
    }

    func withPointUpdated(_ oldPoint: OsmAndShared.GradientPoint, _ newPoint: OsmAndShared.GradientPoint) -> GradientDraft {
        GradientDraft(originalId: originalId, fileType: fileType, points: points.map { $0.isEqual(oldPoint) ? newPoint : $0 }.sorted { $0.value < $1.value }, noDataColor: noDataColor)
    }

    func withPointRemoved(_ point: OsmAndShared.GradientPoint) -> GradientDraft {
        var newPoints = points
        if let index = newPoints.firstIndex(where: { $0.isEqual(point) }) {
            newPoints.remove(at: index)
        }

        return GradientDraft(originalId: originalId, fileType: fileType, points: newPoints, noDataColor: noDataColor)
    }
}
