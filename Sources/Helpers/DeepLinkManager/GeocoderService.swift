//
//  GeocoderService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.04.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

/// A service responsible for converting a textual address into geographic coordinates.
///
/// `GeocoderService` provides a unified API for geocoding across different iOS versions.
/// - On iOS 26 and later, it uses `MKGeocodingRequest` with async/await.
/// - On earlier versions, it falls back to `CLGeocoder`.
///
/// The result is returned via a completion handler with an optional `CLLocationCoordinate2D`.
/// If geocoding fails or no result is found, `nil` is returned.
///
/// ### Usage Example:
/// ```swift
/// let service = GeocoderService()
/// service.geocode(address: "1 Infinite Loop, Cupertino, CA") { coordinate in
///     guard let coordinate else { return }
///     print("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
/// }
/// ```
final class GeocoderService {
    /// Converts a human-readable address string into geographic coordinates.
    ///
    /// This method performs an asynchronous request. If the address is not found, or if a
    /// network/parsing error occurs, the completion handler returns `nil`.
    ///
    /// - Parameters:
    ///   - address: A string describing a physical location (e.g., "1 Infinite Loop, Cupertino, CA").
    ///   - completion: A closure called when the geocoding request finishes.
    ///     Returns an optional `CLLocationCoordinate2D`.
    ///
    /// - Note: Internal process logs and errors are output via `NSLog`.
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
