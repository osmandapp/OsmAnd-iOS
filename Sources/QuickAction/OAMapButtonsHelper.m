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

static QuickActionType *TYPE_CREATE_CATEGORY;
static QuickActionType *TYPE_CONFIGURE_MAP;
static QuickActionType *TYPE_NAVIGATION;
static QuickActionType *TYPE_CONFIGURE_SCREEN;
static QuickActionType *TYPE_SETTINGS;
static QuickActionType *TYPE_MAP_INTERACTIONS;
static QuickActionType *TYPE_MY_PLACES;
static QuickActionType *TYPE_INTERFACE;

@implementation OAMapButtonsHelper
{
    OAAppSettings *_settings;
    QuickActionSerializer *_serializer;
    
    Map3DButtonState *_map3DButtonState;
    CompassButtonState *_compassButtonState;
    ZoomInButtonState *_zoomInButtonState;
    ZoomOutButtonState *_zoomOutButtonState;
    SearchButtonState *_searchButtonState;
    DriveModeButtonState *_navigationModeButtonState;
    MyLocationButtonState *_myLocationButtonState;
    OptionsMenuButtonState *_menuButtonState;
    MapSettingsButtonState *_configureMapButtonState;
    NSMutableArray<QuickActionButtonState *> *_mapButtonStates;

    NSArray<QuickActionType *> *_enabledTypes;
    NSDictionary<NSNumber *, QuickActionType *> *_quickActionTypesInt;
    NSDictionary<NSString *, QuickActionType *> *_quickActionTypesStr;
    
    OACommonInteger *_defaultSizePref;
    OACommonDouble *_defaultOpacityPref;
    OACommonInteger *_defaultCornerRadiusPref;
    OACommonInteger *_defaultGlassStylePref;
}

+ (void)initialize
{
    TYPE_CREATE_CATEGORY = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                       name:OALocalizedString(@"quick_action_add_create_items")]
                      category:QuickActionTypeCategoryCreateCategory];

    TYPE_CONFIGURE_MAP = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                           name:OALocalizedString(@"configure_map")]
                          category:QuickActionTypeCategoryConfigureMap];

    TYPE_NAVIGATION = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                        name:OALocalizedString(@"shared_string_navigation")]
                       category:QuickActionTypeCategoryNavigation];

    TYPE_CONFIGURE_SCREEN = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                              name:OALocalizedString(@"layer_map_appearance")]
                             category:QuickActionTypeCategoryConfigureScreen];

    TYPE_SETTINGS = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                      name:OALocalizedString(@"shared_string_settings")]
                     category:QuickActionTypeCategorySettings];

    TYPE_MAP_INTERACTIONS = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                  name:OALocalizedString(@"key_event_category_map_interactions")]
                 category:QuickActionTypeCategoryMapInteractions];
    
    TYPE_MY_PLACES = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                  name:OALocalizedString(@"shared_string_my_places")]
                 category:QuickActionTypeCategoryMyPlaces];
    
    TYPE_INTERFACE = [[[[QuickActionType alloc] initWithId:0 stringId:@""]
                  name:OALocalizedString(@"shared_string_interface")]
                          category:QuickActionTypeCategoryInterface];
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

+ (QuickActionType *) TYPE_CREATE_CATEGORY
{
    return TYPE_CREATE_CATEGORY;
}

+ (QuickActionType *) TYPE_INTERFACE
{
    return TYPE_INTERFACE;
}

+ (QuickActionType *) TYPE_CONFIGURE_MAP
{
    return TYPE_CONFIGURE_MAP;
}

+ (QuickActionType *) TYPE_NAVIGATION
{
    return TYPE_NAVIGATION;
}

+ (QuickActionType *) TYPE_CONFIGURE_SCREEN
{
    return TYPE_CONFIGURE_SCREEN;
}

+ (QuickActionType *) TYPE_SETTINGS
{
    return TYPE_SETTINGS;
}

+ (QuickActionType *) TYPE_MAP_INTERACTIONS
{
    return TYPE_MAP_INTERACTIONS;
}

+ (QuickActionType *) TYPE_MY_PLACES
{
    return TYPE_MY_PLACES;
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
        _serializer = [QuickActionSerializer new];
        
        _defaultSizePref = [[_settings registerIntPreference:@"default_map_button_size" defValue:(int)MapButtonState.originalValue] makeProfile];
        _defaultOpacityPref = [[_settings registerFloatPreference:@"default_map_button_opacity" defValue:(float)MapButtonState.originalValue] makeProfile];
        _defaultCornerRadiusPref = [[_settings registerIntPreference:@"default_map_button_corner_radius" defValue:(int)MapButtonState.originalValue] makeProfile];
        _defaultGlassStylePref = [[_settings registerIntPreference:@"default_map_button_glass_style" defValue:(int)MapButtonState.originalValue] makeProfile];
        
        [self updateActionTypes];
        [self initDefaultButtons];
    }
    return self;
}

