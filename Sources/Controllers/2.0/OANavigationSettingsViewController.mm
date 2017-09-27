//
//  OANavigationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANavigationSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "PXAlertView.h"

#include <generalRouter.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"

@interface OANavigationSettingsViewController ()

@property (nonatomic) NSDictionary *settingItem;

@end

@implementation OANavigationSettingsViewController
{
    OAApplicationMode *_am;
    NSArray *_data;
    
    BOOL _initialSpeedCam;
    BOOL _initialFavorites;
    BOOL _initialPOI;
    
    BOOL _showAppModeDialog;
}

static NSArray<NSNumber *> *autoFollowRouteValues;
static NSArray<NSString *> *autoFollowRouteEntries;
static NSArray<NSNumber *> *keepInformingValues;
static NSArray<NSString *> *keepInformingEntries;
static NSArray<NSNumber *> *arrivalValues;
static NSArray<NSString *> *arrivalNames;
static NSArray<NSNumber *> *speedLimitsKm;
static NSArray<NSNumber *> *speedLimitsMiles;
static NSArray<NSNumber *> *screenPowerSaveValues;
static NSArray<NSString *> *screenPowerSaveNames;

+ (void) initialize
{
    if (self == [OANavigationSettingsViewController class])
    {
        autoFollowRouteValues = @[ @0, @5, @10, @15, @20, @25, @30, @45, @60, @90 ];
        NSMutableArray *array = [NSMutableArray array];
        for (NSNumber *val in autoFollowRouteValues)
        {
            if (val.intValue == 0)
                [array addObject:OALocalizedString(@"shared_string_never")];
            else
                [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"int_seconds")]];
        }
        autoFollowRouteEntries = [NSArray arrayWithArray:array];
        
        keepInformingValues = @[ @0, @1, @2, @3, @5, @7, @10, @15, @20, @25, @30 ];
        array = [NSMutableArray array];
        for (NSNumber *val in keepInformingValues)
        {
            if (val.intValue == 0)
                [array addObject:OALocalizedString(@"keep_informing_never")];
            else
                [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"units_min")]];
        }
        keepInformingEntries = [NSArray arrayWithArray:array];
        
        arrivalValues = @[ @1.5f, @1.f, @0.5f, @0.25f ];
        arrivalNames =  @[ OALocalizedString(@"arrival_distance_factor_early"),
                           OALocalizedString(@"arrival_distance_factor_normally"),
                           OALocalizedString(@"arrival_distance_factor_late"),
                           OALocalizedString(@"arrival_distance_factor_at_last") ];
        
        speedLimitsKm = @[ @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
        speedLimitsMiles = @[ @0.f, @3.f, @5.f, @7.f, @10.f, @15.f ];
        
        screenPowerSaveValues = @[ @0, @5, @10, @15, @20, @30, @45, @60 ];
        array = [NSMutableArray array];
        for (NSNumber *val in screenPowerSaveValues)
        {
            if (val.intValue == 0)
                [array addObject:OALocalizedString(@"shared_string_never")];
            else
                [array addObject:[NSString stringWithFormat:@"%d %@", val.intValue, OALocalizedString(@"int_seconds")]];
        }
        screenPowerSaveNames = [NSArray arrayWithArray:array];
    }
}

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        _am = [OAApplicationMode CAR];
        _showAppModeDialog = YES;
    }
    return self;
}

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        _am = applicationMode;
        _showAppModeDialog = NO;
    }
    return self;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"routing_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
    if (_showAppModeDialog)
    {
        _showAppModeDialog = NO;
        [self showAppModeDialog];
    }
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSMutableArray *dataArr = [NSMutableArray array];
    switch (self.settingsType)
    {
        case kNavigationSettingsScreenGeneral:
        {
            //data[OALocalizedString(@"routing_preferences_descr")] = dataArr;

            auto router = [self getRouter:_am];
            if (router)
            {
                auto& parameters = router->getParameters();
                if (parameters.find("short_way") != parameters.end())
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"fast_route_mode",
                       @"title" : OALocalizedString(@"fast_route_mode"),
                       @"description" : OALocalizedString(@"fast_route_mode_descr"),
                       @"value" : settings.fastRouteMode,
                       @"type" : kCellTypeSwitch }
                     ];
                }
                BOOL avoidParameters = NO;
                BOOL preferParameters = NO;
                BOOL reliefFactorParameters = NO;
                NSString *reliefFactorParameterSelected = @"";
                NSString *reliefFactorParameterGroup = nil;
                vector<RoutingParameter> others;
                for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                {
                    NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
                    auto& routingParameter = it->second;
                    if ([param hasPrefix:@"avoid_"])
                    {
                        avoidParameters = YES;
                    }
                    else if ([param hasPrefix:@"prefer_"])
                    {
                        preferParameters = YES;
                    }
                    else if ("relief_smoothness_factor" == routingParameter.group)
                    {
                        reliefFactorParameters = YES;
                        if ([self isRoutingParameterSelected:_am routingParameter:routingParameter])
                            reliefFactorParameterSelected = [self getRoutingStringPropertyName:[NSString stringWithUTF8String:routingParameter.id.c_str()]];
                        if (!reliefFactorParameterGroup)
                            reliefFactorParameterGroup = [NSString stringWithUTF8String:routingParameter.group.c_str()];
                    }
                    else if (![param isEqualToString:@"short_way"] && "driving_style" != routingParameter.group)
                    {
                        others.push_back(routingParameter);
                    }
                }
                if (avoidParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"avoid_routing",
                       @"title" : OALocalizedString(@"avoid_in_routing_title"),
                       @"description" : OALocalizedString(@"avoid_in_routing_descr"),
                       @"img" : @"menu_cell_pointer.png",
                       @"type" : kCellTypeMultiSelectionList }
                     ];
                }
                if (preferParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"prefer_routing",
                       @"title" : OALocalizedString(@"prefer_in_routing_title"),
                       @"description" : OALocalizedString(@"prefer_in_routing_descr"),
                       @"img" : @"menu_cell_pointer.png",
                       @"type" : kCellTypeMultiSelectionList }
                     ];
                }
                if (reliefFactorParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"relief_factor",
                       @"title" : [self getRoutingStringPropertyName:reliefFactorParameterGroup],
                       @"description" : OALocalizedString(@"relief_smoothness_factor_descr"),
                       @"value" : reliefFactorParameterSelected,
                       @"img" : @"menu_cell_pointer.png",
                       @"type" : kCellTypeSingleSelectionList }
                     ];
                }
                for (auto& p : others)
                {
                    NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                    NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                    NSString *description = [self getRoutingStringPropertyDescription:paramId defaultName:[NSString stringWithUTF8String:p.description.c_str()]];

                    if (p.type == RoutingParameterType::BOOLEAN)
                    {
                        OAProfileBoolean *booleanParam = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                        [dataArr addObject:
                         @{
                           @"name" : paramId,
                           @"title" : title,
                           @"description" : description,
                           @"value" : booleanParam,
                           @"type" : kCellTypeSwitch }
                         ];
                    }
                    else
                    {
                        OAProfileString *stringParam = [settings getCustomRoutingProperty:paramId defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                        
                        NSString *v = [stringParam get:_am];
                        double d = v ? v.doubleValue : DBL_MAX;
                        
                        int index = -1;
                        for (int i = 0; i < p.possibleValues.size(); i++)
                        {
                            double vl = p.possibleValues[i];
                            if (vl == d)
                            {
                                index = i;
                                break;
                            }
                        }
                        
                        if (index != -1)
                            v = [NSString stringWithUTF8String:p.possibleValueDescriptions[index].c_str()];
                        
                        [dataArr addObject:
                         @{
                           @"name" : paramId,
                           @"title" : title,
                           @"description" : description,
                           @"value" : v,
                           @"setting" : stringParam,
                           @"img" : @"menu_cell_pointer.png",
                           @"type" : kCellTypeSingleSelectionList }
                         ];
                    }
                }
            }
            
            NSString *value = nil;
            NSUInteger index = [autoFollowRouteValues indexOfObject:@([settings.autoFollowRoute get:_am])];
            if (index != NSNotFound)
                value = autoFollowRouteEntries[index];
            
            [dataArr addObject:
             @{
               @"name" : @"auto_follow_route",
               @"header" : OALocalizedString(@"guidance_preferences_descr"),
               @"title" : OALocalizedString(@"choose_auto_follow_route"),
               @"description" : OALocalizedString(@"choose_auto_follow_route_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            if (![settings.autoZoomMap get:_am])
            {
                value = OALocalizedString(@"auto_zoom_none");
            }
            else
            {
                EOAAutoZoomMap autoZoomMap = [settings.autoZoomMapScale get:_am];
                value = [OAAutoZoomMap getName:autoZoomMap];
            }
            
            [dataArr addObject:
             @{
               @"name" : @"auto_zoom_map_on_off",
               @"title" : OALocalizedString(@"auto_zoom_map"),
               @"description" : OALocalizedString(@"auto_zoom_map_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            [dataArr addObject:
             @{
               @"name" : @"snap_to_road",
               @"title" : OALocalizedString(@"snap_to_road"),
               @"description" : OALocalizedString(@"snap_to_road_descr"),
               @"value" : settings.snapToRoad,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSwitch }
             ];

            [dataArr addObject:
             @{
               @"name" : @"show_routing_alarms",
               @"title" : OALocalizedString(@"show_warnings_title"),
               @"description" : OALocalizedString(@"show_warnings_descr"),
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeMultiSelectionList }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"speak_routing_alarms",
               @"title" : OALocalizedString(@"speak_title"),
               @"description" : OALocalizedString(@"speak_descr"),
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeMultiSelectionList }
             ];

            value = nil;
            index = [keepInformingValues indexOfObject:@([settings.keepInforming get:_am])];
            if (index != NSNotFound)
                value = keepInformingEntries[index];

            [dataArr addObject:
             @{
               @"name" : @"keep_informing",
               @"title" : OALocalizedString(@"keep_informing"),
               @"description" : OALocalizedString(@"keep_informing_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            
            value = nil;
            index = [arrivalValues indexOfObject:@([settings.arrivalDistanceFactor get:_am])];
            if (index != NSNotFound)
                value = arrivalNames[index];

            [dataArr addObject:
             @{
               @"name" : @"arrival_distance_factor",
               @"title" : OALocalizedString(@"arrival_distance"),
               @"description" : OALocalizedString(@"arrival_distance_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList
               }
             ];
            
            [dataArr addObject:
             @{
               @"name" : @"default_speed_system",
               @"title" : OALocalizedString(@"default_speed_system"),
               @"description" : OALocalizedString(@"default_speed_system_descr"),
               @"value" : [OASpeedConstant toHumanString:[settings.speedSystem get:_am]],
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            if ([_am isDerivedRoutingFrom:[OAApplicationMode CAR]])
            {
                value = nil;
                if (settings.metricSystem == KILOMETERS_AND_METERS)
                {
                    value = [NSString stringWithFormat:@"%d %@", (int)[settings.speedLimitExceed get:_am], OALocalizedString(@"units_kmh")];
                }
                else
                {
                    NSUInteger index = [speedLimitsKm indexOfObject:@([settings.speedLimitExceed get:_am])];
                    if (index != NSNotFound)
                        value = [NSString stringWithFormat:@"%d %@", speedLimitsMiles[index].intValue, OALocalizedString(@"units_mph")];
                }
                
                [dataArr addObject:
                 @{
                   @"name" : @"speed_limit_exceed",
                   @"title" : OALocalizedString(@"speed_limit_exceed"),
                   @"description" : OALocalizedString(@"speed_limit_exceed_message"),
                   @"value" : value,
                   @"img" : @"menu_cell_pointer.png",
                   @"type" : kCellTypeSingleSelectionList }
                 ];
            }
            
            value = nil;
            if (settings.metricSystem == KILOMETERS_AND_METERS)
            {
                value = [NSString stringWithFormat:@"%d %@", (int)[settings.switchMapDirectionToCompass get:_am], OALocalizedString(@"units_kmh")];
            }
            else
            {
                NSUInteger index = [speedLimitsKm indexOfObject:@([settings.switchMapDirectionToCompass get:_am])];
                if (index != NSNotFound)
                    value = [NSString stringWithFormat:@"%d %@", speedLimitsMiles[index].intValue, OALocalizedString(@"units_mph")];
            }

            [dataArr addObject:
             @{
               @"name" : @"speed_for_map_to_direction_of_movement",
               @"title" : OALocalizedString(@"map_orientation_change_in_accordance_with_speed"),
               @"description" : OALocalizedString(@"map_orientation_change_in_accordance_with_speed_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            value = nil;
            index = [screenPowerSaveValues indexOfObject:@([settings.wakeOnVoiceInt get:_am])];
            if (index != NSNotFound)
                value = screenPowerSaveNames[index];
            
            [dataArr addObject:
             @{
               @"name" : @"wake_on_voice_int",
               @"title" : OALocalizedString(@"wake_on_voice"),
               @"description" : OALocalizedString(@"wake_on_voice_descr"),
               @"value" : value,
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];
            
            /* TODO - voice
             
            //data[OALocalizedString(@"voice_pref_title")] = dataArr;

            [dataArr addObject:
             @{
               @"name" : @"voice_provider",
               @"title" : OALocalizedString(@"voice_provider"),
               @"description" : OALocalizedString(@"voice_provider_descr"),
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            [dataArr addObject:
             @{
               @"name" : @"audio_stream_guidance",
               @"title" : OALocalizedString(@"choose_audio_stream"),
               @"description" : OALocalizedString(@"choose_audio_stream_descr"),
               @"img" : @"menu_cell_pointer.png",
               @"type" : kCellTypeSingleSelectionList }
             ];

            [dataArr addObject:
             @{
               @"name" : @"interrupt_music",
               @"title" : OALocalizedString(@"interrupt_music"),
               @"description" : OALocalizedString(@"interrupt_music_descr"),
               @"value" : settings.interruptMusic,
               @"type" : kCellTypeSwitch }
             ];
             */

            NSMutableDictionary *firstRow = [NSMutableDictionary dictionaryWithDictionary:dataArr[0]];
            firstRow[@"header"] = OALocalizedString(@"routing_preferences_descr");
            dataArr[0] = [NSDictionary dictionaryWithDictionary:firstRow];

            break;
        }
        case kNavigationSettingsScreenAvoidRouting:
        {
            _titleView.text = OALocalizedString(@"avoid_in_routing_title");
            auto router = [self getRouter:_am];
            if (router)
            {
                auto& parameters = router->getParameters();
                for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                {
                    NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
                    if ([param hasPrefix:@"avoid_"])
                    {
                        auto& p = it->second;
                        NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                        NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                        OAProfileBoolean *value = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                        [dataArr addObject:
                         @{
                           @"name" : param,
                           @"title" : title,
                           @"value" : value,
                           @"type" : kCellTypeSwitch }
                         ];
                    }
                }
            }
            break;
        }
        case kNavigationSettingsScreenPreferRouting:
        {
            _titleView.text = OALocalizedString(@"prefer_in_routing_title");
            auto router = [self getRouter:_am];
            if (router)
            {
                auto& parameters = router->getParameters();
                for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                {
                    NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
                    if ([param hasPrefix:@"prefer_"])
                    {
                        auto& p = it->second;
                        NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                        NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                        OAProfileBoolean *value = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];
                        
                        [dataArr addObject:
                         @{
                           @"name" : param,
                           @"title" : title,
                           @"value" : value,
                           @"type" : kCellTypeSwitch }
                         ];
                    }
                }
            }
            break;
        }
        case kNavigationSettingsScreenReliefFactor:
        {
            auto router = [self getRouter:_am];
            if (router)
            {
                NSString *reliefFactorParameterGroup = nil;
                auto& parameters = router->getParameters();
                for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                {
                    NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
                    auto& routingParameter = it->second;
                    if ("relief_smoothness_factor" == routingParameter.group)
                    {
                        BOOL selected = [self isRoutingParameterSelected:_am routingParameter:routingParameter];
                        [dataArr addObject:
                         @{
                           @"name" : param,
                           @"title" : [self getRoutingStringPropertyName:[NSString stringWithUTF8String:routingParameter.id.c_str()]],
                           @"img" : selected ? @"menu_cell_selected.png" : @"",
                           @"type" : kCellTypeCheck }
                         ];
                        
                        if (!reliefFactorParameterGroup)
                            reliefFactorParameterGroup = [NSString stringWithUTF8String:routingParameter.group.c_str()];
                    }
                }
                if (reliefFactorParameterGroup)
                    _titleView.text = [self getRoutingStringPropertyName:reliefFactorParameterGroup];
            }
            break;
        }
        case kNavigationSettingsScreenRoutingParameter:
        {
            if ([_settingItem[@"setting"] isKindOfClass:[OAProfileString class]])
            {
                _titleView.text = _settingItem[@"title"];
                NSString *name = _settingItem[@"name"];
                OAProfileString *stringParam = _settingItem[@"setting"];
                auto router = [self getRouter:_am];
                if (router)
                {
                    auto& parameters = router->getParameters();
                    for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                    {
                        auto& p = it->second;
                        NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                        if ([paramId isEqualToString:name])
                        {
                            NSString *v = [stringParam get:_am];
                            double d = v ? v.doubleValue : DBL_MAX;
                            
                            for (int i = 0; i < p.possibleValues.size(); i++)
                            {
                                double vl = p.possibleValues[i];
                                [dataArr addObject:
                                 @{
                                   @"name" : [NSString stringWithFormat:@"%f", p.possibleValues[i]],
                                   @"title" : [NSString stringWithUTF8String:p.possibleValueDescriptions[i].c_str()],
                                   @"img" : vl == d ? @"menu_cell_selected.png" : @"",
                                   @"type" : kCellTypeCheck }
                                 ];
                            }
                        }
                    }
                }
            }
            break;
        }
        case kNavigationSettingsScreenAutoFollowRoute:
        {
            _titleView.text = OALocalizedString(@"choose_auto_follow_route");
            int selectedValue = [settings.autoFollowRoute get:_am];
            for (int i = 0; i < autoFollowRouteValues.count; i++)
            {
                [dataArr addObject:
                 @{
                   @"name" : autoFollowRouteValues[i],
                   @"title" : autoFollowRouteEntries[i],
                   @"img" : autoFollowRouteValues[i].intValue == selectedValue ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        case kNavigationSettingsScreenAutoZoomMap:
        {
            _titleView.text = OALocalizedString(@"auto_zoom_map");
            
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"auto_zoom_none"),
               @"img" : ![settings.autoZoomMap get:_am] ? @"menu_cell_selected.png" : @"",
               @"type" : kCellTypeCheck }
             ];

            EOAAutoZoomMap autoZoomMap = [settings.autoZoomMapScale get:_am];
            NSArray<OAAutoZoomMap *> *values = [OAAutoZoomMap values];
            for (OAAutoZoomMap *v in values)
            {
                [dataArr addObject:
                 @{
                   @"name" : @(v.autoZoomMap),
                   @"title" : v.name,
                   @"img" : [settings.autoZoomMap get:_am] && v.autoZoomMap == autoZoomMap ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        case kNavigationSettingsScreenShowRoutingAlarms:
        {
            _titleView.text = OALocalizedString(@"show_warnings_title");

            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"show_traffic_warnings"),
               @"value" : settings.showTrafficWarnings,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"show_pedestrian_warnings"),
               @"value" : settings.showPedestrian,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"show_cameras"),
               @"value" : settings.showCameras,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"show_lanes"),
               @"value" : settings.showLanes,
               @"type" : kCellTypeSwitch }
             ];

            break;
        }
        case kNavigationSettingsScreenSpeakRoutingAlarms:
        {
            _titleView.text = OALocalizedString(@"speak_title");
                        
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_street_names"),
               @"value" : settings.speakStreetNames,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_traffic_warnings"),
               @"value" : settings.speakTrafficWarnings,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_pedestrian"),
               @"value" : settings.speakPedestrian,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_speed_limit"),
               @"value" : settings.speakSpeedLimit,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_cameras"),
               @"value" : settings.speakCameras,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"announce_gpx_waypoints"),
               @"value" : settings.announceWpt,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_favorites"),
               @"value" : settings.announceNearbyFavorites,
               @"type" : kCellTypeSwitch }
             ];
            [dataArr addObject:
             @{
               @"title" : OALocalizedString(@"speak_poi"),
               @"value" : settings.announceNearbyPoi,
               @"type" : kCellTypeSwitch }
             ];

            _initialSpeedCam = [settings.speakCameras get:_am];
            _initialFavorites = [settings.announceNearbyFavorites get:_am];
            _initialPOI = [settings.announceNearbyPoi get:_am];

            break;
        }
        case kNavigationSettingsScreenKeepInforming:
        {
            _titleView.text = OALocalizedString(@"keep_informing");
            
            int selectedValue = [settings.keepInforming get:_am];
            for (int i = 0; i < keepInformingValues.count; i++)
            {
                [dataArr addObject:
                 @{
                   @"name" : keepInformingValues[i],
                   @"title" : keepInformingEntries[i],
                   @"img" : keepInformingValues[i].intValue == selectedValue ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        case kNavigationSettingsScreenArrivalDistanceFactor:
        {
            _titleView.text = OALocalizedString(@"arrival_distance");
            
            double selectedValue = [settings.arrivalDistanceFactor get:_am];
            for (int i = 0; i < arrivalValues.count; i++)
            {
                [dataArr addObject:
                 @{
                   @"name" : arrivalValues[i],
                   @"title" : arrivalNames[i],
                   @"img" : arrivalValues[i].doubleValue == selectedValue ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        case kNavigationSettingsScreenSpeedSystem:
        {
            _titleView.text = OALocalizedString(@"default_speed_system");
            
            NSArray<OASpeedConstant *> *values = [OASpeedConstant values];
            EOASpeedConstant selectedValue = [settings.speedSystem get:_am];
            for (OASpeedConstant *sc in values)
            {
                [dataArr addObject:
                 @{
                   @"name" : @(sc.sc),
                   @"title" : sc.descr,
                   @"img" : sc.sc == selectedValue ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        case kNavigationSettingsScreenSpeedLimitExceed:
        case kNavigationSettingsScreenSwitchMapDirectionToCompass:
        {
            NSUInteger index = NSNotFound;
            if (self.settingsType == kNavigationSettingsScreenSpeedLimitExceed)
            {
                _titleView.text = OALocalizedString(@"speed_limit_exceed");
                index = [speedLimitsKm indexOfObject:@([settings.speedLimitExceed get:_am])];
            }
            else
            {
                _titleView.text = OALocalizedString(@"map_orientation_change_in_accordance_with_speed");
                index = [speedLimitsKm indexOfObject:@([settings.switchMapDirectionToCompass get:_am])];
            }
            
            if (settings.metricSystem == KILOMETERS_AND_METERS)
            {
                for (int i = 0; i < speedLimitsKm.count; i++)
                {
                    [dataArr addObject:
                     @{
                       @"name" : speedLimitsKm[i],
                       @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsKm[i].intValue, OALocalizedString(@"units_kmh")],
                       @"img" : index == i ? @"menu_cell_selected.png" : @"",
                       @"type" : kCellTypeCheck }
                     ];
                }
            }
            else
            {
                for (int i = 0; i < speedLimitsKm.count; i++)
                {
                    [dataArr addObject:
                     @{
                       @"name" : speedLimitsKm[i],
                       @"title" : [NSString stringWithFormat:@"%d %@", speedLimitsMiles[i].intValue, OALocalizedString(@"units_mph")],
                       @"img" : index == i ? @"menu_cell_selected.png" : @"",
                       @"type" : kCellTypeCheck }
                     ];
                }
            }
            break;
        }
        case kNavigationSettingsScreenWakeOnVoice:
        {
            _titleView.text = OALocalizedString(@"wake_on_voice");
            int selectedValue = [settings.wakeOnVoiceInt get:_am];
            for (int i = 0; i < screenPowerSaveValues.count; i++)
            {
                [dataArr addObject:
                 @{
                   @"name" : screenPowerSaveValues[i],
                   @"title" : screenPowerSaveNames[i],
                   @"img" : screenPowerSaveValues[i].intValue == selectedValue ? @"menu_cell_selected.png" : @"",
                   @"type" : kCellTypeCheck }
                 ];
            }
            break;
        }
        default:
            break;
    }
    
    _data = [NSArray arrayWithArray:dataArr];
    
    [self.tableView reloadData];
    
    [self updateAppModeButton];
}

- (IBAction) backButtonClicked:(id)sender
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    switch (_settingsType)
    {
        case kNavigationSettingsScreenSpeakRoutingAlarms:
        {
            if ([settings.announceNearbyPoi get:_am] != _initialPOI)
                [settings.showNearbyPoi set:[settings.announceNearbyPoi get:_am] mode:_am];
            
            if ([settings.announceNearbyFavorites get:_am] != _initialFavorites)
                [settings.showNearbyFavorites set:[settings.announceNearbyFavorites get:_am] mode:_am];

            if ([settings.announceWpt get:_am])
                settings.showGpxWpt = [settings.announceWpt get:_am];
            
            if (!_initialSpeedCam)
            {
                if ([settings.speakCameras get:_am])
                {
                    [settings.speakCameras set:NO mode:_am];
                    [self confirmSpeedCamerasDlg];
                }
            }
            break;
        }
        default:
            break;
    }
    [super backButtonClicked:sender];
}

- (IBAction) appModeButtonClicked:(id)sender
{
    [self showAppModeDialog];
}

- (void) showAppModeDialog
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    NSMutableArray *modes = [NSMutableArray array];
    
    NSArray<OAApplicationMode *> *values = [OAApplicationMode values];
    for (OAApplicationMode *v in values)
    {
        if (v == [OAApplicationMode DEFAULT])
            continue;
        
        [titles addObject:v.name];
        [images addObject:v.smallIconDark];
        [modes addObject:v];
    }
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"map_settings_mode")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:titles
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 _am = modes[buttonIndex];
                                 [self setupView];
                             }
                         }];
}

- (void) updateAppModeButton
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
    {
        [_appModeButton setImage:[UIImage imageNamed:_am.smallIconDark] forState:UIControlStateNormal];
        _appModeButton.hidden = NO;
    }
    else
    {
        _appModeButton.hidden = YES;
    }
}

- (void) confirmSpeedCamerasDlg
{
    [PXAlertView showAlertWithTitle:nil
                            message:OALocalizedString(@"confirm_usage_speed_cameras")
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 [[OAAppSettings sharedManager].speakCameras set:YES mode:_am];
                             }
                         }];
}

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    OsmAndAppInstance app = [OsmAndApp instance];
    auto router = app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    
    return router;
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = [[propertyName stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedStringWithLocale:[NSLocale currentLocale]];
    
    return res;
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    
    return res;
}

- (NSString *) getRoutingStringPropertyDescription:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_description", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    
    return res;
}

- (BOOL) isRoutingParameterSelected:(OAApplicationMode *)am routingParameter:(RoutingParameter)routingParameter
{
    OAProfileBoolean *property = [[OAAppSettings sharedManager] getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:routingParameter.id.c_str()] defaultValue:routingParameter.defaultBoolean];
    if (am)
        return [property get:am];
    else
        return [property get];
}

- (void) setRoutingParameterSelected:(OAApplicationMode *)am routingParameter:(RoutingParameter)routingParameter isChecked:(BOOL)isChecked
{
    OAProfileBoolean *property = [[OAAppSettings sharedManager] getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:routingParameter.id.c_str()] defaultValue:routingParameter.defaultBoolean];
    if (am)
        return [property set:isChecked mode:am];
    else
        return [property set:isChecked];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
        return _data[indexPath.section];
    else
        return _data[indexPath.row];
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        
        BOOL isChecked = ((UISwitch *) sender).on;
        OAProfileBoolean *value = item[@"value"];
        [value set:isChecked mode:_am];
    }
}

#pragma mark - UITableViewDataSource

 - (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
        return _data.count;
    else
        return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
        return 1;
    else
        return _data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];

    if ([type isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            OAProfileBoolean *value = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [value get:_am];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        return [OASwitchTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTitleTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
    {
        NSDictionary *item = _data[section];
        return item[@"header"];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    switch (_settingsType)
    {
        case kNavigationSettingsScreenGeneral:
            [self selectGeneral:item];
            break;
        case kNavigationSettingsScreenReliefFactor:
            [self selectReliefFactor:item];
            break;
        case kNavigationSettingsScreenRoutingParameter:
            [self selectRoutingParameter:item];
            break;
        case kNavigationSettingsScreenAutoFollowRoute:
            [self selectAutoFollowRoute:item];
            break;
        case kNavigationSettingsScreenAutoZoomMap:
            [self selectAutoZoomMap:item];
            break;
        case kNavigationSettingsScreenKeepInforming:
            [self selectKeepInforming:item];
            break;
        case kNavigationSettingsScreenArrivalDistanceFactor:
            [self selectArrivalDistanceFactor:item];
            break;
        case kNavigationSettingsScreenSpeedSystem:
            [self selectSpeedSystem:item];
            break;
        case kNavigationSettingsScreenSpeedLimitExceed:
            [self selectSpeedLimitExceed:item];
            break;
        case kNavigationSettingsScreenSwitchMapDirectionToCompass:
            [self selectSwitchMapDirectionToCompass:item];
            break;
        case kNavigationSettingsScreenWakeOnVoice:
            [self selectWakeOnVoice:item];
            break;
        default:
            break;
    }
}

- (void) selectGeneral:(NSDictionary *)item
{
    NSString *name = item[@"name"];
    NSObject *setting = item[@"setting"];
    if ([@"avoid_routing" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenAvoidRouting applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"prefer_routing" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenPreferRouting applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"relief_factor" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenReliefFactor applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([setting isKindOfClass:[OAProfileSetting class]])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenRoutingParameter applicationMode:_am];
        settingsViewController.settingItem = item;
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"auto_follow_route" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenAutoFollowRoute applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"auto_zoom_map_on_off" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenAutoZoomMap applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"show_routing_alarms" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenShowRoutingAlarms applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"speak_routing_alarms" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenSpeakRoutingAlarms applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"keep_informing" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenKeepInforming applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"arrival_distance_factor" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenArrivalDistanceFactor applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"default_speed_system" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenSpeedSystem applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"speed_limit_exceed" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenSpeedLimitExceed applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"speed_for_map_to_direction_of_movement" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenSwitchMapDirectionToCompass applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([@"wake_on_voice_int" isEqualToString:name])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenWakeOnVoice applicationMode:_am];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
}

- (void) selectReliefFactor:(NSDictionary *)item
{
    auto router = [self getRouter:_am];
    if (router)
    {
        auto& parameters = router->getParameters();
        for (auto it = parameters.begin() ; it != parameters.end(); ++it)
        {
            NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
            auto& routingParameter = it->second;
            if ("relief_smoothness_factor" == routingParameter.group)
            {
                [self setRoutingParameterSelected:_am routingParameter:routingParameter isChecked:[param isEqualToString:item[@"name"]]];
            }
        }
    }
    [self backButtonClicked:nil];
}

- (void) selectRoutingParameter:(NSDictionary *)item
{
    if ([_settingItem[@"setting"] isKindOfClass:[OAProfileString class]])
    {
        OAProfileString *s = (OAProfileString *)_settingItem[@"setting"];
        [s set:item[@"name"] mode:_am];
        [self backButtonClicked:nil];
    }
}

- (void) selectAutoFollowRoute:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].autoFollowRoute set:((NSNumber *)item[@"name"]).intValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectAutoZoomMap:(NSDictionary *)item
{
    if (!item[@"name"])
    {
        [[OAAppSettings sharedManager].autoZoomMap set:NO mode:_am];
    }
    else
    {
        [[OAAppSettings sharedManager].autoZoomMap set:YES mode:_am];
        [[OAAppSettings sharedManager].autoZoomMapScale set:(EOAAutoZoomMap)((NSNumber *)item[@"name"]).intValue mode:_am];
    }
    [self backButtonClicked:nil];
}

- (void) selectKeepInforming:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].keepInforming set:((NSNumber *)item[@"name"]).intValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectArrivalDistanceFactor:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].arrivalDistanceFactor set:((NSNumber *)item[@"name"]).doubleValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectSpeedSystem:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].speedSystem set:(EOASpeedConstant)((NSNumber *)item[@"name"]).intValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectSpeedLimitExceed:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].speedLimitExceed set:((NSNumber *)item[@"name"]).doubleValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectSwitchMapDirectionToCompass:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].switchMapDirectionToCompass set:((NSNumber *)item[@"name"]).doubleValue mode:_am];
    [self backButtonClicked:nil];
}

- (void) selectWakeOnVoice:(NSDictionary *)item
{
    [[OAAppSettings sharedManager].wakeOnVoiceInt set:((NSNumber *)item[@"name"]).intValue mode:_am];
    [self backButtonClicked:nil];
}

@end
