//
//  TracksSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

protocol SortableFolder {
    func lastModified() -> Int64
    func getDirName(includingSubdirs: Bool) -> String
    func getFolderAnalysis() -> TrackFolderAnalysis
}

@objc enum TracksSortMode: Int, CaseIterable {
    case nearestToCurrentLocation
    case lastModified
    case nameAZ
    case nameZA
    case newestDateFirst
    case oldestDateFirst
    case longestDistanceFirst
    case shortestDistanceFirst
    case longestDurationFirst
    case shorterDurationFirst
    case nearestToMapCenter

    var value: String {
        switch self {
        case .nearestToCurrentLocation: return "NEAREST"
        case .nearestToMapCenter: return "NEAREST_TO_MAP_CENTER"
        case .lastModified: return "LAST_MODIFIED"
        case .nameAZ: return "NAME_ASCENDING"
        case .nameZA: return "NAME_DESCENDING"
        case .newestDateFirst: return "DATE_ASCENDING"
        case .oldestDateFirst: return "DATE_DESCENDING"
        case .longestDistanceFirst: return "DISTANCE_DESCENDING"
        case .shortestDistanceFirst: return "DISTANCE_ASCENDING"
        case .longestDurationFirst: return "DURATION_DESCENDING"
        case .shorterDurationFirst: return "DURATION_ASCENDING"
        }
    }
    
    var title: String {
        switch self {
        case .nearestToCurrentLocation: return localizedString("sort_by_nearest_to_current_location")
        case .nearestToMapCenter: return localizedString("sort_by_nearest_to_map_center")
        case .lastModified: return localizedString("sort_last_modified")
        case .nameAZ: return localizedString("track_sort_az")
        case .nameZA: return localizedString("track_sort_za")
        case .newestDateFirst: return localizedString("newest_date_first")
        case .oldestDateFirst: return localizedString("oldest_date_first")
        case .longestDistanceFirst: return localizedString("longest_distance_first")
        case .shortestDistanceFirst: return localizedString("shortest_distance_first")
        case .longestDurationFirst: return localizedString("longest_duration_first")
        case .shorterDurationFirst: return localizedString("shorter_duration_first")
        }
    }
    
    var image: UIImage? {
        switch self {
        case .nearestToCurrentLocation: return .icCustomNearby
        case .nearestToMapCenter: return .icCustomNearestMapCenter
        case .lastModified: return .icCustomLastModified
        case .nameAZ: return .icCustomSortNameAscending
        case .nameZA: return .icCustomSortNameDescending
        case .newestDateFirst: return .icCustomSortDateNewest
        case .oldestDateFirst: return .icCustomSortDateOldest
        case .longestDistanceFirst: return .icCustomSortLongToShort
        case .shortestDistanceFirst: return .icCustomSortShortToLong
        case .longestDurationFirst: return .icCustomSortDurationLongToShort
        case .shorterDurationFirst: return .icCustomSortDurationShortToLong
        }
    }
    
    static func getByValue(_ value: String) -> TracksSortMode {
        TracksSortMode.allCases.first(where: { $0.value == value }) ?? .lastModified
    }

    var isDistanceOriented: Bool {
        isCurrentLocationDistanceOriented || isMapCenterDistanceOriented
    }

    var isCurrentLocationDistanceOriented: Bool {
        self == .nearestToCurrentLocation
    }

    var isMapCenterDistanceOriented: Bool {
        self == .nearestToMapCenter
    }
}

@objc final class TracksSortModeHelper: NSObject {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
    
    @objc static func defaultSortMode(for sortEntryId: String?) -> TracksSortMode {
        sortEntryId == nil || sortEntryId?.isEmpty == true || sortEntryId == "rec" || sortEntryId == "import"
        ? .lastModified
        : .nameAZ
    }
    
    @objc static func getDefaultSortModeTitle(for sortEntryId: String?) -> String {
        title(for: defaultSortMode(for: sortEntryId))
    }

    @objc static func getDefaultSortModeValue(for sortEntryId: String?) -> String {
        defaultSortMode(for: sortEntryId).value
    }
    
    @objc static private func title(for mode: TracksSortMode) -> String {
        mode.title
    }
    
    static func sortFoldersWithMode(_ folders: [SortableFolder], mode: TracksSortMode) -> [SortableFolder] {
        switch mode {
        case .nearestToCurrentLocation, .nearestToMapCenter:
            return folders
        case .lastModified:
            return folders.sorted { $0.lastModified() > $1.lastModified() }
        case .nameAZ:
            return folders.sorted { $0.getDirName(includingSubdirs: false).localizedCaseInsensitiveCompare($1.getDirName(includingSubdirs: false)) == .orderedAscending }
        case .nameZA:
            return folders.sorted { $0.getDirName(includingSubdirs: false).localizedCaseInsensitiveCompare($1.getDirName(includingSubdirs: false)) == .orderedDescending }
        case .newestDateFirst:
            return folders.sorted { $0.lastModified() > $1.lastModified() }
        case .oldestDateFirst:
            return folders.sorted { $0.lastModified() < $1.lastModified() }
        case .longestDistanceFirst:
            return folders.sorted { $0.getFolderAnalysis().totalDistance > $1.getFolderAnalysis().totalDistance }
        case .shortestDistanceFirst:
            return folders.sorted { $0.getFolderAnalysis().totalDistance < $1.getFolderAnalysis().totalDistance }
        case .longestDurationFirst:
            return folders.sorted { $0.getFolderAnalysis().timeSpan > $1.getFolderAnalysis().timeSpan }
        case .shorterDurationFirst:
            return folders.sorted { $0.getFolderAnalysis().timeSpan < $1.getFolderAnalysis().timeSpan }
        }
    }
    