- (void)initDefaultButtons
{
    _map3DButtonState = [Map3DButtonState new];
    _compassButtonState = [CompassButtonState new];
    _zoomInButtonState = [ZoomInButtonState new];
    _zoomOutButtonState = [ZoomOutButtonState new];
    _searchButtonState = [SearchButtonState new];
    _navigationModeButtonState = [DriveModeButtonState new];
    _myLocationButtonState = [MyLocationButtonState new];
    _menuButtonState = [OptionsMenuButtonState new];
    _configureMapButtonState = [MapSettingsButtonState new];
}

- (Map3DButtonState *)getMap3DButtonState
{
    return _map3DButtonState;
}

- (CompassButtonState *)getCompassButtonState
{
    return _compassButtonState;
}

- (ZoomInButtonState *)getZoomInButtonState
{
    return _zoomInButtonState;
}

- (ZoomOutButtonState *)getZoomOutButtonState
{
    return _zoomOutButtonState;
}

- (SearchButtonState *)getSearchButtonState
{
    return _searchButtonState;
}

- (DriveModeButtonState *)getNavigationModeButtonState
{
    return _navigationModeButtonState;
}

- (MyLocationButtonState *)getMyLocationButtonState
{
    return _myLocationButtonState;
}

- (OptionsMenuButtonState *)getMenuButtonState
{
    return _menuButtonState;
}

- (MapSettingsButtonState *)getConfigureMapButtonState
{
    return _configureMapButtonState;
}

- (NSArray<QuickActionButtonState *> *)getButtonsStates;
{
    return _mapButtonStates;
}

- (NSArray<QuickActionButtonState *> *)getEnabledButtonsStates
{
    NSMutableArray<QuickActionButtonState *> *list = [NSMutableArray array];
    for (QuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([buttonState isEnabled])
            [list addObject:buttonState];
    }
    return list;
}

- (NSArray<MapButtonState *> *)getDefaultButtonsStates
{
    return @[_configureMapButtonState,
             _searchButtonState,
             _compassButtonState,
             _menuButtonState,
             _navigationModeButtonState,
             _map3DButtonState,
             _myLocationButtonState,
             _zoomInButtonState,
             _zoomOutButtonState];
}

- (QuickActionSerializer *)getSerializer
{
    return _serializer;
}

- (void)addQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState add:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)deleteQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState remove:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)updateQuickAction:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    [buttonState set:action];
    [self onQuickActionsChanged:buttonState];
}

- (void)updateQuickActions:(QuickActionButtonState *)buttonState actions:(NSArray<OAQuickAction *> *)actions
{
    [buttonState setWithQuickActions:actions];
    [self onQuickActionsChanged:buttonState];
}

- (void)onQuickActionsChanged:(QuickActionButtonState *)buttonState
{
    [buttonState saveActions:_serializer];
    [_quickActionsChangedObservable notifyEventWithKey:buttonState];
}

- (void)refreshQuickActionButtons
{
    [_quickActionButtonsChangedObservable notifyEvent];
}

