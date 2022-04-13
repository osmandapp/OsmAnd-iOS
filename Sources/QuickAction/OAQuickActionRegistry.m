//
//  OAQuickActionRegistry.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionRegistry.h"
#import "OAAppSettings.h"
#import "OAPlugin.h"
#import "OAQuickAction.h"
#import "OAIAPHelper.h"
#import "OAMapSourceAction.h"
#import "OAMapStyleAction.h"
#import "OAQuickActionType.h"
#import "OANewAction.h"
#import "OAFavoriteAction.h"
#import "OAGPXAction.h"
#import "OAMarkerAction.h"
#import "OAShowHideFavoritesAction.h"
#import "OAShowHidePoiAction.h"
#import "OAShowHideGPXTracksAction.h"
#import "OADayNightModeAction.h"
#import "OANavVoiceAction.h"
#import "OAShowHideTransportLinesAction.h"
#import "OANavDirectionsFromAction.h"
#import "OANavAddDestinationAction.h"
#import "OANavAddFirstIntermediateAction.h"
#import "OANavReplaceDestinationAction.h"
#import "OANavAutoZoomMapAction.h"
#import "OANavStartStopAction.h"
#import "OANavResumePauseAction.h"
#import "OAMapOverlayAction.h"
#import "OAMapUnderlayAction.h"
#import "OASwitchProfileAction.h"
#import "OANavRemoveNextDestination.h"
#import "OAUnsupportedAction.h"
#import "OAContourLinesAction.h"
#import "OATerrainAction.h"
#import "OAShowHideCoordinatesAction.h"
#import "OAShowHideTemperatureAction.h"
#import "OAShowHidePressureAction.h"
#import "OAShowHideWindAction.h"
#import "OAShowHideCloudAction.h"
#import "OAShowHidePrecipitationAction.h"

#define kType @"type"
#define kName @"name"
#define kParams @"params"
#define kId @"id"
#define kActionType @"actionType"


static OAQuickActionType *TYPE_ADD_ITEMS;
static OAQuickActionType *TYPE_CONFIGURE_MAP;
static OAQuickActionType *TYPE_NAVIGATION;
static OAQuickActionType *TYPE_CONFIGURE_SCREEN;

@implementation OAQuickActionRegistry
{
    OAAppSettings *_settings;
    
    NSMutableArray<OAQuickAction *> *_quickActions;
    NSArray<OAQuickActionType *> *_quickActionTypes;
    NSDictionary<NSNumber *, OAQuickActionType *> *_quickActionTypesInt;
    NSDictionary<NSString *, OAQuickActionType *> *_quickActionTypesStr;
    NSArray<OAQuickActionType *> *_disabledQuickActionTypes;
    NSDictionary<NSNumber *, OAQuickActionType *> *_disabledQuickActionTypesInt;
    NSDictionary<NSString *, OAQuickActionType *> *_disabledQuickActionTypesStr;
}

+ (void)initialize
{
    TYPE_ADD_ITEMS = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"create_items") category:CREATE_CATEGORY iconName:nil];
    TYPE_CONFIGURE_MAP = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"configure_map") category:CONFIGURE_MAP iconName:nil];
    TYPE_NAVIGATION = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"routing_settings") category:NAVIGATION iconName:nil];
    TYPE_CONFIGURE_SCREEN = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"layer_map_appearance") category:CONFIGURE_SCREEN iconName:nil];
}

+ (OAQuickActionRegistry *)sharedInstance
{
    static OAQuickActionRegistry *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAQuickActionRegistry alloc] init];
    });
    return _sharedInstance;
}

+ (OAQuickActionType *) TYPE_ADD_ITEMS
{
    return TYPE_ADD_ITEMS;
}

+ (OAQuickActionType *) TYPE_CONFIGURE_MAP
{
    return TYPE_CONFIGURE_MAP;
}

+ (OAQuickActionType *) TYPE_NAVIGATION
{
    return TYPE_NAVIGATION;
}

