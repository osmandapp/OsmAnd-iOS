//
//  AstroDataProvider.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import UIKit

class AstroDataProvider {
    private var cachedSkyObjects: [SkyObject]?
    private var cachedCatalogs: [Catalog]?
    private var cachedConstellations: [Constellation]?

    func getSkyObjectsImpl(preferredLocale: String?) -> [SkyObject] {
        []
    }

    func getCatalogsImpl() -> [Catalog] {
        []
    }

    func getConstellationsImpl(preferredLocale: String?) -> [Constellation] {
        []
    }

    func getAstroArticleImpl(wikidataId: String, lang: String? = nil) -> AstroArticle? {
        nil
    }

    func getCatalogs() -> [Catalog] {
        if let cachedCatalogs {
            return cachedCatalogs
        }
        let catalogs = getCatalogsImpl()
        cachedCatalogs = catalogs
        return catalogs
    }

    func getSkyObjects(preferredLocale: String?) -> [SkyObject] {
        if cachedCatalogs == nil {
            cachedCatalogs = getCatalogsImpl()
        }
        if let cachedSkyObjects {
            return cachedSkyObjects
        }
        let objects = getSkyObjectsImpl(preferredLocale: preferredLocale)
        cachedSkyObjects = objects
        return objects
    }

    func getConstellations(preferredLocale: String?) -> [Constellation] {
        if let cachedConstellations {
            return cachedConstellations
        }
        let constellations = getConstellationsImpl(preferredLocale: preferredLocale)
        var skyObjectMap: [Int: SkyObject] = [:]
        for object in getSkyObjects(preferredLocale: preferredLocale) {
            skyObjectMap[object.hip] = object
        }
        for constellation in constellations {
            if let center = AstroUtils.calculateConstellationCenter(constellation, skyObjectMap: skyObjectMap) {
                constellation.ra = center.0
                constellation.dec = center.1
            } else {
                constellation.ra = 0
                constellation.dec = 0
            }
        }
        cachedConstellations = constellations
        return constellations
    }

    func getAstroArticle(wikidataId: String, lang: String? = nil) -> AstroArticle? {
        getAstroArticleImpl(wikidataId: wikidataId, lang: lang)
    }

    func clearCache() {
        cachedSkyObjects = nil
        cachedCatalogs = nil
        cachedConstellations = nil
    }

    func getPlanets(_ objects: inout [SkyObject]) {
        let planets: [(Body, UIColor, String)] = [
            (Body.sun, AstroUtils.bodyColor(Body.sun), "Q525"),
            (Body.moon, AstroUtils.bodyColor(Body.moon), "Q405"),
            (Body.mercury, AstroUtils.bodyColor(Body.mercury), "Q308"),
            (Body.venus, AstroUtils.bodyColor(Body.venus), "Q313"),
            (Body.mars, AstroUtils.bodyColor(Body.mars), "Q111"),
            (Body.jupiter, AstroUtils.bodyColor(Body.jupiter), "Q319"),
            (Body.saturn, AstroUtils.bodyColor(Body.saturn), "Q193"),
            (Body.uranus, AstroUtils.bodyColor(Body.uranus), "Q324"),
            (Body.neptune, AstroUtils.bodyColor(Body.neptune), "Q332")
        ]

        for (body, color, wid) in planets {
            objects.append(SkyObject(id: body.name.lowercased(),
                                     hip: -1,
                                     wid: wid,
                                     type: body === Body.sun ? .SUN : (body === Body.moon ? .MOON : .PLANET),
                                     body: body,
                                     name: AstroUtils.bodyName(body),
                                     ra: 0,
                                     dec: 0,
                                     magnitude: -2,
                                     color: color))
        }
    }

    func getTypeColor(_ type: SkyObjectType) -> UIColor {
        switch type {
        case .STAR:
            return .white
        case .GALAXY, .GALAXY_CLUSTER:
            return .lightGray
        case .BLACK_HOLE:
            return .magenta
        case .NEBULA:
            return UIColor(red: 0.88, green: 0.81, blue: 0.96, alpha: 1.0)
        case .OPEN_CLUSTER:
            return UIColor(red: 1.0, green: 1.0, blue: 0.88, alpha: 1.0)
        case .GLOBULAR_CLUSTER:
            return UIColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0)
        default:
            return .white
        }
    }

    func parseLines(_ json: String?) -> [(Int, Int)] {
        guard let json, !json.isEmpty, let data = json.data(using: .utf8) else {
            return []
        }

        guard let array = try? JSONSerialization.jsonObject(with: data) as? [[Int]] else {
            return []
        }
        return array.compactMap { segment in
            guard segment.count >= 2 else {
                return nil
            }
            return (segment[0], segment[1])
        }
    }

    func generateId(type: SkyObjectType, name: String) -> String {
        switch type {
        case .STAR, .GALAXY:
            return name.lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .filter { type == .STAR || $0.isLetter || $0.isNumber || $0 == "_" }
        case .BLACK_HOLE:
            return "bh_" + name.lowercased()
                .replacingOccurrences(of: "*", with: "_")
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
                .replacingOccurrences(of: "(", with: "_")
                .replacingOccurrences(of: ")", with: "_")
        default:
            return name.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }
}
