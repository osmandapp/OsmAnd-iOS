//
//  RouteInfoCalculator.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 14.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

struct DestinationInfo {
    let distance: Int32
    let arrivalTime: TimeInterval
    let timeToGo: TimeInterval
}

final class RouteInfoCalculator {
    private let mapViewController: OAMapViewController
    private let routingHelper: OARoutingHelper
    private let targetPointsHelper: OATargetPointsHelper
    
    init() {
        mapViewController = OARootViewController.instance().mapPanel.mapViewController
        routingHelper = OARoutingHelper.sharedInstance()
        targetPointsHelper = OATargetPointsHelper.sharedInstance()
    }
    
    func calculateRouteInformationWith(_ priority: RouteInfoDisplayPriority) -> [DestinationInfo] {
        let finalDestination = getFinalDestinationInfo()
        
        if let currentIntermediate = getCurrentIntermediateInfo(), let finalDestination {
            return priority == .intermediateFirst ? [currentIntermediate, finalDestination] : [finalDestination, currentIntermediate]
        } else if let finalDestination {
            return [finalDestination]
        }
        return []
    }
    
    private func getCurrentIntermediateInfo() -> DestinationInfo? {
        let intermediateInfos = collectNotPassedIntermediatePointsWith(pointsLimit: 1)
        return intermediateInfos.first
    }
    
    private func collectNotPassedIntermediatePointsWith(pointsLimit: Int) -> [DestinationInfo] {
        var result: [DestinationInfo] = []
        var intermediatePointIndex: Int32 = 0
        
        while let intermediate = targetPointsHelper.getIntermediatePoint(intermediatePointIndex) {
            let distance = getDistanceToIntermediateWith(location: intermediate.point, intermediateIndexOffset: intermediatePointIndex)
            let estimatedTime = getEstimatedTimeToIntermediateWith(intermediateIndexOffset: intermediatePointIndex)

            if isPointNotPassedWith(distance: distance, leftSeconds: estimatedTime) {
                result.append(createDestinationInfoWith(distance: distance, leftSeconds: estimatedTime))
                if result.count == pointsLimit {
                    break
                }
            }
            intermediatePointIndex += 1
        }
        return result
    }
    
    private func getFinalDestinationInfo() -> DestinationInfo? {
        if let destination = OATargetPointsHelper.sharedInstance()!.getPointToNavigate() {
            let distance = getDistanceToDestinationWith(location: CLLocation(latitude: destination.getLatitude(), longitude: destination.getLongitude()))
            let leftTime = getEstimatedTimeToDestination()
            if isPointNotPassedWith(distance: distance, leftSeconds: leftTime) {
                return createDestinationInfoWith(distance: distance, leftSeconds: leftTime)
            }
        }
        return nil
    }
    
    private func getDistanceToIntermediateWith(location: CLLocation, intermediateIndexOffset: Int32) -> Int32 {
        routingHelper.isRouteCalculated() ? routingHelper.getLeftDistanceNextIntermediate(with: intermediateIndexOffset) : calculateDefaultDistanceWith(location: location)
    }
    
    private func getDistanceToDestinationWith(location: CLLocation) -> Int32 {
        routingHelper.isRouteCalculated() ? routingHelper.getLeftDistance() : calculateDefaultDistanceWith(location: location)
    }
    
    private func calculateDefaultDistanceWith(location: CLLocation) -> Int32 {
        Int32(mapViewController.getMapLocation().distance(from: location))
    }
    
    private func getEstimatedTimeToIntermediateWith(intermediateIndexOffset: Int32) -> Int {
        routingHelper.getLeftTimeNextIntermediate(with: intermediateIndexOffset)
    }
    
    private func getEstimatedTimeToDestination() -> Int {
        routingHelper.getLeftTime()
    }
    
    private func isPointNotPassedWith(distance: Int32, leftSeconds: Int) -> Bool {
        distance > 20 && leftSeconds > 0
    }
    
    private func createDestinationInfoWith(distance: Int32, leftSeconds: Int) -> DestinationInfo {
        let timeToGo = TimeInterval(leftSeconds)
        let arrivalTime = Date().timeIntervalSince1970 + timeToGo
        return DestinationInfo(distance: distance, arrivalTime: arrivalTime, timeToGo: timeToGo)
    }
}
