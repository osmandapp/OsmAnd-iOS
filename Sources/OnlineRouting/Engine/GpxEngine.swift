//
//  GpxEngine.swift
//  OsmAnd Maps
//
//  Created by Skalii on 12.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGpxEngine)
@objcMembers
class GpxEngine: OnlineRoutingEngine {

    private static let onlineRoutingGpxFileName: String = "online_routing_gpx"

    override func getType() -> OnlineRoutingEngine {
        return EngineType.GpxType
    }

    override func getTitle() -> String {
        return "GPX"
    }

    override func getTypeName() -> String {
        return "GPX"
    }

    /*protected*/
    override func makeFullUrl(sb: inout String, path: [[NSNumber]], startBearing: Float?) {
        sb.append("?")
        for (index, point) in path.enumerated() {
            sb.append("point=")
            sb.append(point.first!.stringValue)
            sb.append(",")
            sb.append(point.last!.stringValue)
            if index < path.count - 1 {
                sb.append("&")
            }
        }
        if let startBearing = startBearing {
            if sb.last != "?" {
                sb.append("&")
            }
            sb.append("heading=")
            sb.append(String(Int(startBearing)))
        }
    }

    override func getStandardUrl() -> String {
        return ""
    }

    override func collectAllowedParameters(params: inout Set<EngineParameter>) {
        params.insert(EngineParameter.key)
        params.insert(EngineParameter.customName)
        params.insert(EngineParameter.nameIndex)
        params.insert(EngineParameter.customURL)
        params.insert(EngineParameter.approximationRoutingProfile)
        params.insert(EngineParameter.approximationDerivedProfile)
        params.insert(EngineParameter.networkApproximateRoute)
        params.insert(EngineParameter.useExternalTimestamps)
        params.insert(EngineParameter.useRoutingFallback)
    }

    override func updateRouteParameters(params: OARouteCalculationParams, previousRoute: OARouteCalculationResult?) {
        super.updateRouteParameters(params: params, previousRoute: previousRoute)
        if (previousRoute == nil || previousRoute!.isEmpty()) && shouldApproximateRoute() {
            params.initialCalculation = true
        }
    }

    override func newInstance(params: [String: String]) -> OnlineRoutingEngine {
        return GpxEngine(params: params)
    }

    override func parseResponse(content: String,
                                leftSideNavigation: Bool,
                                initialCalculation: Bool,
                                calculationProgress: OARouteCalculationProgress) -> OnlineRoutingResponse? {
        var gpxFile: OAGPXDocument? = parseGpx(content: content)
        return gpxFile != nil ? prepareResponse(gpxFile: &gpxFile!, initialCalculation: initialCalculation, calculationProgress: calculationProgress) : nil
    }

    private func prepareResponse(gpxFile: inout OAGPXDocument,
                                 initialCalculation: Bool,
                                 calculationProgress: OARouteCalculationProgress) -> OnlineRoutingResponse {
        var calculatedTimeSpeed: NSMutableArray = [useExternalTimestamps()]
        if shouldApproximateRoute() && !initialCalculation {
            if let approximated = approximateGpxFile(gpxFile: gpxFile, calculationProgress: calculationProgress, calculatedTimeSpeed: &calculatedTimeSpeed) {
                gpxFile = approximated
            }
        }
        return OnlineRoutingResponse(gpxFile: gpxFile, calculatedTimeSpeed: calculatedTimeSpeed[0] as! Bool)
    }

    private func approximateGpxFile(gpxFile: OAGPXDocument,
                                    calculationProgress: OARouteCalculationProgress,
                                    calculatedTimeSpeed: inout NSMutableArray) -> OAGPXMutableDocument? {
        let routingHelper: OARoutingHelper = OARoutingHelper.sharedInstance()
        let appMode: OAApplicationMode = routingHelper.getAppMode()
        let oldRoutingProfile: String = appMode.getRoutingProfile()
        let oldDerivedProfile: String = appMode.getDerivedProfile()

        do {
            defer {
                appMode.setRoutingProfile(oldRoutingProfile)
                appMode.setDerivedProfile(oldDerivedProfile)
            }

            let routingProfile: String? = getApproximationRoutingProfile()
            if let routingProfile: String = routingProfile {
                appMode.setRoutingProfile(routingProfile)
                appMode.setDerivedProfile(getApproximationDerivedProfile())
            }
            let points: [OAWptPt] = gpxFile.getAllSegmentsPoints()
            let holder: OALocationsHolder = OALocationsHolder(locations: points)
            if holder.size > 1 {
                let start: CLLocation = CLLocation.init(latitude: holder.getLatitude(0), longitude: holder.getLongitude(0))
                let end: CLLocation = CLLocation.init(latitude: holder.getLatitude(holder.size - 1), longitude: holder.getLongitude(holder.size - 1))
                let env: OARoutingEnvironment = routingHelper.getRoutingEnvironment(appMode, start: start, end: end)
                let gctx: OAGpxRouteApproximation = OAGpxRouteApproximation(routingEnvironment: env, routeCalculationProgress: calculationProgress)
                
                return routingHelper.approximateGpxFile(gpxFile,
                                                        calculatedTimeSpeed: calculatedTimeSpeed,
                                                        env: env,
                                                        gctx: gctx,
                                                        locationsHolder: holder,
                                                        shouldNetworkApproximateRoute: shouldNetworkApproximateRoute(),
                                                        points: points,
                                                        appMode: appMode,
                                                        routingGpxFileName: GpxEngine.onlineRoutingGpxFileName)
            }
        } catch /*(IOException | InterruptedException e)*/ {
            //            LOG.error(error.localizedDescription)
        }
        return nil
    }

    override func isResultOk(errorMessage: String, content: String) -> Bool {
        return parseGpx(content: content) != nil
    }

    private func parseGpx(content: String) -> OAGPXDocument? {
        if let gpxStream = content.data(using: .utf8) {
            return OAGPXDocument.init(data: gpxStream)
        }
        return nil
    }

}
