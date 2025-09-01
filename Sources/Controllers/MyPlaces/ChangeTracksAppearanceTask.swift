//
//  ChangeTracksAppearanceTask.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 20.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class ChangeTracksAppearanceTask: NSObject {
    private let gpxDbHelper: GpxDbHelper?
    private let data: AppearanceData
    private let items: Set<TrackItem>
    private let callback: (() -> Void)?
    
    init(data: AppearanceData, items: Set<TrackItem>, callback: (() -> Void)? = nil) {
        self.data = data
        self.items = items
        self.callback = callback
        gpxDbHelper = GpxDbHelper.shared
    }
    
    private func doInBackground() {
        let resetAnything = data.shouldResetAnything()
        for track in items {
            if track.isShowCurrentTrack {
                updateCurrentTrackAppearance()
            } else if let file = track.getFile() {
                let gpxFile = resetAnything ? getGpxFile(for: file) : nil
                updateTrackAppearance(file: file, gpxFile: gpxFile)
            }
        }
    }
    
    private func updateTrackAppearance(file: KFile, gpxFile: GpxFile?) {
        let callback = getGpxDataItemCallback(gpxFile: gpxFile)
        if let dataItem = gpxDbHelper?.getItem(file: file, callback: callback) {
            updateTrackAppearance(item: dataItem, gpxFile: gpxFile)
        }
    }
    
    private func getGpxFile(for file: KFile) -> GpxFile? {
        let gpxFile = GpxUtilities.shared.loadGpxFile(file: file)
        return gpxFile.error == nil ? gpxFile : nil
    }
    
    private func updateCurrentTrackAppearance() {
        let settings = OAAppSettings.sharedManager()
        if let color: Int = data.getParameter(for: GpxParameter.color) {
            settings.currentTrackColor.set(Int32(color))
        }
        if let coloringType: String = data.getParameter(for: GpxParameter.coloringType) {
            let requiredValue = ColoringType.companion.requireValueOf(purpose: ColoringPurpose.track, name: coloringType)
            settings.currentTrackColoringType.set(Int32(requiredValue.ordinal))
            if let routeInfoAttribute = ColoringType.companion.getRouteInfoAttribute(name: coloringType) {
                settings.routeInfoAttribute.set(routeInfoAttribute)
            }
        }
        if let width: String = data.getParameter(for: GpxParameter.width) {
            settings.currentTrackWidth.set(width)
        }
        if let showArrows: Bool = data.getParameter(for: GpxParameter.showArrows) {
            settings.currentTrackShowArrows.set(showArrows)
        }
        if let showStartFinish: Bool = data.getParameter(for: GpxParameter.showStartFinish) {
            settings.currentTrackShowStartFinish.set(showStartFinish)
        }
        if let trackVisualizationType: String = data.getParameter(for: GpxParameter.trackVisualizationType),
           let intValue = Int32(trackVisualizationType) {
            settings.currentTrackVisualization3dByType.set(intValue)
        }
        if let gradientPalette: String = data.getParameter(for: GpxParameter.colorPalette) {
            settings.gradientPalettes.set(gradientPalette)
        }
    }
    
    private func getGpxDataItemCallback(gpxFile: GpxFile?) -> GpxDbHelperGpxDataItemCallback {
        let handler = GpxDataItemHandler()
        handler.onGpxDataItemReady = { [weak self] item in
            self?.updateTrackAppearance(item: item, gpxFile: gpxFile)
        }
        
        return handler
    }
    
    private func updateTrackAppearance(item: GpxDataItem, gpxFile: GpxFile?) {
        for parameter in GpxParameter.companion.getAppearanceParameters() {
            if data.shouldResetParameter(parameter), let gpxFile = gpxFile {
                item.readGpxAppearanceParameter(gpxFile: gpxFile, parameter: parameter)
            } else if let value: Any = data.getParameter(for: parameter) {
                item.setParameter(parameter: parameter, value: value)
            }
        }
        
        gpxDbHelper?.updateDataItem(item: item)
    }
    
    private func onPostExecute() {
        callback?()
    }
    
    func execute() {
        DispatchQueue.global(qos: .default).async {
            self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute()
            }
        }
    }
}
