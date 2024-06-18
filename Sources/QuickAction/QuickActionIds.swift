//
//  QuickActionIds.swift
//  OsmAnd Maps
//
//  Created by Skalii on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objc(EOAQuickActionIds)
enum QuickActionIds: Int {
    case unsupportedId = -1
    case newActionId = 1
    case markerActionId
    case favoriteActionId
    case showHideFavoritesActionId
    case showHidePoiActionId
    case gpxActionId
    case parkingActionId
    case takeAudioNoteActionId
    case takeVideoNoteActionId
    case takePhotoNoteActionId
    case navVoiceActionId
    case addOsmBugActionId
    case addPoiActionId
    case mapStyleActionId
    case mapOverlayActionId
    case mapUnderlayActionId
    case mapSourceActionId
    case showHideLocalOsmChangesActionId // 18 only ios
    case navDirectionsFromActionId
    case navAddDestinationActionId
    case navReplaceDestinationActionId
    case navAddFirstIntermediateActionId
    case navAutoZoomMapActionId
    case showHideOsmBugActionId
    case navStartStopActionId
    case navResumePauseActionId
    case dayNightModeActionId
    case showHideGpxTracksActionId
    case contourLinesActionId
    case terrainActionId
    case showHideTransportLinesActionId
    case switchProfileActionId
    case showHideMapillaryActionId
    case navRemoveNextDestinationActionId
    case displayPositionActionId = 36
    case routeActionId
    case showHideTemperatureLayerActionId = 39
    case showHidePrecipitationLayerActionId
    case showHideWindLayerActionId
    case showHideCloudLayerActionId
    case showHideAirPressureLayerActionId
    case openWeatherActionId
    case locationSimulationActionId
}
