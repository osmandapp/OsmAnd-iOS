//
//  SelectedMapObject.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class SelectedMapObject: NSObject {
    var object: Any
    private(set) var provider: OAContextMenuProvider?
    // Hit location on geometry such as a track, which has no single object coordinate.
    var selectionLocation: CLLocation?
    
    init(mapObject: Any, provider: OAContextMenuProvider?) {
        self.object = mapObject
        self.provider = provider
        super.init()
    }
} 
