//
//  MapButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
open class MapButtonState: NSObject {

    let id: String
    
    var allPreferences: [OACommonPreference]
    var iconPref: OACommonString
    var sizePref: OACommonInteger
    var opacityPref: OACommonDouble
    var cornerRadiusPref: OACommonInteger
    var portraitPositionPref: OACommonLong
    var landscapePositionPref: OACommonLong
    //var positionSize: ButtonPositionSize
    //var defaultPositionSize: ButtonPositionSize

    init(withId id: String) {
        self.id = id
        self.allPreferences = []
        
        self.iconPref = OAAppSettings.sharedManager().registerStringPreference(id + "_icon", defValue: nil).makeProfile().cache()
        self.sizePref = OAAppSettings.sharedManager().registerIntPreference(id + "_size", defValue: -1).makeProfile().cache()
        self.opacityPref = OAAppSettings.sharedManager().registerFloatPreference(id + "_opacity", defValue: -1).makeProfile().cache()
        self.cornerRadiusPref = OAAppSettings.sharedManager().registerIntPreference(id + "_corner_radius", defValue: -1).makeProfile().cache()
        self.portraitPositionPref = OAAppSettings.sharedManager().registerLongPreference(id + "_position_portrait", defValue: -1).makeProfile().cache()
        self.landscapePositionPref = OAAppSettings.sharedManager().registerLongPreference(id + "_position_landscape", defValue: -1).makeProfile().cache()
        //this.positionSize = setupButtonPosition(new ButtonPositionSize(getId()));
        //this.defaultPositionSize = setupButtonPosition(new ButtonPositionSize(getId()));
        
        super.init()
        self.addPreference(self.iconPref)
        self.addPreference(self.sizePref)
        self.addPreference(self.opacityPref)
        self.addPreference(self.cornerRadiusPref)
        self.addPreference(self.portraitPositionPref)
        self.addPreference(self.landscapePositionPref)
    }
    
    func addPreference(_ preference: OACommonPreference) -> OACommonPreference {
        allPreferences.append(preference)
        return preference
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
