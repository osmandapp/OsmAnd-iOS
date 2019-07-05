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
#import "OATripRecordingSettingsViewController.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAApplicationMode.h"
#import "OAMapViewTrackingUtilities.h"
#import "SunriseSunset.h"
#import "OADayNightHelper.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"
#define kCellTypeSettings @"settings"
#define kFooterId @"TableViewSectionFooter"

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

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _settingsTableView;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    OAAppSettings* settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = settings.applicationMode;
    switch (self.settingsType)
    {
        case kSettingsScreenMain:
        {
            NSMutableArray *arr = [NSMutableArray arrayWithObjects:@{
                                                                     @"name" : @"general_settings",
                                                                     @"title" : OALocalizedString(@"general_settings_2"),
                                                                     @"description" : OALocalizedString(@"general_settings_descr"),
                                                                     @"img" : @"menu_cell_pointer.png",
                                                                     @"type" : kCellTypeCheck },
                                                                    @{
                                                                     @"name" : @"routing_settings",
                                                                     @"title" : OALocalizedString(@"routing_settings_2"),
                                                                     @"description" : OALocalizedString(@"routing_settings_descr"),
                                                                     @"img" : @"menu_cell_pointer.png",
                                                                     @"type" : kCellTypeCheck }, nil];
            BOOL shouldAddHeader = YES;
            if ([[OAIAPHelper sharedInstance].trackRecording isActive])
            {
                NSMutableDictionary *pluginsRow = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                @"name" : @"track_recording",
                                                                                                @"title" : OALocalizedString(@"product_title_track_recording"),
                                                                                                @"description" : @"",
                                                                                                @"img" : @"menu_cell_pointer.png",
                                                                                                @"type" : kCellTypeCheck
                                                                                                }];
                shouldAddHeader = NO;
                pluginsRow[@"header"] = OALocalizedString(@"plugins");
                [arr addObject:pluginsRow];
            }
            if ([[OAIAPHelper sharedInstance].osmEditing isActive])
            {
                NSMutableDictionary *pluginsRow = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                  @"name" : @"osm_editing",
                                                                                                  @"title" : OALocalizedString(@"product_title_osm_editing"),
                                                                                                  @"description" : @"",
                                                                                                  @"img" : @"menu_cell_pointer.png",
                                                                                                  @"type" : kCellTypeCheck,
                                                                                                  }];
                if (shouldAddHeader)
                    pluginsRow[@"header"] = OALocalizedString(@"plugins");
                
                shouldAddHeader = NO;
                [arr addObject:pluginsRow];
            }
            self.data = [NSArray arrayWithArray:arr];
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
            NSString* angularUnitsValue = [settings.angularUnits get] == DEGREES ? OALocalizedString(@"sett_deg") : OALocalizedString(@"shared_string_milliradians");
            NSNumber *doNotShowDiscountValue = @(settings.settingDoNotShowPromotions);
            NSNumber *doNotUseFirebaseValue = @(settings.settingDoNotUseFirebase);
            
            NSString* externalInputDeviceValue;
            if (settings.settingExternalInputDevice == GENERIC_EXTERNAL_DEVICE)
                externalInputDeviceValue = OALocalizedString(@"sett_generic_ext_input");
            else if (settings.settingExternalInputDevice == WUNDERLINQ_EXTERNAL_DEVICE)
                externalInputDeviceValue = OALocalizedString(@"sett_wunderlinq_ext_input");
            else
                externalInputDeviceValue = OALocalizedString(@"sett_no_ext_input");
            
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
                              @"name" : @"angular_units",
                              @"title" : OALocalizedString(@"angular_units"),
                              @"description" : OALocalizedString(@"angular_units_descr"),
                              @"value" : angularUnitsValue,
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
                              @"type" : kCellTypeSwitch },
                          @{
                              @"name" : @"sett_ext_input",
                              @"title" : OALocalizedString(@"sett_ext_input"),
                              @"description" : OALocalizedString(@"sett_ext_input_desc"),
                              @"value" : externalInputDeviceValue,
                              @"img" : @"menu_cell_pointer.png",
                              @"type" : kCellTypeSingleSelectionList }
                          ];
            
            SunriseSunset *sunriseSunset = [[OADayNightHelper instance] getSunriseSunset];
            if (sunriseSunset)
            {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateStyle:NSDateFormatterNoStyle];
                [formatter setTimeStyle:NSDateFormatterShortStyle];
                
                self.data = [self.data arrayByAddingObject:
                             @{
                               @"name" : @"day_night_info",
                               @"title" : [NSString stringWithFormat:OALocalizedString(@"day_night_info_description"), [formatter stringFromDate:[sunriseSunset getSunrise]], [formatter stringFromDate:[sunriseSunset getSunset]]],
                               @"description" : OALocalizedString(@"day_night_info"),
                               @"value" : @"",
                               @"nonclickable" : @"true",
                               @"type" : kCellTypeCheck }
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
            _titleView.text = OALocalizedString(@"coords_format");
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
            if (!location)
                location = mapPanel.mapViewController.getMapLocation;
            double lat = location.coordinate.latitude;
            double lon = location.coordinate.longitude;
            self.data = @[
                          @{
                              @"name" : @"navigate_point_format_D",
                              @"title" : OALocalizedString(@"navigate_point_format_D"),
                              @"value" : @"",
                              @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_DEGREES]],
                              @"img" : settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"navigate_point_format_DM",
                              @"title" : OALocalizedString(@"navigate_point_format_DM"),
                              @"value" : @"",
                              @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_MINUTES]],
                              @"img" : settings.settingGeoFormat == MAP_GEO_FORMAT_MINUTES ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"navigate_point_format_DMS",
                              @"title" : OALocalizedString(@"navigate_point_format_DMS"),
                              @"value" : @"",
                              @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert formatLocationCoordinates:lat lon:lon format:FORMAT_SECONDS]],
                              @"img" : settings.settingGeoFormat == MAP_GEO_FORMAT_SECONDS ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"utm_format",
                              @"title" : @"UTM",
                              @"url" : @"https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system",
                              @"description" : [NSString stringWithFormat:@"%@: %@\n%@", OALocalizedString(@"coordinates_example"), [OALocationConvert getUTMCoordinateString:lat lon:lon], OALocalizedString(@"utm_description")],
                              @"img" : settings.settingGeoFormat == MAP_GEO_UTM_FORMAT ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"olc_format",
                              @"title" : OALocalizedString(@"navigate_point_format_OLC"),
                              @"url" : @"https://en.wikipedia.org/wiki/Open_Location_Code",
                              @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OALocationConvert getLocationOlcName:lat lon:lon]],
                              @"img" : settings.settingGeoFormat == MAP_GEO_OLC_FORMAT ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck }
                          ];
            break;
        }
        case kSettingsScreenAngularUnits:
        {
            EOAAngularConstant angularUnits = [settings.angularUnits get];
            _titleView.text = OALocalizedString(@"angular_units");
            self.data = @[
                          @{
                              @"name" : @"degrees",
                              @"title" : OALocalizedString(@"sett_deg"),
                              @"value" : @"",
                              @"img" : angularUnits == DEGREES ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"milliradians",
                              @"title" : OALocalizedString(@"shared_string_milliradians"),
                              @"value" : @"",
                              @"img" : angularUnits == MILLIRADS ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          ];
            break;
        }
        case kSettingsScreenExternalInput:
        {
            _titleView.text = OALocalizedString(@"sett_ext_input");
            self.data = @[
                          @{
                              @"name" : @"sett_no_ext_input",
                              @"title" : OALocalizedString(@"sett_no_ext_input"),
                              @"value" : @"",
                              @"img" : settings.settingExternalInputDevice == NO_EXTERNAL_DEVICE ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"sett_generic_ext_input",
                              @"title" : OALocalizedString(@"sett_generic_ext_input"),
                              @"value" : @"",
                              @"img" : settings.settingExternalInputDevice == GENERIC_EXTERNAL_DEVICE ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          @{
                              @"name" : @"sett_wunderlinq_ext_input",
                              @"title" : OALocalizedString(@"sett_wunderlinq_ext_input"),
                              @"value" : @"",
                              @"img" : settings.settingExternalInputDevice == WUNDERLINQ_EXTERNAL_DEVICE ? @"menu_cell_selected.png" : @"",
                              @"type" : kCellTypeCheck },
                          ];
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
    [self.settingsTableView setSeparatorInset:UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0)];
    [self.settingsTableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
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
            OAAppSettings *settings = [OAAppSettings sharedManager];
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([name isEqualToString:@"do_not_show_discount"])
                [settings setSettingDoNotShowPromotions:isChecked];
            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
                [settings setSettingDoNotUseFirebase:isChecked];
        }
    }
}

