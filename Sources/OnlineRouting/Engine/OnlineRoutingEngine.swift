//
//  OnlineRoutingEngine.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAOnlineRoutingEngine)
@objcMembers
class OnlineRoutingEngine: NSObject, NSCopying {

    static let onlineRoutingEnginePrefix: String = "online_routing_engine_"
    static let predefinedPrefix: String = onlineRoutingEnginePrefix + "predefined_"

    static let customVehicle: VehicleType = VehicleType(key: "", titleKey: localizedString("shared_string_custom"))
    static let noneVehicle: VehicleType = VehicleType(key: "None", titleKey: localizedString("shared_string_none"))

    private var params: [String: String] = [:]
    private var allowedVehicles: [VehicleType] = []
    private var allowedParameters: Set<EngineParameter> = []

    init(params: [String: String]?) {
        super.init()
        // Params represents the entire state of an engine object.
        // An engine object with nil params used only to provide information about the engine type
        if params != nil && !params!.isEmpty {
            self.params = self.params.merging(params!) { $1 }
        }
        collectAllowedVehicles()
        collectAllowedParameters()
    }

    func getType() -> OnlineRoutingEngine {
        fatalError("Subclasses must override getType()")
    }

    func getTitle() -> String {
        fatalError("Subclasses must override getTitle()")
    }

    func getTypeName() -> String {
        fatalError("Subclasses must override getTypeName()")
    }

    func getStringKey() -> String? {
        return get(key: EngineParameter.key)
    }

    /**
    * Only used when creating a full API url
    * @return a string that represents the type of vehicle, or an empty string
    * if the vehicle type not provided
    */
    func getVehicleKeyForUrl() -> String {
        guard let key = get(key: EngineParameter.vehicleKey), key != OnlineRoutingEngine.noneVehicle.getKey() else {
            return ""
        }
        return key
    }

    func getName() -> String {
        let name: String = get(key: EngineParameter.customName) ?? getStandardName()
        let index: String? = get(key: EngineParameter.nameIndex)
        return index != nil && index!.length > 0 ? (name + " " + index!) : name
    }

    func getStandardName() -> String {
        let vehicleTitle: String? = getSelectedVehicleName()
        if vehicleTitle == nil || vehicleTitle!.isEmpty {
            return getType().getTitle()
        } else {
            let pattern = localizedString("ltr_or_rtl_combine_via_dash")
            return String(format: pattern, getType().getTitle(), vehicleTitle!)
        }
    }

    func shouldApproximateRoute() -> Bool {
        let value: String? = get(key: EngineParameter.approximationRoutingProfile)
        return (value != nil && value!.length > 0) || shouldNetworkApproximateRoute()
    }

    func shouldNetworkApproximateRoute() -> Bool {
        let value: String? = get(key: EngineParameter.networkApproximateRoute)
        if value != nil && value!.length > 0 {
            return Bool(value!) ?? false
        }
        return false
    }

    func getApproximationRoutingProfile() -> String? {
        let routingProfile: String? = get(key: EngineParameter.approximationRoutingProfile)
        return routingProfile != nil && routingProfile!.length > 0 ? routingProfile : nil
    }

    func getApproximationDerivedProfile() -> String? {
        let derivedProfile: String? = get(key: EngineParameter.approximationDerivedProfile)
        return derivedProfile != nil && derivedProfile!.length > 0 ? derivedProfile : nil
    }

    func useExternalTimestamps() -> Bool {
        let value: String? = get(key: EngineParameter.useExternalTimestamps)
        return value != nil && value!.length > 0 && Bool(value!) ?? false
    }

    func useRoutingFallback() -> Bool {
        let value: String? = get(key: EngineParameter.useRoutingFallback)
        return value != nil && value!.length > 0 && Bool(value!) ?? false
    }

    func getFullUrl(path: [[NSNumber]], startBearing: Float?) -> String {
        let sb: String = getBaseUrl()
        makeFullUrl(sb: sb, path: path, startBearing: startBearing)
        return sb
    }

    fileprivate func makeFullUrl(sb: String, path: [[NSNumber]], startBearing: Float?) {
        fatalError("Subclasses must override makeFullUrl(sb:path:startBearing:)")
    }

    func getBaseUrl() -> String {
        let customUrl: String? = get(key: EngineParameter.customURL)
        if customUrl == nil || customUrl?.length == 0 {
            return getStandardUrl()
        }
        return customUrl!
    }

    func getStandardUrl() -> String {
        fatalError("Subclasses must override getStandardUrl()")
    }

    func getHTTPMethod() -> String {
        return "GET"
    }

    func getRequestHeaders() -> [String: String]? {
        return nil
    }

    func getRequestBody(path: [[NSNumber]], startBearing: Float?) throws -> String? {
        return nil
    }

    func parseResponse(content: String, leftSideNavigation: Bool, initialCalculation: Bool/*, calculationProgress: OARouteCalculationProgress?*/) throws -> OnlineRoutingResponse? {
        fatalError("Subclasses must override parseResponse(content:app:leftSideNavigation:initialCalculation:calculationProgress:)")
    }

    func isResultOk(errorMessage: String, content: String) throws -> Bool {
        fatalError("Subclasses must override isResultOk(errorMessage:content:)")
    }

