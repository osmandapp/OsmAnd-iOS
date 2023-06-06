//
//  OsmAccessTokenModel.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

struct OsmAccessTokenModel: Codable {
    var access_token: String?
    var token_type: String?
    var scopesuccess: String?
    var created_at: Int?
}
