//
//  OARoutePreferencesParameters.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesParameters.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OASelectedGPXHelper.h"
#import "OARouteProvider.h"
#import "OAColors.h"
#import "OAAvoidSpecificRoads.h"
#import "OAGPXDocument.h"
#import "OsmAndApp.h"
#import "OAIconTitleValueCell.h"
#import "OASettingSwitchCell.h"
#import "OASwitchTableViewCell.h"

@implementation OALocalRoutingParameter
{
    OAApplicationMode *_am;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _am = _settings.applicationMode.get;
    }
    return self;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)am
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _am = am;
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
}

- (NSString *) getText
{
    NSString *key;
    NSString *id = [NSString stringWithUTF8String:_routingParameter.id.c_str()];
    if ([id isEqualToString:kRouteParamIdHeightObstacles])
        key = @"shared_string_any";
    else
        key = [NSString stringWithFormat:@"routing_attr_%@_name", id];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = [NSString stringWithUTF8String:_routingParameter.name.c_str()];
    
    return res;
}

- (BOOL) isSelected
{
    OACommonBoolean *property = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:_routingParameter.id.c_str()] defaultValue:_routingParameter.defaultBoolean];
    
    return [property get:_am];
}

- (void) setSelected:(BOOL)isChecked
{
    OACommonBoolean *property = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:_routingParameter.id.c_str()] defaultValue:_routingParameter.defaultBoolean];
    
    [property set:isChecked mode:_am];
    if (self.delegate)
        [self.delegate updateParameters];
}

- (BOOL) routeAware
{
    return YES;
}

- (OAApplicationMode *) getApplicationMode
{
    return _am;
}

- (BOOL) isChecked
{
    if (([[NSString stringWithUTF8String:self.routingParameter.id.c_str()] isEqualToString:kRouteParamIdShortWay]))
        return ![self.settings.fastRouteMode get:[self.routingHelper getAppMode]];
    else
        return [self isSelected];
}

- (NSString *) getValue
{
    return nil;
}

- (NSString *) getDescription
{
    NSString *id = [NSString stringWithUTF8String:_routingParameter.id.c_str()];
    NSString *description;
    if ([id isEqualToString:kRouteParamIdHeightObstacles])
        description = @"route_preferred_terrain_any";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorPlain])
        description = @"route_preferred_terrain_less_hilly";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorMorePlain])
        description = @"route_preferred_terrain_flat";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorHills])
        description = @"route_preferred_terrain_hilly";
    return description ? OALocalizedString(description) : @"";
}

- (UIImage *) getIcon
{
    NSString *id = [NSString stringWithUTF8String:_routingParameter.id.c_str()];
    NSString *name;
    if ([id isEqualToString:kRouteParamIdHeightObstacles])
        name = @"ic_custom_terrain_any";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorPlain])
        name = @"ic_custom_terrain_less_hilly";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorMorePlain])
        name = @"ic_custom_terrain_flat";
    else if ([id isEqualToString:kRouteParamIdReliefSmoothnessFactorHills])
        name = @"ic_custom_terrain_hilly";
    return name ? [UIImage imageNamed:name] : nil;
}

- (NSString *) getCellType
{
    return [OASwitchTableViewCell getCellIdentifier];
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(applyRoutingParameter:) forControlEvents:UIControlEventValueChanged];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
}

- (void)applyNewParameterValue:(BOOL)isChecked
{
    if ([[NSString stringWithUTF8String:self.routingParameter.id.c_str()] isEqualToString:kRouteParamIdShortWay])
        [self.settings.fastRouteMode set:!isChecked mode:[self.routingHelper getAppMode]];
    
    [self setSelected:isChecked];
    
    if ([self isKindOfClass:[OAOtherLocalRoutingParameter class]])
        [self updateGpxRoutingParameter:((OAOtherLocalRoutingParameter *) self)];
    
    if ([self routeAware])
        [self.routingHelper recalculateRouteDueToSettingsChange];
}

