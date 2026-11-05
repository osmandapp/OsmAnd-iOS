// Copyright © 2026 OsmAnd. All rights reserved.

/// Track recording content and state, corresponding to Android's GpxNotification.
@available(iOS 16.2, *)
@MainActor
final class TrackRecordingLiveActivity: BaseLiveActivity {
    private var lastTrackIndex: Int32?

    init() {
        super.init(kind: .recording, relevanceScore: 0.5)
    }

    override func isActive() -> Bool {
        guard let trackHelper = OASavingTrackHelper.sharedInstance() else { return false }
        let isRecordingPluginEnabled = OAPluginsHelper.getEnabledPlugin(OAMonitoringPlugin.self) != nil
        return isRecordingPluginEnabled && (trackHelper.getIsRecording() || (hasActiveSession && trackHelper.hasTrackPoints))
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
                // Detect a new track even when the previous card was dismissed or disabled.
                removeActivity()
            }
            lastTrackIndex = currentTrackIndex
        }
        super.refreshActivity()
    }

    override func buildContent() async -> LiveActivityContent? {
        guard let trackHelper = OASavingTrackHelper.sharedInstance() else { return nil }
        let snapshot: TrackRecordingSnapshot = await withCheckedContinuation { continuation in
            trackHelper.readTrackRecordingSnapshot { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
        guard snapshot.trackIndex == trackHelper.currentTrackIndex else {
            // The track was saved/cleared while the snapshot was returning to the main actor.
            refreshActivity()
            return nil
        }
        let isRecording = trackHelper.getIsRecording()
        guard isRecording || snapshot.hasTrackPoints else { return nil }
        var content = LiveActivityContent()
        content.phase = isRecording ? .active : .paused
        content.title = localizedString(isRecording ? "record_plugin_name" : "shared_string_paused")
        content.distanceText = OAOsmAndFormatter.getFormattedDistance(snapshot.distance) ?? ""
        content.durationText = OAOsmAndFormatter.getFormattedDuration(snapshot.duration) ?? ""
        return content
    }
}
