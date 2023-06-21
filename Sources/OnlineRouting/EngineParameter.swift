//
//  EngineParameter.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objc(EOAEngineParameter)
public enum EngineParameter: Int, RawRepresentable {

    case key
    case vehicleKey
    case customName
    case nameIndex
    case customURL
    case approximationRoutingProfile
    case approximationDerivedProfile
    case networkApproximateRoute
    case useExternalTimestamps
    case useRoutingFallback
    case apiKey

    func name() -> String {
        switch self {
            case .key: return "KEY"
            case .vehicleKey: return "VEHICLE_KEY"
            case .customName: return "CUSTOM_NAME"
            case .nameIndex: return "NAME_INDEX"
            case .customURL: return "CUSTOM_URL"
            case .approximationRoutingProfile: return "APPROXIMATION_ROUTING_PROFILE"
            case .approximationDerivedProfile: return "APPROXIMATION_DERIVED_PROFILE"
            case .networkApproximateRoute: return "NETWORK_APPROXIMATE_ROUTE"
            case .useExternalTimestamps: return "USE_EXTERNAL_TIMESTAMPS"
            case .useRoutingFallback: return "USE_ROUTING_FALLBACK"
            case .apiKey: return "API_KEY"
        }
    }

}
