//
//  OARoutePreferencesMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesMainScreen.h"
#import "OARoutePreferencesViewController.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAFileNameTranslationHelper.h"
#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsTableViewCell.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"

#include <generalRouter.h>

#define calculate_osmand_route_without_internet_id 100
#define fast_route_mode_id 101
#define use_points_as_intermediates_id 102
#define gpx_option_reverse_route_id 103
#define gpx_option_from_start_point_id 104
#define gpx_option_calculate_first_last_segment_id 105
#define calculate_osmand_route_gpx_id 106
#define speak_favorites_id 107

@protocol OARoutePreferencesMainScreenDelegate <NSObject>

@required
- (void) updateParameters;

@end


@interface OALocalRoutingParameter : NSObject

@property (nonatomic) OARoutingHelper *routingHelper;
@property (nonatomic) OAAppSettings *settings;

@property (nonatomic, weak) id<OARoutePreferencesMainScreenDelegate> delegate;

@property struct RoutingParameter routingParameter;

- (instancetype)initWithAppMode:(OAApplicationMode *)am;
- (void) commonInit;

- (NSString *) getText;
- (BOOL) isSelected;
- (void) setSelected:(BOOL)isChecked;
- (OAApplicationMode *) getApplicationMode;

- (BOOL) isChecked;
- (NSString *) getValue;
- (NSString *) getDescription;
- (UIImage *) getIcon;
- (NSString *) getCellType;

- (void) setControlAction:(UIControl *)control;
- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;

@end


@interface OAOtherLocalRoutingParameter : OALocalRoutingParameter
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

@interface OALocalRoutingParameterGroup : OALocalRoutingParameter

- (void) addRoutingParameter:(RoutingParameter)routingParameter;
- (NSString *) getGroupName;
- (NSMutableArray<OALocalRoutingParameter *> *) getRoutingParameters;
- (OALocalRoutingParameter *) getSelected;

@end

@implementation OALocalRoutingParameterGroup
{
    NSString *_groupName;
    NSMutableArray<OALocalRoutingParameter *> *_routingParameters;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)am groupName:(NSString *)groupName
{
    self = [super initWithAppMode:am];
    if (self)
    {
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

@end

@interface OAMuteSoundRoutingParameter : OALocalRoutingParameter
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

@interface OAInterruptMusicRoutingParameter : OALocalRoutingParameter
@end
@implementation OAInterruptMusicRoutingParameter

- (BOOL) isSelected
{
    return [self.settings.interruptMusic get];
}

- (void) setSelected:(BOOL)isChecked
{
    [self.settings.interruptMusic set:isChecked];
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

@interface OAVoiceGuidanceRoutingParameter : OALocalRoutingParameter
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
    [OARoutePreferencesMainScreen selectVoiceGuidance:^BOOL(NSString *result) {
        [OARoutePreferencesMainScreen applyVoiceProvider:result];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return YES;
    }];
}

@end

@interface OAAvoidRoadsRoutingParameter : OALocalRoutingParameter
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
    // TODO
}

@end

@interface OAGpxLocalRoutingParameter : OALocalRoutingParameter
@end
@implementation OAGpxLocalRoutingParameter

- (NSString *) getText
{
    return OALocalizedString(@"gpx_navigation");
}

- (NSString *) getValue
{
    OAGPXRouteParamsBuilder *rp = [self.routingHelper getCurrentGPXRoute];
    return !rp ? OALocalizedString(@"map_settings_none") : [rp.file.fileName lastPathComponent];
}

- (NSString *) getCellType
{
    return @"OASettingsCell";
}

- (void) rowSelectAction:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    // TODO
}

@end

@interface OAOtherSettingsRoutingParameter : OALocalRoutingParameter
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

@end

@interface OARoutePreferencesMainScreen ()<OARoutePreferencesMainScreenDelegate>

@end

@implementation OARoutePreferencesMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
}

@synthesize preferencesScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OARoutePreferencesViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _routingHelper = [OARoutingHelper sharedInstance];
        
        title = OALocalizedString(@"sett_settings");
        preferencesScreen = ERoutePreferencesScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    auto router = _app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = _app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    
    return router;
}

