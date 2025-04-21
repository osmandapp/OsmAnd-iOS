//
//  OAVehicleParametersViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVehicleParametersViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OAValueTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OAVehicleParametersSettingsViewController.h"
#import "OADefaultSpeedViewController.h"
#import "OARouteSettingsBaseViewController.h"
#import "OARouteProvider.h"
#import "OARoutePreferencesParameters.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAVehicleParametersViewController () <OASettingsDataDelegate>

@end

@implementation OAVehicleParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    vector<RoutingParameter> _otherParameters;
    NSInteger _dimensionsSection;
    NSInteger _fuelSection;
    NSInteger _otherSection;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"vehicle_parameters");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *exraParametersArr = [NSMutableArray array];
    NSMutableArray *defaultSpeedArr = [NSMutableArray array];
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    _otherParameters.clear();
    NSString *appModeRoutingProfile = self.appMode.getRoutingProfile;
    NSString *parentAppModeRoutingProfile = self.appMode.parent.getRoutingProfile;
    BOOL isPublicTransport = [appModeRoutingProfile isEqualToString:OAApplicationMode.PUBLIC_TRANSPORT.stringKey];
    
    if (isPublicTransport)
    {
        _data = [NSArray arrayWithArray:tableData];
        return;
    }
    
    if (router && ![appModeRoutingProfile isEqualToString:OAApplicationMode.PUBLIC_TRANSPORT.stringKey] &&
        ![appModeRoutingProfile isEqualToString:OAApplicationMode.SKI.stringKey] &&
        ![parentAppModeRoutingProfile isEqualToString:OAApplicationMode.PUBLIC_TRANSPORT.stringKey] &&
        ![parentAppModeRoutingProfile isEqualToString:OAApplicationMode.SKI.stringKey])
    {
        auto parameters = router->getParameters(string(self.appMode.getDerivedProfile.UTF8String));
        for (auto it = parameters.begin(); it != parameters.end(); ++it)
        {
            auto& p = it->second;
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *group = [NSString stringWithUTF8String:p.group.c_str()];
            if (![param hasPrefix:@"avoid_"]
                    && ![param hasPrefix:@"prefer_"]
                    && ![param isEqualToString:kRouteParamShortWay]
                    && ![param isEqualToString:kRouteParamHazmatCategory]
                    && ![group isEqualToString:kRouteParamGroupDrivingStyle])
                _otherParameters.push_back(p);
        }
        for (const auto& p : _otherParameters)
        {
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            if (!(p.type == RoutingParameterType::BOOLEAN))
            {
                BOOL isMotorType = [paramId isEqualToString:@"motor_type"];
                OACommonString *stringParam = [_settings getCustomRoutingProperty:paramId defaultValue:@"0"];
                NSString *value = [stringParam get:self.appMode];
                int index = -1;
                
                NSMutableArray<NSNumber *> *possibleValues = [NSMutableArray new];
                NSMutableArray<NSString *> *valueDescriptions = [NSMutableArray new];
                
                double d = value ? floorf(value.doubleValue * 100 + 0.5) / 100 : DBL_MAX;
                
                for (int i = 0; i < p.possibleValues.size(); i++)
                {
                    double vl = floorf(p.possibleValues[i] * 100 + 0.5) / 100;
                    [possibleValues addObject:@(vl)];
                    NSString *descr = [NSString stringWithUTF8String:p.possibleValueDescriptions[i].c_str()];
                    [valueDescriptions addObject:descr];
                    if (vl == d)
                        index = i;
                }

                if (index == 0)
                    value = OALocalizedString([paramId isEqualToString:@"motor_type"] ? @"shared_string_not_selected" : @"shared_string_none");
                else if (index != -1)
                    value = [NSString stringWithUTF8String:p.possibleValueDescriptions[index].c_str()];
                else
                    value = [NSString stringWithFormat:@"%@ %@", value, [paramId isEqualToString:@"weight"] ? OALocalizedString(@"metric_ton") : OALocalizedString(@"m")];
                [isMotorType ? exraParametersArr : parametersArr addObject:
                 @{
                     @"name" : paramId,
                     @"title" : title,
                     @"value" : value,
                     @"selectedItem" : @(index),
                     @"icon" : [self getParameterIcon:paramId],
                     @"possibleValues" : possibleValues,
                     @"possibleValuesDescr" : valueDescriptions,
                     @"setting" : stringParam,
                     @"type" : [OAValueTableViewCell getCellIdentifier] }
                 ];
                
                if (isMotorType)
                {
                    [self setupFuelTankCapacity:exraParametersArr];
                }
            }
        }
    }
    [defaultSpeedArr addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"default_speed_setting_title"),
        @"icon" : @"ic_action_speed",
        @"name" : @"defaultSpeed",
    }];
    if (parametersArr.count > 0)
    {
        [tableData addObject:parametersArr];
        _dimensionsSection = tableData.count - 1;
    }
    if (exraParametersArr.count > 0)
    {
        [tableData addObject:exraParametersArr];
        _fuelSection = tableData.count - 1;
    }
    if (defaultSpeedArr.count > 0)
    {
        [tableData addObject:defaultSpeedArr];
        _otherSection = tableData.count - 1;
    }
    _data = [NSArray arrayWithArray:tableData];
}

