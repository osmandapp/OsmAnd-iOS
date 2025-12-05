//
//  TripRecordingTimeWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 27.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TripRecordingTimeWidget: OASimpleWidget {
    private let savingTrackHelper = OASavingTrackHelper.sharedInstance()
    
    private var cachedTimeSpan: Int64 = -1
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: [String: Any]? = nil) {
        super.init(type: .tripRecordingTime)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
        onClickFunction = { [weak self] _ in
            guard let self, self.cachedTimeSpan > 0, let gpxFile = self.savingTrackHelper?.currentTrack else { return }
            let trackItem = TrackItem(gpxFile: gpxFile)
            OARootViewController.instance().mapPanel.openTargetView(withGPX: trackItem, selectedTab:  .segmentsTab, selectedStatisticsTab: .overviewTab, openedFromMap: true)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult override func updateInfo() -> Bool {
        setIcon("widget_track_recording_duration")
        let timeSpan = getTimeSpan()
        if cachedTimeSpan != timeSpan {
            cachedTimeSpan = timeSpan
            let formattedTime = OAOsmAndFormatter.getFormattedDurationShort(Double(timeSpan) / 1000, fullForm: false)
            setText(formattedTime, subtext: nil)
        }
        
        return true
    }
    
    override func configureContextMenu(addGroup: UIMenu, settingsGroup: UIMenu, deleteGroup: UIMenu) -> UIMenu {
        var updatedSettingsGroup = settingsGroup
        let resetAction = UIAction(title: localizedString("show_track_on_map"), image: .icCustomCenterOnTrack) { [weak self] _ in
            guard let self else { return }
            self.showTrackOnMap()
        }
        
        updatedSettingsGroup = settingsGroup.replacingChildren([resetAction] + settingsGroup.children)
        return UIMenu(title: "", children: [addGroup, updatedSettingsGroup, deleteGroup])
    }
    
    private func getTimeSpan() -> Int64 {
        guard let currentTrack = OASavingTrackHelper.sharedInstance().currentTrack else { return 0 }
        let joinSegments = OAAppSettings.sharedManager().currentTrackIsJoinSegments.get()
        let tracks = (currentTrack.tracks as? [Track]) ?? []
        let firstIsGeneral = tracks.first?.generalTrack ?? false
        let withoutGaps = !joinSegments && (tracks.isEmpty || firstIsGeneral)
        let analysis = currentTrack.getAnalysis(fileTimestamp: 0)
        return withoutGaps ? analysis.timeSpanWithoutGaps : analysis.timeSpan
    }
    
    private func showTrackOnMap() {
        OARootViewController.instance()?.mapPanel.openTargetView(withGPX: nil)
    }
}