- (void) applyRoutingParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        BOOL isChecked = ((UISwitch *) sender).on;
        // if short way that it should set valut to fast mode opposite of current
        [self applyNewParameterValue:isChecked];
    }
}

- (void) updateGpxRoutingParameter:(OAOtherLocalRoutingParameter *)gpxParam
{
    OAGPXRouteParamsBuilder *rp = [self.routingHelper getCurrentGPXRoute];
    BOOL selected = [gpxParam isSelected];
    if (rp)
    {
        if ([gpxParam getId] == gpx_option_reverse_route_id)
        {
            [rp setReverse:selected];
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            NSArray<CLLocation *> *ps = [rp getPoints];
            if (ps.count > 0)
            {
                CLLocation *firstLoc = ps.firstObject;
                CLLocation *lastLoc = ps.lastObject;
                OARTargetPoint *pointToStart = tg.getPointToStart;
                OARTargetPoint *pointToNavigate = tg.getPointToNavigate;
                if (rp.file.hasRoute)
                {
                    CLLocationCoordinate2D firstLatLon = CLLocationCoordinate2DMake(firstLoc.coordinate.latitude, firstLoc.coordinate.longitude);
                    CLLocationCoordinate2D endLocation = pointToStart != nil ? pointToStart.point.coordinate :
                    CLLocationCoordinate2DMake(lastLoc.coordinate.latitude, lastLoc.coordinate.longitude);
                    CLLocationCoordinate2D startLocation = pointToNavigate != nil ? pointToNavigate.point.coordinate : firstLatLon;
                    [tg navigateToPoint:[[CLLocation alloc] initWithLatitude:endLocation.latitude longitude:endLocation.longitude] updateRoute:NO intermediate:-1];
                    if (pointToStart != nil)
                    {
                        [tg setStartPoint:[[CLLocation alloc] initWithLatitude:startLocation.latitude longitude:startLocation.longitude] updateRoute:NO name:nil];
                    }
                    [tg updateRouteAndRefresh:YES];
                }
                else
                {
                    BOOL update = NO;
                    if (pointToNavigate == nil
                        || getDistance(pointToNavigate.point.coordinate.latitude, pointToNavigate.point.coordinate.longitude, firstLoc.coordinate.latitude, firstLoc.coordinate.longitude) < 10)
                    {
                        [tg navigateToPoint:lastLoc updateRoute:NO intermediate:-1];
                        update = YES;
                    }
                    if (pointToStart != nil
                        && getDistance(pointToStart.point.coordinate.latitude, pointToStart.point.coordinate.longitude,
                                       lastLoc.coordinate.latitude, lastLoc.coordinate.longitude) < 10)
                    {
                        [tg setStartPoint:firstLoc updateRoute:NO name:nil];
                        update = YES;
                    }
                    if (update)
                    {
                        [tg updateRouteAndRefresh:YES];
                    }
                }
            }
        }
        else if ([gpxParam getId] == gpx_option_calculate_first_last_segment_id)
        {
            [rp setCalculateOsmAndRouteParts:selected];
            [self.settings.gpxRouteCalcOsmandParts set:selected];
        }
        else if ([gpxParam getId] == gpx_option_from_start_point_id)
        {
            [rp setPassWholeRoute:selected];
        }
        else if ([gpxParam getId] == use_points_as_intermediates_id)
        {
            [self.settings.gpxCalculateRtept set:selected];
            [rp setUseIntermediatePointsRTE:selected];
        }
        else if ([gpxParam getId] == calculate_osmand_route_gpx_id)
        {
            [self.settings.gpxRouteCalc set:selected];
            [rp setCalculateOsmAndRoute:selected];
            if (self.delegate)
                [self.delegate updateParameters];
        }
        else if ([gpxParam getId] == connect_route_points_id)
        {
            [rp setConnectRoutePoints:selected];
        }
    }
    if ([gpxParam getId] == calculate_osmand_route_without_internet_id)
        [self.settings.gpxRouteCalcOsmandParts set:selected];
    
    if ([gpxParam getId] == fast_route_mode_id)
        [self.settings.fastRouteMode set:selected];
    
    if ([gpxParam getId] == speak_favorites_id)
        [self.settings.announceNearbyFavorites set:selected];
}

