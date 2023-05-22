//
//  CurrentTimeWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACurrentTimeWidget)
@objcMembers
class CurrentTimeWidget: OATextInfoWidget {
    
    var cachedTime: TimeInterval = 0
    
    init() {
        super.init(type: .currentTime)
        setIcons(.currentTime)
        setText(nil, subtext: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        var time = Date.now.timeIntervalSince1970
        if (isUpdateNeeded() || time - cachedTime > TimeInterval(UPDATE_INTERVAL_MILLIS)) {
            cachedTime = time
            setTimeText(time)
            return true
        }
        return false
    }
}
