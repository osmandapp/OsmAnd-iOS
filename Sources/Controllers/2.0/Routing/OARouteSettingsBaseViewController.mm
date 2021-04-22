//
//  OARouteSettingsBaseViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteSettingsBaseViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OARouteSettingsParameterController.h"
#import "OARouteAvoidTransportSettingsViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OANavigationLanguageViewController.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OADestinationItem.h"
#import "OADestinationsHelper.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OAFileNameTranslationHelper.h"
#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsTableViewCell.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OABaseSettingsViewController.h"
#import "OARootViewController.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OASettingSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OAFollowTrackBottomSheetViewController.h"

#include <generalRouter.h>

@interface OARouteSettingsBaseViewController () <OARoutePreferencesParametersDelegate, OASettingsDataDelegate>

@end

@implementation OARouteSettingsBaseViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OARouteSettingsBaseViewController" bundle:nil];
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _routingHelper = [OARoutingHelper sharedInstance];
    
    [self generateData];
}

- (void) generateData
{
}

-(void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
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
    [super viewWillAppear:animated];
    [self setupView];
}

- (NSArray<OALocalRoutingParameter *> *) getNonAvoidRoutingParameters:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    
    auto rm = [OARouteProvider getRouter:am];
    if (rm == nullptr)
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
            else if (![[NSString stringWithUTF8String:r.id.c_str()] containsString:@"avoid"])
            {
                OALocalNonAvoidParameter *rp = [[OALocalNonAvoidParameter alloc] initWithAppMode:am];
                rp.routingParameter = r;
                rp.delegate = self;
                [list addObject:rp];
            }
        }
    }

    return list;
}

- (NSArray<OALocalRoutingParameter *> *) getAvoidRoutingParameters:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    
    auto rm = [OARouteProvider getRouter:am];
    if (rm == nullptr)
        return list;
    
    auto& params = rm->getParametersList();
    for (auto& r : params)
    {
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if ("relief_smoothness_factor" == r.group)
                continue;
            
            if (r.group.empty() && [[NSString stringWithUTF8String:r.id.c_str()] containsString:@"avoid"])
            {
                OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:am];
                rp.routingParameter = r;
                rp.delegate = self;
                [list addObject:rp];
            }
        }
    }

    return list;
}

- (NSArray<OALocalRoutingParameter *> *) getRoutingParametersGpx:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    OAGPXRouteParamsBuilder *rparams = [_routingHelper getCurrentGPXRoute];
//    BOOL osmandRouter = [_settings.routerService get:am] == EOARouteService::OSMAND;
//    if (!osmandRouter)
//    {
//        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:calculate_osmand_route_without_internet_id text:OALocalizedString(@"calculate_osmand_route_without_internet") selected:_settings.gpxRouteCalcOsmandParts]];
//
//        [list addObject:[[OAOtherLocalRoutingParameter alloc] initWithId:fast_route_mode_id text:OALocalizedString(@"fast_route_mode") selected:[_settings.fastRouteMode get:am]]];
//
//        return list;
//    }
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

