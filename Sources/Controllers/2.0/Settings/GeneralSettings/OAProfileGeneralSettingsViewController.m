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
#import "OAIconTitleValueCell.h"
#import "OASettingsTableViewCell.h"
#import "OASettingSwitchCell.h"
#import "OAProfileGeneralSettingsParametersViewController.h"
#import "OACoordinatesFormatViewController.h"
#import "PXAlertView.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconTextSwitch @"OASettingSwitchCell"
#define kCellTypeTitle @"OASettingsCell"

@interface OAProfileGeneralSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileGeneralSettingsViewController
{
    OAApplicationMode *_appMode;
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    BOOL _showAppModeDialog;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _appMode = [OAApplicationMode CAR];
        _showAppModeDialog = YES;
    }
    return self;
}

- (id) initWithSettingsMode:(OAApplicationMode *)applicationMode
{
    self = [super init];
    if (self)
    {
        _appMode = applicationMode;
        _showAppModeDialog = NO;
    }
    return self;
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"general_settings_2");
    self.subtitleLabel.text = _appMode.name;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _settings = [OAAppSettings sharedManager];
    self.profileButton.hidden = NO;
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    if (_showAppModeDialog)
    {
        _showAppModeDialog = NO;
        [self showAppModeDialog];
    }
    [self.tableView reloadData];
}

- (void) showAppModeDialog
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];
    NSMutableArray *modes = [NSMutableArray array];
    
    NSArray<OAApplicationMode *> *values = [OAApplicationMode values];
    for (OAApplicationMode *v in values)
    {
        if (v == [OAApplicationMode DEFAULT])
            continue;
        
        [titles addObject:v.name];
        [images addObject:v.getIconName];
        [modes addObject:v];
    }
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"map_settings_mode")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:titles
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
        if (!cancelled)
        {
            _appMode = modes[buttonIndex];
            [self setupView];
        }
    }];
}

- (IBAction)profileButtonPressed:(id)sender {
    [self showAppModeDialog];
}

- (void) setupView
{
    NSString *rotateMapValue;
    if ([_settings.rotateMap get:_appMode] == ROTATE_MAP_BEARING)
        rotateMapValue = OALocalizedString(@"rotate_map_bearing_opt");
    else if ([_settings.rotateMap get:_appMode] == ROTATE_MAP_COMPASS)
        rotateMapValue = OALocalizedString(@"rotate_map_compass_opt");
    else
        rotateMapValue = OALocalizedString(@"do_not_rotate");
    
    NSNumber *allow3DValue = @([_settings.settingAllow3DView get:_appMode]);
    
    NSString *drivingRegionValue;
    if ([_settings.drivingRegionAutomatic get:_appMode])
        drivingRegionValue = OALocalizedString(@"driving_region_automatic");
    else
        drivingRegionValue = [OADrivingRegion getName:[_settings.drivingRegion get:_appMode]];
    
    NSString* metricSystemValue;
    switch ([_settings.metricSystem get:_appMode]) {
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
        case NAUTICAL_MILES:
            metricSystemValue = OALocalizedString(@"si_nm");
            break;
        default:
            metricSystemValue = OALocalizedString(@"si_km_m");
            break;
    }
    
    NSString* speedSystemValue;
    switch ([_settings.speedSystem get:_appMode]) {
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
    switch ([_settings.settingGeoFormat get:_appMode]) {
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
    switch ([_settings.angularUnits get:_appMode])
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
    if ([_settings.settingExternalInputDevice get:_appMode] == GENERIC_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_generic_ext_input");
    else if ([_settings.settingExternalInputDevice get:_appMode] == WUNDERLINQ_EXTERNAL_DEVICE)
        externalInputDeviceValue = OALocalizedString(@"sett_wunderlinq_ext_input");
    else
        externalInputDeviceValue = OALocalizedString(@"sett_no_ext_input");
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *appearanceArr = [NSMutableArray array];
    NSMutableArray *unitsAndFormatsArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
//    [appearanceArr addObject:@{
//        @"type" : kCellTypeIconTitleValue,
//        @"title" : OALocalizedString(@"settings_app_theme"),
//        @"value" : OALocalizedString(@"app_theme_light"),
//        @"icon" : @"ic_custom_contrast",
//        @"key" : @"app_theme",
//    }];
    [appearanceArr addObject:@{
        @"type" : kCellTypeIconTitleValue,
        @"title" : OALocalizedString(@"rotate_map_to_bearing"),
        @"value" : rotateMapValue,
        @"icon" : @"ic_action_compass",
        @"key" : @"map_orientation",
    }];
    [appearanceArr addObject:@{
        @"name" : @"allow_3d",
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
        @"icon" : @"ic_profile_car",
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
        @"value" : speedSystemValue,
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
        @"icon" : @"ic_custom_angular_unit",
        @"key" : @"angulerMeasurmentUnits",
    }];
    [otherArr addObject:@{
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"sett_ext_input"),
        @"value" : externalInputDeviceValue,
        @"key" : @"externalImputDevice",
    }];
    [tableData addObject:appearanceArr];
    [tableData addObject:unitsAndFormatsArr];
    [tableData addObject:otherArr];
    _data = [NSArray arrayWithArray:tableData];
    [self updateNavBar];
    [self.tableView reloadData];
}

- (void) updateNavBar
{
    [self.profileButton setImage:_appMode.getIcon forState:UIControlStateNormal];
    self.subtitleLabel.text = _appMode.name;
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
            cell.imgView.tintColor = UIColorFromRGB(color_icon_inactive);
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
    OABaseSettingsViewController* settingsViewController = nil;
    if ([itemKey isEqualToString:@"app_theme"])
        settingsViewController = [[OABaseSettingsViewController alloc] init];
    else if ([itemKey isEqualToString:@"map_orientation"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsMapOrientation applicationMode:_appMode];
    else if ([itemKey isEqualToString:@"drivingRegion"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsDrivingRegion applicationMode:_appMode];
    else if ([itemKey isEqualToString:@"lengthUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsUnitsOfLenght applicationMode:_appMode];
    else if ([itemKey isEqualToString:@"speedUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsUnitsOfSpeed applicationMode:_appMode];
    else if ([itemKey isEqualToString:@"coordsFormat"])
        settingsViewController = [[OACoordinatesFormatViewController alloc] initWithMode:_appMode];
    else if ([itemKey isEqualToString:@"angulerMeasurmentUnits"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsAngularMeasurmentUnits applicationMode:_appMode];
    else if ([itemKey isEqualToString:@"externalImputDevice"])
        settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initWithType:kProfileGeneralSettingsExternalInputDevices applicationMode:_appMode];
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

#pragma mark - Switch

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
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([name isEqualToString:@"allow_3d"])
            {
                [_settings.settingAllow3DView set:isChecked mode:_appMode];
                if (!isChecked)
                {
                    OsmAndAppInstance app = OsmAndApp.instance;
                    if (app.mapMode == OAMapModeFollow)
                        [app setMapMode:OAMapModePositionTrack];
                    else
                        [app.mapModeObservable notifyEvent];
                }
            }
        }
    }
}

@end