- (NSArray<OALocalRoutingParameter *> *) getRoutingParametersInner:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    OAGPXRouteParamsBuilder *rparams = [_routingHelper getCurrentGPXRoute];
    BOOL osmandRouter = [_settings.routerService get] == EOARouteService::OSMAND;
    if (!osmandRouter)
    {
        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:calculate_osmand_route_without_internet_id text:OALocalizedString(@"calculate_osmand_route_without_internet") selected:_settings.gpxRouteCalcOsmandParts]];
        
        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:fast_route_mode_id text:OALocalizedString(@"fast_route_mode") selected:[_settings.fastRouteMode get]]];
    
        return list;
    }
    if (rparams)
    {
        OAGPXDocument *fl = rparams.file;
        if ([fl hasRtePt])
        {
            [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:use_points_as_intermediates_id text:OALocalizedString(@"use_points_as_intermediates") selected:rparams.useIntermediatePointsRTE]];
        }
        
        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_reverse_route_id text:OALocalizedString(@"gpx_option_reverse_route") selected:rparams.reverse]];
        
        if (!rparams.useIntermediatePointsRTE)
        {
            [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_from_start_point_id text:OALocalizedString(@"gpx_option_from_start_point") selected:rparams.passWholeRoute]];
            
            [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_calculate_first_last_segment_id text:OALocalizedString(@"gpx_option_calculate_first_last_segment") selected:rparams.calculateOsmAndRouteParts]];
        }
    }
    
    auto rm = [self getRouter:am];
    if (!rm || ((rparams && !rparams.calculateOsmAndRoute) && ![rparams.file hasRtePt]))
        return list;
    
    auto& params = rm->getParameters();
    for (auto it = params.begin(); it != params.end(); ++it)
    {
        auto& r = it->second;
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if ("relief_smoothness_factor" == r.group)
                continue;
            
            if (!r.group.empty())
            {
                OALocalRoutingParameterGroup *rpg = [self getLocalRoutingParameterGroup:list groupName:[NSString stringWithUTF8String:r.group.c_str()]];
                if (!rpg)
                {
                    rpg = [[OALocalRoutingParameterGroup alloc] initWithAppMode:am groupName:[NSString stringWithUTF8String:r.group.c_str()]];
                    [list addObject:rpg];
                }
                rpg.delegate = self;
                [rpg addRoutingParameter:r];
            }
            else
            {
                OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:am];
                rp.routingParameter = r;
                [list addObject:rp];
            }
        }
    }
    
    for (OALocalRoutingParameter *param in list)
        param.delegate = self;

    return list;
}

- (OALocalRoutingParameterGroup *) getLocalRoutingParameterGroup:(NSMutableArray<OALocalRoutingParameter *> *)list groupName:(NSString *)groupName
{
    for (OALocalRoutingParameter *p in list)
    {
        if ([p isKindOfClass:[OALocalRoutingParameterGroup class]] && [groupName isEqualToString:[((OALocalRoutingParameterGroup *) p) getGroupName]])
        {
            return (OALocalRoutingParameterGroup *) p;
        }
    }
    return nil;
}

- (NSArray *) getRoutingParameters:(OAApplicationMode *) am
{
    NSMutableArray *list = [NSMutableArray array];

    [list addObject:[[OAMuteSoundRoutingParameter alloc] init]];
    [list addObject:[[OAVoiceGuidanceRoutingParameter alloc] init]];
    [list addObject:[[OAInterruptMusicRoutingParameter alloc] init]];
    [list addObject:[[OAAvoidRoadsRoutingParameter alloc] init]];

    [list addObjectsFromArray:[self getRoutingParametersInner:am]];
    
    [list addObject:[[OAGpxLocalRoutingParameter alloc] init]];
    [list addObject:[[OAOtherSettingsRoutingParameter alloc] init]];

    return [NSArray arrayWithArray:list];
}

- (void) setupView
{
    tableData = [self getRoutingParameters:[_routingHelper getAppMode]];
}

- (void) updateParameters
{
    [self setupView];
    [tblView reloadData];
}

- (void) selectRestrictedRoads
{
    // TODO
    //mapActivity.getDashboard().setDashboardVisibility(false, DashboardOnMap.DashboardType.ROUTE_PREFERENCES);
    //controlsLayer.getMapRouteInfoMenu().hide();
    //app.getAvoidSpecificRoads().showDialog(mapActivity);
}

+ (void) applyVoiceProvider:(NSString *)provider
{
    [OAAppSettings sharedManager].voiceProvider = provider;
    [[OsmAndApp instance] initVoiceCommandPlayer:[[OARoutingHelper sharedInstance] getAppMode] warningNoneProvider:NO showDialog:YES force:NO];
}

+ (void) selectVoiceGuidance:(BOOL (^)(NSString * result))callback
{
    // TODO
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableData.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = tableData[indexPath.row];
    NSString *text = [param getText];
    NSString *description = [param getDescription];
    NSString *value = [param getValue];
    UIImage *icon = [param getIcon];
    NSString *type = [param getCellType];
    
    if ([type isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:text];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.switchView setOn:[param isChecked]];
            [param setControlAction:cell.switchView];
        }
        return cell;
    }
    else if ([type isEqualToString:@"OASettingsCell"])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:text];
            [cell.descriptionView setText:value];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OALocalRoutingParameter *param = tableData[indexPath.row];
    [param rowSelectAction:tableView indexPath:indexPath];
}

@end
