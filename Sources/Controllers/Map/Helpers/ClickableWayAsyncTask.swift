//
//  ClickableWayAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/track/clickable/ClickableWayAsyncTask.java
// git revision a9b2a06728af2430efcc0bcf90b0c3568d239da1

import Foundation

@objcMembers
class ClickableWayAsyncTask: OABaseLoadAsyncTask {
    
    private var clickableWay: ClickableWay
    
    init(clickableWay: ClickableWay) {
        self.clickableWay = clickableWay
        super.init()
    }
    
    override func doInBackground() -> Any? {
        let result = ClickableWayHelper.readHeightData(clickableWay, canceller: self)
        return result ? clickableWay : nil
    }
    
    override func onPostExecute(result: Any?) {
        ClickableWayHelper.openAsGpxFile(result as? ClickableWay)
        super.onPostExecute(result: result)
    }
}
