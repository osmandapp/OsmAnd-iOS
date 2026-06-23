//
//  AstroContextUiState.swift
//  OsmAnd Maps
//
//  Ported from Android AstroContextUiState.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

struct AstroContextUiState {
    var selectedObjectId: String?
    var currentLocalDate: Date?
    var selectedVisibilityDateOverride: Date?
    var visibilityCursorReferenceTimeMillis: Int64?
    var schedulePeriodStart: Date?
    var catalogsExpanded: Bool
    var galleryState: AstroGalleryState

    init(selectedObjectId: String? = nil,
         currentLocalDate: Date? = nil,
         selectedVisibilityDateOverride: Date? = nil,
         visibilityCursorReferenceTimeMillis: Int64? = nil,
         schedulePeriodStart: Date? = nil,
         catalogsExpanded: Bool = false,
         galleryState: AstroGalleryState = .collapsed) {
        self.selectedObjectId = selectedObjectId
        self.currentLocalDate = currentLocalDate
        self.selectedVisibilityDateOverride = selectedVisibilityDateOverride
        self.visibilityCursorReferenceTimeMillis = visibilityCursorReferenceTimeMillis
        self.schedulePeriodStart = schedulePeriodStart
        self.catalogsExpanded = catalogsExpanded
        self.galleryState = galleryState
    }
}