- (void) setupFuelTankCapacity:(NSMutableArray *)exraParametersArr
{
    OACommonString *stringParam = [_settings getCustomRoutingProperty:@"fuel_tank_capacity" defaultValue:@"0"];
    NSString *value = [stringParam get:self.appMode];
    double convertedValue = [OAOsmAndFormatter readSavedFuelTankCapacity:[_settings.volumeUnits get:self.appMode] mode:self.appMode value:[value doubleValue]];
    value = [OAOsmAndFormatter getFormattedFuelCapacity:[_settings.volumeUnits get:self.appMode] mode:self.appMode value:convertedValue];
    int index = -1;
    
    NSMutableArray<NSNumber *> *possibleValues = [NSMutableArray new];
    NSMutableArray<NSString *> *valueDescriptions = [NSMutableArray new];
    
    double d = value ? floorf(value.doubleValue * 100 + 0.5) / 100 : DBL_MAX;
    
    for (int i = 0; i <= 11; i++)
    {
        double fuelTankCapacityValue = i == 0 ? 0 : 10 * i;
        double vl = floorf(fuelTankCapacityValue * 100 + 0.5) / 100;
        [possibleValues addObject:@(vl)];
        NSString *descr = fuelTankCapacityValue == 0 ? @"-" : [OAOsmAndFormatter getFormattedFuelCapacity:[_settings.volumeUnits get:self.appMode] mode:self.appMode value:fuelTankCapacityValue];
        [valueDescriptions addObject:descr];
        if (vl == d)
            index = i;
    }
    
    [exraParametersArr addObject:
         @{
        @"name" : @"fuel_tank_capacity",
        @"title" : OALocalizedString(@"fuel_tank_capacity"),
        @"value" : value,
        @"selectedItem" : @(index),
        @"icon" : @"ic_custom_obd_fuel_tank",
        @"possibleValues" : possibleValues,
        @"possibleValuesDescr" : valueDescriptions,
        @"setting" : stringParam,
        @"type" : [OAValueTableViewCell getCellIdentifier] }
    ];
}

- (NSString *) getParameterIcon:(NSString *)parameterName
{
    if ([parameterName isEqualToString:@"weight"])
        return @"ic_custom_weight_limit";
    else if ([parameterName isEqualToString:@"height"])
        return @"ic_custom_height_limit";
    else if ([parameterName isEqualToString:@"length"])
        return @"ic_custom_length_limit";
    else if ([parameterName isEqualToString:@"width"])
        return @"ic_custom_width_limit";
    else if ([parameterName isEqualToString:@"motor_type"])
        return @"ic_custom_fuel";
    return @"";
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == _dimensionsSection)
        return OALocalizedString(@"shared_strings_dimensions");
    else if (section == _fuelSection)
        return OALocalizedString(@"poi_filter_fuel");
    else if (section == _otherSection)
        return OALocalizedString(@"other_location");
    else
        return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (section == _dimensionsSection)
        return OALocalizedString(@"touting_specified_vehicle_parameters_descr");
    else if (section == _otherSection)
        return OALocalizedString(@"default_speed_descr");
    else
        return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [item[@"selectedItem"] intValue] == 0 ? [UIColor colorNamed:ACColorNameIconColorDisabled] : self.appMode.getProfileColor;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = self.appMode.getProfileColor;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemName = item[@"name"];
    OABaseSettingsViewController *settingsViewController = nil;
    if ([itemName isEqualToString:@"defaultSpeed"])
        settingsViewController = [[OADefaultSpeedViewController alloc] initWithApplicationMode:self.appMode speedParameters:item];
    else
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    settingsViewController.delegate = self;
    [self showModalViewController:settingsViewController];
}

#pragma mark - OAVehicleParametersSettingDelegate

- (void) onSettingsChanged
{
    [self generateData];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

@end
