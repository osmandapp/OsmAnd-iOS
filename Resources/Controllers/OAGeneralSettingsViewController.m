//
//  OAGeneralSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 01.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGeneralSettingsViewController.h"
#import "OAAppSettings.h"
#import "OAIconTitleValueCell.h"
#import "OASettingsTableViewCell.h"
#import "OASettingSwitchCell.h"

#import "OAMapOrientationViewController.h"
#import "OADrivingRegionViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconTextSwitch @"OASettingSwitchCell"
#define kCellTypeTitle @"OASettingsCell"

@interface OAGeneralSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAGeneralSettingsViewController
{
    NSArray<NSArray *> *_data;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"general_settings_2");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSString *rotateMapValue;
    if ([settings.rotateMap get] == ROTATE_MAP_BEARING)
        rotateMapValue = OALocalizedString(@"rotate_map_bearing_opt");
    else if ([settings.rotateMap get] == ROTATE_MAP_COMPASS)
        rotateMapValue = OALocalizedString(@"rotate_map_compass_opt");
    else
        rotateMapValue = OALocalizedString(@"rotate_map_none_opt");
    NSString *drivingRegionValue;
    if (settings.drivingRegionAutomatic)
        drivingRegionValue = OALocalizedString(@"driving_region_automatic");
    else
        drivingRegionValue = [OADrivingRegion getName:settings.drivingRegion];
    NSString* metricSystemValue = settings.metricSystem == KILOMETERS_AND_METERS ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
    NSString* geoFormatValue;
    switch (settings.settingGeoFormat) {
        case MAP_GEO_FORMAT_DEGREES:
            geoFormatValue = OALocalizedString(@"navigate_point_format_D");
            break;
        case MAP_GEO_FORMAT_MINUTES:
            geoFormatValue = OALocalizedString(@"navigate_point_format_DM");
            break;
        case MAP_GEO_FORMAT_SECONDS:
            geoFormatValue = OALocalizedString(@"navigate_point_format_DMS");
            break;
        case MAP_GEO_UTM_FORMAT:
            geoFormatValue = @"UTM";
            break;
        case MAP_GEO_OLC_FORMAT:
            geoFormatValue = @"OLC";
            break;
        default:
            geoFormatValue = OALocalizedString(@"navigate_point_format_D");
            break;
    }
    NSString* angularUnitsValue = @"";
    switch ([settings.angularUnits get])
    {
        case DEGREES360:
        {
            angularUnitsValue = OALocalizedString(@"sett_deg360");
            break;
        }
        case DEGREES:
        {
            angularUnitsValue = OALocalizedString(@"sett_deg180");
            break;
        }
        case MILLIRADS:
        {
            angularUnitsValue = OALocalizedString(@"shared_string_milliradians");
            break;
        }
        default:
            break;
    }
    NSNumber *allow3DValue = @(settings.settingAllow3DView);
    NSString* externalInputDeviceValue;
    if (settings.settingExternalInputDevice == GENERIC_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_generic_ext_input");
    else if (settings.settingExternalInputDevice == WUNDERLINQ_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_wunderlinq_ext_input");
    else
        externalInputDeviceValue = OALocalizedString(@"sett_no_ext_input");
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *appearanceArr = [NSMutableArray array];
    NSMutableArray *unitsAndFormatsArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [appearanceArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"settings_app_theme"), // ???
        @"value" : OALocalizedString(@"app_theme_light"),
        @"icon" : @"ic_custom_contrast",
        @"key" : @"app_theme",
    }];
    [appearanceArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"rotate_map_to_bearing"),
        @"value" : rotateMapValue,
        @"icon" : @"ic_action_compass",
        @"key" : @"map_orientation",
    }];
    [appearanceArr addObject:@{
        @"type" : kCellTypeIconTextSwitch,
        @"title" : OALocalizedString(@"allow_3D_view"),
        @"isOn" : allow3DValue,
        @"icon" : @"ic_action_compass",
        @"key" : @"3dView",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"driving_region"),
        @"value" : drivingRegionValue,
        @"icon" : @"ic_profile_car", // has to change accordign to chosen profile
        @"key" : @"drivingRegion",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"unit_of_length"),
        @"value" : metricSystemValue,
        @"icon" : @"ic_custom_ruler",
        @"key" : @"lengthUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"units_of_speed"),
        @"value" : OALocalizedString(@"units_kmh"), // ???
        @"icon" : @"ic_action_speed",
        @"key" : @"speedUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"coords_format"),
        @"value" : geoFormatValue,
        @"icon" : @"ic_custom_coordinates",
        @"key" : @"coordsFormat",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"angular_measurment_units"),
        @"value" : angularUnitsValue,
        @"icon" : @"",
        @"key" : @"angulerMeasurmentUnits",
    }];
    [otherArr addObject:@{
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"sett_ext_input"), // device / devices ???
        @"value" : externalInputDeviceValue,
        @"key" : @"externalImputDevice",
    }];
    [tableData addObject:appearanceArr];
    [tableData addObject:unitsAndFormatsArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
}

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
    else if ([cellType isEqualToString:kCellTypeIconTextSwitch])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
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
            cell.imgView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeTitle])
    {
        static NSString* const identifierCell = kCellTypeTitle;
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    return nil;
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
    OAAppSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"app_theme"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"map_orientation"])
        settingsViewController = [[OAMapOrientationViewController alloc] init];
    else if ([itemKey isEqualToString:@"drivingRegion"])
        settingsViewController = [[OADrivingRegionViewController alloc] init];
    else if ([itemKey isEqualToString:@"lengthUnits"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"speedUnits"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"coordsFormat"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"angulerMeasurmentUnits"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"externalImputDevice"])
        settingsViewController = [[OAAppSettingsViewController alloc] init];
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
    if (section == 0)
        return OALocalizedString(@"map_settings_appearance");
    else if (section == 1)
        return OALocalizedString(@"units_and_formats");
    else
        return OALocalizedString(@"help_other_header");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
}

@end