- (BOOL) sectionsOnly
{
    return _settingsType == kSettingsScreenMain || _settingsType == kSettingsScreenGeneral || _settingsType == kSettingsScreenDrivingRegion || _settingsType == kSettingsScreenGeoCoords;
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
            if (item[@"img"])
                [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            else
                [cell.iconView setImage:nil];
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
            if (item[@"img"])
                [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            else
                [cell.iconView setImage:nil];
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
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeSettings])
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        NSString *text = item[@"description"];
        OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];
        NSString *url = item[@"url"];
        if (url)
        {
            NSURL *URL = [NSURL URLWithString:url];
            UIFont *textFont = [UIFont systemFontOfSize:13];
            NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"shared_string_read_more") attributes:@{NSFontAttributeName : textFont}];
            [str addAttribute:NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
            text = [text stringByAppendingString:@" "];
            NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                        attributes:@{NSFontAttributeName : textFont,
                                                                                                     NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
            [textStr appendAttributedString:str];
            vw.label.attributedText = textStr;
        }
        else
        {
            vw.label.text = text;
        }
        return vw;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        NSString *text = item[@"description"];
        NSString *url = item[@"url"];
        return [OATableViewCustomFooterView getHeight:url ? [NSString stringWithFormat:@"%@ %@", text, OALocalizedString(@"shared_string_read_more")] : text width:tableView.bounds.size.width];
    }
    else
    {
        return 0.01;
    }
}

