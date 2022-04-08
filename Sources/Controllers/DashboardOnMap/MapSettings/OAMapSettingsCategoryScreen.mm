//
//  OAMapSettingsCategoryScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsCategoryScreen.h"
#import "OAMapSettingsViewController.h"
#import "OATableViewCustomHeaderView.h"
#import "OASettingsTableViewCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAMapStyleSettings.h"

#define kContourLines @"contourLines"
#define kTempContourLines @"weatherTempContours"
#define kPressureContourLines @"weatherPressureContours"

typedef void(^OAMapSettingsCategoryCellDataOnSwitch)(BOOL is, NSIndexPath *indexPath);
typedef void(^OAMapSettingsCategoryCellDataOnSelect)();

@implementation OAMapSettingsCategoryScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    OAMapStyleSettings *_styleSettings;

    BOOL _isTransport;
    NSInteger _transportStopsSection;
    NSInteger _transportRoutesSection;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource, categoryName;

-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _styleSettings = [OAMapStyleSettings sharedInstance];

        categoryName = param;
        _isTransport = [categoryName isEqualToString:TRANSPORT_CATEGORY];

        settingsScreen = EMapSettingsScreenCategory;

        vwController = viewController;
        tblView = tableView;

        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{

    NSArray<OAMapStyleParameter *> *parameters;
    if ([categoryName isEqual:@"details"])
    {
        parameters = [[_styleSettings getParameters:categoryName] filteredArrayUsingPredicate:
                [NSPredicate predicateWithFormat:@"(_name != %@) AND (_name != %@) AND (_name != %@)",
                                kContourLines, kTempContourLines, kPressureContourLines]];
    }
    else
    {
        parameters = [_styleSettings getParameters:categoryName];
    }

    NSMutableArray *data = [NSMutableArray array];

    NSMutableDictionary *transportCell;
    if (_isTransport)
    {
        BOOL enabled = ![_styleSettings isCategoryDisabled:TRANSPORT_CATEGORY];
        transportCell = [NSMutableDictionary dictionary];
        transportCell[@"title"] = OALocalizedString(enabled ? @"shared_string_enabled" : @"rendering_value_disabled_name");
        transportCell[@"value"] = @(enabled);
        transportCell[@"icon"] = enabled ? @"ic_custom_show" : @"ic_custom_hide";
        transportCell[@"type"] = [OAIconTextDividerSwitchCell getCellIdentifier];
        transportCell[@"switch"] = ^(BOOL isOn, NSIndexPath *indexPath) {
            [_styleSettings setCategoryEnabled:isOn categoryName:TRANSPORT_CATEGORY];
            transportCell[@"title"] = OALocalizedString(isOn ? @"shared_string_enabled" : @"rendering_value_disabled_name");
            transportCell[@"value"] = @(isOn);
            transportCell[@"icon"] = isOn ? @"ic_custom_show" : @"ic_custom_hide";
            [self.tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        };
        [data addObject:@[transportCell]];
    }

    NSMutableArray *section = [NSMutableArray array];
    for (OAMapStyleParameter *parameter in parameters)
    {
        BOOL isBool = parameter.dataType == OABoolean;
        if (isBool)
        {
            NSMutableDictionary *cell = [NSMutableDictionary dictionary];
            cell[@"title"] = parameter.title;
            cell[@"value"] = @([parameter.storedValue isEqualToString:@"true"]);
            cell[@"type"] = [OAIconTextDividerSwitchCell getCellIdentifier];
            cell[@"switch"] = ^(BOOL isOn, NSIndexPath *indexPath) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    parameter.value = isOn ? @"true" : @"false";
                    [_styleSettings save:parameter];
                    cell[@"value"] = @(isOn);
                    [self.tblView reloadRowsAtIndexPaths:@[indexPath]
                                        withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            };

            if (_isTransport)
            {
                cell[@"icon"] = [self getTransportIconForName:parameter.name];
                cell[@"index"] = @([self getTransportSortIndexForName:parameter.name]);

                if ([parameter.name isEqualToString:@"transportStops"])
                {
                    _transportStopsSection = data.count;
                    [data addObject:@[cell]];
                    continue;
                }
            }

            [section addObject:cell];
        }
        else
        {
            [section addObject:@{
                    @"title": parameter.title,
                    @"description": [parameter getValueTitle],
                    @"type": [OASettingsTableViewCell getCellIdentifier],
                    @"select": ^() {
                        OAMapSettingsViewController *mapSettingsViewController =
                                [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter
                                                                                      param:parameter.name];
                        [mapSettingsViewController show:vwController.parentViewController
                                   parentViewController:vwController
                                               animated:YES];
                    }
            }];
        }
    }

    if (_isTransport)
        _transportRoutesSection = data.count;

    [data addObject:!_isTransport ? section : [section sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"index"] compare:obj2[@"index"]];
    }]];

    _data = data;
}

