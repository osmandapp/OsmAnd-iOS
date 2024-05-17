//
//  OAProfileGeneralSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 01.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileGeneralSettingsViewController.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAProfileGeneralSettingsParametersViewController.h"
#import "OACoordinatesFormatViewController.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAProfileGeneralSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"general_settings_2");
}

#pragma mark - Table data

- (void)generateData
{
    NSString *appThemeValue;
    NSString *appThemeIcon;
    if ([_settings.appearanceProfileTheme get:self.appMode] == ThemeLight)
    {
        appThemeValue = OALocalizedString(@"shared_string_light");
        appThemeIcon = @"ic_custom_sun";
    }
    else if ([_settings.appearanceProfileTheme get:self.appMode] == ThemeDark)
    {
        appThemeValue = OALocalizedString(@"shared_string_dark");
        appThemeIcon = @"ic_custom_moon";
    }
    else
    {
        appThemeValue = OALocalizedString(@"shared_string_system_default");
        appThemeIcon = @"ic_custom_device";
    }
    
    NSString *rotateMapValue;
    NSString *rotateMapIcon;
    if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_BEARING)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_bearing_opt");
        rotateMapIcon = @"ic_custom_direction_bearing_day";
    }
    else if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_COMPASS)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_compass_opt");
        rotateMapIcon = @"ic_custom_direction_compass_day";
    }
    else if ([_settings.rotateMap get:self.appMode] == ROTATE_MAP_MANUAL)
    {
        rotateMapValue = OALocalizedString(@"rotate_map_manual_opt");
        rotateMapIcon = @"ic_custom_direction_manual_day";
    }
    else
    {
        rotateMapValue = OALocalizedString(@"rotate_map_north_opt");
        rotateMapIcon = @"ic_custom_direction_north_day";
    }

    NSString *rotateScreenValue;
    NSString *rotateScreenIcon;
    NSInteger mapScreenOrientation = [_settings.mapScreenOrientation get:self.appMode];
    if (mapScreenOrientation == EOAScreenOrientationPortrait)
    {
        rotateScreenValue = OALocalizedString(@"map_orientation_portrait");
        rotateScreenIcon = @"ic_custom_iphone_portrait";
    }
    else if (mapScreenOrientation == EOAScreenOrientationLandscape)
    {
        rotateScreenValue = OALocalizedString(@"map_orientation_landscape");
        rotateScreenIcon = @"ic_custom_iphone_landscape";
    }
    else
    {
        rotateScreenValue = OALocalizedString(@"map_orientation_default");
        rotateScreenIcon = @"ic_custom_iphone_portrait_settings";
    }
    
    NSString *drivingRegionValue;
    if ([_settings.drivingRegionAutomatic get:self.appMode])
        drivingRegionValue = OALocalizedString(@"shared_string_automatic");
    else
        drivingRegionValue = [OADrivingRegion getName:[_settings.drivingRegion get:self.appMode]];
    
    NSString* metricSystemValue;
    switch ([_settings.metricSystem get:self.appMode]) {
        case KILOMETERS_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_km_m");
            break;
        case MILES_AND_FEET:
            metricSystemValue = OALocalizedString(@"si_mi_feet");
            break;
        case MILES_AND_YARDS:
            metricSystemValue = OALocalizedString(@"si_mi_yard");
            break;
        case MILES_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_mi_meters");
            break;
        case NAUTICAL_MILES_AND_METERS:
            metricSystemValue = OALocalizedString(@"si_nm_mt");
            break;
        case NAUTICAL_MILES_AND_FEET:
            metricSystemValue = OALocalizedString(@"si_nm_ft");
            break;
        default:
            metricSystemValue = OALocalizedString(@"si_km_m");
            break;
    }
    
    NSString* speedSystemValue;
    switch ([_settings.speedSystem get:self.appMode]) {
        case KILOMETERS_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_kmh");
            break;
        case MILES_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_mph");
            break;
        case METERS_PER_SECOND:
            speedSystemValue = OALocalizedString(@"si_m_s");
            break;
        case MINUTES_PER_MILE:
            speedSystemValue = OALocalizedString(@"si_min_m");
            break;
        case MINUTES_PER_KILOMETER:
            speedSystemValue = OALocalizedString(@"si_min_km");
            break;
        case NAUTICALMILES_PER_HOUR:
            speedSystemValue = OALocalizedString(@"si_nm_h");
            break;
        default:
            speedSystemValue = OALocalizedString(@"si_kmh");
            break;
    }
    
    NSString* geoFormatValue;
    switch ([_settings.settingGeoFormat get:self.appMode]) {
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
        case MAP_GEO_MGRS_FORMAT:
            geoFormatValue = @"MGRS";
            break;
        default:
            geoFormatValue = OALocalizedString(@"navigate_point_format_D");
            break;
    }
    
    NSString* angularUnitsValue = @"";
    switch ([_settings.angularUnits get:self.appMode])
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
    
    NSString* externalInputDeviceValue;
    if ([_settings.settingExternalInputDevice get:self.appMode] == GENERIC_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_generic_ext_input");
    else if ([_settings.settingExternalInputDevice get:self.appMode] == WUNDERLINQ_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_wunderlinq_ext_input");
    else
        externalInputDeviceValue = OALocalizedString(@"shared_string_none");
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *appearanceArr = [NSMutableArray array];
    NSMutableArray *unitsAndFormatsArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [appearanceArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"settings_app_theme"),
        @"value" : appThemeValue,
        @"icon" : appThemeIcon,
        @"key" : @"app_theme",
    }];
    [appearanceArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"rotate_map_to"),
        @"value" : rotateMapValue,
        @"icon" : rotateMapIcon,
        @"no_tint" : @YES,
        @"key" : @"map_orientation",
    }];
    if (![OAUtilities isIPad])
    {
        [appearanceArr addObject:@{
            @"type" : [OAValueTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"map_screen_orientation"),
            @"value" : rotateScreenValue,
            @"icon" : rotateScreenIcon,
            @"key" : @"screenOrientation",
        }];
    }
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"driving_region"),
        @"value" : drivingRegionValue,
        @"icon" : @"ic_profile_car",
        @"key" : @"drivingRegion",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"unit_of_length"),
        @"value" : metricSystemValue,
        @"icon" : @"ic_custom_ruler",
        @"key" : @"lengthUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"units_of_speed"),
        @"value" : speedSystemValue,
        @"icon" : @"ic_action_speed",
        @"key" : @"speedUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"coords_format"),
        @"value" : geoFormatValue,
        @"icon" : @"ic_custom_coordinates",
        @"key" : @"coordsFormat",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"angular_measurment_units"),
        @"value" : angularUnitsValue,
        @"icon" : @"ic_custom_angular_unit",
        @"key" : @"angulerMeasurmentUnits",
    }];
    [unitsAndFormatsArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"distance_during_navigation"),
        @"value" : OALocalizedString([_settings.preciseDistanceNumbers get:self.appMode] ? @"shared_string_precise" : @"shared_string_round_up"),
        @"icon" : [_settings.preciseDistanceNumbers get:self.appMode] ? @"ic_custom_distance_number_precise" : @"ic_custom_distance_number_rounded",
        @"key" : @"distanceDuringNavigation",
    }];
    [otherArr addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"external_input_device"),
        @"value" : externalInputDeviceValue,
        @"key" : @"externalImputDevice",
    }];
    [tableData addObject:appearanceArr];
    [tableData addObject:unitsAndFormatsArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"shared_string_appearance");
    else if (section == 1)
        return OALocalizedString(@"units_and_formats");
    else
        return OALocalizedString(@"other_location");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}
- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [item[@"isOn"] boolValue] ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);

            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
        }
        if (cell)
        {
            if ([item[@"key"] isEqualToString:@"externalImputDevice"])
            {
                [cell leftIconVisibility:NO];
            }
            else
            {
                [cell leftIconVisibility:YES];
                if ([item[@"no_tint"] boolValue])
                    cell.leftIconView.image = [UIImage imageNamed:item[@"icon"]];
                else
                    cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            }
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
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
    NSString *itemKey = item[@"key"];
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"app_theme"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsAppTheme applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"map_orientation"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsMapOrientation applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"screenOrientation"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsScreenOrientation applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"drivingRegion"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsDrivingRegion applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"lengthUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsUnitsOfLenght applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"speedUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsUnitsOfSpeed applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"coordsFormat"])
        settingsViewController = [[OACoordinatesFormatViewController alloc] initWithAppMode:self.appMode];
    else if ([itemKey isEqualToString:@"angulerMeasurmentUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsAngularMeasurmentUnits applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"distanceDuringNavigation"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsDistanceDuringNavigation applicationMode:self.appMode];
    else if ([itemKey isEqualToString:@"externalImputDevice"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:EOAProfileGeneralSettingsExternalInputDevices applicationMode:self.appMode];
    if (settingsViewController != nil)
    {
        settingsViewController.delegate = self;
        if ([itemKey isEqualToString:@"app_theme"] || [itemKey isEqualToString:@"screenOrientation"] || [itemKey isEqualToString:@"distanceDuringNavigation"])
            [self showMediumSheetViewController:settingsViewController isLargeAvailable:NO];
        else
            [self showModalViewController:settingsViewController];
    }
}

#pragma mark - Selectors

- (void)onRotation
{
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *name = item[@"name"];
        if (name)
        {
            [self generateData];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged;
{
    [self generateData];
    [self.tableView reloadData];
}

@end
