//
//  OAAsyncTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class OAAsyncTask: NSObject, OACancellable {
    
    var cancelled: Bool = false
    
    func execute() {
        onPreExecute()
        DispatchQueue.global(qos: .default).async {
            let result = self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute(result: result)
            }
        }
    }
    
    func onPreExecute() {
        // override
    }
    
    func doInBackground() -> Any? {
        // override
        return nil
    }
    
    func onPostExecute(result: Any?) {
        // override
    }
    
    func isCancelled() -> Bool {
        cancelled
    }
}
