//
//  OsmUserDataModel.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

struct OsmUserDataModel: Codable {
    var user: OsmUserDataUserModel
}

struct OsmUserDataUserModel: Codable {
    var id: Int
    var display_name: String
    var img: OsmUserDataUserImageModel?
}

struct OsmUserDataUserImageModel: Codable {
    var href: String
}