+ (OAQuickActionType *) TYPE_CONFIGURE_SCREEN
{
    return TYPE_CONFIGURE_SCREEN;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _quickActionTypes = [NSArray new];
        _quickActionTypesInt = [NSDictionary new];
        _quickActionTypesStr = [NSDictionary new];
        _disabledQuickActionTypes = [NSArray new];
        _disabledQuickActionTypesInt = [NSDictionary new];
        _disabledQuickActionTypesStr = [NSDictionary new];
        _quickActions = [NSMutableArray new];
        _settings = [OAAppSettings sharedManager];
        _quickActionListChangedObservable = [[OAObservable alloc] init];
        
        [self updateActionTypes];
    }
    return self;
}

- (void) updateActionTypes
{
    NSMutableArray<OAQuickActionType *> *quickActionTypes = [NSMutableArray new];
    [quickActionTypes addObject:OANewAction.TYPE];
    [quickActionTypes addObject:OAFavoriteAction.TYPE];
    [quickActionTypes addObject:OAGPXAction.TYPE];
    [quickActionTypes addObject:OAMarkerAction.TYPE];
    // configure map
    [quickActionTypes addObject:OAShowHideFavoritesAction.TYPE];
    [quickActionTypes addObject:OAShowHideGPXTracksAction.TYPE];
    [quickActionTypes addObject:OAShowHidePoiAction.TYPE];
    [quickActionTypes addObject:OAMapSourceAction.TYPE];
    [quickActionTypes addObject:OAMapOverlayAction.TYPE];
    [quickActionTypes addObject:OAMapUnderlayAction.TYPE];
    [quickActionTypes addObject:OAMapStyleAction.TYPE];
    [quickActionTypes addObject:OADayNightModeAction.TYPE];
    [quickActionTypes addObject:OAShowHideTransportLinesAction.TYPE];
    
    // navigation
    [quickActionTypes addObject:OANavVoiceAction.TYPE];
    [quickActionTypes addObject:OANavDirectionsFromAction.TYPE];
    [quickActionTypes addObject:OANavAddDestinationAction.TYPE];
    [quickActionTypes addObject:OANavRemoveNextDestination.TYPE];
    [quickActionTypes addObject:OANavAddFirstIntermediateAction.TYPE];
    [quickActionTypes addObject:OANavReplaceDestinationAction.TYPE];
    [quickActionTypes addObject:OANavAutoZoomMapAction.TYPE];
    [quickActionTypes addObject:OANavStartStopAction.TYPE];
    [quickActionTypes addObject:OANavResumePauseAction.TYPE];
    [quickActionTypes addObject:OASwitchProfileAction.TYPE];
    
    // configure screen
    [quickActionTypes addObject:OAShowHideCoordinatesAction.TYPE];
    
    [OAPlugin registerQuickActionTypesPlugins:quickActionTypes disabled:NO];
    if ([OAIAPHelper.sharedInstance.srtm isActive])
        [quickActionTypes addObjectsFromArray:@[OAContourLinesAction.TYPE, OATerrainAction.TYPE]];

    if ([[OAIAPHelper sharedInstance].weather isActive])
    {
        [quickActionTypes addObjectsFromArray:@[
                OAShowHideTemperatureAction.TYPE,
                OAShowHidePressureAction.TYPE,
                OAShowHideWindAction.TYPE,
                OAShowHideCloudAction.TYPE,
                OAShowHidePrecipitationAction.TYPE
        ]];
    }
    
    NSMutableDictionary<NSNumber *, OAQuickActionType *> *quickActionTypesInt = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, OAQuickActionType *> *quickActionTypesStr = [NSMutableDictionary new];
    for (OAQuickActionType *qt in quickActionTypes)
    {
        [quickActionTypesInt setObject:qt forKey:@(qt.identifier)];
        [quickActionTypesStr setObject:qt forKey:qt.stringId];
    }
    _quickActionTypes = [NSArray arrayWithArray:quickActionTypes];
    _quickActionTypesInt = [NSDictionary dictionaryWithDictionary:quickActionTypesInt];
    _quickActionTypesStr = [NSDictionary dictionaryWithDictionary:quickActionTypesStr];
    
    NSMutableArray<OAQuickActionType *> *disabledQuickActionTypes = [NSMutableArray new];
    [OAPlugin registerQuickActionTypesPlugins:disabledQuickActionTypes disabled:YES];
    if (![OAIAPHelper.sharedInstance.srtm isActive])
        [disabledQuickActionTypes addObjectsFromArray:@[OAContourLinesAction.TYPE, OATerrainAction.TYPE]];

    if (![[OAIAPHelper sharedInstance].weather isActive])
    {
        [disabledQuickActionTypes addObjectsFromArray:@[
                OAShowHideTemperatureAction.TYPE,
                OAShowHidePressureAction.TYPE,
                OAShowHideWindAction.TYPE,
                OAShowHideCloudAction.TYPE,
                OAShowHidePrecipitationAction.TYPE
        ]];
    }

    NSMutableDictionary<NSNumber *, OAQuickActionType *> *disabledQuickActionTypesInt = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, OAQuickActionType *> *disabledQuickActionTypesStr = [NSMutableDictionary new];
    for (OAQuickActionType *qt in disabledQuickActionTypes)
    {
        [disabledQuickActionTypesInt setObject:qt forKey:@(qt.identifier)];
        [disabledQuickActionTypesStr setObject:qt forKey:qt.stringId];
    }
    _disabledQuickActionTypes = [NSArray arrayWithArray:disabledQuickActionTypes];
    _disabledQuickActionTypesInt = [NSDictionary dictionaryWithDictionary:disabledQuickActionTypesInt];
    _disabledQuickActionTypesStr = [NSDictionary dictionaryWithDictionary:disabledQuickActionTypesStr];

    // reparse to get new quick actions
    _quickActions = [self parseActiveActionsList:_settings.quickActionsList.get];
}

