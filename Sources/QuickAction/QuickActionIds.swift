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
    case markerActionId = 2
    case favoriteActionId = 3
    case showHideFavoritesActionId = 4
    case showHidePoiActionId = 5
    case gpxActionId = 6
    case parkingActionId = 7
    case takeAudioNoteActionId = 8
    case takeVideoNoteActionId = 9
    case takePhotoNoteActionId = 10
    case navVoiceActionId = 11
    case addOsmBugActionId = 12
    case addPoiActionId = 13
    case mapStyleActionId = 14
    case mapOverlayActionId = 15
    case mapUnderlayActionId = 16
    case mapSourceActionId = 17
    case showHideLocalOsmChangesActionId = 18 // action 18 exists only in ios
    case navDirectionsFromActionId = 19
    case navAddDestinationActionId = 20
    case navReplaceDestinationActionId = 21
    case navAddFirstIntermediateActionId = 22
    case navAutoZoomMapActionId = 23
    case showHideOsmBugActionId = 24
    case navStartStopActionId = 25
    case navResumePauseActionId = 26
    case dayNightModeActionId = 27
    case showHideGpxTracksActionId = 28
    case contourLinesActionId = 29
    case terrainActionId = 30
    case showHideTransportLinesActionId = 31
    case switchProfileActionId = 32
    case showHideMapillaryActionId = 33
    case navRemoveNextDestinationActionId = 34
    // action 35 is skipped in android
    case displayPositionActionId = 36
    case routeActionId = 37
    // action 38 is skipped in android
    case showHideTemperatureLayerActionId = 39
    case showHidePrecipitationLayerActionId = 40
    case showHideWindLayerActionId = 41
    case showHideCloudLayerActionId = 42
    case showHideAirPressureLayerActionId = 43
    case openWeatherActionId = 44
    case locationSimulationActionId = 45
    case mapScrollUpActionId = 46
    case mapScrollDownActionId = 47
    case mapScrollLeftActionId = 48
    case mapScrollRightActionId = 49
    case mapZoomInActionId = 50
    case mapZoomOutActionId = 51
    case moveToMyLocationActionId = 52
    case nextProfileActionId = 53
    case previousProfileActionId = 54
    case terrainColorSchemeActionId = 55
    case continuousMapZoomInActionId = 56
    case continuousMapZoomOutActionId = 57
    case showHideCycleRoutesActionId = 58
    case showHideMtbRoutesActionId = 59
    case showHideHikingRoutesActionId = 60
    case showHideDifficultyClasificationActionId = 61
    case showHideSkiSlopesRoutesActionId = 62
    case showHideHorseRoutesActionId = 63
    case showHideWhitewaterSportsRoutesActionId = 64
    case showHideFitnessTrailsRoutesActionId = 65
    case showHideRunningRoutesActionId = 66
    case openWunderlinqDatagridAction = 67
    case changeMapOrientationAction = 68
    case openNavigationViewAction = 69
    case openSearchViewAction = 70
    case showHideDrawerAction = 71
    case navigatePreviousScreenAction = 72
}
