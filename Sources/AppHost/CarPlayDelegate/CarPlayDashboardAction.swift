//
//  CarPlayDashboardAction.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum CarPlayDashboardAction: String {
    case search
    case navigation
    
    private static let scheme = "osmandmaps://"
    
    var url: URL? {
        return URL(string: "\(Self.scheme)\(self.rawValue)")
    }
    
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let actionKey = components.host ?? components.path.replacingOccurrences(of: "/", with: "")
        
        self.init(rawValue: actionKey.lowercased())
    }
}
