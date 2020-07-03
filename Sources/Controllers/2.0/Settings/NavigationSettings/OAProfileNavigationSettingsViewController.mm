//
//  OAProfileNavigationSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileNavigationSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OAVehicleParametersViewController.h"
#import "OAMapBehaviorViewController.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAProfileDataObject.h"
#import "OsmAndApp.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconText @"OAIconTextCell"
#define kCellTypeTitle @"OASettingsTitleCell"

@interface OAProfileNavigationSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileNavigationSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAApplicationMode *_appMode;
    
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    NSDictionary<NSString *, OARoutingProfileDataObject *> *_routingProfileDataObjects;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        _settings = OAAppSettings.sharedManager;
        _app = [OsmAndApp instance];
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    _routingProfileDataObjects = [self getRoutingProfiles];
    
    OARoutingProfileDataObject *routingData = _routingProfileDataObjects[[_settings.routingProfile get:_appMode]];
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *navigationArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [navigationArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"nav_type_title"),
        @"value" : routingData ? routingData.name : @"",
        @"icon" : routingData ? routingData.iconName : @"ic_custom_navigation",
        @"key" : @"navigationType",
    }];
    [navigationArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"route_params"),
        @"icon" : @"ic_custom_route",
        @"key" : @"routeParams",
    }];
    [navigationArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"voice_prompts"),
        @"icon" : @"ic_custom_sound",
        @"key" : @"voicePrompts",
    }];
    [navigationArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"screen_alerts"),
        @"icon" : @"ic_custom_alert",
        @"key" : @"screenAlerts",
    }];
    [navigationArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"vehicle_parameters"),
        @"icon" : @"ic_profile_car", // has to change according to current profile icon
        @"key" : @"vehicleParams",
    }];
    [otherArr addObject:@{
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"map_behavior"),
        @"key" : @"mapBehavior",
    }];
    [tableData addObject:navigationArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"routing_settings_2");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}


- (NSDictionary<NSString *, OARoutingProfileDataObject *> *) getRoutingProfiles
{
    NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *profilesObjects = [NSMutableDictionary new];
    OARoutingProfileDataObject *straightLine = [[OARoutingProfileDataObject alloc] initWithResource:EOARouringProfilesResourceStraightLine];
    straightLine.descr = OALocalizedString(@"special_routing");
    [profilesObjects setObject:straightLine forKey:[OARoutingProfileDataObject getProfileKey:EOARouringProfilesResourceStraightLine]];
    
    OARoutingProfileDataObject *directTo = [[OARoutingProfileDataObject alloc] initWithResource:EOARouringProfilesResourceDirectTo];
    directTo.descr = OALocalizedString(@"special_routing");
    [profilesObjects setObject:directTo forKey:[OARoutingProfileDataObject getProfileKey:EOARouringProfilesResourceDirectTo]];
    
//    if (context.getBRouterService() != null) {
//        profilesObjects.put(RoutingProfilesResources.BROUTER_MODE.name(), new RoutingProfileDataObject(
//                RoutingProfilesResources.BROUTER_MODE.name(),
//                context.getString(RoutingProfilesResources.BROUTER_MODE.getStringRes()),
//                context.getString(R.string.third_party_routing_type),
//                RoutingProfilesResources.BROUTER_MODE.getIconRes(),
//                false, null));
//    }

//    List<String> disabledRouterNames = OsmandPlugin.getDisabledRouterNames();
//    for (RoutingConfiguration.Builder builder : context.getAllRoutingConfigs()) {
//        collectRoutingProfilesFromConfig(context, builder, profilesObjects, disabledRouterNames);
//    }
    [self collectRoutingProfilesFromConfig:_app.defaultRoutingConfig profileObjects:profilesObjects disabledRouterNames:@[]];
    return profilesObjects;
}

- (void) collectRoutingProfilesFromConfig:(std::shared_ptr<RoutingConfigurationBuilder>) builder
                           profileObjects:(NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *) profilesObjects disabledRouterNames:(NSArray<NSString *> *) disabledRouterNames
{
    for (auto it = builder->routers.begin(); it != builder->routers.end(); ++it)
    {
        NSString *routerKey = [NSString stringWithCString:it->first.c_str() encoding:NSUTF8StringEncoding];
        const auto router = it->second;
        if (router != nullptr && ![routerKey isEqualToString:@"geocoding"] && ![disabledRouterNames containsObject:routerKey])
        {
            NSString *iconName = @"ic_custom_navigation";
            NSString *name = [NSString stringWithCString:router->profileName.c_str() encoding:NSUTF8StringEncoding];
            NSString *descr = OALocalizedString(@"osmand_routing");
            NSString *fileName = [NSString stringWithCString:router->fileName.c_str() encoding:NSUTF8StringEncoding];
            if (fileName.length > 0)
            {
                descr = fileName;
                OARoutingProfileDataObject *data = [[OARoutingProfileDataObject alloc] initWithStringKey:routerKey name:name descr:descr iconName:iconName isSelected:NO fileName:fileName];
                [profilesObjects setObject:data forKey:routerKey];
            }
            else if ([OARoutingProfileDataObject isRpValue:name.upperCase])
            {
                OARoutingProfileDataObject *data = [OARoutingProfileDataObject getRoutingProfileDataByName:name.upperCase];
                data.descr = descr;
                [profilesObjects setObject:data forKey:routerKey];
            }
        }
    }
}

//public static List<ProfileDataObject> getBaseProfiles(OsmandApplication app) {
//    return getBaseProfiles(app, false);
//}
//
//public static List<ProfileDataObject> getBaseProfiles(OsmandApplication app, boolean includeBrowseMap) {
//    List<ProfileDataObject> profiles = new ArrayList<>();
//    for (ApplicationMode mode : ApplicationMode.allPossibleValues()) {
//        if (mode != ApplicationMode.DEFAULT || includeBrowseMap) {
//            String description = mode.getDescription();
//            if (Algorithms.isEmpty(description)) {
//                description = getAppModeDescription(app, mode);
//            }
//            profiles.add(new ProfileDataObject(mode.toHumanString(), description,
//                    mode.getStringKey(), mode.getIconRes(), false, mode.getIconColorInfo()));
//        }
//    }
//    return profiles;
//}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.leftImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconText])
    {
        static NSString* const identifierCell = kCellTypeIconText;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeTitle])
    {
        static NSString* const identifierCell = kCellTypeTitle;
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"navigationType"])
        settingsViewController = [[OANavigationTypeViewController alloc] init];
    else if ([itemKey isEqualToString:@"routeParams"])
        settingsViewController = [[OARouteParametersViewController alloc] init];
    else if ([itemKey isEqualToString:@"voicePrompts"])
        settingsViewController = [[OAVoicePromptsViewController alloc] init];
    else if ([itemKey isEqualToString:@"screenAlerts"])
        settingsViewController = [[OAScreenAlertsViewController alloc] init];
    else if ([itemKey isEqualToString:@"vehicleParams"])
        settingsViewController = [[OAVehicleParametersViewController alloc] init];
    else if ([itemKey isEqualToString:@"mapBehavior"])
        settingsViewController = [[OAMapBehaviorViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"routing_settings") : OALocalizedString(@"help_other_header");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"change_map_behavior");
}

@end
