//
//  Locale+Extension.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 05.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension Locale {
    static let preferredLanguageCodes: [String] = {
        Locale.preferredLanguages.compactMap { identifier in
            if #available(iOS 16, *) {
                return Locale(identifier: identifier).language.languageCode?.identifier
            } else {
                return Locale(identifier: identifier).languageCode
            }
        }
    }()
}
