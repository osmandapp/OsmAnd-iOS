//
//  GlideAverageWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 04.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideAverageWidget)
@objcMembers
final class GlideAverageWidget: GlideBaseWidget {

    private static let measuredIntervalPrefID = "average_glide_measured_interval_millis"
    private let averageGlideComputer = AverageGlideComputer.shared
    private var measuredIntervalPref: OACommonLong
    private var cachedFormattedGlideRatio: String?

    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        measuredIntervalPref = Self.registerMeasuredIntervalPref(customId)
        super.init(WidgetType.glideAverage, customId: customId, appMode: appMode, widgetParams: widgetParams)
        updateInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getMeasuredInterval(_ appMode: OAApplicationMode) -> Int {
        return measuredIntervalPref.get(appMode)
    }

    func setMeasuredInterval(_ appMode: OAApplicationMode, measuredInterval: Int) {
        measuredIntervalPref.set(measuredInterval, mode: appMode)
    }

    override func updateInfo() -> Bool {
        if isTimeToUpdate() {
            let measuredInterval: Int = measuredIntervalPref.get()
            let ratio: String? = averageGlideComputer.getFormattedAverageGlideRatio(measuredInterval)
            if ratio != cachedFormattedGlideRatio {
                cachedFormattedGlideRatio = ratio
                if let ratio, !ratio.isEmpty {
                    setText(ratio, subtext: "")
                } else {
                    setText("-", subtext: "")
                }
            }
        }
        return true
    }

    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerMeasuredIntervalPref(customId).set(measuredIntervalPref.get(appMode), mode: appMode)
    }

    private static func registerMeasuredIntervalPref(_ customId: String?) -> OACommonLong {
        var prefId: String
        if let customId, !customId.isEmpty {
            prefId = Self.measuredIntervalPrefID + customId
        } else {
            prefId = Self.measuredIntervalPrefID
        }
        return OAAppSettings.sharedManager().registerLongPreference(prefId, defValue: Int(AverageValueComputer.defaultIntervalMillis))
    }
}
