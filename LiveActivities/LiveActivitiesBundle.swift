// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct LiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
    }
}

struct LiveActivityWidget: Widget {
    private enum Constants {
        static let expandedSymbolSize: CGFloat = 36
        static let compactSymbolSize: CGFloat = 22
        static let compactDistanceMaxWidth: CGFloat = 64
        static let expandedDistanceMinimumScaleFactor: CGFloat = 0.7
        static let compactDistanceMinimumScaleFactor: CGFloat = 0.6
        static let distanceLineLimit = 1
    }

    var body: some WidgetConfiguration {
        activityConfiguration
    }

    private var activityConfiguration: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            lockScreenView(context)
        } dynamicIsland: { context in
            dynamicIsland(context)
        }
    }

    private var lockScreenBackgroundColor: Color {
        // Keep the tint dark even when the Lock Screen initially provides a light appearance.
        Color(uiColor: UIColor.groupBg.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    }

    private func lockScreenView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        ActivityView(attributes: context.attributes, state: context.state, isDataOutdated: context.isStale)
            .background(lockScreenBackgroundColor)
            .activityBackgroundTint(lockScreenBackgroundColor)
            .activitySystemActionForegroundColor(.white)
            .environment(\.colorScheme, .dark)
    }

    private func dynamicIsland(_ context: ActivityViewContext<LiveActivityAttributes>) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                expandedLeadingView(context)
            }
            DynamicIslandExpandedRegion(.trailing) {
                expandedTrailingView(context)
            }
            DynamicIslandExpandedRegion(.bottom) {
                expandedBottomView(context)
            }
        } compactLeading: {
            compactLeadingView(context)
        } compactTrailing: {
            compactTrailingView(context)
        } minimal: {
            minimalView(context)
        }
        .keylineTint(Color.iconColorSelected)
    }

    private func expandedLeadingView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        activitySymbolView(context).frame(width: Constants.expandedSymbolSize, height: Constants.expandedSymbolSize)
            // The bottom region reads distance and street details separately.
            .accessibilityValue("")
    }

    private func expandedTrailingView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        Text(displayedDistanceText(context))
            .font(.title3.bold()).monospacedDigit()
            .lineLimit(Constants.distanceLineLimit).minimumScaleFactor(Constants.expandedDistanceMinimumScaleFactor)
            // The bottom region reads the distance with the street details.
            .accessibilityHidden(true)
    }

    private func expandedBottomView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        ActivityView(attributes: context.attributes, state: context.state, isDynamicIsland: true, isDataOutdated: context.isStale)
    }

    private func compactLeadingView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        activitySymbolView(context).frame(width: Constants.compactSymbolSize, height: Constants.compactSymbolSize)
    }

    private func compactTrailingView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        Text(displayedDistanceText(context))
            .font(.caption.bold()).monospacedDigit()
            .lineLimit(Constants.distanceLineLimit).minimumScaleFactor(Constants.compactDistanceMinimumScaleFactor)
            .frame(maxWidth: Constants.compactDistanceMaxWidth)
            // The leading symbol includes this distance in its VoiceOver description.
            .accessibilityHidden(true)
    }

    private func minimalView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        activitySymbolView(context).frame(width: Constants.compactSymbolSize, height: Constants.compactSymbolSize)
    }

    private func activitySymbolView(_ context: ActivityViewContext<LiveActivityAttributes>) -> some View {
        ActivitySymbolView(kind: context.attributes.kind, state: context.state, isDataOutdated: context.isStale)
    }

    private func displayedDistanceText(_ context: ActivityViewContext<LiveActivityAttributes>) -> String {
        if context.attributes.kind == .navigation {
            return context.state.isLocationUnavailable ? "" : context.state.turnDistanceText
        }
        return context.state.distanceText
    }
}

private struct LiveActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            navigationPreview(ActivityView_Previews.navigation).previewDisplayName("Expanded · navigation")
            navigationPreview(ActivityView_Previews.pausedNavigation).previewDisplayName("Expanded · paused")
            navigationPreview(ActivityView_Previews.calculating).previewDisplayName("Expanded · calculating")
            navigationPreview(ActivityView_Previews.calculationError).previewDisplayName("Expanded · error")
            navigationPreview(ActivityView_Previews.navigation, isDataOutdated: true).previewDisplayName("Expanded · stale")
            navigationPreview(ActivityView_Previews.locationUnavailable, isDataOutdated: true).previewDisplayName("Expanded · location unavailable")
            navigationPreview(ActivityView_Previews.longStreetName).previewDisplayName("Expanded · long text")
            navigationPreview(ActivityView_Previews.navigation).previewDisplayName("Expanded · large text")
                .dynamicTypeSize(.accessibility3)
            navigationPreview(ActivityView_Previews.rtlNavigation).previewDisplayName("Expanded · RTL")
                .environment(\.layoutDirection, .rightToLeft)
            ActivityView_Previews.attributes(.recording)
                .previewContext(ActivityView_Previews.recording, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Expanded · recording")
            ActivityView_Previews.attributes(.recording)
                .previewContext(ActivityView_Previews.pausedRecording, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Expanded · recording paused")
            ActivityView_Previews.attributes(.navigation)
                .previewContext(ActivityView_Previews.navigation, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Compact")
            ActivityView_Previews.attributes(.navigation)
                .previewContext(ActivityView_Previews.navigation, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Minimal")
        }
    }

    private static func navigationPreview(_ state: LiveActivityContent, isDataOutdated: Bool = false) -> some View {
        ActivityView_Previews.attributes(.navigation)
            .previewContext(state, isStale: isDataOutdated, viewKind: .dynamicIsland(.expanded))
    }
}
