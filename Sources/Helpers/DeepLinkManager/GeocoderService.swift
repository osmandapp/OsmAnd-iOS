//
//  GeocoderService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.04.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class GeocoderService {
    
    func geocode(address: String,
                 completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        
        NSLog("[GeocoderService] Attempting to geocode address: %@", address)
        
        if #available(iOS 26.0, *) {
            Task {
                do {
                    guard let request = MKGeocodingRequest(addressString: address) else {
                        NSLog("[GeocoderService] Error: Failed to initialize MKGeocodingRequest")
                        completion(nil)
                        return
                    }
                    
                    let items = try await request.mapItems
                    
                    if let firstCoord = items.first?.placemark.coordinate {
                        NSLog("[GeocoderService] Success: %f, %f", firstCoord.latitude, firstCoord.longitude)
                        completion(firstCoord)
                    } else {
                        NSLog("[GeocoderService] Warning: No coordinates found for address")
                        completion(nil)
                    }
                } catch {
                    NSLog("[GeocoderService] Error: %@", error.localizedDescription)
                    completion(nil)
                }
            }
        } else {
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error {
                    NSLog("[GeocoderService] [CLGeocoder] Error: %@", error.localizedDescription)
                    completion(nil)
                    return
                }
                
                if let coord = placemarks?.first?.location?.coordinate {
                    NSLog("[GeocoderService] [CLGeocoder] Success: %f, %f", coord.latitude, coord.longitude)
                    completion(coord)
                } else {
                    NSLog("[GeocoderService] [CLGeocoder] Warning: No coordinates found for address")
                    completion(nil)
                }
            }
        }
    }
}
