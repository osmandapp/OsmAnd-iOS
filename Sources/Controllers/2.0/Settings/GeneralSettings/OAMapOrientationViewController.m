//
//  OAMapOrientationViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapOrientationViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"
#import "OAAppSettings.h"
#import "OAFileNameTranslationHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OATitleDescriptionCheckmarkCell.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeCheck @"OAIconTextCell"
#define kCellTypeTitleDescriptionCheck @"OATitleDescriptionCheckmarkCell"
#define kCellTypeTitleCheck @"OASettingsTitleCell"

@interface OAMapOrientationViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapOrientationViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    kProfileGeneralSettingsParameter _settingsType;
    NSString *_title;
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

- (instancetype) initWithType:(kProfileGeneralSettingsParameter)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
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
    switch (_settingsType) {
        case kProfileGeneralSettingsMapOrientation:
            _title = OALocalizedString(@"rotate_map_to_bearing");
            break;
        case kProfileGeneralSettingsDrivingRegion:
            _title = OALocalizedString(@"driving_region");
            break;
        case kProfileGeneralSettingsUnitsOfLenght:
            _title = OALocalizedString(@"unit_of_length");
            break;
        case kProfileGeneralSettingsUnitsOfSpeed:
            _title = OALocalizedString(@"units_of_speed");
            break;
        case kProfileGeneralSettingsAngularMeasurmentUnits:
            _title = OALocalizedString(@"angular_measurment_units");
            break;
        case kProfileGeneralSettingsExternalInputDevices:
            _title = OALocalizedString(@"sett_ext_input");
            break;
        default:
            break;
    }
}

