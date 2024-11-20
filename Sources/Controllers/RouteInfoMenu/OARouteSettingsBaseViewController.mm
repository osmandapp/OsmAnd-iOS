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
#import "OsmAnd_Maps-Swift.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OAApplicationMode.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OAFollowTrackBottomSheetViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OASimulationNavigationSettingViewController.h"
#import "OARouteParameterValuesViewController.h"
#import "GeneratedAssetSymbols.h"

static NSString *enabledRouteSettingsKey = @"enabled";

@interface OARouteSettingsBaseViewController () <OARoutePreferencesParametersDelegate, OASettingsDataDelegate, OARouteLineAppearanceViewControllerDelegate>

@end

@implementation OARouteSettingsBaseViewController
{
    vector<RoutingParameter> _hazmatCategoryUSAParameters;
}

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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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
    
    [self configureNavigationBar];
    [self setupView];
}

- (void) configureNavigationBar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.tableView.backgroundColor;
    appearance.shadowColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];

    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:cancelButton animated:YES];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_done") style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
    [self.navigationController.navigationBar.topItem setRightBarButtonItem:doneButton animated:YES];
}

- (NSArray<OALocalRoutingParameter *> *) getNonAvoidRoutingParameters:(OAApplicationMode *) am
{
    NSMutableArray<OALocalRoutingParameter *> *list = [NSMutableArray array];
    
    auto rm = [_app getRouter:am];
    if (rm == nullptr)
        return list;
    
    auto params = rm->getParameters(string(am.getDerivedProfile.UTF8String));
    vector<RoutingParameter> reliefFactorParameters;
    _hazmatCategoryUSAParameters.clear();
    for (auto it = params.begin(); it != params.end(); ++it)
    {
        auto& r = it->second;
        if (r.type == RoutingParameterType::BOOLEAN)
        {
            if ([[NSString stringWithUTF8String:r.group.c_str()] isEqualToString:kRouteParamReliefSmoothnessFactor])
            {
                reliefFactorParameters.push_back(r);
                continue;
            }
            else if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamHeightObstacles])
            {
                reliefFactorParameters.insert(reliefFactorParameters.begin(), r);
                continue;
            }
            else if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamShortWay] && ![am isDerivedRoutingFrom:OAApplicationMode.CAR])
            {
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
                if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamGoodsRestrictions])
                    continue;
                if ([[NSString stringWithUTF8String:r.id.c_str()] containsString:kRouteParamHazmatCategory])
                {
                    _hazmatCategoryUSAParameters.push_back(r);
                    continue;
                }
                rp.routingParameter = r;
                rp.delegate = self;
                [list addObject:rp];
            }
        }
        else if ([[NSString stringWithUTF8String:r.id.c_str()] isEqualToString:kRouteParamHazmatCategory] && [_settings.drivingRegion get:am] != DR_US)
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
                                                                                          groupName:kRouteParamReliefSmoothnessFactor];
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
            if ([[NSString stringWithUTF8String:r.group.c_str()] isEqualToString:kRouteParamReliefSmoothnessFactor])
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
        OASGpxFile *fl = rparams.file;
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
    BOOL isTruckTransport = [am isDerivedRoutingFrom:OAApplicationMode.TRUCK];
    
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
        
        OAShowAlongTheRouteItem *showAlongTheRouteItem = [[OAShowAlongTheRouteItem alloc] initWithAppMode:am];
        showAlongTheRouteItem.delegate = self;
        [list addObject:showAlongTheRouteItem];
        
        [list addObjectsFromArray:[self getNonAvoidRoutingParameters:am]];
        
        if (isTruckTransport && [_settings.drivingRegion get:am] == DR_US)
            [list addObject:[self createHazmatInfoForApplicationMode:am]];
        
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

- (NSDictionary *) createHazmatInfoForApplicationMode:(OAApplicationMode *)am
{
    NSArray<NSArray<NSString *> *> *fetchedParams = [self getHazmatUsaParamsIdsWithAppMode:am];
    NSMutableArray<NSString *> *paramsIds = [NSMutableArray arrayWithArray:fetchedParams[0]];
    NSMutableArray<NSString *> *paramsNames = [NSMutableArray arrayWithArray:fetchedParams[1]];
    NSMutableArray<NSString *> *enabledParamsIds = [NSMutableArray arrayWithArray:fetchedParams[2]];
    BOOL enabled = enabledParamsIds.count > 0;
    UIImage *icon = [UIImage templateImageNamed:enabled ? @"ic_custom_placard_hazard" : @"ic_custom_placard_hazard_off"];
    UIColor *tint = [UIColor colorNamed:enabled ? ACColorNameIconColorDisruptive : ACColorNameIconColorDisabled];
    NSDictionary *hazmatInfo = @{
        cellTypeRouteSettingsKey : [OAValueTableViewCell getCellIdentifier],
        keyRouteSettingsKey : dangerousGoodsRouteSettingsUsaKey,
        titleRouteSettingsKey : OALocalizedString(@"dangerous_goods"),
        valueRouteSettingsKey : [self getHazmatUsaDescription:enabledParamsIds],
        iconRouteSettingsKey : icon,
        iconTintRouteSettingsKey : tint,
        paramsIdsRouteSettingsKey : paramsIds,
        paramsNamesRouteSettingsKey : paramsNames
    };
    
    return hazmatInfo;
}

