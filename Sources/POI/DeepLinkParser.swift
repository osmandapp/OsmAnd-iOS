//
//  DeepLinkParser.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class DeepLinkParser: NSObject {
    
    static func handleIncomingMapPoiURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard OAUtilities.isOsmAndSite(url), OAUtilities.isPathPrefix(url, pathPrefix: "/map/poi") else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var nameParam: String?
        var typeParam: String?
        for item in items {
            let key = item.name.lowercased()
            if key == "name" {
                nameParam = item.value
            } else if key == "type" {
                typeParam = item.value
            }
        }
        
        if !(typeParam?.isEmpty ?? true) {
            return handleIncomingAmenityURL(url, rootViewController: rootViewController)
        } else if !(nameParam?.isEmpty ?? true) {
            return handleIncomingFavouriteURL(url, rootViewController: rootViewController)
        }
        
        return false
    }
    
    static func handleIncomingAmenityURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var name: String?
        var type: String?
        var wikiDataId: String?
        var osmId: String?
        var latLonParam: String?
        for item in items {
            let key = item.name.lowercased()
            if key == "name" {
                name = item.value
            } else if key == "type" {
                type = item.value
            } else if key == "wikidataid" {
                wikiDataId = item.value
            } else if key == "osmid" {
                osmId = item.value
            } else if key == "pin" {
                latLonParam = item.value
            }
        }
        
        let latLon: CLLocation? = {
            guard let latLonParam, !latLonParam.isEmpty else { return nil }
            return OAUtilities.parseLatLon(latLonParam)
        }()
        
        if let latLon {
            let pinLat = latLon.coordinate.latitude
            let pinLon = latLon.coordinate.longitude
            let zoom = rootViewController.mapPanel.mapViewController.getMapZoom()
            guard let amenity = searchBaseDetailsObject(pinLat: pinLat, pinLon: pinLon, name: name, poiType: type, wikiDataId: wikiDataId, osmId: osmId) else { return false }
            let synthetic = amenity.syntheticAmenity
            guard let targetPoint = rootViewController.mapPanel.mapViewController.getMapPoiLayer().getTargetPoint(synthetic) else { return false }
            targetPoint.location = latLon.coordinate
            targetPoint.initAdderssIfNeeded()
            targetPoint.centerMap = true
            rootViewController.mapPanel.showContextMenu(targetPoint, saveState: false, preferredZoom: zoom)
            return true
        }
        
        return false
    }
    
    static func handleIncomingFavouriteURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var name: String?
        var latLonParam: String?
        for item in items {
            let key = item.name.lowercased()
            if key == "name" {
                name = item.value
            } else if key == "pin" {
                latLonParam = item.value
            }
        }
        
        guard let latLonParam, !latLonParam.isEmpty, let name, !name.isEmpty else { return false }
        let latLon = OAUtilities.parseLatLon(latLonParam)
        let lat = latLon.coordinate.latitude
        let lon = latLon.coordinate.longitude
        let zoom = rootViewController.mapPanel.mapViewController.getMapZoom()
        return OAFavoritesBridge.openFavouriteOrMoveMap(withLat: lat, lon: lon, zoom: Int32(zoom), name: name)
    }
    
    static func searchBaseDetailsObject(pinLat: Double, pinLon: Double, name: String?, poiType: String?, wikiDataId: String?, osmId: String?) -> BaseDetailsObject? {
        let names = [name].compactMap { $0 }
        var parsedOsmId: Int64 = -1
        if let osmId, !osmId.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if let num = formatter.number(from: osmId) {
                parsedOsmId = num.int64Value
            } else {
                NSLog("[SceneDelegate] Incorrect OsmId: %@", osmId)
            }
        }
        
        var subType: String?
        let category: OAPOICategory? = (poiType?.isEmpty ?? true) ? nil : OAPOIHelper.sharedInstance().getPoiCategory(byName: poiType)
        if category == nil || category == OAPOIHelper.sharedInstance().otherPoiCategory {
            subType = poiType
        }
        
        var wikidata = wikiDataId
        if let wd = wikidata, !wd.isEmpty, !wd.hasPrefix("Q") {
            wikidata = "Q" + wd
        }
        
        let request = OAAmenitySearcherRequest()
        request.type = kEntityTypeNode
        request.latLon = CLLocation(latitude: pinLat, longitude: pinLon)
        request.names = NSMutableArray(array: names)
        request.wikidata = wikidata
        request.osmId = parsedOsmId
        request.mainAmenityType = subType
        return OAAmenitySearcher.sharedInstance().searchDetailedObject(request)
    }
}
