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
/// - Supports optional bias via `near` coordinate
/// - On earlier versions, it falls back to `CLGeocoder`.
///
/// The result is returned via a completion handler with an optional `CLLocationCoordinate2D`.
/// If geocoding fails or no result is found, `nil` is returned.
///
/// ### Usage Example:
/// ```swift
/// let service = GeocoderService()
/// service.geocode(address: "1 Infinite Loop, Cupertino, CA", near: coordinate) { coordinate in
///     guard let coordinate else { return }
///     print("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
/// }
/// ```

final class GeocoderService {

    // MARK: - Config

    private let searchRadius: CLLocationDistance = 10_000

    // MARK: - Public API

    /// Converts a human-readable address string into geographic coordinates.
    ///
    /// This method performs an asynchronous request. If the address is not found, or if a
    /// network/parsing error occurs, the completion handler returns `nil`.
    ///
    /// - Parameters:
    ///   - address: A string describing a physical location (e.g., "1 Infinite Loop, Cupertino, CA").
    ///   - near: Optional coordinate used as a bias location to improve search relevance.
    ///   - completion: A closure called when the geocoding request finishes.
    ///     Returns an optional `CLLocationCoordinate2D`.
    ///
    /// - Note: Internal process logs and errors are output via `NSLog`.
    func geocode(address: String,
                 near location: CLLocationCoordinate2D? = nil,
                 completion: @escaping (CLLocationCoordinate2D?) -> Void) {

        NSLog("[GeocoderService] Start geocoding: %@", address)

        if let location {
            NSLog("[GeocoderService] Bias: %f, %f (%.0f m)",
                  location.latitude,
                  location.longitude,
                  searchRadius)
        }

        if #available(iOS 26.0, *) {
            geocodeWithMK(address: address,
                          near: location,
                          completion: completion)
        } else {
            geocodeWithCL(address: address,
                          near: location,
                          completion: completion)
        }
    }

    // MARK: - MapKit search

    private func geocodeWithMK(address: String,
                               near location: CLLocationCoordinate2D?,
                               completion: @escaping (CLLocationCoordinate2D?) -> Void) {

        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = address

            if let location {
                request.region = MKCoordinateRegion(
                    center: location,
                    latitudinalMeters: searchRadius,
                    longitudinalMeters: searchRadius
                )
            }

            let search = MKLocalSearch(request: request)

            do {
                let response = try await search.start()

                let coords = response.mapItems.compactMap {
                    $0.placemark.coordinate
                }

                NSLog("[GeocoderService] [MK] candidates: %d", coords.count)

                let best = pickBest(from: coords, near: location)

                if let best {
                    NSLog("[GeocoderService] [MK] result: %f, %f",
                          best.latitude, best.longitude)
                } else {
                    NSLog("[GeocoderService] [MK] no result")
                }

                completion(best)
            } catch {
                NSLog("[GeocoderService] [MK] error: %@",
                      error.localizedDescription)

                geocodeWithCL(address: address,
                              near: location,
                              completion: completion)
            }
        }
    }

    // MARK: - CLGeocoder search

    private func geocodeWithCL(address: String,
                               near location: CLLocationCoordinate2D?,
                               completion: @escaping (CLLocationCoordinate2D?) -> Void) {

        let handler: CLGeocodeCompletionHandler = { [weak self] placemarks, error in
            guard let self else { return }

            if let error {
                NSLog("[GeocoderService] [CL] error: %@",
                      error.localizedDescription)
                completion(nil)
                return
            }

            let coords = placemarks?.compactMap { $0.location?.coordinate } ?? []

            NSLog("[GeocoderService] [CL] candidates: %d", coords.count)

            let best = self.pickBest(from: coords, near: location)

            if let best {
                NSLog("[GeocoderService] [CL] result: %f, %f",
                      best.latitude, best.longitude)
            }

            completion(best)
        }

        let geocoder = CLGeocoder()
        
        if let location {
            let region = CLCircularRegion(center: location,
                                          radius: searchRadius,
                                          identifier: "biasRegion")

            geocoder.geocodeAddressString(address,
                                          in: region,
                                          completionHandler: handler)
        } else {
            geocoder.geocodeAddressString(address,
                                          completionHandler: handler)
        }
    }

    // MARK: - Ranking

    private func pickBest(from coords: [CLLocationCoordinate2D],
                          near location: CLLocationCoordinate2D?) -> CLLocationCoordinate2D? {

        guard !coords.isEmpty else {
            return nil
        }

        guard let location else {
            return coords.first
        }

        let origin = CLLocation(latitude: location.latitude,
                                longitude: location.longitude)

        return coords.min {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                .distance(from: origin)
            <
            CLLocation(latitude: $1.latitude, longitude: $1.longitude)
                .distance(from: origin)
        }
    }
}
