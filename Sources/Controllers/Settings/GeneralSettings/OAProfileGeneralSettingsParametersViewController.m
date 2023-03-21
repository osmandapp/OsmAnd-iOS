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
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASimpleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAProfileGeneralSettingsParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    EOAProfileGeneralSettingsParameter _settingsType;
    NSString *_title;
    UIView *_tableHeaderView;
    BOOL _openFromMap;
}

#pragma mark - Initialization

- (instancetype) initWithType:(EOAProfileGeneralSettingsParameter)settingsType applicationMode:(OAApplicationMode *)applicationMode
{
    self = [super initWithAppMode:applicationMode];
    if (self)
    {
        _settingsType = settingsType;
        [self postInit];
    }
    return self;
}

- (instancetype) initMapOrientationFromMap
{
    self = [super initWithAppMode:OAAppSettings.sharedManager.applicationMode.get];
    if (self)
    {
        _settingsType = EOAProfileGeneralSettingsMapOrientation;
        _openFromMap = YES;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    switch (_settingsType)
    {
        case EOAProfileGeneralSettingsMapOrientation:
            _title = OALocalizedString(@"rotate_map_to");
            break;
        case EOAProfileGeneralSettingsDisplayPosition:
            _title = OALocalizedString(@"position_on_map");
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
            _title = OALocalizedString(@"external_input_device");
            break;
        default:
            break;
    }
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _title;
}

- (NSString *)getSubtitle
{
    return _settingsType == EOAProfileGeneralSettingsMapOrientation && _openFromMap ? @"" : [self.appMode toHumanString];
}

- (BOOL)isNavbarSeparatorVisible
{
    return !_openFromMap;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return _settingsType == EOAProfileGeneralSettingsMapOrientation ? EOABaseNavbarStyleDescription : EOABaseNavbarStyleSimple;
}

- (NSString *)getCustomTableViewDescription
{
    return OALocalizedString(@"compass_click_desc");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _openFromMap ? OALocalizedString(@"shared_string_close") : nil;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    NSInteger rotateMap = [_settings.rotateMap get:self.appMode];
    EOAPositionPlacement positionMap = [_settings.positionPlacementOnMap get:self.appMode];
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
                @"title" : OALocalizedString(@"rotate_map_north_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_NONE),
                @"icon" : @"ic_custom_direction_north_day",
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"bearing",
                @"title" : OALocalizedString(@"rotate_map_bearing_opt"),
                @"selected" : @(rotateMap == ROTATE_MAP_BEARING),
                @"icon" : @"ic_custom_direction_bearing_day",
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
               @"name" : @"compass",
               @"title" : OALocalizedString(@"rotate_map_compass_opt"),
               @"selected" : @(rotateMap == ROTATE_MAP_COMPASS),
               @"icon" : @"ic_custom_direction_compass_day",
               @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
               @"name" : @"manually",
               @"title" : OALocalizedString(@"rotate_map_manual_opt"),
               @"selected" : @(rotateMap == ROTATE_MAP_MANUAL),
               @"icon" : @"ic_custom_direction_manual_day",
               @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsDisplayPosition:
            [dataArr addObject:@{
                @"name" : @"auto",
                @"title" : OALocalizedString(@"shared_string_automatic"),
                @"selected" : @(positionMap == EOAPositionPlacementAuto),
                @"icon" : @"ic_custom_display_position_automatic",
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"center",
                @"title" : OALocalizedString(@"position_on_map_center"),
                @"selected" : @(positionMap == EOAPositionPlacementCenter),
                @"icon" : @"ic_custom_display_position_center",
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"bottom",
                @"title" : OALocalizedString(@"position_on_map_bottom"),
                @"selected" : @(positionMap == EOAPositionPlacementBottom),
                @"icon" : @"ic_custom_display_position_bottom",
                @"type" : [OAIconTextTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsDrivingRegion:
            self.tableView.rowHeight = 60.;
            [dataArr addObject:@{
                @"name" : @"AUTOMATIC",
                @"title" : OALocalizedString(@"shared_string_automatic"),
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
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_FEET",
                @"title" : OALocalizedString(@"si_mi_feet"),
                @"selected" : @(metricSystem == MILES_AND_FEET),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_YARDS",
                @"title" : OALocalizedString(@"si_mi_yard"),
                @"selected" : @(metricSystem == MILES_AND_YARDS),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_AND_METERS",
                @"title" : OALocalizedString(@"si_mi_meters"),
                @"selected" : @(metricSystem == MILES_AND_METERS),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICAL_MILES_AND_METERS",
                @"title" : OALocalizedString(@"si_nm_mt"),
                @"selected" : @(metricSystem == NAUTICAL_MILES_AND_METERS),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICAL_MILES_AND_FEET",
                @"title" : OALocalizedString(@"si_nm_ft"),
                @"selected" : @(metricSystem == NAUTICAL_MILES_AND_FEET),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsUnitsOfSpeed:
            [dataArr addObject:@{
                @"name" : @"KILOMETERS_PER_HOUR",
                @"title" : OALocalizedString(@"si_kmh"),
                @"selected" : @(speedSystem == KILOMETERS_PER_HOUR),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_mph"),
                @"selected" : @(speedSystem == MILES_PER_HOUR),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"METERS_PER_SECOND",
                @"title" : OALocalizedString(@"si_m_s"),
                @"selected" : @(speedSystem == METERS_PER_SECOND),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_MILE",
                @"title" : OALocalizedString(@"si_min_m"),
                @"selected" : @(speedSystem == MINUTES_PER_MILE),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"MINUTES_PER_KILOMETER",
                @"title" : OALocalizedString(@"si_min_km"),
                @"selected" : @(speedSystem == MINUTES_PER_KILOMETER),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"NAUTICALMILES_PER_HOUR",
                @"title" : OALocalizedString(@"si_nm_h"),
                @"selected" : @(speedSystem == NAUTICALMILES_PER_HOUR),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsAngularMeasurmentUnits:
            [dataArr addObject:@{
                @"name" : @"degrees_180",
                @"title" : OALocalizedString(@"sett_deg180"),
                @"selected" : @(angularUnits == DEGREES),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"degrees_360",
                @"title" : OALocalizedString(@"sett_deg360"),
                @"selected" : @(angularUnits == DEGREES360),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"milliradians",
                @"title" : OALocalizedString(@"shared_string_milliradians"),
                @"selected" : @(angularUnits == MILLIRADS),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            break;
            
        case EOAProfileGeneralSettingsExternalInputDevices:
            [dataArr addObject:@{
                @"name" : @"sett_no_ext_input",
                @"title" : OALocalizedString(@"shared_string_none"),
                @"selected" : @(externamlInputDevices == NO_EXTERNAL_DEVICE),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"sett_generic_ext_input",
                @"title" : OALocalizedString(@"sett_generic_ext_input"),
                @"selected" : @(externamlInputDevices == GENERIC_EXTERNAL_DEVICE),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            [dataArr addObject:@{
                @"name" : @"sett_wunderlinq_ext_input",
                @"title" : OALocalizedString(@"sett_wunderlinq_ext_input"),
                @"selected" : @(externamlInputDevices == WUNDERLINQ_EXTERNAL_DEVICE),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
            }];
            break;
            
        default:
            break;
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (BOOL) hideFirstHeader
{
    return _settingsType == EOAProfileGeneralSettingsMapOrientation;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            [cell.arrowIconView setHidden:YES];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            if ([item[@"selected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.iconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    if ([cellType isEqualToString:[OATitleDescriptionCollapsableCell getCellIdentifier]])
    {
        OATitleDescriptionCollapsableCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionCollapsableCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionCollapsableCell *)[nib objectAtIndex:0];
            [cell.iconView setHidden:YES];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"description"];
            if ([item[@"selected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        return cell;
    }
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell.descriptionLabel setHidden:YES];
            if (!item[@"icon"])
                [cell.leftIconView setHidden:YES];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            if (_settingsType != EOAProfileGeneralSettingsMapOrientation)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
                cell.leftIconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(self.appMode.getIconColor) : UIColorFromRGB(color_icon_inactive);
            }
            else
            {
                cell.leftIconView.image = [UIImage imageNamed:item[@"icon"]];
            }
            if ([item[@"selected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *name = item[@"name"];
    switch (_settingsType) {
        case EOAProfileGeneralSettingsMapOrientation:
            [self selectMapOrientation:name];
            break;
        case EOAProfileGeneralSettingsDisplayPosition:
            [self selectDisplayPosition:(int)indexPath.row];
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
    [self generateData];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.delegate onSettingsChanged];
    [self dismissViewController];
}

#pragma mark - Selectors

- (void) selectMapOrientation:(NSString *)name
{
    if ([name isEqualToString:@"bearing"])
        [_settings.rotateMap set:ROTATE_MAP_BEARING mode:self.appMode];
    else if ([name isEqualToString:@"compass"])
        [_settings.rotateMap set:ROTATE_MAP_COMPASS mode:self.appMode];
    else if ([name isEqualToString:@"manually"])
        [_settings.rotateMap set:ROTATE_MAP_MANUAL mode:self.appMode];
    else
        [_settings.rotateMap set:ROTATE_MAP_NONE mode:self.appMode];
    
    [[OAMapViewTrackingUtilities instance] updateSettings];
    [OARootViewController.instance.mapPanel.mapViewController refreshMap];
}

- (void) selectDisplayPosition:(int)idx
{
    [_settings.positionPlacementOnMap set:idx mode:self.appMode];
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
    else if ([name isEqualToString:@"NAUTICAL_MILES_AND_METERS"])
        [_settings.metricSystem set:NAUTICAL_MILES_AND_METERS mode:self.appMode];
    else if ([name isEqualToString:@"NAUTICAL_MILES_AND_FEET"])
        [_settings.metricSystem set:NAUTICAL_MILES_AND_FEET mode:self.appMode];
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