- (UIImage *)getSecondaryIcon
{
    return nil;
}

- (UIColor *) getTintColor
{
    return UIColorFromRGB(color_primary_purple);
}

@end

@implementation OALocalNonAvoidParameter

- (NSString *)getCellType
{
    return [OASettingSwitchCell getCellIdentifier];
}

- (UIImage *)getIcon
{
    NSString *id = [NSString stringWithUTF8String:self.routingParameter.id.c_str()];
    BOOL isChecked = self.isChecked;
    NSString *name = @"ic_custom_trip";
    if ([id isEqualToString:kRouteParamIdShortWay])
        name = @"ic_custom_fuel";
    else if ([id isEqualToString:kRouteParamIdAllowPrivate])
        name = isChecked ? @"ic_custom_allow_private_access" : @"ic_custom_forbid_private_access";
    else if ([id isEqualToString:kRouteParamIdAllowMotorway])
        name = isChecked ? @"ic_custom_motorways" : @"ic_custom_avoid_motorways";
    else if ([id isEqualToString:kRouteParamIdHeightObstacles])
        name = @"ic_custom_ascent";
    
    return [UIImage imageNamed:name];
}

- (UIColor *)getTintColor
{
    return UIColorFromRGB(color_chart_orange);
}

@end

@implementation OAOtherLocalRoutingParameter
{
    NSString *_text;
    BOOL _selected;
    int _id;
}

- (instancetype)initWithId:(int)paramId text:(NSString *)text selected:(BOOL)selected
{
    self = [super init];
    if (self)
    {
        _id = paramId;
        _text = text;
        _selected = selected;
    }
    return self;
}

- (int) getId
{
    return _id;
}

- (NSString *) getText
{
    return _text;
}

- (BOOL) isSelected
{
    return _selected;
}

- (void) setSelected:(BOOL)isChecked
{
    _selected = isChecked;
}

- (BOOL) routeAware
{
    // Prevent the route from refreshing twice when "reverse route" setting is changed
    return self.getId != gpx_option_reverse_route_id;
}

@end

@implementation OALocalRoutingParameterGroup
{
    NSString *_groupName;
    NSMutableArray<OALocalRoutingParameter *> *_routingParameters;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)am groupName:(NSString *)groupName
{
    self = [super initWithAppMode:am];
    if (self)
    {
        _routingParameters = [NSMutableArray array];
        _groupName = groupName;
    }
    return self;
}

- (void) addRoutingParameter:(RoutingParameter)routingParameter
{
    OALocalRoutingParameter *p = [[OALocalRoutingParameter alloc] initWithAppMode:[self getApplicationMode]];
    p.delegate = self.delegate;
    p.routingParameter = routingParameter;
    [_routingParameters addObject:p];
}

- (NSString *) getGroupName
{
    return _groupName;
}

- (NSMutableArray<OALocalRoutingParameter *> *) getRoutingParameters
{
    return _routingParameters;
}

