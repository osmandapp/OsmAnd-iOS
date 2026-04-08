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

    @objc(cancelWikiOnlineLoadingExcept:)
    func cancelWikiOnlineLoading(except rect: QuadRect?) {
        guard filter.isTopWikiFilter(), dataSourceType() == .online else {
            return
        }
        if let rect {
            NSLog("[TopWikiTrace][PoiUIFilterDataProvider] cancelWikiOnlineLoading except=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
        } else {
            NSLog("[TopWikiTrace][PoiUIFilterDataProvider] cancelWikiOnlineLoading except=nil")
        }
        explorePlacesProvider.cancelLoading(except: rect)
    }
    
    private func searchWikiOnline(lat: Double,
                                  lon: Double,
                                  topLatitude: Double,
                                  bottomLatitude: Double,
                                  leftLongitude: Double,
                                  rightLongitude: Double,
                                  matcher: OAResultMatcher<OAPOI>? = nil) -> [OAPOI] {
        let rect = QuadRect(left: leftLongitude, top: topLatitude, right: rightLongitude, bottom: bottomLatitude)
        let isCancelled = {
            matcher?.isCancelled() ?? false
        }

        if isCancelled() {
            NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline startCancelled rect=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
            return []
        }

        NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline start rect=(\(rect.left),\(rect.top),\(rect.right),\(rect.bottom))")
        var data = explorePlacesProvider.getDataCollection(rect, limit: 0, isCancelled: isCancelled)
        var loading = false
        NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline firstFetch count=\(data.count)")
        
        while explorePlacesProvider.isLoading(rect: rect) && !isCancelled() {
            if !loading {
                NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline waitingForRectLoads")
            }
            Thread.sleep(forTimeInterval: 0.1)
            loading = true
            if isCancelled() {
                NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline cancelledWhileWaiting")
                return []
            }
        }

        if isCancelled() {
            NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline cancelledAfterWaiting")
            return []
        }
        
        if loading {
            data = explorePlacesProvider.getDataCollection(rect, limit: 0, isCancelled: isCancelled)
            NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline secondFetch count=\(data.count)")
            if isCancelled() {
                NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline cancelledAfterSecondFetch")
                return []
            }
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
        NSLog("[TopWikiTrace][PoiUIFilterDataProvider] searchWikiOnline done result=\(sortedPOIs.count) loading=\(loading)")
        return sortedPOIs
    }
}