    func getParams() -> [String: String] {
        return params
    }

    func get(key: EngineParameter) -> String? {
        return params[key.name()]
    }

    func put(key: EngineParameter, value: String) {
        params[key.name()] = value
    }

    func remove(key: EngineParameter) {
        params.removeValue(forKey: key.name())
    }

    private func collectAllowedVehicles() {
        allowedVehicles.removeAll()
        collectAllowedVehicles(vehicles: &allowedVehicles)
        allowedVehicles.append(OnlineRoutingEngine.customVehicle)
        allowedVehicles.append(OnlineRoutingEngine.noneVehicle)
    }

    fileprivate func collectAllowedVehicles(vehicles: inout [VehicleType]) {
        fatalError("Subclasses must override collectAllowedVehicles(vehicles:)")
    }

    func getAllowedVehicles() -> [VehicleType] {
        return allowedVehicles
    }

    private func collectAllowedParameters() {
        collectAllowedParameters(params: &allowedParameters)
    }

    fileprivate func collectAllowedParameters(params: inout Set<EngineParameter>) {
        fatalError("Subclasses must override collectAllowedParameters(params:)")
    }

    func isParameterAllowed(key: EngineParameter) -> Bool {
        return allowedParameters.contains(key)
    }

    func isPredefined() -> Bool {
        return OnlineRoutingEngine.isPredefinedEngineKey(stringKey: getStringKey())
    }

    func updateRouteParameters(/*params: OARouteCalculationParams, previousRoute: OARouteCalculationResult?*/) {
    }

    fileprivate func getSelectedVehicleName() -> String? {
        if isCustomParameterizedVehicle() {
            return OnlineRoutingEngine.customVehicle.getTitle()
        }
        let key: String? = get(key: EngineParameter.vehicleKey);
        let vt: VehicleType = getVehicleTypeByKey(vehicleKey: key)
        if vt != OnlineRoutingEngine.customVehicle {
            return vt.getTitle()
        }
        return key != nil ? OAUtilities.capitalizeFirstLetter(key) : nil
    }

    func getSelectedVehicleType() -> VehicleType {
        let key: String? = get(key: EngineParameter.vehicleKey)
        return getVehicleTypeByKey(vehicleKey: key)
    }

    func getVehicleTypeByKey(vehicleKey: String?) -> VehicleType {
        if let key = vehicleKey {
            for vt in allowedVehicles {
                if vt.getKey() == key {
                    return vt
                }
            }
        }
        return OnlineRoutingEngine.customVehicle
    }

    func isCustomParameterizedVehicle() -> Bool {
        return isCustomParameterizedValue(value: get(key: EngineParameter.vehicleKey))
    }

    /**
    * @return 'true' if the custom input has any custom parameters, 'false' - otherwise.
    * For example, for custom input "&profile=car&locale=en" the method returns 'true'.
    */
    func isCustomParameterizedValue(value: String?) -> Bool {
        if let value = value {
            return value.starts(with: "&") || value.contains("=")
        }
        return false
    }

    func clone() -> Any {
        return newInstance(params: getParams())
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let engine = object as? OnlineRoutingEngine else { return false }
        if getType() != engine.getType() { return false }
        return getParams() == engine.getParams()
    }

    func newInstance(params: [String: String]) -> OnlineRoutingEngine
    {
        fatalError("Subclasses must override newInstance(params:)")
    }

    static func generateKey() -> String {
        return onlineRoutingEnginePrefix + String(Date().timeIntervalSince1970)
    }

    static func generatePredefinedKey(provider: String, type: String) -> String {
        let key = predefinedPrefix + provider + "_" + type
        return key.replacingOccurrences(of: " ", with: "_").lowercased()
    }

    static func isPredefinedEngineKey(stringKey: String?) -> Bool {
        return stringKey?.starts(with: predefinedPrefix) ?? false
    }

    static func isOnlineEngineKey(stringKey: String?) -> Bool {
        return stringKey?.starts(with: onlineRoutingEnginePrefix) ?? false
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy: OnlineRoutingEngine = OnlineRoutingEngine(params: self.params)
        copy.allowedVehicles = allowedVehicles
        copy.allowedParameters = allowedParameters
        return copy
    }

    class OnlineRoutingResponse {

        private var route: [CLLocation]?
//        let directions: [OARouteDirectionInfo]?
        private var gpxFile: OAGPXDocument?
        private var calculatedTimeSpeed: Bool

        init(route: [CLLocation]?/*, directions: [OARouteDirectionInfo]?*/) {
            self.route = route
//            self.directions = directions
            self.gpxFile = nil
            self.calculatedTimeSpeed = false
        }

        init(gpxFile: OAGPXDocument?, calculatedTimeSpeed: Bool) {
            self.route = nil
//            self.directions = nil
            self.gpxFile = gpxFile
            self.calculatedTimeSpeed = calculatedTimeSpeed
        }

        func getRoute() -> [CLLocation]? {
            return route
        }

//        func getDirections() -> [OARouteDirectionInfo]? {
//            return directions
//        }

        func getGpxFile() -> OAGPXDocument? {
            return gpxFile
        }

        func hasCalculatedTimeSpeed() -> Bool {
            return calculatedTimeSpeed
        }
    }

}
