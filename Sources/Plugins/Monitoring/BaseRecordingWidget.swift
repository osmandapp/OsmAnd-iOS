//
//  BaseRecordingWidget.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

typealias SlopeInfo = ElevationDiffsCalculator.SlopeInfo

@objcMembers
class BaseRecordingWidget: OASimpleWidget {
    private var currentTrackIndex: Int = -1
    private var slopeUphillInfo: SlopeInfo?
    private var slopeDownhillInfo: SlopeInfo?
    
    override init(type: WidgetType) {
        super.init(type: type)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @discardableResult override func updateInfo() -> Bool {
        let newIndex = OASavingTrackHelper.sharedInstance().currentTrackIndex
        if currentTrackIndex != newIndex {
            resetCachedValue()
        }
        
        currentTrackIndex = Int(newIndex)
        if let analysis = getAnalysis() {
            slopeUphillInfo = updateSlopeInfo(oldInfo: slopeUphillInfo, newInfo: analysis.lastUphill)
            slopeDownhillInfo = updateSlopeInfo(oldInfo: slopeDownhillInfo, newInfo: analysis.lastDownhill)
        }
        
        return super.updateInfo()
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
    
    func resetCachedValue() {
        slopeUphillInfo = nil
        slopeDownhillInfo = nil
    }
    
    func getLastSlope(isUphill: Bool) -> SlopeInfo? {
        isUphill ? slopeUphillInfo : slopeDownhillInfo
    }
    
    func getAnalysis() -> GpxTrackAnalysis? {
        guard let currentTrack = OASavingTrackHelper.sharedInstance().currentTrack else { return nil }
        return currentTrack.getAnalysis(fileTimestamp: 0)
    }
    
    private func updateSlopeInfo(oldInfo: SlopeInfo?, newInfo: SlopeInfo?) -> SlopeInfo? {
        guard let oldInfo else { return newInfo }
        guard let newInfo else { return oldInfo }
        let isSameSlope = oldInfo.startPointIndex == newInfo.startPointIndex
        let isNextSlope = oldInfo.startPointIndex < newInfo.startPointIndex
        if isSameSlope {
            oldInfo.elevDiff = max(oldInfo.elevDiff, newInfo.elevDiff)
            oldInfo.distance = max(oldInfo.distance, newInfo.distance)
            oldInfo.maxSpeed = max(oldInfo.maxSpeed, newInfo.maxSpeed)
            return oldInfo
        } else if isNextSlope {
            return newInfo
        } else {
            return oldInfo
        }
    }
    
    private func showTrackOnMap() {
        OARootViewController.instance()?.mapPanel.openTargetView(withGPX: nil)
    }
}
