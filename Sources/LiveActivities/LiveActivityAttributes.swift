// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit

@available(iOS 16.2, *)
struct LiveActivityAttributes: ActivityKit.ActivityAttributes {
    typealias ContentState = LiveActivityContent

    var kind: LiveActivityKind
    var appName: String
}