    static func sortTracksWithMode(_ tracks: [GpxDataItem], mode: TracksSortMode) -> [GpxDataItem] {
        switch mode {
        case .nearestToCurrentLocation, .nearestToMapCenter:
            let referenceLocation = referenceLocation(for: mode)
            return tracks.sorted { distanceToGPX(gpx: $0, from: referenceLocation) < distanceToGPX(gpx: $1, from: referenceLocation) }
        case .lastModified:
            return tracks.sorted { $0.lastModifiedTime > $1.lastModifiedTime }
        case .nameAZ:
            return tracks.sorted { $0.gpxFileName.localizedCaseInsensitiveCompare($1.gpxFileName) == .orderedAscending }
        case .nameZA:
            return tracks.sorted { $0.gpxFileName.localizedCaseInsensitiveCompare($1.gpxFileName) == .orderedDescending }
        case .newestDateFirst:
            return tracks.sorted { $0.creationDate > $1.creationDate }
        case .oldestDateFirst:
            return tracks.sorted { $0.creationDate < $1.creationDate }
        case .longestDistanceFirst:
            return tracks.sorted { $0.totalDistance > $1.totalDistance }
        case .shortestDistanceFirst:
            return tracks.sorted { $0.totalDistance < $1.totalDistance }
        case .longestDurationFirst:
            return tracks.sorted { $0.timeSpan > $1.timeSpan }
        case .shorterDurationFirst:
            return tracks.sorted { $0.timeSpan < $1.timeSpan }
        }
    }
    
