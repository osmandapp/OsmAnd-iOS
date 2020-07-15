//
//  OARouteParametersViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteParametersViewController.h"
#import "OADeviceScreenTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAAvoidPreferParametersViewController.h"
#import "OARecalculateRouteViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OARouteSettingsBaseViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeScreenImage @"OADeviceScreenTableViewCell"
#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconTitle @"OAIconTextCell"
#define kCellTypeSwitch @"OASettingSwitchCell"

@interface OARouteParametersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OARouteParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    NSInteger iconColor;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"route_params");
    self.subtitleLabel.text = self.appMode.name;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    iconColor = self.appMode.getIconColor;
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    OAAppSettings* settings = [OAAppSettings sharedManager];
    [otherArr addObject:@{
        @"type" : kCellTypeScreenImage,
        @"foregroundImage" : @"img_settings_sreen_route_parameters@3x.png",
        @"backgroundImage" : @"img_settings_device_bottom_light@3x.png",
    }];
    [parametersArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"recalculate_route"),
        @"value" : @"120 m", // has to be changed
        @"icon" : @"ic_custom_minimal_distance",
        @"key" : @"recalculateRoute",
    }];
    
    auto router = [self.class getRouter:self.appMode];
    if (router)
    {
        auto& parameters = router->getParametersList();
        vector <RoutingParameter> otherParameters;
        vector <RoutingParameter> avoidParameters;
        vector <RoutingParameter> preferParameters;
        vector <RoutingParameter> reliefFactorParameters;
        vector <RoutingParameter> drivingStyleParameters;
        for (auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:@"avoid_"])
                avoidParameters.push_back(p);
            else if ([param hasPrefix:@"prefer_"])
                preferParameters.push_back(p);
            else if ("relief_smoothness_factor" == p.group)
                reliefFactorParameters.push_back(p);
            else if ("driving_style" == p.group)
                drivingStyleParameters.push_back(p);
            else
                otherParameters.push_back(p);
        }
        if (avoidParameters.size() > 0)
        {
            [parametersArr addObject:@{
                @"type" : kCellTypeIconTitle,
                @"title" : OALocalizedString(@"impassable_road"),
                @"icon" : @"ic_custom_alert",
                @"value" : @([self checkIfAnyParameterIsSelected:avoidParameters]),
                @"key" : @"avoidRoads"
            }];
        }
        for (auto& p : otherParameters)
        {
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OAProfileBoolean *booleanParam = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];
                [parametersArr addObject:
                 @{
                   @"name" : paramId,
                   @"title" : title,
                   @"icon" : [self getParameterIcon:paramId isSelected:[booleanParam get:self.appMode]],
                   @"value" : booleanParam,
                   @"type" : kCellTypeSwitch }
                 ];
            }
        }
        if (preferParameters.size() > 0)
        {
            [parametersArr addObject:@{
                @"type" : kCellTypeIconTitle,
                @"title" : OALocalizedString(@"prefer_in_routing_title"),
                @"icon" : @"ic_custom_alert",
                @"value" : @([self checkIfAnyParameterIsSelected:preferParameters]),
                @"key" : @"preferRoads"
            }];
        }
    }
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    return res;
}

+ (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    OsmAndAppInstance app = [OsmAndApp instance];
    auto router = app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    return router;
}
 
- (BOOL) checkIfAnyParameterIsSelected:(vector <RoutingParameter>)routingParameters
{
    for (auto& p : routingParameters)
    {
        OALocalRoutingParameter *rp = [[OALocalRoutingParameter alloc] initWithAppMode:self.appMode];
        rp.routingParameter = p;
        if (rp.isSelected)
            return YES;
    }
    return NO;
}

- (NSString *)getParameterIcon:(NSString *)parameterName isSelected:(BOOL)isSelected
{
    if ([parameterName isEqualToString:@"short_way"])
        return @"ic_custom_fuel";
    else if ([parameterName isEqualToString:@"allow_private"])
        return isSelected ? @"ic_custom_allow_private_access" : @"ic_custom_forbid_private_access";
    else if ([parameterName isEqualToString:@"allow_motorway"])
        return isSelected ? @"ic_custom_motorways" : @"ic_custom_avoid_motorways";
    else if ([parameterName isEqualToString:@"height_obstacles"])
        return @"ic_custom_ascent";
    return @"";
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeScreenImage])
    {
        static NSString* const identifierCell = kCellTypeScreenImage;
        OADeviceScreenTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OADeviceScreenTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundImageView.image = [UIImage imageNamed:item[@"backgroundImage"]];
            cell.foregroundImageView.image = [UIImage imageNamed:item[@"foregroundImage"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        if (cell)
        {
            cell.leftImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB(iconColor);
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconTitle])
    {
        static NSString* const identifierCell = kCellTypeIconTitle;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = [item[@"value"] boolValue] ? UIColorFromRGB(iconColor) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = kCellTypeSwitch;
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.imgView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = cell.switchView.on ? UIColorFromRGB(iconColor) : UIColorFromRGB(color_icon_inactive);
            id v = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            else
            {
                cell.switchView.on = [v boolValue];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.01 : 19.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemKey = item[@"key"];
    if ([itemKey isEqualToString:@"preferRoads"])
    {
        OABaseSettingsViewController *preferViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:NO];
        preferViewController.delegate = self;
        [self presentViewController:preferViewController animated:YES completion:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"recalculateRoute"])
    {
        settingsViewController = [[OARecalculateRouteViewController alloc] initWithAppMode:self.appMode];
    }
    else if ([itemKey isEqualToString:@"avoidRoads"])
    {
        settingsViewController = [[OAAvoidPreferParametersViewController alloc] initWithAppMode:self.appMode isAvoid:YES];
        settingsViewController.delegate = self;
    }
    [self.navigationController pushViewController:settingsViewController animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - Switch

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        BOOL isChecked = ((UISwitch *) sender).on;
        auto router = [self.class getRouter:self.appMode];
        if (router)
        {
            auto& parameters = router->getParametersList();
            for (auto& routingParameter : parameters)
            {
                NSString *param = [NSString stringWithUTF8String:routingParameter.id.c_str()];
                if ([param isEqualToString:item[@"name"]])
                {
                    OAProfileBoolean *property = [[OAAppSettings sharedManager] getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:routingParameter.id.c_str()] defaultValue:routingParameter.defaultBoolean];
                    [property set:isChecked mode:self.appMode];
                }
            }
        }
        [self setupView];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void) onSettingsChanged;
{
    [self setupView];
    [self.tableView reloadData];
}

@end