- (NSString *) getText
{
    NSString *key;
    if ([_groupName isEqualToString:kRouteParamGroupReliefSmoothnessFactor])
        key = @"preferred_terrain";
    else
        key = [NSString stringWithFormat:@"routing_attr_%@_name", _groupName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = [[_groupName stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedStringWithLocale:[NSLocale currentLocale]];
    
    return res;
}

- (BOOL) isSelected
{
    return NO;
}

- (void) setSelected:(BOOL)isChecked
{
}

- (NSString *) getValue
{
    OALocalRoutingParameter *selected = [self getSelected];
    if (selected)
        return [selected getText];
    else
        return nil;
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (OALocalRoutingParameter *) getSelected
{
    OALocalRoutingParameter *useElevation;
    for (OALocalRoutingParameter *p in _routingParameters)
    {
        if ([[NSString stringWithUTF8String:p.routingParameter.id.c_str()] isEqualToString:kRouteParamIdHeightObstacles])
            useElevation = p;
        else if ([p isSelected])
            return p;
    }
    return useElevation;
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showParameterGroupScreen:self];
}

- (UIImage *)getIcon
{
    NSString *name;
    if ([_groupName isEqualToString:kRouteParamGroupDrivingStyle])
        name = @"ic_profile_bicycle";
    else if ([_groupName isEqualToString:kRouteParamGroupReliefSmoothnessFactor])
        name = @"ic_custom_terrain_any";
    return name ? [UIImage imageNamed:name] : nil;
}

- (UIColor *)getTintColor
{
    return UIColorFromRGB(color_chart_orange);
}

@end

@implementation OAMuteSoundRoutingParameter
{
    OAVoiceRouter *_voiceRouter;
}

- (void)commonInit
{
    [super commonInit];
    _voiceRouter = [self.routingHelper getVoiceRouter];
}

- (BOOL) isSelected
{
    return [self.settings.voiceMute get:self.getApplicationMode];
}

- (void) setSelected:(BOOL)isChecked
{
    [_voiceRouter setMute:isChecked mode:self.getApplicationMode];
    if (self.delegate)
        [self.delegate updateParameters];
    [[OARootViewController instance].mapPanel updateRouteInfo];
}


- (BOOL) isChecked
{
    return ![self isSelected];
}

- (BOOL) routeAware
{
    return NO;
}

- (NSString *) getText
{
    return OALocalizedString(@"shared_string_sound");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:[self.settings.voiceMute get:self.getApplicationMode] ? @"ic_custom_sound_off" : @"ic_custom_sound"];
}

- (NSString *) getCellType
{
    return [OASettingSwitchCell getCellIdentifier];
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(switchSound:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchSound:(id)sender
{
    [self setSelected:![self isSelected]];
}

- (void)rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate selectVoiceGuidance:tableView indexPath:indexPath];
}

- (UIImage *)getSecondaryIcon
{
    return [UIImage imageNamed:@"ic_action_additional_option"];
}

- (UIColor *)getTintColor
{
    return UIColorFromRGB(color_chart_orange);
}

@end

@implementation OAInterruptMusicRoutingParameter

- (BOOL) isSelected
{
    return [self.settings.interruptMusic get:[self getApplicationMode]];
}

- (void) setSelected:(BOOL)isChecked
{
    [self.settings.interruptMusic set:isChecked mode:[self getApplicationMode]];
}

- (BOOL) routeAware
{
    return NO;
}

- (NSString *) getText
{
    return OALocalizedString(@"interrupt_music");
}

- (NSString *)getDescription
{
    return OALocalizedString(@"interrupt_music_descr");
}

- (NSString *) getCellType
{
    return [OASwitchTableViewCell getCellIdentifier];
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(switchMusic:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchMusic:(id)sender
{
    [self setSelected:![self isSelected]];
}

@end

@implementation OAAvoidRoadsRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"impassable_road");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"impassable_road_desc");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_custom_alert"];
}

- (NSString *) getValue
{
    return OALocalizedString(@"shared_string_select");
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showAvoidRoadsScreen];    
}

- (UIColor *)getTintColor
{
    return [OAAvoidSpecificRoads instance].getImpassableRoads.count > 0 || [self hasAnyAvoidEnabled] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
}

- (BOOL) hasAnyAvoidEnabled
{
    OAApplicationMode *am = [self getApplicationMode];
    OsmAndAppInstance app = [OsmAndApp instance];
    auto rm = [app getRoutingConfigForMode:am]->getRouter([am.getRoutingProfile UTF8String]);
    if (!rm && am.parent)
        rm = [app getRoutingConfigForMode:am.parent]->getRouter([am.parent.getRoutingProfile UTF8String]);
    
    auto& params = rm->getParametersList();
    for (auto& r : params)
    {
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if (r.group.empty() && [[NSString stringWithUTF8String:r.id.c_str()] containsString:@"avoid"])
            {
                OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:am];
                rp.routingParameter = r;
                if (rp.isSelected)
                    return YES;
            }
        }
    }
    return NO;
}

