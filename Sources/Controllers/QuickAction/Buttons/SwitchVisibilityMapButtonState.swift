//
//  SwitchVisibilityMapButtonState.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 07.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

class SwitchVisibilityMapButtonState: MapButtonState {
    override func copyForMode(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) {
        super.copyForMode(from: fromMode, to: toMode)
        storedVisibilityPref().set(storedVisibilityPref().get(fromMode), mode: toMode)
    }
    
    override func storedVisibilityPref() -> OACommonBoolean {
        fatalError("visibilityPref is not defined")
    }
}
