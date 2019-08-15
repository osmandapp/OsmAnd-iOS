//
//  OAQuickActionFactory.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionFactory.h"
#import "OAQuickAction.h"
#import "Localization.h"
#import "OAFavoriteAction.h"
#import "OAGPXAction.h"
#import "OAMarkerAction.h"
#import "OAAddOSMBugAction.h"
#import "OAAddPOIAction.h"
#import "OAParkingAction.h"
#import "OAShowHideFavoritesAction.h"
#import "OAShowHideGpxTracksAction.h"
#import "OAShowHidePoiAction.h"
#import "OAShowHideOSMBugAction.h"
#import "OAShowHideLocalOSMChanges.h"
#import "OAMapStyleAction.h"
#import "OAMapOverlayAction.h"
#import "OAMapUnderlayAction.h"
#import "OAMapSourceAction.h"
#import "OADayNightModeAction.h"
#import "OANavVoiceAction.h"
#import "OANavAddDestinationAction.h"
#import "OANavAddFirstIntermediateAction.h"
#import "OANavReplaceDestinationAction.h"
#import "OANavAutoZoomMapAction.h"
#import "OANavStartStopAction.h"
#import "OANavResumePauseAction.h"
#import "OANewAction.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAParkingPositionPlugin.h"

@implementation OAQuickActionFactory

-(NSString *) quickActionListToString:(NSArray<OAQuickAction *> *) quickActions
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:quickActions options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

