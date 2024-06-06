//
//  OAMapButtonsHelper.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapButtonsHelper.h"
#import "OAAppSettings.h"
#import "OAPlugin.h"
#import "OAQuickAction.h"
#import "OAMapSourceAction.h"
#import "OAMapStyleAction.h"
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
#import "OAShowHideMapillaryAction.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kType = @"type";
static NSString * const kName = @"name";
static NSString * const kParams = @"params";
static NSString * const kId = @"id";
static NSString * const kActionType = @"actionType";

static OAQuickActionType *TYPE_ADD_ITEMS;
static OAQuickActionType *TYPE_CONFIGURE_MAP;
static OAQuickActionType *TYPE_NAVIGATION;
static OAQuickActionType *TYPE_CONFIGURE_SCREEN;
static OAQuickActionType *TYPE_SETTINGS;
static OAQuickActionType *TYPE_OPEN;

@implementation OAMapButtonsHelper
{
    OAAppSettings *_settings;
    OAQuickActionSerializer *_serializer;
    
    OAMap3DButtonState *_map3DButtonState;
    OACompassButtonState *_compassButtonState;
    NSMutableArray<OAQuickActionButtonState *> *_mapButtonStates;

    NSArray<OAQuickActionType *> *_enabledTypes;
    NSDictionary<NSNumber *, OAQuickActionType *> *_quickActionTypesInt;
    NSDictionary<NSString *, OAQuickActionType *> *_quickActionTypesStr;
}

+ (void)initialize
{
    TYPE_ADD_ITEMS = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                       name:OALocalizedString(@"quick_action_add_create_items")]
                      category:EOAQuickActionTypeCategoryCreateCategory];

    TYPE_CONFIGURE_MAP = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                           name:OALocalizedString(@"configure_map")]
                          category:EOAQuickActionTypeCategoryConfigureMap];

    TYPE_NAVIGATION = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                        name:OALocalizedString(@"routing_settings")]
                       category:EOAQuickActionTypeCategoryNavigation];

    TYPE_CONFIGURE_SCREEN = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                              name:OALocalizedString(@"layer_map_appearance")]
                             category:EOAQuickActionTypeCategoryConfigureScreen];

    TYPE_SETTINGS = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                      name:OALocalizedString(@"shared_string_settings")]
                     category:EOAQuickActionTypeCategorySettings];

    TYPE_OPEN = [[[[OAQuickActionType alloc] initWithId:0 stringId:@""]
                  name:OALocalizedString(@"shared_string_open")]
                 category:EOAQuickActionTypeCategoryOpen];
}

+ (OAMapButtonsHelper *)sharedInstance
{
    static OAMapButtonsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAMapButtonsHelper alloc] init];
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

+ (OAQuickActionType *) TYPE_SETTINGS
{
    return TYPE_SETTINGS;
}

+ (OAQuickActionType *) TYPE_OPEN
{
    return TYPE_OPEN;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _mapButtonStates = [NSMutableArray new];
        _quickActionTypesInt = [NSDictionary new];
        _quickActionTypesStr = [NSDictionary new];
        _enabledTypes = [NSMutableArray new];
        _settings = [OAAppSettings sharedManager];
        _quickActionsChangedObservable = [[OAObservable alloc] init];
        _quickActionButtonsChangedObservable = [[OAObservable alloc] init];
        _serializer = [OAQuickActionSerializer new];
        
        [self updateActionTypes];
        [self initDefaultButtons];
    }
    return self;
}

- (void)initDefaultButtons
{
    _map3DButtonState = [OAMap3DButtonState new];
    _compassButtonState = [OACompassButtonState new];
}

- (OAMap3DButtonState *)getMap3DButtonState
{
    return _map3DButtonState;
}

- (OACompassButtonState *)getCompassButtonState
{
    return _compassButtonState;
}

- (NSArray<OAQuickActionButtonState *> *)getButtonsStates;
{
    return _mapButtonStates;
}

- (NSArray<OAQuickActionButtonState *> *)getEnabledButtonsStates
{
    NSMutableArray<OAQuickActionButtonState *> *list = [NSMutableArray array];
    for (OAQuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([buttonState isEnabled])
            [list addObject:buttonState];
    }
    return list;
}

- (void)addQuickAction:(OAQuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState add:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)deleteQuickAction:(OAQuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState remove:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)updateQuickAction:(OAQuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState set:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)updateQuickActions:(OAQuickActionButtonState *)buttonState actions:(NSArray<OAQuickAction *> *)actions
{
    [buttonState setWithQuickActions:actions];
    [self onQuickActionsChanged:buttonState];
}

