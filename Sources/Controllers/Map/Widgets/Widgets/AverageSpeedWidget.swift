//
//  AverageSpeedWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 18.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAAverageSpeedWidget)
@objcMembers
class AverageSpeedWidget: OATextInfoWidget {
    
    private static let MEASURED_INTERVAL_PREF_ID = "average_speed_measured_interval_millis"
    private static let SKIP_STOPS_PREF_ID = "average_speed_skip_stops"
    
    private static let UPDATE_INTERVAL_MILLIS = 1000
    private static let DASH = "—"
    
    private let averageSpeedComputer = OAAverageSpeedComputer.sharedInstance()
    
    private let measuredIntervalPref: OACommonLong
    private let skipStopsPref: OACommonBoolean
    
    private var lastUpdateTime = 0
    
    init(customId: String) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        skipStopsPref = Self.registerSkipStopsPref(customId)
        super.init(type: .averageSpeed)
        setIcons(.averageSpeed)
        self.setMetricSystemDepended(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getMeasuredInterval(_ appMode: OAApplicationMode) -> Int {
        measuredIntervalPref.get(appMode)
    }
    
    func setMeasuredInterval(_ appMode: OAApplicationMode, measuredInterval: Int) {
        measuredIntervalPref.set(measuredInterval, mode: appMode)
    }
    
    func shouldSkipStops(_ appMode: OAApplicationMode) -> Bool {
        return skipStopsPref.get(appMode)
    }
    
    func setShouldSkipStops(_ appMode: OAApplicationMode, skipStops: Bool) {
        skipStopsPref.set(skipStops, mode: appMode)
    }
    
    override func updateInfo() -> Bool {
        let time = Int(Date.now.timeIntervalSince1970 * 1000)
        if (isUpdateNeeded() || time - lastUpdateTime > Self.UPDATE_INTERVAL_MILLIS) {
            lastUpdateTime = time
            updateAverageSpeed()
            return true
        }
        return false
    }
    
    func updateAverageSpeed() {
        let measuredInterval = measuredIntervalPref.get()
        let skipLowSpeed = skipStopsPref.get()
        let averageSpeed = averageSpeedComputer.getAverageSpeed(measuredInterval, skipLowSpeed: skipLowSpeed)
        if (averageSpeed.isNaN) {
            setText(Self.DASH, subtext: nil)
        } else {
            let formattedAverageSpeed = OAOsmAndFormatter.getFormattedSpeed(averageSpeed).components(separatedBy: " ")
            setText(formattedAverageSpeed.first, subtext: formattedAverageSpeed.count > 1 ? formattedAverageSpeed.last : nil)
        }
    }
    
    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerMeasuredIntervalPref(customId).set(measuredIntervalPref.get(appMode), mode: appMode)
        Self.registerSkipStopsPref(customId).set(skipStopsPref.get(appMode), mode: appMode)
    }
    
    static func registerMeasuredIntervalPref(_ customId: String?) -> OACommonLong {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty
        ? Self.MEASURED_INTERVAL_PREF_ID
        : Self.MEASURED_INTERVAL_PREF_ID + customId!
        return settings.registerLongPreference(prefId, defValue: OAAverageSpeedComputer.default_INTERVAL_MILLIS())
    }
    
    static func registerSkipStopsPref(_ customId: String?) -> OACommonBoolean {
        let settings = OAAppSettings.sharedManager()!
        let prefId = customId == nil || customId!.isEmpty ? Self.SKIP_STOPS_PREF_ID : Self.SKIP_STOPS_PREF_ID + customId!
        return settings.registerBooleanPreference(prefId, defValue: true)
    }
}
