//
//  TracksSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.11.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

@objc enum TracksSortMode: Int, CaseIterable {
    case nearest
    case lastModified
    case nameAZ
    case nameZA
    case newestDateFirst
    case oldestDateFirst
    case longestDistanceFirst
    case shortestDistanceFirst
    case longestDurationFirst
    case shorterDurationFirst
    
    var title: String {
        switch self {
        case .nearest: return localizedString("shared_string_nearest")
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
        case .nearest: return .icCustomNearby
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
    
    static func getByTitle(_ title: String) -> TracksSortMode {
        TracksSortMode.allCases.first(where: { $0.title == title }) ?? .lastModified
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
    
    @objc static var defaultSortModeTitle: String {
        TracksSortMode.lastModified.title
    }
    
    @objc static func title(for mode: TracksSortMode) -> String {
        mode.title
    }
    
    static func sortFoldersWithMode(_ folders: [TrackFolder], mode: TracksSortMode) -> [TrackFolder] {
        switch mode {
        case .nearest:
            return folders
        case .lastModified:
            return folders.sorted { $0.lastModified() > $1.lastModified() }
        case .nameAZ:
            return folders.sorted { $0.getDirName().localizedCaseInsensitiveCompare($1.getDirName()) == .orderedAscending }
        case .nameZA:
            return folders.sorted { $0.getDirName().localizedCaseInsensitiveCompare($1.getDirName()) == .orderedDescending }
        case .newestDateFirst:
            return folders.sorted { $0.lastModified() > $1.lastModified() }
        case .oldestDateFirst:
            return folders.sorted { $0.lastModified() < $1.lastModified() }
        case .longestDistanceFirst:
            return folders.sorted { folder1, folder2 in
                folder1.getFolderAnalysis().totalDistance > folder2.getFolderAnalysis().totalDistance
            }
        case .shortestDistanceFirst:
            return folders.sorted { folder1, folder2 in
                folder1.getFolderAnalysis().totalDistance < folder2.getFolderAnalysis().totalDistance
            }
        case .longestDurationFirst:
            return folders.sorted { folder1, folder2 in
                folder1.getFolderAnalysis().timeSpan > folder2.getFolderAnalysis().timeSpan
            }
        case .shorterDurationFirst:
            return folders.sorted { folder1, folder2 in
                folder1.getFolderAnalysis().timeSpan < folder2.getFolderAnalysis().timeSpan
            }
        }
    }
    
    static func sortTracksWithMode(_ tracks: [GpxDataItem], mode: TracksSortMode) -> [GpxDataItem] {
        switch mode {
        case .nearest:
            return tracks.sorted { TracksSortModeHelper.distanceToGPX(gpx: $0) < TracksSortModeHelper.distanceToGPX(gpx: $1) }
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
        let folderName = folder.getDirName()
        let tracksCount = folder.totalTracksCount
        let basicDescription = String(format: localizedString("folder_tracks_count"), tracksCount)
        
        if let lastModifiedDate = OAUtilities.getFileLastModificationDate(currentFolderPath.appendingPathComponent(folderName)) {
            let lastModifiedString = TracksSortModeHelper.dateFormatter.string(from: lastModifiedDate)
            return "\(lastModifiedString) • \(basicDescription)"
        }

        return basicDescription
    }
    
    static func getTrackDescription(track: GpxDataItem, sortMode: TracksSortMode, includeFolderInfo: Bool = false) -> NSAttributedString {
        let date = TracksSortModeHelper.dateFormatter.string(from: track.lastModifiedTime)
        let creationDate = TracksSortModeHelper.dateFormatter.string(from: track.creationDate)
        let distance = OAOsmAndFormatter.getFormattedDistance(track.totalDistance) ?? localizedString("shared_string_not_available")
        let time = OAOsmAndFormatter.getFormattedTimeInterval(TimeInterval(track.timeSpan / 1000), shortFormat: true) ?? localizedString("shared_string_not_available")
        let waypointCount = "\(track.wptPoints)"
        let fullString = NSMutableAttributedString()
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.textColorSecondary]
        let detailsText = "\(distance) • \(time) • \(waypointCount)"
        let detailsString = NSAttributedString(string: detailsText, attributes: defaultAttributes)
        switch sortMode {
        case .nearest:
            let distanceToTrack: String
            let calculatedDistance = distanceToGPX(gpx: track)
            if calculatedDistance != CGFloat.greatestFiniteMagnitude {
                distanceToTrack = OAOsmAndFormatter.getFormattedDistance(Float(calculatedDistance))
            } else {
                distanceToTrack = localizedString("shared_string_not_available")
            }
            
            var directionAngle: CGFloat = 0.0
            if let analysis = track.getAnalysis(), let start = analysis.getLatLonStart() {
                directionAngle = OADistanceAndDirectionsUpdater.getDirectionAngle(from: OsmAndApp.swiftInstance().locationServices?.lastKnownLocation, toDestinationLatitude: start.latitude, destinationLongitude: start.longitude)
            }
            
            let cityName = track.nearestCity ?? localizedString("shared_string_not_available")
            if let locationAttributedString = createImageAttributedString(named: "location.north.fill", tintColor: UIColor.iconColorActive, defaultAttributes: defaultAttributes, rotate: true, rotationAngle: directionAngle) {
                fullString.append(locationAttributedString)
                fullString.append(NSAttributedString(string: " "))
            }
            
            let directionString = distanceToTrack + ", "
            let directionAttributedString = NSAttributedString(string: directionString, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.iconColorActive])
            let cityString = NSAttributedString(string: "\(cityName) | ", attributes: defaultAttributes)
            fullString.append(directionAttributedString)
            fullString.append(cityString)
            fullString.append(detailsString)
        case .lastModified:
            let dateString = NSAttributedString(string: "\(date) | ", attributes: defaultAttributes)
            fullString.append(dateString)
            fullString.append(detailsString)
        case .nameAZ, .nameZA:
            if includeFolderInfo {
                let folderName: String
                if let capitalizedFolderName = OAUtilities.capitalizeFirstLetter(track.gpxFolderName), !capitalizedFolderName.isEmpty {
                    folderName = capitalizedFolderName
                } else {
                    folderName = localizedString("shared_string_gpx_tracks")
                }
                
                fullString.append(detailsString)
                fullString.append(NSAttributedString(string: " | ", attributes: defaultAttributes))
                if let folderAttributedString = createImageAttributedString(named: "folder", tintColor: UIColor.textColorSecondary, defaultAttributes: defaultAttributes, rotate: false) {
                    fullString.append(folderAttributedString)
                    fullString.append(NSAttributedString(string: " \(folderName)", attributes: defaultAttributes))
                }
            } else {
                fullString.append(detailsString)
            }
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
        
        return fullString
    }
    
    static func distanceToGPX(gpx: GpxDataItem) -> CGFloat {
        guard let currentLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation else { return CGFloat.greatestFiniteMagnitude }
        guard let analysis = gpx.getAnalysis(), let start = analysis.getLatLonStart(), CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(start.latitude, start.longitude)) else { return CGFloat.greatestFiniteMagnitude }
        
        return OADistanceAndDirectionsUpdater.getDistanceFrom(currentLocation, toDestinationLatitude: start.latitude, destinationLongitude: start.longitude)
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
}