- (NSArray<NSArray<NSString *> *> *) getHazmatUsaParamsIdsWithAppMode:(OAApplicationMode *)am
{
    NSMutableArray<NSArray<NSString *> *> *params = [NSMutableArray array];
    NSMutableArray<NSString *> *paramsIds = [NSMutableArray array];
    NSMutableArray<NSString *> *paramsNames = [NSMutableArray array];
    NSMutableArray<NSString *> *enabledParamsIds = [NSMutableArray array];
    for (NSInteger i = 0; i < _hazmatCategoryUSAParameters.size(); i++)
    {
        RoutingParameter& parameter = _hazmatCategoryUSAParameters[i];
        NSString *paramId = [NSString stringWithUTF8String:parameter.id.c_str()];
        NSString *name = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:parameter.name.c_str()]];
        OACommonBoolean *pref = [_settings getCustomRoutingBooleanProperty:paramId defaultValue:parameter.defaultBoolean];
        NSString *enabled = [pref get:am] ? enabledRouteSettingsKey : @"";
        [params addObject:@[paramId, name, enabled]];
    }
    
    [params sortUsingComparator:^NSComparisonResult(NSArray<NSString *> * _Nonnull obj1, NSArray<NSString *> *  _Nonnull obj2) {
        return [obj1[0] compare:obj2[0]];
    }];
    
    for (NSArray<NSString *> *param in params)
    {
        [paramsIds addObject:param[0]];
        [paramsNames addObject:param[1]];
        if ([param[2] isEqualToString:enabledRouteSettingsKey])
            [enabledParamsIds addObject:param[0]];
    }

    return @[paramsIds, paramsNames, enabledParamsIds];
}

- (NSString *) getHazmatUsaDescription:(NSArray<NSString *> *)paramsIds
{
    if (paramsIds.count == 0)
        return OALocalizedString(@"shared_string_no");
    
    NSString *result = @"";
    for (int i = 0; i < paramsIds.count; i++)
    {
        NSString *paramsId = paramsIds[i];
        int hazmatClass = [self getHazmatUsaClass:paramsId];
        if (i > 0)
            result = [result stringByAppendingString:@", "];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%d", hazmatClass]];
    }
    
    result = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), OALocalizedString(@"shared_string_class"), result];
    return result;
}

- (int) getHazmatUsaClass:(NSString *)paramsId
{
    return [[paramsId stringByReplacingOccurrencesOfString:kRouteParamHazmatCategoryUsaPrefix withString:@""] intValue];
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
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_chevron"].imageFlippedForRightToLeftLayoutDirection style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:backButton animated:YES];
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
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paramController];
    [self presentViewController:navigationController animated:YES completion:nil];
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
    [self showModalViewController:settingsViewController];
}

- (void) showAvoidRoadsScreen
{
    OARouteAvoidSettingsViewController *avoidController = [[OARouteAvoidSettingsViewController alloc] init];
    avoidController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:avoidController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void) openNavigationSettings
{
    OAProfileNavigationSettingsViewController *settingsViewController = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:[[OARoutingHelper sharedInstance] getAppMode]];
    settingsViewController.openFromRouteInfo = YES;
    settingsViewController.delegate = self;
    [self showModalViewController:settingsViewController];
}

- (void) openRouteLineAppearance
{
    [self dismissViewControllerAnimated:NO completion:^{
        [OARootViewController.instance.mapPanel closeRouteInfo:NO onComplete:^{
            OARouteLineAppearanceHudViewController *routeLineAppearanceHudViewController =
                [[OARouteLineAppearanceHudViewController alloc] initWithAppMode:[_routingHelper getAppMode] prevScreen:EOARouteLineAppearancePrevScreenNavigation];
            routeLineAppearanceHudViewController.delegate = self;
            [OARootViewController.instance.mapPanel showScrollableHudViewController:routeLineAppearanceHudViewController];
        }];
    }];
}

- (void) openSimulateNavigationScreen
{
    OASimulationNavigationSettingViewController *simulateController = [[OASimulationNavigationSettingViewController alloc] initWithAppMode:[_routingHelper getAppMode]];
    simulateController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:simulateController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void) openShowAlongScreen
{
    [[OARootViewController instance].mapPanel showWaypoints:YES];
    [self dismissViewController];
}

- (void) showTripSettingsScreen
{
    [self dismissViewControllerAnimated:NO completion:nil];
    OAGPXRouteParamsBuilder *gpxParams = _routingHelper.getCurrentGPXRoute;
    OASGpxFile *gpx = gpxParams ? gpxParams.file : nil;
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
}

- (void) showAvoidTransportScreen
{
    OARouteAvoidTransportSettingsViewController *avoidTransportController = [[OARouteAvoidTransportSettingsViewController alloc] init];
    avoidTransportController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:avoidTransportController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)doneButtonPressed
{
}

- (void)onLeftNavbarButtonPressed
{
    [self dismissViewController];
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
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
    [self openRouteLineAppearance];
}

#pragma mark - OARouteLineAppearanceViewControllerDelegate

-(void) onCloseAppearance
{
    [OARootViewController.instance.mapPanel showRouteInfo:NO];
}

@end