- (void) applyLocalization
{
    self.titleLabel.text = _title;
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _settings = [OAAppSettings sharedManager];
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *dataArr = [NSMutableArray array];
    int rotateMap = [_settings.rotateMap get];
    BOOL automatic = _settings.drivingRegionAutomatic;
    int drivingRegion = _settings.drivingRegion;
    if (automatic)
        drivingRegion = -1;
    EOAAngularConstant angularUnits = [_settings.angularUnits get];
    
    switch (_settingsType) {
        case kProfileGeneralSettingsMapOrientation:
            [dataArr addObject:@{
                @"name" : @"none",
                @"title" : OALocalizedString(@"rotate_map_none_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_NONE),
                @"icon" : @"ic_custom_direction_north",
                @"type" : kCellTypeCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"bearing",
                @"title" : OALocalizedString(@"rotate_map_bearing_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_BEARING),
                @"icon" : @"ic_custom_direction_movement",
                @"type" : kCellTypeCheck,
            }];
            [dataArr addObject:@{
               @"name" : @"compass",
               @"title" : OALocalizedString(@"rotate_map_compass_opt"),
               @"selected" : @(rotateMap == ROTATE_MAP_COMPASS),
               @"icon" : @"ic_custom_direction_compass",
               @"type" : kCellTypeCheck,
            }];
            break;
            
        case kProfileGeneralSettingsDrivingRegion:
            self.tableView.rowHeight = 60.;
            [dataArr addObject:@{
                @"name" : @"AUTOMATIC",
                @"title" : OALocalizedString(@"driving_region_automatic"),
                @"description" : OALocalizedString(@"device_settings"),
                @"value" : @"",
                @"selected" : @(automatic),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_EUROPE_ASIA",
                @"title" : [OADrivingRegion getName:DR_EUROPE_ASIA],
                @"description" : [OADrivingRegion getDescription:DR_EUROPE_ASIA],
                @"value" : @"",
                @"selected" : @(drivingRegion == DR_EUROPE_ASIA),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_US",
                @"title" : [OADrivingRegion getName:DR_US],
                @"description" : [OADrivingRegion getDescription:DR_US],
                @"value" : @"",
                @"selected" : @(drivingRegion == DR_US),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_CANADA",
                @"title" : [OADrivingRegion getName:DR_CANADA],
                @"description" : [OADrivingRegion getDescription:DR_CANADA],
                @"selected" : @(drivingRegion == DR_CANADA),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_UK_AND_OTHERS",
                @"title" : [OADrivingRegion getName:DR_UK_AND_OTHERS],
                @"description" : [OADrivingRegion getDescription:DR_UK_AND_OTHERS],
                @"selected" : @(drivingRegion == DR_UK_AND_OTHERS),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_JAPAN",
                @"title" : [OADrivingRegion getName:DR_JAPAN],
                @"description" : [OADrivingRegion getDescription:DR_JAPAN],
                @"selected" : @(drivingRegion == DR_JAPAN),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"DR_AUSTRALIA",
                @"title" : [OADrivingRegion getName:DR_AUSTRALIA],
                @"description" : [OADrivingRegion getDescription:DR_AUSTRALIA],
                @"selected" : @(drivingRegion == DR_AUSTRALIA),
                @"type" : kCellTypeTitleDescriptionCheck,
            }];
            break;
            
        case kProfileGeneralSettingsUnitsOfLenght:
            [dataArr addObject:@{
                @"name" : @"KILOMETERS_AND_METERS",
                @"title" : OALocalizedString(@"si_km_m"),
                @"selected" : @(_settings.metricSystem == KILOMETERS_AND_METERS),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_FEET",
                @"title" : OALocalizedString(@"si_mi_feet"),
                @"selected" : @(_settings.metricSystem == MILES_AND_FEET),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_YARDS",
                @"title" : OALocalizedString(@"si_mi_yard"),
                @"selected" : @(_settings.metricSystem == MILES_AND_YARDS),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_METERS",
                @"title" : OALocalizedString(@"si_mi_meters"),
                @"selected" : @(_settings.metricSystem == MILES_AND_METERS),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICAL_MILES",
                @"title" : OALocalizedString(@"si_nm"),
                @"selected" : @(_settings.metricSystem == NAUTICAL_MILES),
                @"type" : kCellTypeTitleCheck,
            }];
            break;
            
        case kProfileGeneralSettingsUnitsOfSpeed:
            [dataArr addObject:@{
                @"name" : @"KILOMETERS_PER_HOUR",
                @"title" : OALocalizedString(@"si_kmh"),
                @"selected" : @(_settings.speedSystem.get == KILOMETERS_PER_HOUR),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_mph"),
                @"selected" : @(_settings.speedSystem.get == MILES_PER_HOUR),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"METERS_PER_SECOND",
                @"title" : OALocalizedString(@"si_m_s"),
                @"selected" : @(_settings.speedSystem.get == METERS_PER_SECOND),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_MILE",
                @"title" : OALocalizedString(@"si_min_m"),
                @"selected" : @(_settings.speedSystem.get == MINUTES_PER_MILE),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_KILOMETER",
                @"title" : OALocalizedString(@"si_min_km"),
                @"selected" : @(_settings.speedSystem.get == MINUTES_PER_KILOMETER),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICALMILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_nm_h"),
                @"selected" : @(_settings.speedSystem.get == NAUTICALMILES_PER_HOUR),
                @"type" : kCellTypeTitleCheck,
            }];
            break;
            
        case kProfileGeneralSettingsAngularMeasurmentUnits:
            [dataArr addObject:@{
                @"name" : @"degrees_180",
                @"title" : OALocalizedString(@"sett_deg180"),
                @"selected" : @(angularUnits == DEGREES),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"degrees_360",
                @"title" : OALocalizedString(@"sett_deg360"),
                @"selected" : @(angularUnits == DEGREES360),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"milliradians",
                @"title" : OALocalizedString(@"shared_string_milliradians"),
                @"selected" : @(angularUnits == MILLIRADS),
                @"type" : kCellTypeTitleCheck,
            }];
            break;
            
        case kProfileGeneralSettingsExternalInputDevices:
            [dataArr addObject:@{
                @"name" : @"sett_no_ext_input",
                @"title" : OALocalizedString(@"sett_no_ext_input"),
                @"selected" : @(_settings.settingExternalInputDevice == NO_EXTERNAL_DEVICE),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"sett_generic_ext_input",
                @"title" : OALocalizedString(@"sett_generic_ext_input"),
                @"selected" : @(_settings.settingExternalInputDevice == GENERIC_EXTERNAL_DEVICE),
                @"type" : kCellTypeTitleCheck,
            }];
            [dataArr addObject:@{
                @"name" : @"sett_wunderlinq_ext_input",
                @"title" : OALocalizedString(@"sett_wunderlinq_ext_input"),
                @"selected" : @(_settings.settingExternalInputDevice == WUNDERLINQ_EXTERNAL_DEVICE),
                @"type" : kCellTypeTitleCheck,
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
    if ([cellType isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = kCellTypeCheck;
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
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.hidden = ![item[@"selected"] boolValue];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    if ([cellType isEqualToString:kCellTypeTitleDescriptionCheck])
    {
        static NSString* const identifierCell = kCellTypeTitleDescriptionCheck;
        OATitleDescriptionCheckmarkCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OATitleDescriptionCheckmarkCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"description"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"selected"] boolValue];
        }
        return cell;
    }
    if ([cellType isEqualToString:kCellTypeTitleCheck])
    {
        static NSString* const identifierCell = kCellTypeTitleCheck;
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
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
        case kProfileGeneralSettingsMapOrientation:
            [self selectMapOrientation:name];
            break;
        case kProfileGeneralSettingsDrivingRegion:
            [self selectDrivingRegion:name];
            break;
        case kProfileGeneralSettingsUnitsOfLenght:
            [self selectMetricSystem:name];
            break;
        case kProfileGeneralSettingsUnitsOfSpeed:
            [self selectSpeedSystem:name];
            break;
        case kProfileGeneralSettingsAngularMeasurmentUnits:
            [self selectSettingAngularUnits:name];
            break;
        case kProfileGeneralSettingsExternalInputDevices:
            [self selectSettingExternalInput:name];
            break;
        default:
            break;
    }
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) selectMapOrientation:(NSString *)name
{
    if ([name isEqualToString:@"bearing"])
        [_settings.rotateMap set:ROTATE_MAP_BEARING];
    else if ([name isEqualToString:@"compass"])
        [_settings.rotateMap set:ROTATE_MAP_COMPASS];
    else
        [_settings.rotateMap set:ROTATE_MAP_NONE];
}

- (void) selectDrivingRegion:(NSString *)name
{
    OAMapViewTrackingUtilities *mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    if ([name isEqualToString:@"AUTOMATIC"])
    {
        _settings.drivingRegionAutomatic = YES;
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
        _settings.drivingRegionAutomatic = NO;;
        _settings.drivingRegion = drivingRegion;
    }
}

- (void) selectMetricSystem:(NSString *)name
{
    if ([name isEqualToString:@"KILOMETERS_AND_METERS"])
        [_settings setMetricSystem:KILOMETERS_AND_METERS];
    else if ([name isEqualToString:@"MILES_AND_FEET"])
        [_settings setMetricSystem:MILES_AND_FEET];
    else if ([name isEqualToString:@"MILES_AND_YARDS"])
        [_settings setMetricSystem:MILES_AND_YARDS];
    else if ([name isEqualToString:@"MILES_AND_METERS"])
        [_settings setMetricSystem:MILES_AND_METERS];
    else if ([name isEqualToString:@"NAUTICAL_MILES"])
        [_settings setMetricSystem:NAUTICAL_MILES];
    _settings.metricSystemChangedManually = YES;
}

- (void) selectSpeedSystem:(NSString *)name
{
//    if ([name isEqualToString:@"KILOMETERS_PER_HOUR"])
//        [_settings setSpeedSystem:KILOMETERS_PER_HOUR];
//    else if ([name isEqualToString:@"MILES_PER_HOUR"])
//        [_settings setSpeedSystem:MILES_PER_HOUR];
//    else if ([name isEqualToString:@"METERS_PER_SECOND"])
//        [_settings setSpeedSystem:METERS_PER_SECOND];
//    else if ([name isEqualToString:@"MINUTES_PER_MILE"])
//        [_settings setSpeedSystem:MINUTES_PER_MILE];
//    else if ([name isEqualToString:@"MINUTES_PER_KILOMETER"])
//        [_settings setSpeedSystem:MINUTES_PER_KILOMETER];
//    else if ([name isEqualToString:@"NAUTICALMILES_PER_HOUR"])
//        [_settings setSpeedSystem:NAUTICALMILES_PER_HOUR];
}

- (void) selectSettingAngularUnits:(NSString *)name
{
    if ([name isEqualToString:@"degrees_180"])
        [_settings.angularUnits set:DEGREES];
    else if ([name isEqualToString:@"degrees_360"])
        [_settings.angularUnits set:DEGREES360];
    else if ([name isEqualToString:@"milliradians"])
        [_settings.angularUnits set:MILLIRADS];
    else
        [_settings.angularUnits set:DEGREES];
}

- (void) selectSettingExternalInput:(NSString *)name
{
    if ([name isEqualToString:@"sett_no_ext_input"])
        [_settings setSettingExternalInputDevice:NO_EXTERNAL_DEVICE];
    else if ([name isEqualToString:@"sett_generic_ext_input"])
        [_settings setSettingExternalInputDevice:GENERIC_EXTERNAL_DEVICE];
    else if ([name isEqualToString:@"sett_wunderlinq_ext_input"])
        [_settings setSettingExternalInputDevice:WUNDERLINQ_EXTERNAL_DEVICE];
}

@end
