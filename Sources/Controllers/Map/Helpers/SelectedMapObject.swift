//
//  SelectedMapObject.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
class SelectedMapObject: NSObject {
    
    private var object: Any
    private var provider: OAContextMenuProvider?
    
    init(mapObject: Any, provider: OAContextMenuProvider?) {
        self.object = mapObject
        self.provider = provider
        super.init()
    }
    
    func getObject() -> Any {
        object
    }
    
    func getProvider() -> OAContextMenuProvider? {
        provider
    }
} 
