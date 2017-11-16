//
//  OASettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OANavigationSettingsViewController.h"
#import "OAApplicationMode.h"
#import "OAMapViewTrackingUtilities.h"

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"
#define kCellTypeSettings @"settings"

@interface OASettingsViewController ()

@property NSArray* data;

@end

@implementation OASettingsViewController

- (id) initWithSettingsType:(kSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
    }
    return self;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
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
    [self setupView];
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = settings.applicationMode;
    switch (self.settingsType)
    {
        case kSettingsScreenMain:
        {
            self.data = @[
                          @{
                              @"name" : @"general_settings",
                              @"title" : OALocalizedString(@"general_settings_2"),
                              @"description" : OALocalizedString(@"general_settings_descr"),
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSettings },
                          @{
                              @"name" : @"routing_settings",
                              @"title" : OALocalizedString(@"routing_settings_2"),
                              @"description" : OALocalizedString(@"routing_settings_descr"),
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSettings }
                          ];
            break;
        }
        case kSettingsScreenGeneral:
        {
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
            NSString* geoFormatValue = settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            NSNumber *doNotShowDiscountValue = @(settings.settingDoNotShowPromotions);
            NSNumber *doNotUseFirebaseValue = @(settings.settingDoNotUseFirebase);
            
            self.data = @[
                          @{
                              @"name" : @"settings_preset",
                              @"title" : OALocalizedString(@"settings_preset"),
                              @"description" : OALocalizedString(@"settings_preset_descr"),
                              @"value" : appMode.name,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList },
                          @{
                              @"name" : @"rotate_map",
                              @"title" : OALocalizedString(@"rotate_map_to_bearing"),
                              @"description" : OALocalizedString(@"rotate_map_to_bearing_descr"),
                              @"value" : rotateMapValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList },
                          @{
                              @"name" : @"driving_region",
                              @"title" : OALocalizedString(@"driving_region"),
                              @"description" : OALocalizedString(@"driving_region_descr"),
                              @"value" : drivingRegionValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList },
                          @{
                              @"name" : @"sett_units",
                              @"title" : OALocalizedString(@"unit_of_length"),
                              @"description" : OALocalizedString(@"unit_of_length_descr"),
                              @"value" : metricSystemValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList },
                          @{
                              @"name" : @"sett_loc_fmt",
                              @"title" : OALocalizedString(@"coords_format"),
                              @"description" : OALocalizedString(@"coords_format_descr"),
                              @"value" : geoFormatValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList },
                          @{
                              @"name" : @"do_not_show_discount",
                              @"title" : OALocalizedString(@"do_not_show_discount"),
                              @"description" : OALocalizedString(@"do_not_show_discount_desc"),
                              @"value" : doNotShowDiscountValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSwitch },
                          @{
                              @"name" : @"do_not_send_anonymous_data",
                              @"title" : OALocalizedString(@"do_not_send_anonymous_data"),
                              @"description" : OALocalizedString(@"do_not_send_anonymous_data_desc"),
                              @"value" : doNotUseFirebaseValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSwitch }
                          ];
            
            if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
            {
                self.data = [self.data arrayByAddingObject:
                             @{
                               @"name" : @"rec_interval",
                               @"title" : OALocalizedString(@"save_global_track_interval"),
                               @"description" : OALocalizedString(@"save_global_track_interval_descr"),
                               @"value" : recIntervalValue,
                               @"img" : @"menu_cell_pointer.png",
                               @"type" : kCellTypeSingleSelectionList }
                             ];
            }
            break;
        }
        case kSettingsScreenAppMode:
        {
            _titleView.text = OALocalizedString(@"settings_preset");
            NSMutableArray *arr = [NSMutableArray array];
            NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
            for (OAApplicationMode *mode in availableModes)
            {
                [arr addObject: @{
                                  @"name" : mode.stringKey,
                                  @"title" : mode.name,
                                  @"value" : @"",
                                  @"img" : appMode == mode ? @"menu_cell_selected.png" : @"",
                                  @"type" : kCellTypeCheck }];
            }
            self.data = [NSArray arrayWithArray:arr];
            
            break;
        }
        case kSettingsScreenRotateMap:
        {
            _titleView.text = OALocalizedString(@"rotate_map_to_bearing");
            int rotateMap = [settings.rotateMap get];
            self.data = @[
                          @{
                              @"name" : @"none",
                              @"title" : OALocalizedString(@"rotate_map_none_opt"),
                              @"value" : @"",
                              @"img" : rotateMap == ROTATE_MAP_NONE ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"bearing",
                              @"title" : OALocalizedString(@"rotate_map_bearing_opt"),
                              @"value" : @"",
                              @"img" : rotateMap == ROTATE_MAP_BEARING ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"compass",
                              @"title" : OALocalizedString(@"rotate_map_compass_opt"),
                              @"value" : @"",
                              @"img" : rotateMap == ROTATE_MAP_COMPASS ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck }
                          ];
            break;
        }
        case kSettingsScreenDrivingRegion:
        {
            _titleView.text = OALocalizedString(@"driving_region");
            BOOL automatic = settings.drivingRegionAutomatic;
            int drivingRegion = settings.drivingRegion;
            if (automatic)
                drivingRegion = -1;

            self.data = @[
                          @{
                              @"name" : @"AUTOMATIC",
                              @"title" : OALocalizedString(@"driving_region_automatic"),
                              @"description" : @"",
                              @"value" : @"",
                              @"img" : automatic ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_EUROPE_ASIA",
                              @"title" : [OADrivingRegion getName:DR_EUROPE_ASIA],
                              @"description" : [OADrivingRegion getDescription:DR_EUROPE_ASIA],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_EUROPE_ASIA ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_US",
                              @"title" : [OADrivingRegion getName:DR_US],
                              @"description" : [OADrivingRegion getDescription:DR_US],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_US ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_CANADA",
                              @"title" : [OADrivingRegion getName:DR_CANADA],
                              @"description" : [OADrivingRegion getDescription:DR_CANADA],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_CANADA ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_UK_AND_OTHERS",
                              @"title" : [OADrivingRegion getName:DR_UK_AND_OTHERS],
                              @"description" : [OADrivingRegion getDescription:DR_UK_AND_OTHERS],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_UK_AND_OTHERS ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_JAPAN",
                              @"title" : [OADrivingRegion getName:DR_JAPAN],
                              @"description" : [OADrivingRegion getDescription:DR_JAPAN],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_JAPAN ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"DR_AUSTRALIA",
                              @"title" : [OADrivingRegion getName:DR_AUSTRALIA],
                              @"description" : [OADrivingRegion getDescription:DR_AUSTRALIA],
                              @"value" : @"",
                              @"img" : drivingRegion == DR_AUSTRALIA ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck }
                          ];
            break;
        }
        case kSettingsScreenMetricSystem:
        {
            _titleView.text = OALocalizedString(@"sett_units");
            self.data = @[
                          @{
                              @"name" : @"sett_km",
                              @"title" : OALocalizedString(@"sett_km"),
                              @"value" : @"",
                              @"img" : settings.metricSystem == KILOMETERS_AND_METERS ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"sett_ml",
                              @"title" : OALocalizedString(@"sett_ml"),
                              @"value" : @"",
                              @"img" : settings.metricSystem == MILES_AND_FEET ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck }
                          ];
            break;
        }
        case kSettingsScreenGeoCoords:
        {
            _titleView.text = OALocalizedString(@"sett_loc_fmt");
            self.data = @[
                          @{
                              @"name" : @"sett_deg",
                              @"title" : OALocalizedString(@"sett_deg"),
                              @"value" : @"",
                              @"img" : settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"sett_deg_min",
                              @"title" : OALocalizedString(@"sett_deg_min"),
                              @"value" : @"",
                              @"img" : settings.settingGeoFormat == MAP_GEO_FORMAT_MINUTES ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          ];
            break;
        }
        case kSettingsScreenRecInterval:
        {
            _titleView.text = OALocalizedString(@"rec_interval");
            NSMutableArray *arr = [NSMutableArray array];
            for (NSNumber *num in settings.trackIntervalArray)
            {
                [arr addObject: @{
                                  @"title" : [settings getFormattedTrackInterval:[num intValue]],
                                  @"value" : @"",
                                  @"img" : settings.mapSettingSaveTrackIntervalGlobal == [num intValue] ? @"menu_cell_selected.png" : @"",
                                  @"type" : kCellTypeCheck }];
            }
            self.data = [NSArray arrayWithArray:arr];
            
            break;
        }
        default:
            break;
    }
    
    [self.settingsTableView setDataSource: self];
    [self.settingsTableView setDelegate:self];
    self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.settingsTableView reloadData];
    [self.settingsTableView reloadInputViews];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if ([self sectionsOnly])
        return _data[indexPath.section];
    else
        return _data[indexPath.row];
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        NSString *name = item[@"name"];
        if (name)
        {
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([name isEqualToString:@"do_not_show_discount"])
                [[OAAppSettings sharedManager] setSettingDoNotShowPromotions:isChecked];
            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
                [[OAAppSettings sharedManager] setSettingDoNotUseFirebase:isChecked];
        }
    }
}

