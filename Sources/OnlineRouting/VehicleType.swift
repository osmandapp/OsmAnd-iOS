//
//  VehicleType.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAVehicleType)
@objcMembers
public class VehicleType: NSObject {

    private let key: String
    private let titleKey: String

    init(key: String, titleKey: String) {
        self.key = key
        self.titleKey = titleKey
    }

    func getKey() -> String {
        return key
    }

    func getTitle() -> String {
        return localizedString(titleKey)
    }

}