- (BOOL)isActionNameUnique:(NSArray<OAQuickAction *> *)actions quickAction:(OAQuickAction *)quickAction
{
    for (OAQuickAction *action in actions)
    {
        if (quickAction.id != action.id && [[quickAction getExtendedName] isEqualToString:[action getExtendedName]])
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
    NSMutableArray<QuickActionType *> *allTypes = [NSMutableArray new];
   
    // configure map
    [allTypes addObject:OAShowHideFavoritesAction.getQuickActionType];
    [allTypes addObject:OAShowHideGPXTracksAction.getQuickActionType];
    [allTypes addObject:OAShowHidePoiAction.getQuickActionType];
    [allTypes addObject:OADayNightModeAction.getQuickActionType];
    [allTypes addObject:OAMapStyleAction.getQuickActionType];
    [allTypes addObject:TerrainColorSchemeAction.getQuickActionType];
    [allTypes addObject:OAMapSourceAction.getQuickActionType];
    [allTypes addObject:OAMapOverlayAction.getQuickActionType];
    [allTypes addObject:[MapUnderlayAction getQuickActionType]];
    [allTypes addObject:OAShowHideMapillaryAction.getQuickActionType];
    [allTypes addObject:OAShowHideTransportLinesAction.getQuickActionType];
    [allTypes addObject:[ShowHideCycleRoutesAction getQuickActionType]];
    [allTypes addObject:[ShowHideMtbRoutesAction getQuickActionType]];
    [allTypes addObject:[ShowHideHikingRoutesAction getQuickActionType]];
    [allTypes addObject:[ShowHideDifficultyClassificationAction getQuickActionType]];
    [allTypes addObject:[ShowHideSkiSlopesAction getQuickActionType]];
    [allTypes addObject:[ShowHideHorseRoutesAction getQuickActionType]];
    [allTypes addObject:[ShowHideWhitewaterSportsAction getQuickActionType]];
    [allTypes addObject:[ShowHideFitnessTrailsAction getQuickActionType]];
    [allTypes addObject:[ShowHideRunningRoutesAction getQuickActionType]];
    [allTypes addObject:ShowHideCoordinatesGridAction.getQuickActionType];
    [allTypes addObject:OpenWeatherAction.getQuickActionType];
    
    // interface
    [allTypes addObject:LockScreenAction.getQuickActionType];
    [allTypes addObject:OpenNavigationViewAction.getQuickActionType];
    [allTypes addObject:OpenSearchViewAction.getQuickActionType];
    [allTypes addObject:ShowHideDrawerAction.getQuickActionType];
    [allTypes addObject:NavigatePreviousScreenAction.getQuickActionType];
    [allTypes addObject:OpenWunderLINQDatagridAction.getQuickActionType];
    
    // map interactions
    [allTypes addObject:MapZoomInAction.getQuickActionType];
    [allTypes addObject:MapZoomOutAction.getQuickActionType];
    [allTypes addObject:MapScrollLeftAction.getQuickActionType];
    [allTypes addObject:MapScrollRightAction.getQuickActionType];
    [allTypes addObject:MoveToMyLocationAction.getQuickActionType];
    [allTypes addObject:MapScrollUpAction.getQuickActionType];
    [allTypes addObject:MapScrollDownAction.getQuickActionType];
    
    // my places
    [allTypes addObject:OAFavoriteAction.getQuickActionType];
    [allTypes addObject:OAGPXAction.getQuickActionType];
    [allTypes addObject:OAMarkerAction.getQuickActionType];
    [allTypes addObject:RouteAction.getQuickActionType];

    // navigation
    [allTypes addObject:OANavStartStopAction.getQuickActionType];
    [allTypes addObject:OANavResumePauseAction.getQuickActionType];
    [allTypes addObject:OANavDirectionsFromAction.getQuickActionType];
    [allTypes addObject:OANavAddFirstIntermediateAction.getQuickActionType];
    [allTypes addObject:OANavAddDestinationAction.getQuickActionType];
    [allTypes addObject:OANavReplaceDestinationAction.getQuickActionType];
    [allTypes addObject:OANavRemoveNextDestination.getQuickActionType];
    [allTypes addObject:OANavAutoZoomMapAction.getQuickActionType];
    [allTypes addObject:OANavVoiceAction.getQuickActionType];
    
    // settings
    [allTypes addObject:DisplayPositionAction.getQuickActionType];
    [allTypes addObject:OASwitchProfileAction.getQuickActionType];
    [allTypes addObject:NextAppProfileAction.getQuickActionType];
    [allTypes addObject:PreviousAppProfileAction.getQuickActionType];
    [allTypes addObject:ChangeMapOrientationAction.getQuickActionType];

    NSMutableArray<QuickActionType *> *enabledTypes = [NSMutableArray arrayWithArray:allTypes];
    [OAPluginsHelper registerQuickActionTypesPlugins:allTypes enabledTypes:enabledTypes];
    
    NSMutableDictionary<NSNumber *, QuickActionType *> *quickActionTypesInt = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, QuickActionType *> *quickActionTypesStr = [NSMutableDictionary new];
    for (QuickActionType *qt in allTypes)
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

- (NSMutableArray<QuickActionButtonState *> * _Nonnull)createButtonsStates
{
    NSMutableArray<QuickActionButtonState *> *list = [NSMutableArray array];
    NSArray<NSString *> *actionsKeys = [_settings.quickActionButtons get];
    if (actionsKeys && actionsKeys.count > 0)
    {
        for (NSString *key in actionsKeys)
        {
            if (key.length > 0)
            {
                @try {
                    QuickActionButtonState *buttonState = [[QuickActionButtonState alloc] initWithId:key];
                    [buttonState parseQuickActions:_serializer error:nil];
                    [list addObject:buttonState];
                }
                @catch (NSException *e)
                {
                    NSLog(@"%@", e.reason);
                }
            }
        }
    }
    return list;
}

- (void)resetQuickActionsForMode:(OAApplicationMode *)appMode
{
    for (QuickActionButtonState *buttonState in [self getButtonsStates])
    {
        [buttonState resetForMode:appMode];
    }
    [self updateActionTypes];
}

- (void)copyQuickActionsFromMode:(OAApplicationMode *)toAppMode fromAppMode:(OAApplicationMode *)fromAppMode
{
    for (QuickActionButtonState *buttonState in [self getButtonsStates])
    {
        [buttonState copyForModeFrom:fromAppMode to:toAppMode];
    }
    [self updateActionTypes];
}

- (NSArray<QuickActionType *> *)produceTypeActionsListWithHeaders:(QuickActionButtonState *)buttonState
{
    NSMutableArray<QuickActionType *> *actionTypes = [NSMutableArray new];
    [self filterQuickActions:buttonState filter:TYPE_CREATE_CATEGORY actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_CONFIGURE_MAP actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_INTERFACE actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_MAP_INTERACTIONS actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_MY_PLACES actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_NAVIGATION actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_CONFIGURE_SCREEN actionTypes:actionTypes];
    [self filterQuickActions:buttonState filter:TYPE_SETTINGS actionTypes:actionTypes];

    return actionTypes;
}

- (void)filterQuickActions:(QuickActionButtonState *)buttonState filter:(QuickActionType *)filter actionTypes:(NSMutableArray<QuickActionType *> *)actionTypes
{
    [actionTypes addObject:filter];

    NSMutableSet<NSNumber *> *set = [NSMutableSet new];
    for (OAQuickAction *action in buttonState.quickActions)
    {
        [set addObject:@(action.actionType.id)];
    }
    for (QuickActionType *type in _enabledTypes)
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
    QuickActionType *quickActionType = _quickActionTypesStr[actionType];
    if (quickActionType)
        return [quickActionType createNew];
    return nil;
}

- (OAQuickAction *)newActionByType:(NSInteger)type
{
    QuickActionType *quickActionType = _quickActionTypesInt[@(type)];
    if (quickActionType != nil)
        return [quickActionType createNew];
    return nil;
}

- (NSArray<NSDictionary *> *)convertActionsToJson:(NSArray<OAQuickAction *> *)quickActions
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    for (OAQuickAction *action in quickActions)
    {
        NSDictionary *dict = [action toDictionary];
        if (dict)
            [jsonArray addObject:dict];
    }
    return [jsonArray copy];
}

- (BOOL)isActionButtonNameUnique:(NSString *)name
{
    return [self getButtonStateByName:name] == nil;
}

- (QuickActionButtonState *)getButtonStateByName:(NSString *)name
{
    for (QuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([[buttonState getName] isEqualToString:name])
            return buttonState;
    }
    return nil;
}

- (QuickActionButtonState *)getButtonStateById:(NSString *)id
{
    for (QuickActionButtonState *buttonState in _mapButtonStates)
    {
        if ([buttonState.id isEqualToString:id])
            return buttonState;
    }
    return nil;
}

- (OACommonInteger *)getDefaultSizePref
{
    return _defaultSizePref;
}

- (OACommonDouble *)getDefaultOpacityPref
{
    return _defaultOpacityPref;
}

- (OACommonInteger *)getDefaultCornerRadiusPref
{
    return _defaultCornerRadiusPref;
}

- (OACommonInteger *)getDefaultGlassStylePref
{
    return _defaultGlassStylePref;
}

- (QuickActionButtonState *)createNewButtonState
{
    NSString *id = [NSString stringWithFormat:@"%@_%ld", QuickActionButtonState.defaultButtonId, (long) ([[NSDate date] timeIntervalSince1970] * 1000)];
    return [[QuickActionButtonState alloc] initWithId:id];
}

- (void)addQuickActionButtonState:(QuickActionButtonState *)buttonState
{
    [_settings.quickActionButtons addUnique:buttonState.id];
    [self updateActiveActions];
    [_quickActionButtonsChangedObservable notifyEventWithKey:buttonState andValue:@(YES)];
}

- (void)removeQuickActionButtonState:(QuickActionButtonState *)buttonState
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