- (void)onQuickActionsChanged:(OAQuickActionButtonState *)buttonState
{
    [buttonState saveActions:_serializer];
    [_quickActionsChangedObservable notifyEventWithKey:buttonState];
}

- (BOOL)isActionNameUnique:(NSArray<OAQuickAction *> *)actions quickAction:(OAQuickAction *)quickAction
{
    for (OAQuickAction *action in actions)
    {
        if (quickAction.id != action.id && [[quickAction getName] isEqualToString:[action getName]])
            return NO;
    }
    return YES;
}

- (OAQuickAction *)generateUniqueActionName:(NSArray<OAQuickAction *> *)actions action:(OAQuickAction *)action
{
    NSInteger number = 0;
    NSString *name = [action getName];
    while(YES)
    {
        number++;
        [action setName:[NSString stringWithFormat:@"%@ (%@)", name, @(number).stringValue]];
        if ([self isActionNameUnique:actions quickAction:action])
            return action;
    }
}

- (NSString *)generateUniqueButtonName:(NSString *)name
{
    NSInteger number = 0;
    while(YES)
    {
        number++;
        NSString *newName = [NSString stringWithFormat:@"%@ (%@)", name, @(number).stringValue];
        if ([self isActionButtonNameUnique:newName])
            return newName;
    }
}

- (void)updateActionTypes
{
    NSMutableArray<OAQuickActionType *> *allTypes = [NSMutableArray new];
//    [allTypes addObject:OANewAction.TYPE];
    [allTypes addObject:OAFavoriteAction.TYPE];
    [allTypes addObject:OAGPXAction.TYPE];
    [allTypes addObject:OAMarkerAction.TYPE];
    // configure map
    [allTypes addObject:OAShowHideFavoritesAction.TYPE];
    [allTypes addObject:OAShowHideGPXTracksAction.TYPE];
    [allTypes addObject:OAShowHidePoiAction.TYPE];
    [allTypes addObject:OAMapStyleAction.TYPE];
    [allTypes addObject:OADayNightModeAction.TYPE];
    [allTypes addObject:OAShowHideTransportLinesAction.TYPE];
    [allTypes addObject:OAShowHideMapillaryAction.TYPE];

    // navigation
    [allTypes addObject:OANavVoiceAction.TYPE];
    [allTypes addObject:OANavDirectionsFromAction.TYPE];
    [allTypes addObject:OANavAddDestinationAction.TYPE];
    [allTypes addObject:OANavAddFirstIntermediateAction.TYPE];
    [allTypes addObject:OANavReplaceDestinationAction.TYPE];
    [allTypes addObject:OANavAutoZoomMapAction.TYPE];
    [allTypes addObject:OANavStartStopAction.TYPE];
    [allTypes addObject:OANavResumePauseAction.TYPE];
    [allTypes addObject:OASwitchProfileAction.TYPE];
    [allTypes addObject:OANavRemoveNextDestination.TYPE];

    // OsmandRasterMapsPlugin
    [allTypes addObject:OAMapSourceAction.TYPE];
    [allTypes addObject:OAMapOverlayAction.TYPE];
    [allTypes addObject:OAMapUnderlayAction.TYPE];

    NSMutableArray<OAQuickActionType *> *enabledTypes = [NSMutableArray arrayWithArray:allTypes];
    [OAPluginsHelper registerQuickActionTypesPlugins:allTypes enabledTypes:enabledTypes];
    
    NSMutableDictionary<NSNumber *, OAQuickActionType *> *quickActionTypesInt = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, OAQuickActionType *> *quickActionTypesStr = [NSMutableDictionary new];
    for (OAQuickActionType *qt in allTypes)
    {
        [quickActionTypesInt setObject:qt forKey:@(qt.id)];
        [quickActionTypesStr setObject:qt forKey:qt.stringId];
    }
    _enabledTypes = enabledTypes;
    _quickActionTypesInt = quickActionTypesInt;
    _quickActionTypesStr = quickActionTypesStr;

    [_serializer setQuickActionTypesStr:quickActionTypesStr];
    [_serializer setQuickActionTypesInt:quickActionTypesInt];

    [self updateActiveActions];
}

- (void)updateActiveActions
{
    _mapButtonStates = [self createButtonsStates];
}