-(NSArray <OAQuickAction *> *) parseActiveActionsList:(NSString *) json
{
    return [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

+(NSArray<OAQuickAction *> *) produceTypeActionsListWithHeaders:(NSArray<OAQuickAction *> *)active
{
    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray new];
    [quickActions addObject:[[OAQuickAction alloc] initWithType:0 name:OALocalizedString(@"create_items")]];
    [quickActions addObject:[[OAFavoriteAction alloc] init]];
    [quickActions addObject:[[OAGPXAction alloc] init]];
    OAQuickAction *marker = [[OAMarkerAction alloc] init];
    
    if (![marker hasInstanceInList:active])
        [quickActions addObject:marker];
    
    //    TODO: add audio/video notes actions when plugin is implemented
//    if (OsmandPlugin.getEnabledPlugin(AudioVideoNotesPlugin.class) != null) {
//        QuickAction audio = new TakeAudioNoteAction();
//        QuickAction photo = new TakePhotoNoteAction();
//        QuickAction video = new TakeVideoNoteAction();
//
//        if (!audio.hasInstanceInList(active)) {
//            quickActions.add(audio);
//        }
//
//        if (!photo.hasInstanceInList(active)) {
//            quickActions.add(photo);
//        }
//
//        if (!video.hasInstanceInList(active)) {
//            quickActions.add(video);
//        }
//    }
    
    BOOL osmEditingEnabled = [OAPlugin getEnabledPlugin:OAOsmEditingPlugin.class] != nil;
    if (osmEditingEnabled)
    {
        [quickActions addObject:[[OAAddPOIAction alloc] init]];
        [quickActions addObject:[[OAAddOSMBugAction alloc] init]];
    }
    
    if ([OAPlugin getEnabledPlugin:OAParkingPositionPlugin.class])
    {
        OAQuickAction *parking = [[OAParkingAction alloc] init];
        if (![parking hasInstanceInList:active])
            [quickActions addObject:parking];
    }
    
    [quickActions addObject:[[OAQuickAction alloc] initWithType:0 name:OALocalizedString(@"configure_map")]];
    
    OAQuickAction *favorites = [[OAShowHideFavoritesAction alloc] init];
    if (![favorites hasInstanceInList:active])
        [quickActions addObject:favorites];
    
    [quickActions addObject:[[OAShowHideGPXTracksAction alloc] init]];
    [quickActions addObject:[[OAShowHidePoiAction alloc] init]];
    
    if (osmEditingEnabled)
    {
        OAQuickAction *showHideNotes = [[OAShowHideOSMBugAction alloc] init];
        OAQuickAction *showHideEdits = [[OAShowHideLocalOSMChanges alloc] init];
        if (![showHideEdits hasInstanceInList:active])
            [quickActions addObject:showHideEdits];
        if (![showHideNotes hasInstanceInList:active])
            [quickActions addObject:showHideNotes];
        
    }
    [quickActions addObject:[[OAMapStyleAction alloc] init]];
    [quickActions addObject:[[OAMapSourceAction alloc] init]];
    [quickActions addObject:[[OAMapOverlayAction alloc] init]];
    [quickActions addObject:[[OAMapUnderlayAction alloc] init]];
    [quickActions addObject:[[OADayNightModeAction alloc] init]];
    
    OAQuickAction *voice = [[OANavVoiceAction alloc] init];
    OAQuickAction *addDestionation = [[OANavAddDestinationAction alloc] init];
    OAQuickAction *addFirstIntermediate = [[OANavAddFirstIntermediateAction alloc] init];
    OAQuickAction *replaceDestination = [[OANavReplaceDestinationAction alloc] init];
    OAQuickAction *autoZoomMap = [[OANavAutoZoomMapAction alloc] init];
    OAQuickAction *startStopNavigation = [[OANavStartStopAction alloc] init];
    OAQuickAction *resumePauseNavigation = [[OANavResumePauseAction alloc] init];
    
    NSMutableArray<OAQuickAction *> *navigationQuickActions = [NSMutableArray new];
    if (![voice hasInstanceInList:active])
        [navigationQuickActions addObject:voice];
    if (![addDestionation hasInstanceInList:active])
        [navigationQuickActions addObject:addDestionation];
    if (![addFirstIntermediate hasInstanceInList:active])
        [navigationQuickActions addObject:addFirstIntermediate];
    if (![replaceDestination hasInstanceInList:active])
        [navigationQuickActions addObject:replaceDestination];
    if (![autoZoomMap hasInstanceInList:active])
        [navigationQuickActions addObject:autoZoomMap];
    if (![startStopNavigation hasInstanceInList:active])
        [navigationQuickActions addObject:startStopNavigation];
    if (![resumePauseNavigation hasInstanceInList:active])
        [navigationQuickActions addObject:resumePauseNavigation];
    
    
    if (navigationQuickActions.count > 0)
    {
        [quickActions addObject:[[OAQuickAction alloc] initWithType:0 name:OALocalizedString(@"routing_settings")]];
        [quickActions addObjectsFromArray:navigationQuickActions];
    }
    
    return [NSArray arrayWithArray:quickActions];
}

+(OAQuickAction *) newActionByType:(NSInteger) type
{
    
    switch (type) {
            
        case EOAQuickActionTypeNew:
            return [[OANewAction alloc] init];
            
        case EOAQuickActionTypeMarker:
            return [[OAMarkerAction alloc] init];
            
        case EOAQuickActionTypeFavorite:
            return [[OAFavoriteAction alloc] init];
            
        case EOAQuickActionTypeShowFavorite:
            return [[OAShowHideFavoritesAction alloc] init];
            
        case EOAQuickActionTypeTogglePOI:
            return [[OAShowHidePoiAction alloc] init];
            
        case EOAQuickActionTypeGPX:
            return [[OAGPXAction alloc] init];
            
        case EOAQuickActionTypeParking:
            return [[OAParkingAction alloc] init];
            
//        case TakeAudioNoteAction.TYPE:
//            return new TakeAudioNoteAction();
//
//        case TakePhotoNoteAction.TYPE:
//            return new TakePhotoNoteAction();
//
//        case TakeVideoNoteAction.TYPE:
//            return new TakeVideoNoteAction();
            
        case EOAQuickActionTypeNavVoice:
            return [[OANavVoiceAction alloc] init];
            
        case EOAQuickActionTypeToggleOsmNotes:
            return [[OAShowHideOSMBugAction alloc] init];
            
        case EOAQuickActionTypeToggleLocalEditsLayer:
            return [[OAShowHideLocalOSMChanges alloc] init];
            
        case EOAQuickActionTypeAddNote:
            return [[OAAddOSMBugAction alloc] init];
            
        case EOAQuickActionTypeAddPOI:
            return [[OAAddPOIAction alloc] init];
            
        case EOAQuickActionTypeMapStyle:
            return [[OAMapStyleAction alloc] init];
            
        case EOAQuickActionTypeMapSource:
            return [[OAMapSourceAction alloc] init];
            
        case EOAQuickActionTypeMapOverlay:
            return [[OAMapOverlayAction alloc] init];
            
        case EOAQuickActionTypeMapUnderlay:
            return [[OAMapUnderlayAction alloc] init];
            
        case EOAQuickActionTypeAddDestination:
            return [[OANavAddDestinationAction alloc] init];
            
        case EOAQuickActionTypeAddFirstIntermediate:
            return [[OANavAddFirstIntermediateAction alloc] init];
            
        case EOAQuickActionTypeReplaceDestination:
            return [[OANavReplaceDestinationAction alloc] init];
            
        case EOAQuickActionTypeAutoZoomMap:
            return [[OANavAutoZoomMapAction alloc] init];
            
        case EOAQuickActionTypeToggleNavigation:
            return [[OANavStartStopAction alloc] init];
            
        case EOAQuickActionTypeResumePauseNavigation:
            return [[OANavResumePauseAction alloc] init];
            
        case EOAQuickActionTypeToggleDayNight:
            return [[OADayNightModeAction alloc] init];
            
        case EOAQuickActionTypeToggleGPX:
            return [[OAShowHideGPXTracksAction alloc] init];
            
        default:
            return [[OAQuickAction alloc] init];
    }
}

+ (OAQuickAction *) produceAction:(OAQuickAction *) quickAction
{
    
    switch (quickAction.type) {
            
        case EOAQuickActionTypeNew:
            return [[OANewAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeMarker:
            return [[OAMarkerAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeFavorite:
            return [[OAFavoriteAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeShowFavorite:
            return [[OAShowHideFavoritesAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeTogglePOI:
            return [[OAShowHidePoiAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeGPX:
            return [[OAGPXAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeParking:
            return [[OAParkingAction alloc] initWithAction:quickAction];
            
            //        case TakeAudioNoteAction.TYPE:
            //            return new TakeAudioNoteAction();
            //
            //        case TakePhotoNoteAction.TYPE:
            //            return new TakePhotoNoteAction();
            //
            //        case TakeVideoNoteAction.TYPE:
            //            return new TakeVideoNoteAction();
            
        case EOAQuickActionTypeNavVoice:
            return [[OANavVoiceAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleOsmNotes:
            return [[OAShowHideOSMBugAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleLocalEditsLayer:
            return [[OAShowHideLocalOSMChanges alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeAddNote:
            return [[OAAddOSMBugAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeAddPOI:
            return [[OAAddPOIAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeMapStyle:
            return [[OAMapStyleAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeMapSource:
            return [[OAMapSourceAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeMapOverlay:
            return [[OAMapOverlayAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeMapUnderlay:
            return [[OAMapUnderlayAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeAddDestination:
            return [[OANavAddDestinationAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeAddFirstIntermediate:
            return [[OANavAddFirstIntermediateAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeReplaceDestination:
            return [[OANavReplaceDestinationAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeAutoZoomMap:
            return [[OANavAutoZoomMapAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleNavigation:
            return [[OANavStartStopAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeResumePauseNavigation:
            return [[OANavResumePauseAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleDayNight:
            return [[OADayNightModeAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleGPX:
            return [[OAShowHideGPXTracksAction alloc] initWithAction:quickAction];
            
        default:
            return quickAction;
    }
}

+(NSString *) getActionIcon:(NSInteger) type
{
    
    switch (type) {
            
        case EOAQuickActionTypeNew:
            return @"ic_custom_plus";
            
        case EOAQuickActionTypeMarker:
        case EOAQuickActionTypeFavorite:
        case EOAQuickActionTypeGPX:
        case EOAQuickActionTypeShowFavorite:
            return @"";
        
        case EOAQuickActionTypeTogglePOI:
            return [[OAShowHidePoiAction alloc] init];
            
        case EOAQuickActionTypeParking:
            return [[OAParkingAction alloc] init];
            
            //        case TakeAudioNoteAction.TYPE:
            //            return new TakeAudioNoteAction();
            //
            //        case TakePhotoNoteAction.TYPE:
            //            return new TakePhotoNoteAction();
            //
            //        case TakeVideoNoteAction.TYPE:
            //            return new TakeVideoNoteAction();
            
        case EOAQuickActionTypeNavVoice:
            return [[OANavVoiceAction alloc] init];
            
        case EOAQuickActionTypeToggleOsmNotes:
            return [[OAShowHideOSMBugAction alloc] init];
            
        case EOAQuickActionTypeToggleLocalEditsLayer:
            return [[OAShowHideLocalOSMChanges alloc] init];
            
        case EOAQuickActionTypeAddNote:
            return [[OAAddOSMBugAction alloc] init];
            
        case EOAQuickActionTypeAddPOI:
            return [[OAAddPOIAction alloc] init];
            
        case EOAQuickActionTypeMapStyle:
            return [[OAMapStyleAction alloc] init];
            
        case EOAQuickActionTypeMapSource:
            return [[OAMapSourceAction alloc] init];
            
        case EOAQuickActionTypeMapOverlay:
            return [[OAMapOverlayAction alloc] init];
            
        case EOAQuickActionTypeMapUnderlay:
            return [[OAMapUnderlayAction alloc] init];
            
        case EOAQuickActionTypeAddDestination:
            return [[OANavAddDestinationAction alloc] init];
            
        case EOAQuickActionTypeAddFirstIntermediate:
            return [[OANavAddFirstIntermediateAction alloc] init];
            
        case EOAQuickActionTypeReplaceDestination:
            return [[OANavReplaceDestinationAction alloc] init];
            
        case EOAQuickActionTypeAutoZoomMap:
            return [[OANavAutoZoomMapAction alloc] init];
            
        case EOAQuickActionTypeToggleNavigation:
            return [[OANavStartStopAction alloc] init];
            
        case EOAQuickActionTypeResumePauseNavigation:
            return [[OANavResumePauseAction alloc] init];
            
        case EOAQuickActionTypeToggleDayNight:
            return [[OADayNightModeAction alloc] init];
            
        case EOAQuickActionTypeToggleGPX:
            return [[OAShowHideGPXTracksAction alloc] init];
            
        default:
            return [[OAQuickAction alloc] init];
    }
}

public static @StringRes int getActionName(int type) {
    
    switch (type) {
            
        case NewAction.TYPE:
            return R.string.quick_action_new_action;
            
        case MarkerAction.TYPE:
            return R.string.quick_action_add_marker;
            
        case FavoriteAction.TYPE:
            return R.string.quick_action_add_favorite;
            
        case ShowHideFavoritesAction.TYPE:
            return R.string.quick_action_showhide_favorites_title;
            
        case ShowHidePoiAction.TYPE:
            return R.string.quick_action_showhide_poi_title;
            
        case GPXAction.TYPE:
            return R.string.quick_action_add_gpx;
            
        case ParkingAction.TYPE:
            return R.string.quick_action_add_parking;
            
        case TakeAudioNoteAction.TYPE:
            return R.string.quick_action_take_audio_note;
            
        case TakePhotoNoteAction.TYPE:
            return R.string.quick_action_take_photo_note;
            
        case TakeVideoNoteAction.TYPE:
            return R.string.quick_action_take_video_note;
            
        case NavVoiceAction.TYPE:
            return R.string.quick_action_navigation_voice;
            
        case ShowHideOSMBugAction.TYPE:
            return R.string.quick_action_showhide_osmbugs_title;
            
        case AddOSMBugAction.TYPE:
            return R.string.quick_action_add_osm_bug;
            
        case AddPOIAction.TYPE:
            return R.string.quick_action_add_poi;
            
        case MapStyleAction.TYPE:
            return R.string.quick_action_map_style;
            
        case MapSourceAction.TYPE:
            return R.string.quick_action_map_source;
            
        case MapOverlayAction.TYPE:
            return R.string.quick_action_map_overlay;
            
        case MapUnderlayAction.TYPE:
            return R.string.quick_action_map_underlay;
            
        case DayNightModeAction.TYPE:
            return R.string.quick_action_day_night_switch_mode;
            
        case NavAddDestinationAction.TYPE:
            return R.string.quick_action_add_destination;
            
        case NavAddFirstIntermediateAction.TYPE:
            return R.string.quick_action_add_first_intermediate;
            
        case NavReplaceDestinationAction.TYPE:
            return R.string.quick_action_replace_destination;
            
        case NavAutoZoomMapAction.TYPE:
            return R.string.quick_action_auto_zoom;
            
        case NavStartStopAction.TYPE:
            return R.string.quick_action_start_stop_navigation;
            
        case NavResumePauseAction.TYPE:
            return R.string.quick_action_resume_pause_navigation;
            
        case ShowHideGpxTracksAction.TYPE:
            return R.string.quick_action_show_hide_gpx_tracks;
            
        default:
            return R.string.quick_action_new_action;
    }
}

public static boolean isActionEditable(int type) {
    
    switch (type) {
            
        case NewAction.TYPE:
        case MarkerAction.TYPE:
        case ShowHideFavoritesAction.TYPE:
        case ShowHidePoiAction.TYPE:
        case ParkingAction.TYPE:
        case TakeAudioNoteAction.TYPE:
        case TakePhotoNoteAction.TYPE:
        case TakeVideoNoteAction.TYPE:
        case NavVoiceAction.TYPE:
        case NavAddDestinationAction.TYPE:
        case NavAddFirstIntermediateAction.TYPE:
        case NavReplaceDestinationAction.TYPE:
        case NavAutoZoomMapAction.TYPE:
        case ShowHideOSMBugAction.TYPE:
        case NavStartStopAction.TYPE:
        case NavResumePauseAction.TYPE:
        case DayNightModeAction.TYPE:
        case ShowHideGpxTracksAction.TYPE:
            return false;
            
        default:
            return true;
    }
}

@end
