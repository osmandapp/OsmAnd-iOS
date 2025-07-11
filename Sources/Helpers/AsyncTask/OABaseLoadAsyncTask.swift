//
//  OABaseLoadAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class OABaseLoadAsyncTask: OAAsyncTask {
    
    var shouldShowProgress: Bool = true
    
    override init() {
        super.init()
        shouldShowProgress = true
    }
    
    // override
    override func onPreExecute() {
        if shouldShowProgress {
            OARootViewController.instance().view.addSpinner(inCenterOfCurrentView: true)
        }
        super.onPreExecute()
    }
    
    // override
    override func onPostExecute(result: Any?) {
        if shouldShowProgress {
            OARootViewController.instance().view.removeSpinner()
        }
        super.onPostExecute(result: result)
    }
} 
