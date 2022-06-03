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
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OARootViewController.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OAFollowTrackBottomSheetViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OASimulationNavigationSettingViewController.h"
#import "OARouteParameterValuesViewController.h"

@interface OARouteSettingsBaseViewController () <OARoutePreferencesParametersDelegate, OASettingsDataDelegate, OARouteLineAppearanceViewControllerDelegate>

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
    
    auto rm = [_app getRouter:am];
    if (rm == nullptr)
        return list;
    
    auto params = rm->getParameters(string(am.getDerivedProfile.UTF8String));
    vector<RoutingParameter> reliefFactorParameters;
    for (auto it = params.begin(); it != params.end(); ++it)
    {
        auto& r = it->second;
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if ([[NSString stringWithUTF8String:r.group.c_str()] isEqualToString:kRouteParamGroupReliefSmoothnessFactor])
            {
                reliefFactorParameters.push_back(r);
                continue;
            }
            else if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamIdHeightObstacles])
            {
                reliefFactorParameters.insert(reliefFactorParameters.begin(), r);
                continue;
            }
            
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
        else if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamIdHazmatCategory])
        {
            OAHazmatRoutingParameter *hazmatCategory = [[OAHazmatRoutingParameter alloc] initWithAppMode:[self.routingHelper getAppMode]];
            hazmatCategory.routingParameter = r;
            hazmatCategory.delegate = self;
            [list addObject:hazmatCategory];
        }
    }

    if (reliefFactorParameters.size() > 0)
    {
        OALocalRoutingParameterGroup *group = [[OALocalRoutingParameterGroup alloc] initWithAppMode:[self.routingHelper getAppMode]
                                                                                          groupName:kRouteParamGroupReliefSmoothnessFactor];
        group.delegate = self;
        for (const auto& p : reliefFactorParameters)
        {
            [group addRoutingParameter:p];
        }
        [list addObject:group];
    }

    return list;
}

- (NSArray<OALocalRoutingParameter *> *) getAvoidRoutingParameters:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    
    auto rm = [_app getRouter:am];
    if (rm == nullptr)
        return list;
    
    auto params = rm->getParameters(string(am.getDerivedProfile.UTF8String));
    for (auto it = params.begin(); it != params.end(); ++it)
    {
        auto& r = it->second;
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if ([[NSString stringWithUTF8String:r.group.c_str()] isEqualToString:kRouteParamGroupReliefSmoothnessFactor])
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

    OACustomizeRouteLineRoutingParameter *customizeRouteLineRoutingParameter = [[OACustomizeRouteLineRoutingParameter alloc] initWithAppMode:am];
    customizeRouteLineRoutingParameter.delegate = self;
    [list addObject:customizeRouteLineRoutingParameter];

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

- (void) showParameterValuesScreen:(OALocalRoutingParameter *)parameter;
{
    OARouteParameterValuesViewController *paramController = [[OARouteParameterValuesViewController alloc] initWithRoutingParameter:parameter
                                                                                                                    appMode:[[OARoutingHelper sharedInstance] getAppMode]];
    paramController.delegate = self;
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
    settingsViewController.openFromRouteInfo = YES;
    settingsViewController.delegate = self;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void) openRouteLineAppearance
{
    [self dismissViewControllerAnimated:YES completion:^{
        [OARootViewController.instance.mapPanel closeRouteInfo:NO onComplete:^{
            OARouteLineAppearanceHudViewController *routeLineAppearanceHudViewController =
                    [[OARouteLineAppearanceHudViewController alloc] initWithAppMode:[_routingHelper getAppMode]];
            routeLineAppearanceHudViewController.delegate = self;
            [OARootViewController.instance.mapPanel showScrollableHudViewController:routeLineAppearanceHudViewController];
        }];
    }];
}

- (void) openSimulateNavigationScreen
{
    OASimulationNavigationSettingViewController *simulateController = [[OASimulationNavigationSettingViewController alloc] initWithAppMode:[_routingHelper getAppMode]];
    simulateController.delegate = self;
    [self presentViewController:simulateController animated:YES completion:nil];
}

- (void) showTripSettingsScreen
{
    [self dismissViewControllerAnimated:YES completion:^{
        OAGPXRouteParamsBuilder *gpxParams = _routingHelper.getCurrentGPXRoute;
        OAGPXDocument *gpx = gpxParams ? gpxParams.file : nil;
        OAFollowTrackBottomSheetViewController *followTrack = [[OAFollowTrackBottomSheetViewController alloc] initWithFile:gpx];
        
        if (gpx)
        {
            followTrack.view.hidden = NO;
            [followTrack presentInViewController:OARootViewController.instance animated:YES];
            
        }
        else
        {
            followTrack.view.hidden = YES;
            [followTrack presentInViewController:OARootViewController.instance animated:NO];
        }
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

- (void)closeSettingsScreenWithRouteInfo
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[OARootViewController instance].mapPanel closeRouteInfo];
    }];
}

#pragma mark - OARouteLineAppearanceViewControllerDelegate

-(void) onCloseAppearance
{
    [OARootViewController.instance.mapPanel showRouteInfo:NO];
}

@end