- (void) setupView
{
    if (_isTransport)
        [self.tblView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [tblView reloadData];
}

- (NSString *)getTransportIconForName:(NSString *)name
{
    if ([name isEqualToString:TRANSPORT_STOPS_ATTR])
        return @"mx_public_transport_stop_position";
    else if ([name isEqualToString:BUS_ROUTES_ATTR])
        return @"mx_highway_bus_stop";
    else if ([name isEqualToString:TROLLEYBUS_ROUTES_ATTR])
        return @"mx_route_trolleybus_ref";
    else if ([name isEqualToString:SUBWAY_MODE_ATTR])
        return @"mx_railway_station_subway_map";
    else if ([name isEqualToString:SHARE_TAXI_ROUTES_ATTR])
        return @"mx_route_share_taxi_ref";
    else if ([name isEqualToString:TRAM_ROUTES_ATTR])
        return @"mx_railway_tram_stop";
    else if ([name isEqualToString:TRAIN_ROUTES_ATTR])
        return @"mx_railway_station";
    else if ([name isEqualToString:LIGHT_RAIL_ROUTES_ATTR])
        return @"mx_route_light_rail_ref";
    else if ([name isEqualToString:FUNICULAR_ROUTES])
        return @"mx_funicular";
    else if ([name isEqualToString:MONORAIL_ROUTES_ATTR])
        return @"mx_route_monorail_ref";
    else
        return nil;
}

- (int)getTransportSortIndexForName:(NSString *)name
{
    if ([name isEqualToString:BUS_ROUTES_ATTR])
        return 1;
    else if ([name isEqualToString:TROLLEYBUS_ROUTES_ATTR])
        return 2;
    else if ([name isEqualToString:SUBWAY_MODE_ATTR])
        return 3;
    else if ([name isEqualToString:SHARE_TAXI_ROUTES_ATTR])
        return 4;
    else if ([name isEqualToString:TRAM_ROUTES_ATTR])
        return 5;
    else if ([name isEqualToString:TRAIN_ROUTES_ATTR])
        return 6;
    else if ([name isEqualToString:LIGHT_RAIL_ROUTES_ATTR])
        return 7;
    else if ([name isEqualToString:FUNICULAR_ROUTES])
        return 8;
    else if ([name isEqualToString:MONORAIL_ROUTES_ATTR])
        return 9;
    else
        return 0;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descriptionView setText:item[@"description"]];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., item[@"icon"] ? 65. : [OAUtilities getLeftMargin] + 16., 0., 0.);
        }
        if (cell)
        {
            BOOL isOn = [item[@"value"] boolValue];
            cell.dividerView.hidden = YES;

            [cell showIcon:_isTransport];
            NSString *iconName = item[@"icon"];
            if (iconName)
            {
                UIImage *icon;
                if ([iconName hasPrefix:@"mx_"])
                    icon = [[OAUtilities getMxIcon:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                else
                    icon = [UIImage templateImageNamed:item[@"icon"]];
                cell.iconView.image = icon;
                cell.iconView.tintColor = isOn ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
            }

            [cell.textView setText:item[@"title"]];
            [cell.switchView setOn:isOn];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if (item[@"select"])
        ((OAMapSettingsCategoryCellDataOnSelect) item[@"select"])();
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_isTransport && section == _transportStopsSection)
    {
        return 35;
    }
    else if (_isTransport && section == _transportRoutesSection)
    {
        return [OATableViewCustomHeaderView getHeight:OALocalizedString(@"transport_routes")
                                                width:tableView.bounds.size.width
                                              yOffset:32
                                                 font:[UIFont systemFontOfSize:13]];
    }
    else
    {
        return 0.01;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_isTransport && section == _transportRoutesSection)
    {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        customHeader.label.text = [OALocalizedString(@"transport_routes") upperCase];
        customHeader.label.font = [UIFont systemFontOfSize:13];
        [customHeader setYOffset:32];
        return customHeader;
    }

    return nil;
}

#pragma mark - Selectors

- (void) onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        if (item[@"switch"])
            ((OAMapSettingsCategoryCellDataOnSwitch) item[@"switch"])(switchView.isOn, indexPath);
    }
}

@end
