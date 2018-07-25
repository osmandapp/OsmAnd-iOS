//
//  OARoutePreferencesParameters.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesParameters.h"
#import "OARootViewController.h"
#import "OANavigationSettingsViewController.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OAFileNameTranslationHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "PXAlertView.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OARouteProvider.h"
#import "OAAbstractCommandPlayer.h"

#include <generalRouter.h>

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
        _am = _settings.applicationMode;
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
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", [NSString stringWithUTF8String:_routingParameter.id.c_str()]];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = [NSString stringWithUTF8String:_routingParameter.name.c_str()];
    
    return res;
}

- (BOOL) isSelected
{
    OAProfileBoolean *property = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:_routingParameter.id.c_str()] defaultValue:_routingParameter.defaultBoolean];
    
    return [property get:_am];
}

- (void) setSelected:(BOOL)isChecked
{
    OAProfileBoolean *property = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:_routingParameter.id.c_str()] defaultValue:_routingParameter.defaultBoolean];
    
    [property set:isChecked mode:_am];
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
    if (self.routingParameter.id == "short_way")
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
    return nil;
}

- (UIImage *) getIcon
{
    return nil;
}

- (NSString *) getCellType
{
    return @"OASwitchCell";
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(applyRoutingParameter:) forControlEvents:UIControlEventValueChanged];
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
}

- (void) applyRoutingParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        BOOL isChecked = ((UISwitch *) sender).on;
        // if short way that it should set valut to fast mode opposite of current
        if (self.routingParameter.id == "short_way")
            [self.settings.fastRouteMode set:!isChecked mode:[self.routingHelper getAppMode]];
        
        [self setSelected:isChecked];
        
        if ([self isKindOfClass:[OAOtherLocalRoutingParameter class]])
            [self updateGpxRoutingParameter:((OAOtherLocalRoutingParameter *) self)];
        
        if ([self routeAware])
            [self.routingHelper recalculateRouteDueToSettingsChange];
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
                CLLocation *first = ps[0];
                CLLocation *end = ps[ps.count - 1];
                OARTargetPoint *pn = [tg getPointToNavigate];
                BOOL update = false;
                if (!pn || [pn.point distanceFromLocation:first] < 10)
                {
                    [tg navigateToPoint:end updateRoute:false intermediate:-1];
                    update = true;
                }
                if (![tg getPointToStart] || [[tg getPointToStart].point distanceFromLocation:end] < 10)
                {
                    [tg setStartPoint:first updateRoute:false name:nil];
                    update = true;
                }
                if (update)
                {
                    [tg updateRouteAndRefresh:true];
                }
            }
        }
        else if ([gpxParam getId] == gpx_option_calculate_first_last_segment_id)
        {
            [rp setCalculateOsmAndRouteParts:selected];
            self.settings.gpxRouteCalcOsmandParts = selected;
        }
        else if ([gpxParam getId] == gpx_option_from_start_point_id)
        {
            [rp setPassWholeRoute:selected];
        }
        else if ([gpxParam getId] == use_points_as_intermediates_id)
        {
            self.settings.gpxCalculateRtept = selected;
            [rp setUseIntermediatePointsRTE:selected];
        }
        else if ([gpxParam getId] == calculate_osmand_route_gpx_id)
        {
            self.settings.gpxRouteCalc = selected;
            [rp setCalculateOsmAndRoute:selected];
            if (self.delegate)
                [self.delegate updateParameters];
        }
    }
    if ([gpxParam getId] == calculate_osmand_route_without_internet_id)
        self.settings.gpxRouteCalcOsmandParts = selected;
    
    if ([gpxParam getId] == fast_route_mode_id)
        [self.settings.fastRouteMode set:selected];
    
    if ([gpxParam getId] == speak_favorites_id)
        [self.settings.announceNearbyFavorites set:selected];
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
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", _groupName];
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
    return @"OASettingsCell";
}

- (OALocalRoutingParameter *) getSelected
{
    for (OALocalRoutingParameter *p in _routingParameters)
        if ([p isSelected])
            return p;
    
    return nil;
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showParameterGroupScreen:self];
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
    return [_voiceRouter isMute];
}