-(NSArray<OAQuickAction *> *) getQuickActions
{
    return [NSArray arrayWithArray:_quickActions];
}

-(void) addQuickAction:(OAQuickAction *) action
{
    [_quickActions addObject:action];
    [_settings.quickActionsList set:[self quickActionListToString:_quickActions]];
}

-(void) updateQuickAction:(OAQuickAction *) action
{
    NSInteger index = [_quickActions indexOfObject:action];
    if (index != NSNotFound)
    {
        NSMutableArray<OAQuickAction *> *mutableActions = [NSMutableArray arrayWithArray:_quickActions];
        [mutableActions setObject:action atIndexedSubscript:index];
        _quickActions = [NSMutableArray arrayWithArray:mutableActions];
    }
    [_settings.quickActionsList set:[self quickActionListToString:_quickActions]];
}

-(void) updateQuickActions:(NSArray<OAQuickAction *> *) quickActions
{
    _quickActions = [NSMutableArray arrayWithArray:quickActions];
    [_settings.quickActionsList set:[self quickActionListToString:_quickActions]];
}

- (void)deleteQuickAction:(OAQuickAction *)action
{
    [_quickActions removeObject:action];
    [_settings.quickActionsList set:[self quickActionListToString:_quickActions]];
}

-(OAQuickAction *) getQuickAction:(long)identifier
{
    for (OAQuickAction *action in _quickActions)
    {
        if (action.identifier == identifier)
            return action;
    }
    return nil;
}

-(OAQuickAction *) getQuickAction:(NSInteger)type name:(NSString *)name params:(NSDictionary<NSString *, NSString *> *)params
{
    for (OAQuickAction *action in _quickActions)
    {
        if (action.getType == type
            && ((action.hasCustomName && [action.getName isEqualToString:name]) || !action.hasCustomName)
            && [action.getParams isEqual:params])
        {
            return action;
        }
    }
    return nil;
}

-(BOOL) isNameUnique:(OAQuickAction *) action
{
    for (OAQuickAction *a in _quickActions)
    {
        if (action.identifier != a.identifier)
        {
            if ([action.getName isEqualToString:a.getName])
                return NO;
        }
    }
    return YES;
}

