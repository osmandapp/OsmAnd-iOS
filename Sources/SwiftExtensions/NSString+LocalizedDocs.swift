//
//  NSString+LocalizedDocs.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 24.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension NSString {
    /// Returns a localized version of the URL if it's part of the osmand.net domain.
    ///
    /// Example:
    /// ```
    /// "https://docs.osmand.net/docs/user/widgets/configure-screen"
    /// → "https://docs.osmand.net/uk/docs/user/widgets/configure-screen"
    /// ```
    ///
    /// - Returns: A localized URL string if applicable, otherwise the original one.
    @objc func localizedURLIfAvailable() -> NSString {
        let urlString = self as String
        
        guard
            var components = URLComponents(string: urlString),
            let host = components.host?.lowercased(),
            host.hasSuffix(kOsmAndHost),
             let languageCode = OsmAndApp.swiftInstance().getLanguageCode()?.lowercased(),
            languageCode != "en"
        else {
            return self
        }
        
        let supportedLanguages = MenuHelpDataService.shared.languages.map { $0.lowercased() }
        guard supportedLanguages.contains(languageCode) else {
            return self
        }
        
        var path = components.path
        
        // Ensure we don't duplicate the language prefix
        if !path.hasPrefix("/\(languageCode)/") {
            path = "/\(languageCode)\(path)"
        }
        
        components.path = path
        return (components.url?.absoluteString ?? urlString) as NSString
    }
}

extension String {
    /// Swift-friendly wrapper that calls the Objective-C implementation under the hood.
    func localizedURLIfAvailable() -> String {
        (self as NSString).localizedURLIfAvailable() as String
    }
}