- (BOOL) sectionsOnly
{
    return _settingsType == kSettingsScreenMain || _settingsType == kSettingsScreenGeneral || _settingsType == kSettingsScreenDrivingRegion;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self sectionsOnly])
        return _data.count;
    else
        return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self sectionsOnly])
        return 1;
    else
        return _data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            id value = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [value boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeSettings])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        return [OASwitchTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTitleTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        return item[@"header"];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return nil;
    }
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *name = item[@"name"];
    if (name)
    {
        switch (self.settingsType)
        {
            case kSettingsScreenMain:
                [self selectSettingMain:name];
                break;
                
            case kSettingsScreenGeneral:
                [self selectSettingGeneral:name];
                break;
            case kSettingsScreenAppMode:
                [self selectAppMode:name];
                break;
            case kSettingsScreenRotateMap:
                [self selectRotateMap:name];
                break;
            case kSettingsScreenDrivingRegion:
                [self selectDrivingRegion:name];
                break;
            case kSettingsScreenMetricSystem:
                [self selectMetricSystem:name];
                break;
            case kSettingsScreenGeoCoords:
                [self selectSettingGeoCode:name];
                break;
            case kSettingsScreenRecInterval:
                [self selectSettingRecInterval:indexPath.row];
                break;
            default:
                break;
        }
    }
}