- (NSDictionary *) getRoutingParameters:(OAApplicationMode *) am
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    NSMutableArray *list = [NSMutableArray array];
    NSInteger section = 0;
    BOOL isPublicTransport = [am isDerivedRoutingFrom:OAApplicationMode.PUBLIC_TRANSPORT];
    
    OAMuteSoundRoutingParameter *muteSoundRoutingParameter = [[OAMuteSoundRoutingParameter alloc] initWithAppMode:am];
    muteSoundRoutingParameter.delegate = self;
    [list addObject:muteSoundRoutingParameter];
    
    [model setObject:[NSArray arrayWithArray:list] forKey:@(section++)];
    [list removeAllObjects];
    
    if (!isPublicTransport)
    {
        OAAvoidRoadsRoutingParameter *avoidRoadsRoutingParameter = [[OAAvoidRoadsRoutingParameter alloc] initWithAppMode:am];
        avoidRoadsRoutingParameter.delegate = self;
        [list addObject:avoidRoadsRoutingParameter];
        
        [list addObjectsFromArray:[self getNonAvoidRoutingParameters:am]];
        
        OAConsiderLimitationsParameter *considerLimitations = [[OAConsiderLimitationsParameter alloc] initWithAppMode:am];
        considerLimitations.delegate = self;
        [list addObject:considerLimitations];
        
        [model setObject:[NSArray arrayWithArray:list] forKey:@(section++)];
        [list removeAllObjects];
        
        OAGpxLocalRoutingParameter *gpxRoutingParameter = [[OAGpxLocalRoutingParameter alloc] initWithAppMode:am];
        gpxRoutingParameter.delegate = self;
        [list addObject:gpxRoutingParameter];
        
    }
    else
    {
        OAAvoidTransportTypesRoutingParameter *avoidTransportTypesParameter = [[OAAvoidTransportTypesRoutingParameter alloc] initWithAppMode:am];
        avoidTransportTypesParameter.delegate = self;
        [list addObject:avoidTransportTypesParameter];
        [model setObject:[NSArray arrayWithArray:list] forKey:@(section++)];
        [list removeAllObjects];
    }
    
    OAOtherSettingsRoutingParameter *otherSettingsRoutingParameter = [[OAOtherSettingsRoutingParameter alloc] initWithAppMode:am];
    otherSettingsRoutingParameter.delegate = self;
    [list addObject:otherSettingsRoutingParameter];
    
    if (!isPublicTransport)
    {
        OASimulationRoutingParameter *simulationRoutingParameter = [[OASimulationRoutingParameter alloc] initWithAppMode:am];
        simulationRoutingParameter.delegate = self;
        [list addObject:simulationRoutingParameter];
        [model setObject:[NSArray arrayWithArray:list] forKey:@(section++)];
    }
    else
    {
        [model setObject:[NSArray arrayWithArray:list] forKey:@(section++)];
    }

    return [NSDictionary dictionaryWithDictionary:model];
}

- (void) setupView
{
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.presentedViewController != nil)
        [self.presentedViewController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void) setCancelButtonAsImage
{
    [self.backButton setTitle:nil forState:UIControlStateNormal];
    [self.backButton setImage:[UIImage imageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
}

- (void)backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonPressed:(id)sender
{
    [self doneButtonPressed];
}

#pragma mark - OARoutePreferencesParametersDelegate

- (void) updateParameters
{
    [self setupView];
    [_tableView reloadData];
}

- (void) showParameterGroupScreen:(OALocalRoutingParameterGroup *)group
{
    OARouteSettingsParameterController *paramController = [[OARouteSettingsParameterController alloc] initWithParameterGroup:group];
    [self presentViewController:paramController animated:YES completion:nil];
}

- (void) selectVoiceGuidance:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    OANavigationLanguageViewController *settingsViewController = [[OANavigationLanguageViewController alloc] initWithAppMode:[[OARoutingHelper sharedInstance] getAppMode]];
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void) showAvoidRoadsScreen
{
    OARouteAvoidSettingsViewController *avoidController = [[OARouteAvoidSettingsViewController alloc] init];
    avoidController.delegate = self;
    [self presentViewController:avoidController animated:YES completion:nil];
}

- (void) openNavigationSettings
{
    OAProfileNavigationSettingsViewController *settingsViewController = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:[[OARoutingHelper sharedInstance] getAppMode]];
    settingsViewController.delegate = self;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void) showTripSettingsScreen
{
    [self dismissViewControllerAnimated:YES completion:^{
        OAGPXRouteParamsBuilder *gpxParams = _routingHelper.getCurrentGPXRoute;
        OAGPXDocument *gpx = gpxParams ? gpxParams.file : nil;
        OAFollowTrackBottomSheetViewController *followTrack = [[OAFollowTrackBottomSheetViewController alloc] initWithFile:gpx];
        [followTrack presentInViewController:OARootViewController.instance animated:YES];
    }];
}

- (void) showAvoidTransportScreen
{
    OARouteAvoidTransportSettingsViewController *avoidTransportController = [[OARouteAvoidTransportSettingsViewController alloc] init];
    avoidTransportController.delegate = self;
    [self presentViewController:avoidTransportController animated:YES completion:nil];
}

- (void)doneButtonPressed
{
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - OANavigationSettingsDelegate

- (void) onSettingsChanged
{
    [self generateData];
    [self setupView];
    [self.tableView reloadData];
}

@end
