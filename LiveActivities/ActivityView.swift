// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared
import SwiftUI

struct ActivityView: View {
    private enum Constants {
        static let contentSpacing: CGFloat = 6
        static let contentPadding: CGFloat = 10
        static let dynamicIslandPadding: CGFloat = 0
        static let dynamicIslandMetricsHorizontalPadding: CGFloat = 16
        static let detailsItemSpacing: CGFloat = 12
        static let detailsSpacerMinLength: CGFloat = 0
        static let descriptionTextSpacing: CGFloat = 2
        static let metricLabelSpacing: CGFloat = 2
        static let metricsSpacerMinLength: CGFloat = 8
        static let symbolSize: CGFloat = 42
        static let progressBarHeight: CGFloat = 4
        static let progressBarBackgroundOpacity = 0.12
        static let progressPercentageDecimalPlaces = 0
        static let singleLineLimit = 1
        static let metricValueMinimumScaleFactor: CGFloat = 0.7
    }

    let attributes: LiveActivityAttributes
    let state: LiveActivityContent
    var isDynamicIsland = false

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            if !isDynamicIsland {
                headerView
            }
            activityDetailsView
            if let progress = state.progress {
                routeProgressView(progress)
            }
            tripMetricsView
                .padding(.horizontal, isDynamicIsland ? Constants.dynamicIslandMetricsHorizontalPadding : Constants.dynamicIslandPadding)
        }
        .padding(isDynamicIsland ? Constants.dynamicIslandPadding : Constants.contentPadding)
        .foregroundStyle(.primary)
        .accessibilityElement(children: .contain)
    }

    private var accessibilityDetails: String {
        let distance = attributes.kind == .navigation && state.phase != .paused ? state.turnDistanceText : ""
        let distanceDescription = distance.isEmpty ? "" : "\(localizedString("shared_string_distance")): \(distance)"
        return [distanceDescription, state.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private var appNameView: some View {
        Text(attributes.appName)
            .font(.subheadline.bold())
            .foregroundStyle(Color.iconColorSelected)
    }

    private var activityDetailsView: some View {
        HStack(spacing: Constants.detailsItemSpacing) {
            if !isDynamicIsland {
                activitySymbolView
            }
            activityDescriptionView
            Spacer(minLength: Constants.detailsSpacerMinLength)
            if attributes.kind == .recording, !state.speedText.isEmpty {
                recordingSpeedView
            }
        }
    }

    private var activityDescriptionView: some View {
        VStack(alignment: .leading, spacing: Constants.descriptionTextSpacing) {
            if attributes.kind == .navigation, !state.turnDistanceText.isEmpty, !isDynamicIsland, state.phase != .paused {
                turnDistanceView
            }
            activityTitleView
            if !state.subtitle.isEmpty {
                activitySubtitleView
            }
        }
        .accessibilityElement(children: .ignore)
        // The symbol reads the maneuver or status; the text adds distance and street details.
        .accessibilityLabel(accessibilityDetails)
        .accessibilityHidden(accessibilityDetails.isEmpty)
    }

    private var activityTitleView: some View {
        Text(state.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(Constants.singleLineLimit)
    }

    private var tripMetricsView: some View {
        HStack(alignment: .firstTextBaseline) {
            distanceView
            Spacer(minLength: Constants.metricsSpacerMinLength)
            durationView
            if let arrivalTime = state.arrivalTime {
                Spacer(minLength: Constants.metricsSpacerMinLength)
                arrivalTimeView(arrivalTime)
            }
        }
    }

    private var distanceView: some View {
        metricView(state.distanceText, label: localizedString("shared_string_distance"))
            .accessibilityLabel(localizedString(attributes.kind == .navigation ? "map_widget_distance_to_destination" : "shared_string_distance"))
    }

    private var durationView: some View {
        metricView(state.durationText, label: localizedString("shared_string_time"))
            .accessibilityLabel(localizedString(attributes.kind == .navigation ? "map_widget_time_to_destination" : "map_widget_trip_recording_duration"))
    }

    private var headerView: some View {
        HStack {
            appNameView
            Spacer()
            if attributes.kind == .navigation {
                navigationSummaryView
            }
        }
    }

    private var navigationSummaryView: some View {
        Text(!state.speedText.isEmpty ? state.speedText : localizedString("shared_string_navigation"))
            .font(.caption).foregroundStyle(.secondary).lineLimit(Constants.singleLineLimit)
            .accessibilityLabel(localizedString("shared_string_speed"))
            .accessibilityValue(state.speedText)
            .accessibilityHidden(state.speedText.isEmpty)
    }

    private var activitySymbolView: some View {
        ActivitySymbolView(kind: attributes.kind, state: state)
            .frame(width: Constants.symbolSize, height: Constants.symbolSize)
            // The adjacent description and metrics already include these details.
            .accessibilityValue("")
    }

    private var turnDistanceView: some View {
        Text(state.turnDistanceText).font(.title3.bold()).monospacedDigit()
    }

    private var activitySubtitleView: some View {
        Text(state.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(Constants.singleLineLimit)
    }

    private var recordingSpeedView: some View {
        metricView(state.speedText, label: localizedString("shared_string_speed"), isProminent: true)
    }

    private func routeProgressView(_ progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(Constants.progressBarBackgroundOpacity))
                Capsule().fill(Color.iconColorSelected).frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: Constants.progressBarHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localizedString("shared_string_progress"))
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(Constants.progressPercentageDecimalPlaces))))
    }

    private func arrivalTimeView(_ arrivalTime: Date) -> some View {
        VStack(alignment: .leading, spacing: Constants.metricLabelSpacing) {
            Text(arrivalTime, style: .time)
                .font(.subheadline.bold()).monospacedDigit()
                .lineLimit(Constants.singleLineLimit).minimumScaleFactor(Constants.metricValueMinimumScaleFactor)
            Text(localizedString("access_arrival_time")).font(.caption2).foregroundStyle(.secondary).lineLimit(Constants.singleLineLimit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localizedString("access_arrival_time"))
        .accessibilityValue(Text(arrivalTime, style: .time))
    }

    private func metricView(_ value: String, label: String, isProminent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Constants.metricLabelSpacing) {
            Text(value.isEmpty ? "—" : value)
                .font(isProminent ? .title2.bold() : .subheadline.bold())
                .monospacedDigit().lineLimit(Constants.singleLineLimit).minimumScaleFactor(Constants.metricValueMinimumScaleFactor)
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(Constants.singleLineLimit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityHidden(value.isEmpty)
    }
}

private struct ActivityView_Previews: PreviewProvider {
    private enum Constants {
        static let previewWidth: CGFloat = 360
        static let timeUntilArrival: TimeInterval = 1080
        static let routeProgress = 0.35
    }

    static var previews: some View {
        Group {
            navigationPreview
            recordingPreview
        }
        .frame(width: Constants.previewWidth)
        .background(Color.groupBg)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
    }

    private static var navigationPreview: some View {
        ActivityView(attributes: attributes(.navigation), state: navigation)
            .previewDisplayName("Navigation")
    }

    private static var recordingPreview: some View {
        ActivityView(attributes: attributes(.recording), state: recording)
            .previewDisplayName("Trip recording")
    }

    private static func attributes(_ kind: LiveActivityKind) -> LiveActivityAttributes {
        LiveActivityAttributes(kind: kind, appName: "OsmAnd Maps")
    }

    private static var navigation: LiveActivityContent {
        var state = LiveActivityContent()
        state.title = "Turn right"
        state.subtitle = "Shevchenko Boulevard"
        state.turnType = TurnType.companion.valueOf(value: TurnType.companion.TR, leftSide: false)
        state.turnDistanceText = "250 m"
        state.distanceText = "12.4 km"
        state.durationText = "18 min"
        state.arrivalTime = Date().addingTimeInterval(Constants.timeUntilArrival)
        state.speedText = "42 km/h"
        state.progress = Constants.routeProgress
        return state
    }

    private static var recording: LiveActivityContent {
        var state = LiveActivityContent()
        state.title = "Trip recording"
        state.distanceText = "8.6 km"
        state.durationText = "32 min"
        state.speedText = "23.8 km/h"
        return state
    }
}