#pragma mark - UITableViewDelegate

- (nullable NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL nonClickable = item[@"nonclickable"] != nil;
    return nonClickable ? nil : indexPath;
}

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
            case kSettingsScreenAngularUnits:
                [self selectSettingAngularUnits:name];
                break;
            case kSettingsScreenExternalInput:
                [self selectSettingExternalInput:name];
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
    else if ([name isEqualToString:@"track_recording"])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenGeneral];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"osm_editing"])
    {
        OAOsmEditingSettingsViewController* settingsViewController = [[OAOsmEditingSettingsViewController alloc] init];
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
    else if ([name isEqualToString:@"angular_units"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenAngularUnits];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"sett_ext_input"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenExternalInput];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"do_not_show_discount"])
    {
    }
    else if ([name isEqualToString:@"do_not_send_anonymous_data"])
    {
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
    
    settings.metricSystemChangedManually = YES;
    
    [self backButtonClicked:nil];
}

- (void) selectSettingGeoCode:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"navigate_point_format_D"])
        [settings setSettingGeoFormat:MAP_GEO_FORMAT_DEGREES];
    else if ([name isEqualToString:@"navigate_point_format_DM"])
        [settings setSettingGeoFormat:MAP_GEO_FORMAT_MINUTES];
    else if ([name isEqualToString:@"navigate_point_format_DMS"])
        [settings setSettingGeoFormat:MAP_GEO_FORMAT_SECONDS];
    else if ([name isEqualToString:@"utm_format"])
        [settings setSettingGeoFormat:MAP_GEO_UTM_FORMAT];
    else if ([name isEqualToString:@"olc_format"])
        [settings setSettingGeoFormat:MAP_GEO_OLC_FORMAT];

    [self backButtonClicked:nil];
}

- (void) selectSettingAngularUnits:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"degrees"])
        [settings.angularUnits set:DEGREES];
    else if ([name isEqualToString:@"milliradians"])
        [settings.angularUnits set:MILLIRADS];
    else
        [settings.angularUnits set:DEGREES];
    
    [self backButtonClicked:nil];
}

- (void) selectSettingExternalInput:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"sett_no_ext_input"])
        [settings setSettingExternalInputDevice:NO_EXTERNAL_DEVICE];
    else if ([name isEqualToString:@"sett_generic_ext_input"])
        [settings setSettingExternalInputDevice:GENERIC_EXTERNAL_DEVICE];
    else if ([name isEqualToString:@"sett_wunderlinq_ext_input"])
        [settings setSettingExternalInputDevice:WUNDERLINQ_EXTERNAL_DEVICE];
    
    [self backButtonClicked:nil];
}

@end