- (NSMutableArray<OAQuickActionButtonState *> * _Nonnull)createButtonsStates
{
    NSMutableArray<OAQuickActionButtonState *> *list = [NSMutableArray array];
    NSArray<NSString *> *actionsKeys = [_settings.quickActionButtons get];
    if (actionsKeys && actionsKeys.count > 0)
    {
        for (NSString *key in actionsKeys)
        {
            if (key.length > 0)
            {
                @try {
                    OAQuickActionButtonState *buttonState = [[OAQuickActionButtonState alloc] init:key];
                    [buttonState parseQuickActions:_serializer error:nil];
                    [list addObject:buttonState];
                }
                @catch (NSException *e)
                {
                    NSLog(e.reason);
                }
            }
        }
    }
    return list;
}

- (void)resetQuickActionsForMode:(OAApplicationMode *)appMode
{
    for (OAQuickActionButtonState *buttonState in [self getButtonsStates])
    {
        [buttonState resetForMode:appMode];
    }
    [self updateActionTypes];
}

- (void)copyQuickActionsFromMode:(OAApplicationMode *)toAppMode fromAppMode:(OAApplicationMode *)fromAppMode
{
    for (OAQuickActionButtonState *buttonState in [self getButtonsStates])
    {
        [buttonState copyForModeFromMode:fromAppMode toMode:toAppMode];
    }
    [self updateActionTypes];
}

- (NSArray<OAQuickActionType *> *)produceTypeActionsListWithHeaders:(OAQuickActionButtonState *)buttonState
{
    NSMutableArray<OAQuickActionType *> *actionTypes = [NSMutableArray new];
    [self filterQuickActions:buttonState filter:TYPE_ADD_ITEMS actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_CONFIGURE_MAP actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_NAVIGATION actionTypes:actionTypes];
//    [self filterQuickActions:buttonState filter:TYPE_CONFIGURE_SCREEN actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_SETTINGS actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_OPEN actionTypes:actionTypes];

    return actionTypes;
}

- (void)filterQuickActions:(OAQuickActionButtonState *)buttonState filter:(OAQuickActionType *)filter actionTypes:(NSMutableArray<OAQuickActionType *> *)actionTypes
{
    [actionTypes addObject:filter];

    NSMutableSet<NSNumber *> *set = [NSMutableSet new];
    for (OAQuickAction *action in buttonState.quickActions)
    {
        [set addObject:@(action.actionType.id)];
    }
    for (OAQuickActionType *type in _enabledTypes)
    {
        if (type.category == filter.category)
        {
            if (!type.actionEditable)
            {
                BOOL instanceInList = [set containsObject:@(type.id)];
                if (!instanceInList)
                {
                    [actionTypes addObject:type];
                }
            }
            else
            {
                [actionTypes addObject:type];
            }
        }
    }
}

- (OAQuickAction *)newActionByStringType:(NSString *)actionType
{
    OAQuickActionType *quickActionType = _quickActionTypesStr[actionType];
    if (quickActionType)
        return [quickActionType createNew];
    return nil;
}

- (OAQuickAction *)newActionByType:(NSInteger)type
{
    OAQuickActionType *quickActionType = _quickActionTypesInt[@(type)];
    if (quickActionType != nil)
        return [quickActionType createNew];
    return nil;
}

- (BOOL)isActionButtonNameUnique:(NSString *)name
{
    return [self getButtonStateByName:name] == nil;
}

- (OAQuickActionButtonState *)getButtonStateByName:(NSString *)name
{
    for (OAQuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([[buttonState getName] isEqualToString:name])
            return buttonState;
    }
    return nil;
}

- (OAQuickActionButtonState *)getButtonStateById:(NSString *)id
{
    for (OAQuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([buttonState.id isEqualToString:id])
            return buttonState;
    }
    return nil;
}

- (OAQuickActionButtonState *)createNewButtonState
{
    NSString *id = [NSString stringWithFormat:@"%@_%@", OAQuickActionButtonState.defaultButtonId, @([[NSDate date] timeIntervalSince1970] * 1000).stringValue];
    return [[OAQuickActionButtonState alloc] init:id];
}

- (void)addQuickActionButtonState:(OAQuickActionButtonState *)buttonState
{
    [_settings.quickActionButtons addUnique:buttonState.id];
    [self updateActiveActions];
    [_quickActionButtonsChangedObservable notifyEventWithKey:buttonState andValue:@(YES)];
}

- (void)removeQuickActionButtonState:(OAQuickActionButtonState *)buttonState
{
    [_settings.quickActionButtons remove:buttonState.id];
    [self updateActiveActions];
    [_quickActionButtonsChangedObservable notifyEventWithKey:buttonState andValue:@(NO)];
}

+ (OAQuickAction *)produceAction:(OAQuickAction *)action
{
    return [action.actionType createNew:action];
}

@end