-(OAQuickAction *) generateUniqueName:(OAQuickAction *) action
{
    NSInteger number = 0;
    NSString *name = action.getName;
    while (YES)
    {
        number++;
        [action setName:[NSString stringWithFormat:@"%@(%ld)", name, number]];
        if ([self isNameUnique:action])
            return action;
    }
}

- (NSArray<OAQuickActionType *> *) produceTypeActionsListWithHeaders
{
    NSMutableArray<OAQuickActionType *> *result = [NSMutableArray new];
    [self filterQuickActions:TYPE_ADD_ITEMS result:result];
    [self filterQuickActions:TYPE_CONFIGURE_MAP result:result];
    [self filterQuickActions:TYPE_NAVIGATION result:result];
    [self filterQuickActions:TYPE_CONFIGURE_SCREEN result:result];
    return result;
}

- (void) filterQuickActions:(OAQuickActionType *)filter result:(NSMutableArray<OAQuickActionType *> *) result
{
    [result addObject:filter];
    NSMutableSet<NSNumber *> *set = [NSMutableSet new];
    for (OAQuickAction *qa in _quickActions)
    {
        [set addObject:@(qa.actionType.identifier)];
    }
    for (OAQuickActionType *t in _quickActionTypes)
    {
        if (t.category == filter.category)
        {
            if (!t.actionEditable)
            {
                BOOL instanceInList = [set containsObject:@(t.identifier)];
                if (!instanceInList)
                {
                    [result addObject:t];
                }
            }
            else
            {
                [result addObject:t];
            }
        }
    }
}

- (OAQuickAction *) newActionByStringType:(NSString *) actionType
{
    OAQuickActionType *quickActionType = _quickActionTypesStr[actionType];
    if (quickActionType)
        return [quickActionType createNew];
    
    quickActionType = _disabledQuickActionTypesStr[actionType];
    if (quickActionType)
        return [quickActionType createNew];

    return nil;
}

- (OAQuickAction *) newActionByType:(NSInteger) type
{
    OAQuickActionType *quickActionType = _quickActionTypesInt[@(type)];
    if (quickActionType != nil)
        return [quickActionType createNew];
    
    quickActionType = _disabledQuickActionTypesInt[@(type)];
    if (quickActionType != nil)
        return [quickActionType createNew];

    return nil;
}

+ (OAQuickAction *) produceAction:(OAQuickAction *) quickAction
{
    return [quickAction.actionType createNew:quickAction];
}

#pragma mark - Json serialization

-(NSMutableArray <OAQuickAction *> *) parseActiveActionsList:(NSString *)json
{
    NSMutableArray<OAQuickAction *> *actions = [NSMutableArray new];
    if (json)
    {
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        for (NSDictionary *data in arr)
        {
            OAQuickActionType *found = nil;
            NSString *actionType = data[kActionType];
            BOOL disabled = NO;
            if (actionType)
            {
                found = _quickActionTypesStr[actionType];
                disabled = _disabledQuickActionTypesStr[actionType] != nil;
            }
            if (!found && !actionType && data[kType])
            {
                NSInteger type = [data[kType] integerValue];
                found = _quickActionTypesInt[@(type)];
            }
            if (!disabled && (found || actionType))
            {
                OAQuickAction *qa = found ? [found createNew] : [[OAUnsupportedAction alloc] initWithActionTypeId:actionType];
                
                if (data[kName])
                    qa.name = data[kName];
                if (data[kId])
                    qa.identifier = [data[kId] longValue];
                
                if (data[kParams])
                    qa.params = data[kParams];
                
                [actions addObject:qa];
            }
        }
    }
    return actions;
}

-(NSString *) quickActionListToString:(NSArray<OAQuickAction *> *) quickActions
{
    NSMutableArray *arr = [NSMutableArray new];
    for (OAQuickAction *action in quickActions)
    {
        [arr addObject:@{
                         kType : @(action.getType),
                         kName : action.getName,
                         kParams : action.getParams,
                         kId : @(action.getId),
                         kActionType : action.getActionTypeId
                         }];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


@end
