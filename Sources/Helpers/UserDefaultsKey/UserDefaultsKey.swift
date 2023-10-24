//
//  UserDefaultsKey.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

enum UserDefaultsKey: String {
    case deviceSettings
}

extension UserDefaults {
    subscript<T: Codable>(key: UserDefaultsKey) -> T? {
        get {
            return object(T.self, with: key.rawValue)
        }
        set {
            set(object: newValue, forKey: key.rawValue)
        }
    }
}
