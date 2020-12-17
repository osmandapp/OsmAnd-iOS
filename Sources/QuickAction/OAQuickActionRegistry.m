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
#import "OAOsmEditingPlugin.h"
#import "OAParkingPositionPlugin.h"
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
#import "OAShowHideOSMBugAction.h"
#import "OAShowHideGPXTracksAction.h"
#import "OAShowHideLocalOSMChanges.h"
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
//#import "OASwitchProfileAction.h"

#define kType @"type"
#define kName @"name"
#define kParams @"params"
#define kId @"id"
#define kActionType @"actionType"


static OAQuickActionType *TYPE_ADD_ITEMS;
static OAQuickActionType *TYPE_CONFIGURE_MAP;
static OAQuickActionType *TYPE_NAVIGATION;

@implementation OAQuickActionRegistry
{
    OAAppSettings *_settings;
    
    NSMutableArray<OAQuickAction *> *_quickActions;
    NSArray<OAQuickActionType *> *_quickActionTypes;
    NSDictionary<NSNumber *, OAQuickActionType *> *_quickActionTypesInt;
    NSDictionary<NSString *, OAQuickActionType *> *_quickActionTypesStr;
}

+ (void)initialize
{
    TYPE_ADD_ITEMS = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"create_items") category:CREATE_CATEGORY iconName:nil];
    TYPE_CONFIGURE_MAP = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"configure_map") category:CONFIGURE_MAP iconName:nil];
    TYPE_NAVIGATION = [[OAQuickActionType alloc] initWithIdentifier:0 stringId:@"" class:nil name:OALocalizedString(@"routing_settings") category:NAVIGATION iconName:nil];
}

+ (instancetype)sharedInstance
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _quickActionTypes = [NSArray new];
        _quickActionTypesInt = [NSDictionary new];
        _quickActionTypesStr = [NSDictionary new];
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
    [quickActionTypes addObject:OANavAddFirstIntermediateAction.TYPE];
    [quickActionTypes addObject:OANavReplaceDestinationAction.TYPE];
    [quickActionTypes addObject:OANavAutoZoomMapAction.TYPE];
    [quickActionTypes addObject:OANavStartStopAction.TYPE];
    [quickActionTypes addObject:OANavResumePauseAction.TYPE];
    //        [quickActionTypes addObject:OASwitchProfileAction.TYPE];
    [self registerPluginDependedActions:quickActionTypes];
    
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
    // reparse to get new quick actions
    _quickActions = [self parseActiveActionsList:_settings.quickActionsList];
}

- (void) registerPluginDependedActions:(NSMutableArray<OAQuickActionType *> *)quickActionTypes
{
    [OAPlugin registerQuickActionTypesPlugins:quickActionTypes];
}

-(NSArray<OAQuickAction *> *) getQuickActions
{
    return [NSArray arrayWithArray:_quickActions];
}

-(NSArray<OAQuickAction *> *) getEnabledQuickActions
{
    NSMutableSet<OAQuickActionType *> *enabledActionTypes = [NSMutableSet setWithArray:_quickActionTypes];
    
    NSMutableSet<OAQuickActionType *> *userAddedActionTypes = [NSMutableSet new];
    for (OAQuickAction *action in _quickActions)
        [userAddedActionTypes addObject:action.actionType];
    
    [userAddedActionTypes intersectSet:enabledActionTypes];
    
    NSMutableArray<OAQuickAction *> *resultActions = [NSMutableArray new];
    for (OAQuickAction *action in _quickActions)
    {
        if ([userAddedActionTypes containsObject:action.actionType])
            [resultActions addObject:action];
    }
    
    return resultActions;
}

-(void) addQuickAction:(OAQuickAction *) action
{
    [_quickActions addObject:action];
    [_settings setQuickActionsList:[self quickActionListToString:_quickActions]];
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
    [_settings setQuickActionsList:[self quickActionListToString:_quickActions]];
}

-(void) updateQuickActions:(NSArray<OAQuickAction *> *) quickActions
{
    _quickActions = [NSMutableArray arrayWithArray:quickActions];
    [_settings setQuickActionsList:[self quickActionListToString:_quickActions]];
}

-(OAQuickAction *) getQuickAction:(long) identifier
{
    for (OAQuickAction *action in _quickActions)
    {
        if (action.identifier == identifier)
            return action;
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
    {
        return [quickActionType createNew];
    }
    return nil;
}

- (OAQuickAction *) newActionByType:(NSInteger) type
{
    OAQuickActionType *quickActionType = _quickActionTypesInt[@(type)];
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
            if (data[kActionType])
            {
                NSString *actionType = data[kActionType];
                found = _quickActionTypesStr[actionType];
            }
            else if (data[kType])
            {
                NSInteger type = [data[kType] integerValue];
                found = _quickActionTypesInt[@(type)];
            }
            if (found != nil)
            {
                OAQuickAction *qa = [found createNew];
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
                         kActionType : action.actionType.stringId
                         }];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


@end