    static func descriptionForFolder(folder: TrackFolder, currentFolderPath: String) -> String {
        let tracksCount = folder.totalTracksCount
        let basicDescription = formattedTracksCount(Int(tracksCount))
        let lastModifiedString = TracksSortModeHelper.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(folder.lastModified() / 1000)))
        if !lastModifiedString.isEmpty {
            return "\(lastModifiedString) • \(basicDescription)"
        } else {
            return basicDescription
        }
    }

    static func formattedTracksCount(_ count: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString("folder_tracks_count", comment: ""), count, NumberFormatter.localizedCount(count))
    }
    
    @objc static func getTrackDescription(track: GpxDataItem, sortMode: TracksSortMode, includeFolderInfo: Bool = false) -> NSAttributedString {
        let date = TracksSortModeHelper.dateFormatter.string(from: track.lastModifiedTime)
        let creationDate = TracksSortModeHelper.dateFormatter.string(from: track.creationDate)
        let distance = OAOsmAndFormatter.getFormattedDistance(track.totalDistance) ?? localizedString("shared_string_not_available")
        let duration = track.getAnalysis()?.getDurationInSeconds() ?? 0
        let time = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(duration), shortFormat: true) ?? localizedString("shared_string_not_available")
        let waypointCount = NumberFormatter.localizedCount(track.wptPoints)
        let fullString = NSMutableAttributedString()
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.textColorSecondary]
        let detailsText = "\(distance) • \(time) • \(waypointCount)"
        let detailsString = NSAttributedString(string: detailsText, attributes: defaultAttributes)
        switch sortMode {
        case .nearestToCurrentLocation, .nearestToMapCenter:
            let distanceToTrack: String
            let referenceLocation = referenceLocation(for: sortMode)
            let calculatedDistance = distanceToGPX(gpx: track, from: referenceLocation)
            if calculatedDistance != CGFloat.greatestFiniteMagnitude {
                distanceToTrack = OAOsmAndFormatter.getFormattedDistance(Float(calculatedDistance))
            } else {
                distanceToTrack = localizedString("shared_string_not_available")
            }
            
            var directionAngle: CGFloat = 0.0
            if let analysis = track.getAnalysis(), let start = analysis.getLatLonStart() {
                if sortMode.isMapCenterDistanceOriented {
                    let mapViewController = OARootViewController.instance().mapPanel.mapViewController
                    directionAngle = OADistanceAndDirectionsUpdater.directionAngle(
                        from: referenceLocation,
                        sourceDirection: Double(mapViewController.azimuth()),
                        toDestinationLatitude: start.latitude,
                        destinationLongitude: start.longitude
                    )
                } else {
                    directionAngle = OADistanceAndDirectionsUpdater.directionAngle(
                        from: referenceLocation,
                        toDestinationLatitude: start.latitude,
                        destinationLongitude: start.longitude
                    )
                }
            }
            
            let cityName = track.nearestCity ?? localizedString("shared_string_not_available")
            let directionColor: UIColor = sortMode.isMapCenterDistanceOriented ? .iconColorDirectionMapCenter : .iconColorActive
            if let locationAttributedString = createImageAttributedString(named: "location.north.fill", tintColor: directionColor, defaultAttributes: defaultAttributes, rotate: true, rotationAngle: directionAngle) {
                fullString.append(locationAttributedString)
                fullString.append(NSAttributedString(string: " "))
            }
            
            let directionString = distanceToTrack + ", "
            let directionAttributedString = NSAttributedString(string: directionString, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: directionColor])
            let cityString = NSAttributedString(string: "\(cityName) | ", attributes: defaultAttributes)
            fullString.append(directionAttributedString)
            fullString.append(cityString)
            fullString.append(detailsString)
        case .lastModified:
            let dateString = NSAttributedString(string: "\(date) | ", attributes: defaultAttributes)
            fullString.append(dateString)
            fullString.append(detailsString)
        case .nameAZ, .nameZA:
            fullString.append(detailsString)
        case .newestDateFirst, .oldestDateFirst:
            let dateString = NSAttributedString(string: "\(creationDate) | ", attributes: defaultAttributes)
            fullString.append(dateString)
            fullString.append(detailsString)
        case .longestDistanceFirst, .shortestDistanceFirst:
            fullString.append(detailsString)
        case .longestDurationFirst, .shorterDurationFirst:
            let durationFirstDetailsString = NSAttributedString(string: "\(time) • \(distance) • \(waypointCount)", attributes: defaultAttributes)
            fullString.append(durationFirstDetailsString)
        }
        
        if includeFolderInfo {
            appendFolderInfo(to: fullString, track: track, defaultAttributes: defaultAttributes)
        }
        
        return fullString
    }
    
    static func referenceLocation(for sortMode: TracksSortMode) -> CLLocation? {
        if sortMode.isMapCenterDistanceOriented {
            let coordinate = OARootViewController.instance().mapPanel.mapViewController.getMapLocation().coordinate
            guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        return OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
    }

    private static func distanceToGPX(gpx: GpxDataItem, from referenceLocation: CLLocation?) -> CGFloat {
        guard let referenceLocation else { return CGFloat.greatestFiniteMagnitude }
        guard let analysis = gpx.getAnalysis(), let start = analysis.getLatLonStart(), CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(start.latitude, start.longitude)) else { return CGFloat.greatestFiniteMagnitude }
        
        return OADistanceAndDirectionsUpdater.distance(from: referenceLocation, toDestinationLatitude: start.latitude, destinationLongitude: start.longitude)
    }
    
    static func createImageAttributedString(named imageName: String, tintColor: UIColor, defaultAttributes: [NSAttributedString.Key: Any], rotate: Bool = false, rotationAngle: CGFloat = 0) -> NSAttributedString? {
        guard let image = UIImage(systemName: imageName)?.withTintColor(tintColor, renderingMode: .alwaysTemplate) else { return nil }
        let attachment = NSTextAttachment()
        var finalImage = image
        if rotate {
            finalImage = image.rotateWithDiagonalSize(radians: rotationAngle) ?? image
        }
        
        attachment.image = finalImage
        if let font = defaultAttributes[.font] as? UIFont {
            let fontHeight = font.capHeight
            let scaleFactor: CGFloat = 1.2
            let adjustedHeight = fontHeight * scaleFactor
            let adjustedYPosition = (fontHeight - adjustedHeight) / 2
            attachment.bounds = CGRect(x: 0, y: adjustedYPosition, width: adjustedHeight + 2, height: rotate ? adjustedHeight + 2 : adjustedHeight)
        }
        
        return NSAttributedString(attachment: attachment)
    }
    
    private static func appendFolderInfo(to attributedString: NSMutableAttributedString, track: GpxDataItem, defaultAttributes: [NSAttributedString.Key: Any]) {
        let folderName: String
        if let capitalizedFolderName = OAUtilities.capitalizeFirstLetter(shortFolderPath(track.gpxFolderName)), !capitalizedFolderName.isEmpty {
            folderName = capitalizedFolderName
        } else {
            folderName = localizedString("shared_string_gpx_tracks")
        }
        
        attributedString.append(NSAttributedString(string: " | ", attributes: defaultAttributes))
        if let folderAttributedString = createImageAttributedString(named: "folder", tintColor: .textColorSecondary, defaultAttributes: defaultAttributes, rotate: false) {
            attributedString.append(folderAttributedString)
            attributedString.append(NSAttributedString(string: " \(folderName)", attributes: defaultAttributes))
        } else {
            attributedString.append(NSAttributedString(string: folderName, attributes: defaultAttributes))
        }
    }
    
    private static func shortFolderPath(_ folderPath: String) -> String {
        let pathComponents = folderPath.split(separator: "/", omittingEmptySubsequences: true).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if pathComponents.count > 2 {
            return "\(pathComponents[0]) / ... / \(pathComponents[pathComponents.count - 1])"
        }
        
        return pathComponents.joined(separator: " / ")
    }
}

extension TrackFolder: SortableFolder { }
extension SmartFolder: SortableFolder { }
