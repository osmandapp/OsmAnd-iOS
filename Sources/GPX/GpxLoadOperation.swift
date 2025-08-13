//
//  GpxLoadOperation.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 12.12.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import OsmAndShared

@objcMembers
final class GpxLoadOperation: Operation, @unchecked Sendable {
    var filePath: String
    var completeHandler: ((String, GpxFile) -> Void)?
    var cancelledHandler: ((String) -> Void)?
    
    init(filePath: String) {
        self.filePath = filePath
    }
    
    override func main() {
        guard !checkIfCancelled() else { return }
        let gpxFile = GpxUtilities.shared.loadGpxFile(file: KFile(filePath: filePath))
        if gpxFile != nil {
            guard !checkIfCancelled() else { return }
            DispatchQueue.main.async {
                guard !self.checkIfCancelled() else { return }
                self.completeHandler?(self.filePath, gpxFile)
            }
        } else {
            NSLog("[ERROR] GpxLoadOperation -> gpxFile is nil: \(filePath)")
        }
    }
    
    private func checkIfCancelled() -> Bool {
        guard !isCancelled else {
            DispatchQueue.main.async {
                NSLog("[WARNING] loadGpxFileFile is cancelled: \(self.filePath)")
                self.cancelledHandler?(self.filePath)
            }
            return true
        }
        return false
    }
}