@end

@implementation OAAvoidTransportTypesRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"avoid_transport_type");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_profile_bus"];
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showAvoidTransportScreen];
}

- (UIColor *)getTintColor
{
    return [self hasAnyAvoidEnabled] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
}

- (BOOL) hasAnyAvoidEnabled
{
    OAApplicationMode *am = [self getApplicationMode];
    OsmAndAppInstance app = [OsmAndApp instance];
    auto rm = [app getRoutingConfigForMode:am]->getRouter([am.getRoutingProfile UTF8String]);
    if (!rm && am.parent)
        rm = [app getRoutingConfigForMode:am.parent]->getRouter([am.parent.getRoutingProfile UTF8String]);
    
    auto& params = rm->getParametersList();
    for (auto& r : params)
    {
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if (r.group.empty() && [[NSString stringWithUTF8String:r.id.c_str()] containsString:@"avoid"])
            {
                OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:am];
                rp.routingParameter = r;
                if (rp.isSelected)
                    return YES;
            }
        }
    }
    return NO;
}

@end

@implementation OAGpxLocalRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"gpx_navigation");
}

- (NSString *) getValue
{
    NSString *path = self.settings.followTheGpxRoute.get;
    return !path ? @"" : [[[[path lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] trim];
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showTripSettingsScreen];
}

- (UIImage *)getIcon
{
    return [UIImage imageNamed:@"ic_custom_trip"];
}

- (UIColor *)getTintColor
{
    return [self.routingHelper getCurrentGPXRoute] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
}

@end

@implementation OASimulationRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"simulate_navigation");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_custom_navigation_arrow"];
}

- (NSString *) getCellType
{
    return [OASettingSwitchCell getCellIdentifier];
}

- (BOOL) isSelected
{
    return self.settings.simulateNavigation;
}

- (void) setSelected:(BOOL)isChecked
{
    [self.settings setSimulateNavigation:isChecked];
    if (self.delegate)
        [self.delegate updateParameters];
}

- (BOOL) isChecked
{
    return [self isSelected];
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(switchValue:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchValue:(id)sender
{
    [self setSelected:![self isSelected]];
}

- (UIColor *)getTintColor
{
    return self.isChecked ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
}

- (void)rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate openSimulateNavigationScreen];
}

- (UIImage *)getSecondaryIcon
{
    return [UIImage imageNamed:@"ic_action_additional_option"];
}

@end

@implementation OAConsiderLimitationsParameter

- (NSString *) getText
{
    return OALocalizedString(@"consider_limitations_param");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_custom_alert"];
}

- (NSString *) getCellType
{
    return [OASettingSwitchCell getCellIdentifier];
}

- (BOOL) isSelected
{
    return [self.settings.enableTimeConditionalRouting get:self.getApplicationMode];
}

- (void) setSelected:(BOOL)isChecked
{
    [self.settings.enableTimeConditionalRouting set:isChecked mode:self.getApplicationMode];
    if (self.delegate)
        [self.delegate updateParameters];
    [self.routingHelper recalculateRouteDueToSettingsChange];
}

- (BOOL) isChecked
{
    return [self isSelected];
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(switchValue:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchValue:(id)sender
{
    [self setSelected:![self isSelected]];
}

- (UIColor *)getTintColor
{
    return self.isChecked ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
}

@end

@implementation OAOtherSettingsRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"routing_settings_2");
}

- (UIImage *) getIcon
{
    return self.getApplicationMode.getIcon;
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate openNavigationSettings];
}

- (UIColor *)getTintColor
{
    return UIColorFromRGB(color_chart_orange);
}

@end

@implementation OACustomizeRouteLineRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"customize_route_line");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_custom_appearance"];
}

- (NSString *) getCellType
{
    return [OAIconTitleValueCell getCellIdentifier];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate openRouteLineAppearance];
}

- (UIColor *)getTintColor
{
    return UIColorFromRGB(color_chart_orange);
}

@end
