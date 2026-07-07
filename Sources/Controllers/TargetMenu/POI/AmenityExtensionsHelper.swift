//
//  AmenityExtensionsHelper.swift
//  OsmAnd
//
//  Created by Xcode Assistant on 07/04/2026.
//

@objcMembers
final class AmenityExtensionsHelper: NSObject {
    static let MIN_UPHILL_DOWNHILL_FIXED_TO_SHOW: Float = 10.0
    static let MIN_UPHILL_DOWNHILL_PERCENT_TO_SHOW: Float = 0.0 // customizable (default 0)
    
    private static let wikidata = "wikidata"
    private static let wikipedia = "wikipedia"
    private static let wikimediaCommons = "wikimedia_commons"
    private static let mapillary = "mapillary"
    private static let image = "image"
    
    private static let osmImageKey = "osm_image"
    
    private static let tags = [
        image,
        mapillary,
        wikidata,
        wikipedia,
        wikimediaCommons
    ]
    
    static func imageParams(from extensions: [String: String]) -> [String: String] {
        tags.reduce(into: [:]) { result, tag in
            guard let value = extensions[tag], !value.isEmpty else { return }
            
            let key = tag == image ? osmImageKey : tag
            result[key] = value.removingPercentEncoding ?? value
        }
    }
    
    static func getAmenityMetricsFormatted(_ amenity: OAPOI) -> String? {
        let distMeters = getAmenityDistanceMeters(amenity)
        let upMeters = KAlgorithms.shared.parseFloatSilently(input: amenity.getAdditionalInfo(TravelGpx.DIFF_ELEVATION_UP), def: 0)
        let downMeters = KAlgorithms.shared.parseFloatSilently(input: amenity.getAdditionalInfo(TravelGpx.DIFF_ELEVATION_DOWN), def: 0)
        
        guard let dist = OAOsmAndFormatter.getFormattedDistance(distMeters, with: OsmAndFormatterParams.noTrailingZeros),
              let uphill = OAOsmAndFormatter.getFormattedDistance(upMeters, with: OsmAndFormatterParams.noTrailingZeros),
              let downhill = OAOsmAndFormatter.getFormattedDistance(downMeters, with: OsmAndFormatterParams.noTrailingZeros) else {
            return nil
        }
        
        var metrics = [String]()
        if distMeters > 0 {
            metrics.append(TrkSegment.SegmentSlopeType.flat.symbol + dist)
            if upMeters >= MIN_UPHILL_DOWNHILL_FIXED_TO_SHOW &&
                upMeters / distMeters * 100 > MIN_UPHILL_DOWNHILL_PERCENT_TO_SHOW {
                metrics.append(TrkSegment.SegmentSlopeType.uphill.symbol + uphill)
            }
            if downMeters >= MIN_UPHILL_DOWNHILL_FIXED_TO_SHOW &&
                downMeters / distMeters * 100 > MIN_UPHILL_DOWNHILL_PERCENT_TO_SHOW {
                metrics.append(TrkSegment.SegmentSlopeType.downhill.symbol + downhill)
            }
        }
        
        return metrics.isEmpty ? nil : metrics.joined(separator: " ")
    }
    
    private static func getAmenityDistanceMeters(_ amenity: OAPOI) -> Float {
        let distanceTag = amenity.getAdditionalInfo(TravelGpx.DISTANCE) ?? ""
        var km = KAlgorithms.shared.parseFloatSilently(input: distanceTag, def: 0)
        if km > 0 && !distanceTag.contains(".") {
            // Before 1 Apr 2025 distance format was MMMMM (meters, no fractional part).
            // Since 1 Apr 2025 format has been fixed to KM.D (km, 1 fractional digit).
            km /= 1000
        }
        return km * 1000
    }
}
