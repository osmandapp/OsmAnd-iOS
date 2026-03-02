//
//  PoiUIFilterDataProvider.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 18.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import CoreLocation

@objcMembers
final class PoiUIFilterDataProvider: NSObject {
    
    private let filter: OAPOIUIFilter
    private let explorePlacesProvider: ExplorePlacesProvider
    
    init(filter: OAPOIUIFilter) {
        self.filter = filter
        self.explorePlacesProvider = ExplorePlacesOnlineProvider()
    }
    
    func dataSourceType() -> DataSourceType {
        if filter.isTopWikiFilter() {
            return OAAppSettings.sharedManager().wikiDataSourceType.get() == .online ? .online : .offline
        } else {
            return .offline
        }
    }
    
    func searchAmenities(lat: Double,
                         lon: Double,
                         topLatitude: Double,
                         bottomLatitude: Double,
                         leftLongitude: Double,
                         rightLongitude: Double,
                         zoom: Int,
                         matcher: OAResultMatcher<OAPOI>? = nil) -> [OAPOI] {
        if filter.isTopWikiFilter() && dataSourceType() == .online {
            return searchWikiOnline(
                lat: lat,
                lon: lon,
                topLatitude: topLatitude,
                bottomLatitude: bottomLatitude,
                leftLongitude: leftLongitude,
                rightLongitude: rightLongitude,
                matcher: matcher
            )
        } else {
            return OAPoiUIFilterDataProviderWrapper.searchAmenities(
                filter,
                additionalFilter: nil,
                topLatitude: topLatitude,
                bottomLatitude: bottomLatitude,
                leftLongitude: leftLongitude,
                rightLongitude: rightLongitude,
                includeTravel: true,
                matcher: matcher,
                publish: nil)
        }
    }
    
    private func searchWikiOnline(lat: Double,
                                  lon: Double,
                                  topLatitude: Double,
                                  bottomLatitude: Double,
                                  leftLongitude: Double,
                                  rightLongitude: Double,
                                  matcher: OAResultMatcher<OAPOI>? = nil) -> [OAPOI] {
        
//        if Thread.isMainThread {
//            fatalError("CRITICAL ERROR: searchAmenities (online) called on Main Thread!")
//        }
        
        let rect = QuadRect(left: leftLongitude, top: topLatitude, right: rightLongitude, bottom: bottomLatitude)
        var data = explorePlacesProvider.getDataCollection(rect, limit: 0)
        var loading = false
        var isCancelled = false

        while explorePlacesProvider.isLoading() && !isCancelled {
            Thread.sleep(forTimeInterval: 0.1)
            loading = true
            isCancelled = matcher?.isCancelled() ?? false
        }
        
        if isCancelled {
            return []
        }
        
        if loading {
            data = explorePlacesProvider.getDataCollection(rect, limit: 0)
        }
        
        var result: [OAPOI] = matcher == nil ? data : []
        
        if let matcher {
            for amenity in data where matcher.publish(amenity) {
                result.append(amenity)
            }
        }
        
        let targetLocation = CLLocation(latitude: lat, longitude: lon)
        
        let sortedPOIs = result.sorted { poi1, poi2 in
            let loc1 = CLLocation(latitude: poi1.latitude, longitude: poi1.longitude)
            let loc2 = CLLocation(latitude: poi2.latitude, longitude: poi2.longitude)
            
            return loc1.distance(from: targetLocation) < loc2.distance(from: targetLocation)
        }
        return sortedPOIs
    }
}
