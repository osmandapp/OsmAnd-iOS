// Copyright © 2026 OsmAnd. All rights reserved.

import Foundation

/// Distances are in meters; durations are in seconds.
/// Immutable values copied on the recording queue; no mutable GPX objects leave that queue.
@objcMembers
final class TrackRecordingSnapshot: NSObject, Codable, Sendable {
    let trackIndex: Int32
    let distance: Float
    let duration: TimeInterval
    let hasRecordedData: Bool

    init(trackIndex: Int32, distance: Float, duration: TimeInterval, hasRecordedData: Bool) {
        self.trackIndex = trackIndex
        self.distance = distance
        self.duration = duration
        self.hasRecordedData = hasRecordedData
        super.init()
    }
}
