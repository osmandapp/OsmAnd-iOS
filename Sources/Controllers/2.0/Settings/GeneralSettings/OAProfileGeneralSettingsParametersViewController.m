//
//  OAProfileGeneralSettingsParametersViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileGeneralSettingsParametersViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"
#import "OAAppSettings.h"
#import "OAFileNameTranslationHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OATitleDescriptionCollapsableCell.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAProfileGeneralSettingsParametersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAProfileGeneralSettingsParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    EOAProfileGeneralSettingsParameter _settingsType;
    NSString *_title;
}

- (instancetype) initWithType:(EOAProfileGeneralSettingsParameter)settingsType applicationMode:(OAApplicationMode *)applicationMode
{
    self = [super initWithAppMode:applicationMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _settingsType = settingsType;
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    switch (_settingsType) {
        case EOAProfileGeneralSettingsMapOrientation:
            _title = OALocalizedString(@"rotate_map_to_bearing");
            break;
        case EOAProfileGeneralSettingsDrivingRegion:
            _title = OALocalizedString(@"driving_region");
            break;
        case EOAProfileGeneralSettingsUnitsOfLenght:
            _title = OALocalizedString(@"unit_of_length");
            break;
        case EOAProfileGeneralSettingsUnitsOfSpeed:
            _title = OALocalizedString(@"units_of_speed");
            break;
        case EOAProfileGeneralSettingsAngularMeasurmentUnits:
            _title = OALocalizedString(@"angular_measurment_units");
            break;
        case EOAProfileGeneralSettingsExternalInputDevices:
            _title = OALocalizedString(@"sett_ext_input");
            break;
        default:
            break;
    }
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = _title;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *dataArr = [NSMutableArray array];
    NSInteger rotateMap = [_settings.rotateMap get:self.appMode];
    BOOL automatic = [_settings.drivingRegionAutomatic get:self.appMode];
    NSInteger drivingRegion = [_settings.drivingRegion get:self.appMode];
    NSInteger metricSystem = [_settings.metricSystem get:self.appMode];
    NSInteger speedSystem = [_settings.speedSystem get:self.appMode];
    NSInteger externamlInputDevices = [_settings.settingExternalInputDevice get:self.appMode];
    if (automatic)
        drivingRegion = -1;
    EOAAngularConstant angularUnits = [_settings.angularUnits get:self.appMode];
    
    switch (_settingsType) {
        case EOAProfileGeneralSettingsMapOrientation:
            [dataArr addObject:@{
                @"name" : @"none",
                @"title" : OALocalizedString(@"rotate_map_none_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_NONE),
                @"icon" : @"ic_custom_direction_north",
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"bearing",
                @"title" : OALocalizedString(@"rotate_map_bearing_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_BEARING),
                @"icon" : @"ic_custom_direction_movement",
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
               @"name" : @"compass",
               @"title" : OALocalizedString(@"rotate_map_compass_opt"),
               @"selected" : @(rotateMap == ROTATE_MAP_COMPASS),
               @"icon" : @"ic_custom_direction_compass",
               @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsDrivingRegion:
            self.tableView.rowHeight = 60.;
            [dataArr addObject:@{
                @"name" : @"AUTOMATIC",
                @"title" : OALocalizedString(@"driving_region_automatic"),
                @"description" : OALocalizedString(@"device_settings"),
                @"value" : @"",
                @"selected" : @(automatic),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_EUROPE_ASIA",
                @"title" : [OADrivingRegion getName:DR_EUROPE_ASIA],
                @"description" : [OADrivingRegion getDescription:DR_EUROPE_ASIA],
                @"value" : @"",
                @"selected" : @(drivingRegion == DR_EUROPE_ASIA),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_US",
                @"title" : [OADrivingRegion getName:DR_US],
                @"description" : [OADrivingRegion getDescription:DR_US],
                @"value" : @"",
                @"selected" : @(drivingRegion == DR_US),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_CANADA",
                @"title" : [OADrivingRegion getName:DR_CANADA],
                @"description" : [OADrivingRegion getDescription:DR_CANADA],
                @"selected" : @(drivingRegion == DR_CANADA),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_UK_AND_OTHERS",
                @"title" : [OADrivingRegion getName:DR_UK_AND_OTHERS],
                @"description" : [OADrivingRegion getDescription:DR_UK_AND_OTHERS],
                @"selected" : @(drivingRegion == DR_UK_AND_OTHERS),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_JAPAN",
                @"title" : [OADrivingRegion getName:DR_JAPAN],
                @"description" : [OADrivingRegion getDescription:DR_JAPAN],
                @"selected" : @(drivingRegion == DR_JAPAN),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"DR_AUSTRALIA",
                @"title" : [OADrivingRegion getName:DR_AUSTRALIA],
                @"description" : [OADrivingRegion getDescription:DR_AUSTRALIA],
                @"selected" : @(drivingRegion == DR_AUSTRALIA),
                @"type" : [OATitleDescriptionCollapsableCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsUnitsOfLenght:
            [dataArr addObject:@{
                @"name" : @"KILOMETERS_AND_METERS",
                @"title" : OALocalizedString(@"si_km_m"),
                @"selected" : @(metricSystem == KILOMETERS_AND_METERS),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_FEET",
                @"title" : OALocalizedString(@"si_mi_feet"),
                @"selected" : @(metricSystem == MILES_AND_FEET),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_YARDS",
                @"title" : OALocalizedString(@"si_mi_yard"),
                @"selected" : @(metricSystem == MILES_AND_YARDS),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_METERS",
                @"title" : OALocalizedString(@"si_mi_meters"),
                @"selected" : @(metricSystem == MILES_AND_METERS),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICAL_MILES",
                @"title" : OALocalizedString(@"si_nm"),
                @"selected" : @(metricSystem == NAUTICAL_MILES),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsUnitsOfSpeed:
            [dataArr addObject:@{
                @"name" : @"KILOMETERS_PER_HOUR",
                @"title" : OALocalizedString(@"si_kmh"),
                @"selected" : @(speedSystem == KILOMETERS_PER_HOUR),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_mph"),
                @"selected" : @(speedSystem == MILES_PER_HOUR),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"METERS_PER_SECOND",
                @"title" : OALocalizedString(@"si_m_s"),
                @"selected" : @(speedSystem == METERS_PER_SECOND),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_MILE",
                @"title" : OALocalizedString(@"si_min_m"),
                @"selected" : @(speedSystem == MINUTES_PER_MILE),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_KILOMETER",
                @"title" : OALocalizedString(@"si_min_km"),
                @"selected" : @(speedSystem == MINUTES_PER_KILOMETER),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICALMILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_nm_h"),
                @"selected" : @(speedSystem == NAUTICALMILES_PER_HOUR),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsAngularMeasurmentUnits:
            [dataArr addObject:@{
                @"name" : @"degrees_180",
                @"title" : OALocalizedString(@"sett_deg180"),
                @"selected" : @(angularUnits == DEGREES),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"degrees_360",
                @"title" : OALocalizedString(@"sett_deg360"),
                @"selected" : @(angularUnits == DEGREES360),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"milliradians",
                @"title" : OALocalizedString(@"shared_string_milliradians"),
                @"selected" : @(angularUnits == MILLIRADS),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsExternalInputDevices:
            [dataArr addObject:@{
                @"name" : @"sett_no_ext_input",
                @"title" : OALocalizedString(@"sett_no_ext_input"),
                @"selected" : @(externamlInputDevices == NO_EXTERNAL_DEVICE),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"sett_generic_ext_input",
                @"title" : OALocalizedString(@"sett_generic_ext_input"),
                @"selected" : @(externamlInputDevices == GENERIC_EXTERNAL_DEVICE),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"sett_wunderlinq_ext_input",
                @"title" : OALocalizedString(@"sett_wunderlinq_ext_input"),
                @"selected" : @(externamlInputDevices == WUNDERLINQ_EXTERNAL_DEVICE),
                @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
            }];
            break;
            
        default:
            break;
    }
    _data = [NSArray arrayWithObject:dataArr];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.hidden = ![item[@"selected"] boolValue];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    if ([cellType isEqualToString:[OATitleDescriptionCollapsableCell getCellIdentifier]])
    {
        OATitleDescriptionCollapsableCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionCollapsableCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionCollapsableCell *)[nib objectAtIndex:0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"description"];
            cell.iconView.hidden = ![item[@"selected"] boolValue];
        }
        return cell;
    }
    if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.hidden = ![item[@"selected"] boolValue];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *name = item[@"name"];
    switch (_settingsType) {
        case EOAProfileGeneralSettingsMapOrientation:
            [self selectMapOrientation:name];
            break;
        case EOAProfileGeneralSettingsDrivingRegion:
            [self selectDrivingRegion:name];
            break;
        case EOAProfileGeneralSettingsUnitsOfLenght:
            [self selectMetricSystem:name];
            break;
        case EOAProfileGeneralSettingsUnitsOfSpeed:
            [self selectSpeedSystem:name];
            break;
        case EOAProfileGeneralSettingsAngularMeasurmentUnits:
            [self selectSettingAngularUnits:name];
            break;
        case EOAProfileGeneralSettingsExternalInputDevices:
            [self selectSettingExternalInput:name];
            break;
        default:
            break;
    }
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self backButtonClicked:self];
}

- (void) selectMapOrientation:(NSString *)name
{
    if ([name isEqualToString:@"bearing"])
        [_settings.rotateMap set:ROTATE_MAP_BEARING mode:self.appMode];
    else if ([name isEqualToString:@"compass"])
        [_settings.rotateMap set:ROTATE_MAP_COMPASS mode:self.appMode];
    else
        [_settings.rotateMap set:ROTATE_MAP_NONE mode:self.appMode];
}

- (void) selectDrivingRegion:(NSString *)name
{
    OAMapViewTrackingUtilities *mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    if ([name isEqualToString:@"AUTOMATIC"])
    {
        [_settings.drivingRegionAutomatic set:YES mode:self.appMode];
        [mapViewTrackingUtilities resetDrivingRegionUpdate];
    }
    else
    {
        EOADrivingRegion drivingRegion;
        if ([name isEqualToString:@"DR_US"])
            drivingRegion = DR_US;
        else if ([name isEqualToString:@"DR_CANADA"])
            drivingRegion = DR_CANADA;
        else if ([name isEqualToString:@"DR_UK_AND_OTHERS"])
            drivingRegion = DR_UK_AND_OTHERS;
        else if ([name isEqualToString:@"DR_JAPAN"])
            drivingRegion = DR_JAPAN;
        else if ([name isEqualToString:@"DR_AUSTRALIA"])
            drivingRegion = DR_AUSTRALIA;
        else
            drivingRegion = DR_EUROPE_ASIA;
        [_settings.drivingRegionAutomatic set:NO mode:self.appMode];
        [_settings.drivingRegion set:drivingRegion mode:self.appMode];
    }
}

- (void) selectMetricSystem:(NSString *)name
{
    if ([name isEqualToString:@"KILOMETERS_AND_METERS"])
        [_settings.metricSystem set:KILOMETERS_AND_METERS mode:self.appMode];
    else if ([name isEqualToString:@"MILES_AND_FEET"])
        [_settings.metricSystem set:MILES_AND_FEET mode:self.appMode];
    else if ([name isEqualToString:@"MILES_AND_YARDS"])
        [_settings.metricSystem set:MILES_AND_YARDS mode:self.appMode];
    else if ([name isEqualToString:@"MILES_AND_METERS"])
        [_settings.metricSystem set:MILES_AND_METERS mode:self.appMode];
    else if ([name isEqualToString:@"NAUTICAL_MILES"])
        [_settings.metricSystem set:NAUTICAL_MILES mode:self.appMode];
    [_settings.metricSystemChangedManually set:YES mode:self.appMode];
}

- (void) selectSpeedSystem:(NSString *)name
{
    if ([name isEqualToString:@"KILOMETERS_PER_HOUR"])
        [_settings.speedSystem set:(KILOMETERS_PER_HOUR) mode:self.appMode];
    else if ([name isEqualToString:@"MILES_PER_HOUR"])
        [_settings.speedSystem set:(MILES_PER_HOUR) mode:self.appMode];
    else if ([name isEqualToString:@"METERS_PER_SECOND"])
        [_settings.speedSystem set:(METERS_PER_SECOND) mode:self.appMode];
    else if ([name isEqualToString:@"MINUTES_PER_MILE"])
        [_settings.speedSystem set:(MINUTES_PER_MILE) mode:self.appMode];
    else if ([name isEqualToString:@"MINUTES_PER_KILOMETER"])
        [_settings.speedSystem set:(MINUTES_PER_KILOMETER) mode:self.appMode];
    else if ([name isEqualToString:@"NAUTICALMILES_PER_HOUR"])
        [_settings.speedSystem set:(NAUTICALMILES_PER_HOUR) mode:self.appMode];
}

- (void) selectSettingAngularUnits:(NSString *)name
{
    if ([name isEqualToString:@"degrees_180"])
        [_settings.angularUnits set:DEGREES mode:self.appMode];
    else if ([name isEqualToString:@"degrees_360"])
        [_settings.angularUnits set:DEGREES360 mode:self.appMode];
    else if ([name isEqualToString:@"milliradians"])
        [_settings.angularUnits set:MILLIRADS mode:self.appMode];
}

- (void) selectSettingExternalInput:(NSString *)name
{
    if ([name isEqualToString:@"sett_no_ext_input"])
        [_settings.settingExternalInputDevice set:NO_EXTERNAL_DEVICE mode:self.appMode];
    else if ([name isEqualToString:@"sett_generic_ext_input"])
        [_settings.settingExternalInputDevice set:GENERIC_EXTERNAL_DEVICE mode:self.appMode];
    else if ([name isEqualToString:@"sett_wunderlinq_ext_input"])
        [_settings.settingExternalInputDevice set:WUNDERLINQ_EXTERNAL_DEVICE mode:self.appMode];
}

@end