- (void) setSelected:(BOOL)isChecked
{
    self.settings.voiceMute = isChecked;
    [_voiceRouter setMute:isChecked];
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
    return [UIImage imageNamed:@"ic_action_volume_up"];
}

- (NSString *) getCellType
{
    return @"OASwitchCell";
}

- (void) setControlAction:(UIControl *)control
{
    [control addTarget:self action:@selector(switchSound:) forControlEvents:UIControlEventValueChanged];
}

- (void) switchSound:(id)sender
{
    [self setSelected:![self isSelected]];
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
    return @"OASwitchCell";
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

@implementation OAVoiceGuidanceRoutingParameter

- (BOOL) routeAware
{
    return NO;
}

- (NSString *) getText
{
    return OALocalizedString(@"voice_provider");
}

- (NSString *) getValue
{
    NSString *voiceProvider = self.settings.voiceProvider;
    NSString *voiceProviderStr;
    if (voiceProvider)
    {
        if ([VOICE_PROVIDER_NOT_USE isEqualToString:voiceProvider])
            voiceProviderStr = OALocalizedString(@"shared_string_do_not_use");
        else
            voiceProviderStr = [OAFileNameTranslationHelper getVoiceName:voiceProvider];
        
        voiceProviderStr = [voiceProviderStr stringByAppendingString:[voiceProvider containsString:@"tts"] ? @" TTS" : @""];
    }
    else
    {
        voiceProviderStr = OALocalizedString(@"not_selected");
    }
    return voiceProviderStr;
}

- (NSString *) getCellType
{
    return @"OASettingsCell";
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate selectVoiceGuidance:tableView indexPath:indexPath];
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
    return [UIImage imageNamed:@"ic_action_road_works_dark"];
}

- (NSString *) getValue
{
    return OALocalizedString(@"shared_string_select");
}

- (NSString *) getCellType
{
    return @"OASettingsCell";
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
        [self.delegate showAvoidRoadsScreen];    
}

@end

@implementation OAGpxLocalRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"gpx_navigation");
}

- (NSString *) getValue
{
    NSString *path = self.settings.followTheGpxRoute;
    return !path ? OALocalizedString(@"map_settings_none") : [[[[path lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] trim];
}

- (NSString *) getCellType
{
    return @"OASettingsCell";
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    OASelectedGPXHelper *_helper = [OASelectedGPXHelper instance];
    OAGPXDatabase *_dbHelper = [OAGPXDatabase sharedDb];
    NSArray<OAGPX *> *gpxFiles = _dbHelper.gpxList;
    NSMutableArray<OAGPX *> *selectedGpxFiles = [NSMutableArray array];
    auto activeGpx = _helper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        OAGPX *gpx = [_dbHelper getGPXItem:[it.key().toNSString() lastPathComponent]];
        if (gpx)
            [selectedGpxFiles addObject:gpx];
    }
    
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    for (OAGPX *gpx in gpxFiles)
    {
        [titles addObject:[gpx getNiceTitle]];
        [images addObject:@"icon_gpx"];
    }
    
    [titles addObject:OALocalizedString(@"map_settings_none")];
    [images addObject:@""];
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"select_gpx")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:titles
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 if (buttonIndex == titles.count - 1)
                                 {
                                     if ([self.routingHelper getCurrentGPXRoute])
                                     {
                                         [self.routingHelper setGpxParams:nil];
                                         self.settings.followTheGpxRoute = nil;
                                         [self.routingHelper recalculateRouteDueToSettingsChange];
                                     }
                                     if (self.delegate)
                                         [self.delegate updateParameters];
                                 }
                                 else
                                 {
                                     [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:gpxFiles[buttonIndex]];
                                     [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
                                     if (self.delegate)
                                         [self.delegate updateParameters];
                                     
                                     [self.routingHelper recalculateRouteDueToSettingsChange];
                                 }
                             }
                         }];
}

@end

@implementation OAOtherSettingsRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"routing_settings_2");
}

- (UIImage *) getIcon
{
    return [UIImage imageNamed:@"ic_action_settings"];
}

- (NSString *) getCellType
{
    return @"OASettingsCell";
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenGeneral applicationMode:[[OARoutingHelper sharedInstance] getAppMode]];
    [[OARootViewController instance].navigationController pushViewController:settingsViewController animated:YES];
}

@end