- (void) selectSettingMain:(NSString *)name
{
    if ([name isEqualToString:@"general_settings"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeneral];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"routing_settings"])
    {
        OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenGeneral];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
}

- (void) selectSettingGeneral:(NSString *)name
{
    if ([name isEqualToString:@"settings_preset"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenAppMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"rotate_map"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenRotateMap];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"driving_region"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenDrivingRegion];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"sett_units"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMetricSystem];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"sett_loc_fmt"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeoCoords];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"do_not_show_discount"])
    {
    }
    else if ([name isEqualToString:@"do_not_send_anonymous_data"])
    {
    }
    else if ([name isEqualToString:@"rec_interval"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenRecInterval];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
}

- (void) selectAppMode:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:name def:[OAApplicationMode DEFAULT]];
    settings.defaultApplicationMode = mode;
    settings.applicationMode = mode;
    [self backButtonClicked:nil];
}

- (void) selectRotateMap:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"bearing"])
        [settings.rotateMap set:ROTATE_MAP_BEARING];
    else if ([name isEqualToString:@"compass"])
        [settings.rotateMap set:ROTATE_MAP_COMPASS];
    else
        [settings.rotateMap set:ROTATE_MAP_NONE];

    [self backButtonClicked:nil];
}

- (void) selectDrivingRegion:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAMapViewTrackingUtilities *mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    if ([name isEqualToString:@"AUTOMATIC"])
    {
        settings.drivingRegionAutomatic = YES;
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

        settings.drivingRegionAutomatic = NO;;
        settings.drivingRegion = drivingRegion;
    }
    [self backButtonClicked:nil];
}

- (void) selectMetricSystem:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"sett_km"])
        [settings setMetricSystem:KILOMETERS_AND_METERS];
    else if ([name isEqualToString:@"sett_ml"])
        [settings setMetricSystem:MILES_AND_FEET];
    
    [self backButtonClicked:nil];
}

- (void) selectSettingGeoCode:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"sett_deg"])
        [settings setSettingGeoFormat:MAP_GEO_FORMAT_DEGREES];
    else if ([name isEqualToString:@"sett_deg_min"])
        [settings setSettingGeoFormat:MAP_GEO_FORMAT_MINUTES];

    [self backButtonClicked:nil];
}

- (void) selectSettingRecInterval:(NSInteger)index
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingSaveTrackIntervalGlobal:[settings.trackIntervalArray[index] intValue]];
    [self backButtonClicked:nil];
}

@end
