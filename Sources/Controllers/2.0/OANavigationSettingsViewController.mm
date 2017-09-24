//
//  OANavigationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANavigationSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"

#include <generalRouter.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"

@interface OANavigationSettingsViewController ()

@end

@implementation OANavigationSettingsViewController
{
    OAApplicationMode *_am;
    NSArray *_data;
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
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
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
            //clearParameters();
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
                        double d = v ? v.intValue : DBL_MAX;
                        
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
                           @"img" : @"menu_cell_pointer.png",
                           @"type" : kCellTypeSingleSelectionList }
                         ];
                    }
                }
            }
            
            //data[OALocalizedString(@"guidance_preferences_descr")] = dataArr;
            
            NSString *value = nil;
            NSUInteger index = [autoFollowRouteValues indexOfObject:@([settings.autoFollowRoute get:_am])];
            if (index != NSNotFound)
                value = autoFollowRouteEntries[index];
            
            [dataArr addObject:
             @{
               @"name" : @"auto_follow_route",
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

            break;
        }
        case kNavigationSettingsScreenAvoidRouting:
        {
            /*
            _titleView.text = OALocalizedString(@"do_not_send_anonymous_data");
            self.data = @[@{@"name": OALocalizedString(@"shared_string_yes"), @"value": @"", @"img": settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"shared_string_no"), @"value": @"", @"img": !settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""}
                          ];
             */
            break;
        }
        default:
            break;
    }
    
    _data = [NSArray arrayWithArray:dataArr];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    [self.tableView reloadInputViews];
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
        OAProfileBoolean *value = [item objectForKey:@"value"];
        [value set:isChecked mode:_am];
    }
}

#pragma mark - UITableViewDataSource

 - (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = [item objectForKey:@"type"];

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
            [cell.textView setText: [item objectForKey:@"title"]];
            OAProfileBoolean *value = [item objectForKey:@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [value get:_am];
            cell.switchView.tag = indexPath.section << 10 + indexPath.row;
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
            cell.textView.numberOfLines = 0;
            cell.descriptionView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: [item objectForKey:@"title"]];
            [cell.descriptionView setText: [item objectForKey:@"value"]];
            [cell.iconView setImage:[UIImage imageNamed:[item objectForKey:@"img"]]];
        }
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = [item objectForKey:@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        return [OASwitchTableViewCell getHeight:[item objectForKey:@"title"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList])
    {
        return [OASettingsTableViewCell getHeight:[item objectForKey:@"title"] value:[item objectForKey:@"value"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (_settingsType == kNavigationSettingsScreenGeneral)
    {
        NSDictionary *item = _data[section];
        return [item objectForKey:@"description"];
    }
    else
    {
        return nil;
    }
}

/*
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}
*/

#pragma mark - UITableViewDelegate

@end
