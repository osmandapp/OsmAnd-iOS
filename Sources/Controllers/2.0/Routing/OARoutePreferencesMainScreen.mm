//
//  OARoutePreferencesMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesMainScreen.h"
#import "OARoutePreferencesViewController.h"
#import "OARoutePreferencesParameters.h"
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
#import "OANavigationSettingsViewController.h"
#import "OARootViewController.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "PXAlertView.h"
#import "OAMapActions.h"
#import "OAUtilities.h"

#include <generalRouter.h>

@interface OARoutePreferencesMainScreen ()<OARoutePreferencesParametersDelegate>

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
    BOOL osmandRouter = [_settings.routerService get:am] == EOARouteService::OSMAND;
    if (!osmandRouter)
    {
        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:calculate_osmand_route_without_internet_id text:OALocalizedString(@"calculate_osmand_route_without_internet") selected:_settings.gpxRouteCalcOsmandParts]];
        
        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:fast_route_mode_id text:OALocalizedString(@"fast_route_mode") selected:[_settings.fastRouteMode get:am]]];
    
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
    
    auto& params = rm->getParametersList();
    for (auto& r : params)
    {
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

    
    OAMuteSoundRoutingParameter *muteSoundRoutingParameter = [[OAMuteSoundRoutingParameter alloc] initWithAppMode:am];
    muteSoundRoutingParameter.delegate = self;
    [list addObject:muteSoundRoutingParameter];
    
    OAVoiceGuidanceRoutingParameter *voiceGuidanceRoutingParameter = [[OAVoiceGuidanceRoutingParameter alloc] initWithAppMode:am];
    voiceGuidanceRoutingParameter.delegate = self;
    [list addObject:voiceGuidanceRoutingParameter];
    
    /*
    OAInterruptMusicRoutingParameter *interruptMusicRoutingParameter = [[OAInterruptMusicRoutingParameter alloc] initWithAppMode:am];
    interruptMusicRoutingParameter.delegate = self;
    [list addObject:interruptMusicRoutingParameter];
    */
    OAAvoidRoadsRoutingParameter *avoidRoadsRoutingParameter = [[OAAvoidRoadsRoutingParameter alloc] initWithAppMode:am];
    avoidRoadsRoutingParameter.delegate = self;
    [list addObject:avoidRoadsRoutingParameter];
    

    [list addObjectsFromArray:[self getRoutingParametersInner:am]];
    
    OAGpxLocalRoutingParameter *gpxLocalRoutingParameter = [[OAGpxLocalRoutingParameter alloc] initWithAppMode:am];
    gpxLocalRoutingParameter.delegate = self;
    [list addObject:gpxLocalRoutingParameter];
    
    OAOtherSettingsRoutingParameter *otherSettingsRoutingParameter = [[OAOtherSettingsRoutingParameter alloc] initWithAppMode:am];
    otherSettingsRoutingParameter.delegate = self;
    [list addObject:otherSettingsRoutingParameter];

    return [NSArray arrayWithArray:list];
}

- (void) setupView
{
    tableData = [self getRoutingParameters:[_routingHelper getAppMode]];
}

- (void) applyVoiceProvider:(NSString *)provider
{
    [[OAAppSettings sharedManager] setVoiceProvider:provider];
    [[OsmAndApp instance] initVoiceCommandPlayer:[[OARoutingHelper sharedInstance] getAppMode] warningNoneProvider:NO showDialog:YES force:NO];
}

- (void) selectVoiceGuidance:(BOOL (^)(NSString * result))callback
{
    OARoutePreferencesViewController *routePreferencesViewController = [[OARoutePreferencesViewController alloc] initWithPreferencesScreen:ERoutePreferencesScreenVoiceProvider];
    [routePreferencesViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    OALocalRoutingParameter *param = tableData[indexPath.row];
    NSString *type = [param getCellType];
    NSString *text = [param getText];
    NSString *value = [param getValue];
    
    if ([type isEqualToString:@"OASwitchCell"])
    {
        return [OASwitchTableViewCell getHeight:text cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:@"OASettingsCell"])
    {
        return [OASettingsTableViewCell getHeight:text value:value cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
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

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = tableData[indexPath.row];
    NSString *text = [param getText];
    //NSString *description = [param getDescription];
    NSString *value = [param getValue];
    //UIImage *icon = [param getIcon];
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
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OALocalRoutingParameter *param = tableData[indexPath.row];
    [param rowSelectAction:tableView indexPath:indexPath];
}

#pragma mark - OARoutePreferencesParametersDelegate

- (void) updateParameters
{
    [self setupView];
    [tblView reloadData];
}

- (void) showParameterGroupScreen:(OALocalRoutingParameterGroup *)group
{
    OARoutePreferencesViewController *routePreferencesViewController = [[OARoutePreferencesViewController alloc] initWithPreferencesScreen:ERoutePreferencesScreenParameterGroup param:group];
    [routePreferencesViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
}

- (void) selectVoiceGuidance:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    [self selectVoiceGuidance:^BOOL(NSString *result) {
        [self applyVoiceProvider:result];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return YES;
    }];
}

- (void) showAvoidRoadsScreen
{
    OARoutePreferencesViewController *routePreferencesViewController = [[OARoutePreferencesViewController alloc] initWithPreferencesScreen:ERoutePreferencesScreenAvoidRoads];
    [routePreferencesViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
}

@end
