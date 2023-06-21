//
//  OnlineRoutingHelper.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAOnlineRoutingHelper)
@objcMembers
class OnlineRoutingHelper: NSObject {

    static private let connectionTimeout: TimeInterval = 30
//    private let LOG = PlatformUtil.getLog(OnlineRoutingHelper.self)

    private let settings: OAAppSettings
    private var cachedEngines: [String: OnlineRoutingEngine]

    override init() {
        self.settings = OAAppSettings.sharedManager()
//        self.cachedEngines = loadSavedEngines()
        self.cachedEngines = [:]
    }

    func getEngines() -> [OnlineRoutingEngine] {
        return Array(cachedEngines.values)
    }

    func getOnlyCustomEngines() -> [OnlineRoutingEngine] {
        var engines: [OnlineRoutingEngine] = []
        for engine in getEngines() {
            if !engine.isPredefined() {
                engines.append(engine)
            }
        }
        return engines
    }

    func getEnginesExceptMentionedKeys(excludeKeys: String?...) -> [OnlineRoutingEngine] {
        var engines: [OnlineRoutingEngine] = getEngines()
        if !excludeKeys.isEmpty {
            for key in excludeKeys {
                if let engine = getEngineByKey(stringKey: key) {
                    if let index = engines.firstIndex(of: engine) {
                        engines.remove(at: index)
                    }
                }
            }
        }
        return engines
    }

    func getEngineByKey(stringKey: String?) -> OnlineRoutingEngine? {
        if stringKey != nil { return cachedEngines[stringKey!] }
        return nil
    }

    func getEngineByName(name: String?) -> OnlineRoutingEngine? {
        for engine in getEngines() {
            if engine.getName() == name {
                return engine
            }
        }
        return nil
    }

//    func calculateRouteOnline(stringKey: String?,
//                              path: [[NSNumber]],
//                              startBearing: Float?,
//                              leftSideNavigation: Bool,
//                              initialCalculation: Bool,
//                              calculationProgress: OARouteCalculationProgress?) throws -> OnlineRoutingEngine.OnlineRoutingResponse? {
//        if let engine = getEngineByKey(stringKey: stringKey) {
//            return try calculateRouteOnline(engine: engine,
//                                            path: path,
//                                            startBearing: startBearing,
//                                            leftSideNavigation: leftSideNavigation,
//                                            initialCalculation: initialCalculation,
//                                            calculationProgress: calculationProgress)
//        } else {
//            return nil
//        }
//    }

//    func calculateRouteOnline(engine: OnlineRoutingEngine,
//                              path: [[NSNumber]],
//                              startBearing: Float?,
//                              leftSideNavigation: Bool,
//                              initialCalculation: Bool,
//                              calculationProgress: OARouteCalculationProgress?) throws -> OnlineRoutingEngine.OnlineRoutingResponse? {
//        let url = engine.getFullUrl(path: path, startBearing: startBearing)
//        let method = engine.getHTTPMethod()
//        let body = try engine.getRequestBody(path: path, startBearing: startBearing)
//        let headers = engine.getRequestHeaders()
//        let content = try makeRequest(url: url, method: method, body: body, headers: headers)
//        return try engine.parseResponse(content: content,
//                                        leftSideNavigation: leftSideNavigation,
//                                        initialCalculation: initialCalculation,
//                                        calculationProgress: calculationProgress)
//    }

//    func makeRequest(url: String) throws -> String {
//        return try makeRequest(url: url, method: "GET", body: nil, headers: nil)
//    }

//    func makeRequest(url: String, method: String, body: String?, headers: [String: String]?) throws -> String {
////        LOG.info("Calling online routing: \(url)")
//        OANetworkUtilities.getHttpURLConnection(url) { (request: NSMutableURLRequest) in
//            request.setValue(OAAppVersionDependentConstants.getAppVersionWithBundle(), forKey: "User-Agent");
//            request.httpMethod = method;
//            request.timeoutInterval = OnlineRoutingHelper.connectionTimeout;
//
//            if let headers = headers {
//                for (key, value) in headers {
//                    request.setValue(value, forKey:key)
//                }
//            }
//
//            if method != "GET" && body != nil {
//                if let bodyData = body?.data(using: .utf8) {
//                    request.setValue("\(bodyData.count)", forKey: "Content-Length")
////                    connection.setDoOutput(true)
//                    request.httpBody = bodyData
//                }
//            }
//        } taskHandler: { (data: Data?, response: URLResponse?, error: Error?) in
//            if data == nil { return }
//
//            let reader: BufferedReader
//            let httpResponse: HTTPURLResponse? = (response as? HTTPURLResponse?) ?? nil
//            var responseCode: Int = httpResponse?.statusCode ?? 500
//            if (responseCode == 200)
//            {
//                let inputStream = try getInputStream(from: data)
//                reader = BufferedReader(inputStream: inputStream)
//            }
//            else
//            {
//                reader = BufferedReader(InputStreamReader(connection.getErrorStream()))
//            }
//
//            var content = ""
//            var line: String?
//            while (line = reader.readLine()) != nil {
//                content.append(line)
//            }
//
//            reader.close()
//            return content
//        }
//
//        return content
//    }

//    func startOsrmEngine(mode: ApplicationMode) -> OnlineRoutingEngine? {
//        let isCarBicycleFoot = mode.isDerivedRoutingFrom(applicationMode: ApplicationMode.CAR) ||
//                               mode.isDerivedRoutingFrom(applicationMode: ApplicationMode.BICYCLE) ||
//                               mode.isDerivedRoutingFrom(applicationMode: ApplicationMode.PEDESTRIAN)
//
//        var paramsOnlineRouting: [String: String] = [:]
//        paramsOnlineRouting[EngineParameter.VEHICLE_KEY.name()] = mode.getStringKey()
//
//        if isCarBicycleFoot {
//            return EngineType.OSRM_TYPE.newInstance(paramsOnlineRouting: paramsOnlineRouting)
//        } else {
//            return nil
//        }
//    }

//    private func loadSavedEngines() -> [String: OnlineRoutingEngine] {
//        var cachedEngines: [String: OnlineRoutingEngine] = [:]
//        for engine in readFromSettings() {
//            let key: String? = engine.getStringKey()
//            if key != nil { cachedEngines[key!] = engine }
//        }
//        return cachedEngines
//    }

//    private func readFromSettings() -> [OnlineRoutingEngine] {
//        var engines: [OnlineRoutingEngine] = []
//        let jsonString = settings.ONLINE_ROUTING_ENGINES.get()
//
//        if !jsonString.isEmpty {
//            do {
//                if let jsonData = jsonString.data(using: .utf8) {
//                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
//                        OnlineRoutingUtils.readFromJson(json: json, engines: &engines)
//                    }
//                }
//            } catch {
//                LOG.debug("Error when reading engines from JSON ", error)
//            }
//        }
//
//        return engines
//    }

//    private func saveCacheToSettings() {
//        if !cachedEngines.isEmpty {
//            do {
//                let json = try OnlineRoutingUtils.writeToJson(engines: getEngines())
//                if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) {
//                    let jsonString = String(data: jsonData, encoding: .utf8)
//                    settings.ONLINE_ROUTING_ENGINES.set(jsonString)
//                }
//            } catch {
//                LOG.debug("Error when writing engines to JSON ", error)
//            }
//        } else {
//            settings.ONLINE_ROUTING_ENGINES.set(nil)
//        }
//    }
}
