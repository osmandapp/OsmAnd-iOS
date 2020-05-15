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
#import "OAContourLinesAction.h"
#import "OATerrainAction.h"
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

#define kType @"type"
#define kName @"name"
#define kParams @"params"

@implementation OAQuickActionFactory

-(NSString *) quickActionListToString:(NSArray<OAQuickAction *> *) quickActions
{
    NSMutableArray *arr = [NSMutableArray new];
    for (OAQuickAction *action in quickActions)
    {
        [arr addObject:@{
                         kType : @(action.type),
                         kName : action.getName,
                         kParams : action.getParams
                         }];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

-(NSArray <OAQuickAction *> *) parseActiveActionsList:(NSString *)json
{
    NSMutableArray<OAQuickAction *> *actions = [NSMutableArray new];
    if (json)
    {
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        for (NSDictionary *data in arr)
        {
            OAQuickAction *action = [self.class newActionByType:[data[kType] integerValue]];
            [action setName:data[kName]];
            [action setParams:data[kParams]];
            [actions addObject:action];
        }
    }
    return [NSArray arrayWithArray:actions];
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
    
    OAQuickAction *contourLines = [[OAContourLinesAction alloc] init];
    if (![contourLines hasInstanceInList:active])
        [quickActions addObject:contourLines];
    OAQuickAction *hillshade = [[OATerrainAction alloc] init];
    if (![hillshade hasInstanceInList:active])
        [quickActions addObject:hillshade];
    
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
        
        case EOAQuickActionTypeToggleContourLines:
            return [[OAContourLinesAction alloc] init];
            
        case EOAQuickActionTypeToggleHillshade:
            return [[OATerrainAction alloc] init];
            
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
            
        case EOAQuickActionTypeToggleContourLines:
            return [[OAContourLinesAction alloc] initWithAction:quickAction];
            
        case EOAQuickActionTypeToggleHillshade:
            return [[OATerrainAction alloc] initWithAction:quickAction];
            
            
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
            return @"ic_custom_add";
            
        case EOAQuickActionTypeMarker:
        case EOAQuickActionTypeFavorite:
        case EOAQuickActionTypeGPX:
        case EOAQuickActionTypeShowFavorite:
            return @"ic_custom_favorites";
        
        case EOAQuickActionTypeTogglePOI:
            return @"ic_custom_poi";
            
        case EOAQuickActionTypeParking:
            return @"ic_custom_parking";
            
            //        case TakeAudioNoteAction.TYPE:
            //            return new TakeAudioNoteAction();
            //
            //        case TakePhotoNoteAction.TYPE:
            //            return new TakePhotoNoteAction();
            //
            //        case TakeVideoNoteAction.TYPE:
            //            return new TakeVideoNoteAction();
            
        case EOAQuickActionTypeNavVoice:
            return @"ic_custom_sound";
            
        case EOAQuickActionTypeAddNote:
        case EOAQuickActionTypeToggleOsmNotes:
            return @"ic_action_osm_note";
            
        case EOAQuickActionTypeToggleLocalEditsLayer:
            return @"ic_custom_osm_edits";
            
        case EOAQuickActionTypeAddPOI:
            return @"ic_action_create_poi";
            
        case EOAQuickActionTypeMapStyle:
            return @"ic_custom_map_style";
            
        case EOAQuickActionTypeMapSource:
            return @"ic_custom_show_on_map";
            
        case EOAQuickActionTypeMapOverlay:
            return @"ic_custom_overlay_map";
            
        case EOAQuickActionTypeMapUnderlay:
            return @"ic_custom_underlay_map";
            
        case EOAQuickActionTypeReplaceDestination:
        case EOAQuickActionTypeAddDestination:
            return @"ic_action_target";
            
        case EOAQuickActionTypeAddFirstIntermediate:
            return @"ic_action_intermediate";
            
        case EOAQuickActionTypeAutoZoomMap:
            return @"ic_navbar_search";
            
        case EOAQuickActionTypeResumePauseNavigation:
        case EOAQuickActionTypeToggleNavigation:
            return @"ic_custom_navigation_arrow";
            
        case EOAQuickActionTypeToggleDayNight:
            return @"ic_custom_sun";
            
        case EOAQuickActionTypeToggleContourLines:
            return @"ic_custom_contour_lines";
        
        case EOAQuickActionTypeToggleHillshade:
            return @"ic_custom_hillshade";
            
        case EOAQuickActionTypeToggleGPX:
            return @"ic_custom_trip";
            
        default:
            return @"ic_custom_add";
    }
}

+(NSString *) getSecondaryIcon:(NSInteger) type
{
    
    switch (type) {
            
        case EOAQuickActionTypeMarker:
        case EOAQuickActionTypeFavorite:
        case EOAQuickActionTypeGPX:
        case EOAQuickActionTypeParking:
        case EOAQuickActionTypeAddNote:
        case EOAQuickActionTypeAddDestination:
        case EOAQuickActionTypeAddFirstIntermediate:
            return @"ic_custom_compound_action_add";
            
        case EOAQuickActionTypeReplaceDestination:
            return @"ic_custom_compound_action_replace";
            
        default:
            return nil;
    }
}

+(NSString *)getActionName:(NSInteger) type
{
    
    switch (type) {
            
        case EOAQuickActionTypeNew:
            return OALocalizedString(@"add_action");
        case EOAQuickActionTypeMarker:
            return OALocalizedString(@"add_map_marker");
        case EOAQuickActionTypeFavorite:
            return OALocalizedString(@"ctx_mnu_add_fav");
        case EOAQuickActionTypeGPX:
            return OALocalizedString(@"add_gpx_waypoint");
        case EOAQuickActionTypeShowFavorite:
            return OALocalizedString(@"toggle_fav");
        case EOAQuickActionTypeTogglePOI:
            return OALocalizedString(@"toggle_poi");
        case EOAQuickActionTypeParking:
            return OALocalizedString(@"add_parking_place");
            
            //        case TakeAudioNoteAction.TYPE:
            //            return new TakeAudioNoteAction();
            //
            //        case TakePhotoNoteAction.TYPE:
            //            return new TakePhotoNoteAction();
            //
            //        case TakeVideoNoteAction.TYPE:
            //            return new TakeVideoNoteAction();
            
        case EOAQuickActionTypeNavVoice:
            return OALocalizedString(@"toggle_voice");
        case EOAQuickActionTypeAddNote:
            return OALocalizedString(@"add_osm_note");
        case EOAQuickActionTypeToggleOsmNotes:
            return OALocalizedString(@"toggle_online_notes");
        case EOAQuickActionTypeToggleLocalEditsLayer:
            return OALocalizedString(@"toggle_local_edits");
        case EOAQuickActionTypeAddPOI:
            return OALocalizedString(@"add_poi");
        case EOAQuickActionTypeMapStyle:
            return OALocalizedString(@"change_map_style");
        case EOAQuickActionTypeMapSource:
            return OALocalizedString(@"change_map_source");
        case EOAQuickActionTypeMapOverlay:
            return OALocalizedString(@"change_map_overlay");
        case EOAQuickActionTypeMapUnderlay:
            return OALocalizedString(@"change_map_underlay");
        case EOAQuickActionTypeReplaceDestination:
            return OALocalizedString(@"replace_destination");
        case EOAQuickActionTypeAddDestination:
            return OALocalizedString(@"add_destination");
        case EOAQuickActionTypeAddFirstIntermediate:
            return OALocalizedString(@"add_first_inermediate");
        case EOAQuickActionTypeAutoZoomMap:
            return OALocalizedString(@"toggle_auto_zoom");
        case EOAQuickActionTypeResumePauseNavigation:
            return OALocalizedString(@"pause_resume_nav");
        case EOAQuickActionTypeToggleNavigation:
            return OALocalizedString(@"toggle_nav");
        case EOAQuickActionTypeToggleDayNight:
            return OALocalizedString(@"toggle_day_night");
        case EOAQuickActionTypeToggleContourLines:
            return OALocalizedString(@"toggle_contour_lines");
        case EOAQuickActionTypeToggleHillshade:
            return OALocalizedString(@"toggle_hillshade");
        case EOAQuickActionTypeToggleGPX:
            return OALocalizedString(@"show_hide_gpx");
        default:
            return OALocalizedString(@"add_action");
    }
}

+(BOOL) isActionEditable:(NSInteger) type
{
    
    switch (type) {
            //        case TakeAudioNoteAction.TYPE:
            //        case TakePhotoNoteAction.TYPE:
            //        case TakeVideoNoteAction.TYPE:
        case EOAQuickActionTypeNew:
        case EOAQuickActionTypeMarker:
        case EOAQuickActionTypeShowFavorite:
        case EOAQuickActionTypeParking:
        case EOAQuickActionTypeNavVoice:
        case EOAQuickActionTypeAddDestination:
        case EOAQuickActionTypeAddFirstIntermediate:
        case EOAQuickActionTypeReplaceDestination:
        case EOAQuickActionTypeAutoZoomMap:
        case EOAQuickActionTypeToggleOsmNotes:
        case EOAQuickActionTypeToggleLocalEditsLayer:
        case EOAQuickActionTypeToggleNavigation:
        case EOAQuickActionTypeResumePauseNavigation:
        case EOAQuickActionTypeToggleDayNight:
        case EOAQuickActionTypeToggleContourLines:
        case EOAQuickActionTypeToggleHillshade:
        case EOAQuickActionTypeToggleGPX:
            return NO;
            
        default:
            return YES;
    }
}

@end
