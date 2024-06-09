//
//  MapButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapButtonState)
@objcMembers
open class MapButtonState: NSObject {

    let id: String

    init(withId id: String) {
        self.id = id
    }

    func getName() -> String {
        fatalError("button state has no name")
    }

    func isEnabled() -> Bool {
        true
    }

    func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_quick_action")
    }
}
