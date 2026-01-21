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
    
    func parseDeepLink(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        handleIncomingFileURL(url, rootViewController: rootViewController)
        || handleIncomingActionsURL(url, rootViewController: rootViewController)
        || handleIncomingNavigationURL(url, rootViewController: rootViewController)
        || handleIncomingSetPinOnMapURL(url, rootViewController: rootViewController)
        || handleIncomingMoveMapToLocationURL(url, rootViewController: rootViewController)
        || handleIncomingOpenLocationMenuURL(url, rootViewController: rootViewController)
        || handleIncomingTileSourceURL(url, rootViewController: rootViewController)
        || handleIncomingOsmAndCloudURL(url, rootViewController: rootViewController)
    }
    
    private func handleIncomingFileURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController, url.scheme?.lowercased() == kFileScheme else { return false }
        return rootViewController.handleIncomingURL(url)
    }
    
    private func handleIncomingActionsURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        // osmandmaps://?lat=45.6313&lon=34.9955&z=8&title=New+York
        guard let rootViewController, url.scheme?.lowercased() == kOsmAndActionScheme else { return false }
        let params = OAUtilities.parseUrlQuery(url)
        let lat = (params["lat"] as NSString?)?.doubleValue ?? 0.0
        let lon = (params["lon"] as NSString?)?.doubleValue ?? 0.0
        let zoom = Int((params["z"] as NSString?)?.intValue ?? 0)
        let title = params["title"]
        if url.host == kNavigateActionHost {
            guard let targetPoint = OADeepLinkBridge.unknownTargetPoint(withLat: lat, lon: lon, rootViewController: rootViewController) else { return false }
            if let title, !title.isEmpty {
                targetPoint.title = title
            }
            
            rootViewController.mapPanel.navigate(targetPoint)
            rootViewController.mapPanel.closeRouteInfo()
            rootViewController.mapPanel.startNavigation()
        } else {
            moveMapToLat(lat, lon: lon, zoom: zoom, title: title, rootViewController: rootViewController)
        }
        
        return true
    }
    
    private func handleIncomingNavigationURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var hasNavigationDestination = false
        var startLatLonParam: String?
        var intermediatePointsParam: String?
        var endLatLonParam: String?
        var appModeKeyParam: String?
        for item in queryItems {
            switch item.name.lowercased() {
            case "end":
                hasNavigationDestination = true
                endLatLonParam = item.value
            case "start":
                startLatLonParam = item.value
            case "profile":
                appModeKeyParam = item.value
            case "via":
                intermediatePointsParam = item.value
            default:
                break
            }
        }
        
        guard hasNavigationDestination, OAUtilities.isOsmAndMapUrl(url) else { return false }
        guard let endParam = endLatLonParam, !endParam.isEmpty else {
            NSLog("Malformed OsmAnd navigation URL: destination location is missing")
            return true
        }
        
        let startLatLon: CLLocation? = {
            guard let startLatLonParam, !startLatLonParam.isEmpty else { return nil }
            let parsed = OAUtilities.parseLatLon(startLatLonParam)
            if !CLLocationCoordinate2DIsValid(parsed.coordinate) {
                NSLog("Malformed OsmAnd navigation URL: start location is broken")
                return nil
            }
            
            return parsed
        }()
        
        let endLatLon = OAUtilities.parseLatLon(endParam)
        if !CLLocationCoordinate2DIsValid(endLatLon.coordinate) {
            NSLog("Malformed OsmAnd navigation URL: destination location is broken")
            return true
        }
        
        let appMode = OAApplicationMode.value(ofStringKey: appModeKeyParam, def: nil)
        if let appModeKeyParam, !appModeKeyParam.isEmpty, appMode == nil {
            NSLog("App mode with specified key not available, using default navigation app mode")
        }
        
        let points = parseIntermediatePoints(intermediatePointsParam)
        rootViewController.mapPanel.buildRoute(startLatLon, end: endLatLon, appMode: appMode, points: points)
        return true
    }
    
    private func handleIncomingSetPinOnMapURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        if handleIncomingMapPoiURL(url, rootViewController: rootViewController) {
            return true
        }
        
        if OAUtilities.isOsmAndSite(url), OAUtilities.isPathPrefix(url, pathPrefix: "/map/poi") {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.handleMapPoiURLWhenMapIsReady(url, rootViewController: rootViewController)
            }
            
            return true
        }
        
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var hasPin = false
        var latLonParam: String?
        for item in queryItems where item.name.lowercased() == "pin" {
            hasPin = true
            latLonParam = item.value
        }
        
        guard hasPin, OAUtilities.isOsmAndMapUrl(url) else { return false }
        guard let latLonParam, !latLonParam.isEmpty else { return false }
        let latLon = OAUtilities.parseLatLon(latLonParam)
        guard CLLocationCoordinate2DIsValid(latLon.coordinate) else { return false }
        let lat = latLon.coordinate.latitude
        let lon = latLon.coordinate.longitude
        var zoom = Int(rootViewController.mapPanel.mapViewController.getMapZoom())
        let decoded = url.absoluteString.removingPercentEncoding ?? url.absoluteString
        let prefix = "pin=" + latLonParam
        if let range = decoded.range(of: prefix) {
            let afterPin = decoded[range.upperBound...]
            let parts = afterPin.components(separatedBy: "/")
            if parts.count == 3 {
                let zStr = parts[0].replacingOccurrences(of: "#", with: "")
                if let z = Int(zStr) {
                    zoom = z
                }
            }
        }
        
        moveMapToLat(lat, lon: lon, zoom: zoom, title: nil, rootViewController: rootViewController)
        return true
    }
    
    private func handleIncomingMoveMapToLocationURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController, OAUtilities.isOsmAndMapUrl(url) else { return false }
        let prefix = "/map#"
        let abs = url.absoluteString
        guard let range = abs.range(of: prefix) else { return false }
        let tail = abs[range.upperBound...]
        let parts = tail.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return false }
        let zoom = Int(parts[0]) ?? 0
        let lat = Double(parts[1]) ?? 0
        let lon = Double(parts[2]) ?? 0
        moveMapToLat(lat, lon: lon, zoom: zoom, title: nil, rootViewController: rootViewController)
        return true
    }
    
    private func handleIncomingOpenLocationMenuURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController, OAUtilities.isOsmAndGo(url) else { return false }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var latParam: String?
        var lonParam: String?
        var zoomParam: String?
        var titleParam: String?
        for item in queryItems {
            switch item.name.lowercased() {
            case "lat":
                latParam = item.value
            case "lon":
                lonParam = item.value
            case "z":
                zoomParam = item.value
            case "title":
                titleParam = item.value
            default:
                break
            }
        }
        
        guard let latParam, let lonParam else { return false }
        let lat = Double(latParam) ?? 0.0
        let lon = Double(lonParam) ?? 0.0
        var zoom = Int(rootViewController.mapPanel.mapViewController.getMapZoom())
        if let zoomParam, !zoomParam.isEmpty {
            zoom = Int(zoomParam) ?? zoom
        }
        
        moveMapToLat(lat, lon: lon, zoom: zoom, title: titleParam, rootViewController: rootViewController)
        return true
    }
    
    private func handleIncomingTileSourceURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        guard OAUtilities.isOsmAndSite(url), OAUtilities.isPathPrefix(url, pathPrefix: "/add-tile-source") else { return false }
        let params = OAUtilities.parseUrlQuery(url)
        // https://osmand.net/add-tile-source?name=&url_template=&min_zoom=&max_zoom=
        guard let editVC = OAOnlineTilesEditingViewController(urlParameters: params) else { return false }
        rootViewController.navigationController?.pushViewController(editVC, animated: false)
        return true
    }
    
    private func handleIncomingOsmAndCloudURL(_ url: URL, rootViewController: OARootViewController?) -> Bool {
        guard let rootViewController else { return false }
        guard OAUtilities.isOsmAndSite(url), OAUtilities.isPathPrefix(url, pathPrefix: "/premium/device-registration") else { return false }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var tokenParam: String?
        for item in queryItems where item.name.lowercased() == "token" {
            tokenParam = item.value
        }
        
        let vc = rootViewController.navigationController?.visibleViewController
        if let verificationVC = vc as? OACloudAccountVerificationViewController {
            let isValidToken: Bool = {
                guard let tokenParam else { return false }
                return BackupUtils.isTokenValid(tokenParam)
            }()
            
            if isValidToken, let tokenParam {
                OABackupHelper.sharedInstance().registerDevice(tokenParam)
            } else {
                verificationVC.errorMessage = localizedString("backup_error_invalid_token")
                verificationVC.updateScreen()
            }
        } else {
            rootViewController.token = tokenParam
        }
        
        return true
    }
    
    @discardableResult private func handleIncomingMapPoiURL(_ url: URL, rootViewController: OARootViewController) -> Bool {
        guard OAUtilities.isOsmAndSite(url), OAUtilities.isPathPrefix(url, pathPrefix: "/map/poi") else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var nameParam: String?
        var typeParam: String?
        for item in items {
            let key = item.name.lowercased()
            if key == "name" {
                nameParam = normalizeQueryValue(item.value)
            } else if key == "type" {
                typeParam = normalizeQueryValue(item.value)
            }
        }
        
        if !(typeParam?.isEmpty ?? true) {
            return handleIncomingAmenityURL(url, rootViewController: rootViewController)
        } else if !(nameParam?.isEmpty ?? true) {
            return handleIncomingFavouriteURL(url, rootViewController: rootViewController)
        }
        
        return false
    }
    
    private func handleIncomingAmenityURL(_ url: URL, rootViewController: OARootViewController) -> Bool {
        guard rootViewController.mapPanel.mapViewController.mapViewLoaded else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var name: String?
        var type: String?
        var wikiDataId: String?
        var osmId: String?
        var latLonParam: String?
        
        for item in items {
            switch item.name.lowercased() {
            case "name":
                name = normalizeQueryValue(item.value)
            case "type":
                type = normalizeQueryValue(item.value)
            case "wikidataid":
                wikiDataId = normalizeQueryValue(item.value)
            case "osmid":
                osmId = normalizeQueryValue(item.value)
            case "pin":
                latLonParam = normalizeQueryValue(item.value)
            default:
                break
            }
        }
        
        guard let latLonParam, !latLonParam.isEmpty else { return false }
        let latLon = OAUtilities.parseLatLon(latLonParam)
        guard CLLocationCoordinate2DIsValid(latLon.coordinate) else { return false }
        let pinLat = latLon.coordinate.latitude
        let pinLon = latLon.coordinate.longitude
        let zoom = extractZoom(from: url, fallback: rootViewController.mapPanel.mapViewController.getMapZoom())
        guard let amenity = searchBaseDetailsObject(pinLat: pinLat, pinLon: pinLon, name: name, poiType: type, wikiDataId: wikiDataId, osmId: osmId) else { return false }
        let synthetic = amenity.syntheticAmenity
        guard let targetPoint = rootViewController.mapPanel.mapViewController.getMapPoiLayer().getTargetPoint(synthetic) else { return false }
        targetPoint.location = latLon.coordinate
        targetPoint.initAdderssIfNeeded()
        targetPoint.centerMap = true
        rootViewController.mapPanel.showContextMenu(targetPoint, saveState: false, preferredZoom: zoom)
        return true
    }
    
    private func handleIncomingFavouriteURL(_ url: URL, rootViewController: OARootViewController) -> Bool {
        guard rootViewController.mapPanel.mapViewController.mapViewLoaded else { return false }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        var name: String?
        var latLonParam: String?
        for item in items {
            switch item.name.lowercased() {
            case "name":
                name = normalizeQueryValue(item.value)
            case "pin":
                latLonParam = normalizeQueryValue(item.value)
            default:
                break
            }
        }
        
        guard let name, !name.isEmpty, let latLonParam, !latLonParam.isEmpty else { return false }
        let latLon = OAUtilities.parseLatLon(latLonParam)
        guard CLLocationCoordinate2DIsValid(latLon.coordinate) else { return false }
        let lat = latLon.coordinate.latitude
        let lon = latLon.coordinate.longitude
        let zoom = extractZoom(from: url, fallback: rootViewController.mapPanel.mapViewController.getMapZoom())
        return OADeepLinkBridge.openFavouriteOrMoveMap(withLat: lat, lon: lon, zoom: Int32(zoom), name: name)
    }
    
    private func searchBaseDetailsObject(pinLat: Double, pinLon: Double, name: String?, poiType: String?, wikiDataId: String?, osmId: String?) -> BaseDetailsObject? {
        let names = name.map { $0.isEmpty ? [] : [$0] } ?? []
        var parsedOsmId: Int64 = -1
        if let osmId, !osmId.isEmpty {
            let trimmed = osmId.trimmingCharacters(in: .whitespacesAndNewlines)
            if let id = Int64(trimmed) {
                parsedOsmId = id
            } else {
                NSLog("[DeepLinkParser] Incorrect OsmId: %@", osmId)
            }
        }
        
        let category: OAPOICategory? = {
            guard let poiType, !poiType.isEmpty else { return nil }
            return OAPOIHelper.sharedInstance().getPoiCategory(byName: poiType)
        }()
        
        let subType: String? = {
            guard let poiType, !poiType.isEmpty else { return nil }
            return category == nil || category == OAPOIHelper.sharedInstance().otherPoiCategory ? poiType : nil
        }()
        
        let wikidata: String? = {
            guard let wd = wikiDataId, !wd.isEmpty else { return nil }
            return wd.hasPrefix("Q") ? wd : "Q" + wd
        }()
        
        let request = OAAmenitySearcherRequest()
        request.type = kEntityTypeNode
        request.latLon = CLLocation(latitude: pinLat, longitude: pinLon)
        request.names = NSMutableArray(array: names)
        request.wikidata = wikidata
        request.osmId = parsedOsmId
        request.mainAmenityType = subType
        return OAAmenitySearcher.sharedInstance().searchDetailedObject(with: request)
    }
    
    private func normalizeQueryValue(_ rawValue: String?) -> String? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        let normalized = (rawValue.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? rawValue).trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }
    
    private func parseIntermediatePoints(_ parameter: String?) -> [CLLocation]? {
        guard let parameter, !parameter.isEmpty else { return nil }
        let params = parameter.components(separatedBy: CharacterSet(charactersIn: ",;"))
        let count = params.count
        guard count >= 2, count.isMultiple(of: 2) else {
            NSLog("Malformed OsmAnd navigation URL: corrupted intermediate points")
            return nil
        }
        
        var points: [CLLocation] = []
        points.reserveCapacity(count / 2)
        for i in stride(from: 0, to: count, by: 2) {
            let lat = (params[i] as NSString).doubleValue
            let lon = (params[i + 1] as NSString).doubleValue
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            guard CLLocationCoordinate2DIsValid(coordinate) else {
                NSLog("Malformed OsmAnd navigation URL: corrupted intermediate point (%@, %@)", params[i], params[i + 1])
                continue
            }
            
            points.append(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        
        return points.isEmpty ? nil : points
    }
    
    private func handleMapPoiURLWhenMapIsReady(_ url: URL, rootViewController: OARootViewController) {
        let mapVC = rootViewController.mapPanel.mapViewController
        guard mapVC.mapViewLoaded else { return }
        handleIncomingMapPoiURL(url, rootViewController: rootViewController)
    }
    
    private func moveMapToLat(_ lat: Double, lon: Double, zoom: Int, title: String?, rootViewController: OARootViewController) {
        OADeepLinkBridge.moveMap(toLat: lat, lon: lon, zoom: Int32(zoom), title: title, rootViewController: rootViewController)
    }
    
    private func extractZoom(from url: URL, fallback: Float) -> Float {
        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: true)?.fragment else { return fallback }
        let parts = fragment.split(separator: "/", omittingEmptySubsequences: true)
        if let first = parts.first, let zoom = Float(first) {
            return zoom
        }
        
        return fallback
    }
}
