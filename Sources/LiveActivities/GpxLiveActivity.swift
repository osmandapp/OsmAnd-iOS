// Copyright © 2026 OsmAnd. All rights reserved.

/// Track recording content and state, corresponding to Android's GpxNotification.
@available(iOS 16.2, *)
@MainActor
final class GpxLiveActivity: BaseLiveActivity {
    private var lastTrackIndex: Int32?

    init() {
        super.init(kind: .recording, relevanceScore: 0.5)
    }

    override func isActive() -> Bool {
        guard let trackHelper = OASavingTrackHelper.sharedInstance() else { return false }
        let isRecordingPluginEnabled = OAPluginsHelper.getEnabledPlugin(OAMonitoringPlugin.self) != nil
        return isRecordingPluginEnabled && (trackHelper.getIsRecording() || (hasActiveSession && hasRecordedTrackPoints(trackHelper)))
    }

    override func isRunning() -> Bool {
        OASavingTrackHelper.sharedInstance()?.getIsRecording() == true
    }

    override func isEnabled() -> Bool {
        OAAppSettings.sharedManager().recordingLiveActivityEnabled.get()
    }

    override func refreshActivity() {
        if let trackHelper = OASavingTrackHelper.sharedInstance() {
            let currentTrackIndex = trackHelper.currentTrackIndex
            if let lastTrackIndex, lastTrackIndex != currentTrackIndex {
                // Saving/clearing a track ends its activity before another recording starts.
                removeActivity()
            }
            lastTrackIndex = currentTrackIndex
        }
        super.refreshActivity()
    }

    override func buildContent() -> LiveActivityContent? {
        guard let trackHelper = OASavingTrackHelper.sharedInstance() else { return nil }
        let isRecording = trackHelper.getIsRecording()
        var content = LiveActivityContent()
        content.phase = isRecording ? .active : .paused
        content.title = localizedString(isRecording ? "record_plugin_name" : "shared_string_paused")
        content.distanceText = OAOsmAndFormatter.getFormattedDistance(trackHelper.distance) ?? ""
        content.speedText = formattedCurrentSpeed(isPaused: !isRecording)
        content.durationText = OAOsmAndFormatter.getFormattedDuration(recordedDuration(trackHelper)) ?? ""
        return content
    }

    private func hasRecordedTrackPoints(_ trackHelper: OASavingTrackHelper) -> Bool {
        var hasPoints = false
        trackHelper.runSyncBlock {
            hasPoints = trackHelper.currentTrack?.hasTrkPt() == true
        }
        return hasPoints
    }

    private func recordedDuration(_ trackHelper: OASavingTrackHelper) -> TimeInterval {
        var duration: TimeInterval = 0
        trackHelper.runSyncBlock {
            guard let trackFile = trackHelper.currentTrack else { return }
            // Recorded points are chronological. Read only segment endpoints, without analysing every point.
            for case let track as Track in trackFile.tracks where !track.generalTrack {
                for case let segment as TrkSegment in track.segments where !segment.generalSegment {
                    guard let firstPoint = segment.points.firstObject as? WptPt,
                          let lastPoint = segment.points.lastObject as? WptPt,
                          firstPoint.time > 0, lastPoint.time >= firstPoint.time else { continue }
                    // Like Android, exclude pauses between recorded segments.
                    duration += Double(lastPoint.time - firstPoint.time) / 1000
                }
            }
        }
        return duration
    }
}
