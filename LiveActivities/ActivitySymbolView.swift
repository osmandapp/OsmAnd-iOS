// Copyright © 2026 OsmAnd. All rights reserved.

import SwiftUI

struct ActivitySymbolView: View {
    let kind: LiveActivityKind
    let state: LiveActivityContent
    var isDataOutdated = false

    var body: some View {
        Group {
            if state.isLocationUnavailable {
                locationUnavailableSymbolView
            } else if state.phase == .paused {
                pausedSymbolView
            } else if kind == .recording {
                recordingSymbolView
            } else if state.phase == .calculating {
                calculatingSymbolView
            } else {
                maneuverSymbolView
            }
        }
        .foregroundStyle(isDataOutdated && !state.isLocationUnavailable ? Color.secondary : Color.iconColorSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isImage)
        .accessibilityLabel(state.accessibilityTitle(for: kind))
        .accessibilityValue(accessibilityDetails)
    }

    private var accessibilityDetails: String {
        let distance = kind == .navigation ? (state.isLocationUnavailable ? "" : state.turnDistanceText) : state.distanceText
        let distanceDescription = distance.isEmpty ? "" : "\(localizedString("shared_string_distance")): \(distance)"
        return [distanceDescription, state.isLocationUnavailable ? "" : state.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private var locationUnavailableSymbolView: some View {
        Image(systemName: "location.slash").resizable().scaledToFit()
    }

    private var pausedSymbolView: some View {
        Image(systemName: "pause.fill").resizable().scaledToFit()
    }

    private var recordingSymbolView: some View {
        Image(systemName: "record.circle").resizable().scaledToFit()
    }

    private var calculatingSymbolView: some View {
        Image(systemName: "arrow.triangle.turn.up.right.diamond").resizable().scaledToFit()
    }

    private var maneuverSymbolView: some View {
        ActivityTurnView(turnType: state.turnType)
    }
}
