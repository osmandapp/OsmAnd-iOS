//
//  OAMapSettingsWeatherScreen.m
//  OsmAnd Maps
//
//  Created by Alexey on 31.01.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAMapSettingsWeatherScreen.h"
#import "OAMapSettingsViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OAColors.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

#define kLayersSection 1
#define kContoursSection 2
#define kLayersHeaderHeight 56.

#define kWeather @"weather"
#define kWeatherContourLines @"weather_contour_lines"

#define kTempContourLines @"weatherTempContours"
#define kPressureContourLines @"weatherPressureContours"

@implementation OAMapSettingsWeatherScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapStyleSettings *_styleSettings;
    
    NSArray *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _styleSettings = [OAMapStyleSettings sharedInstance];
        
        title = OALocalizedString(@"product_title_weather");
        settingsScreen = EMapSettingsScreenWeather;
        
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

- (void) setupView
{
    BOOL enabled = _app.data.weather;
    NSArray* mainSwitch = @[@{
        @"type" : [OASettingSwitchCell getCellIdentifier],
        @"name"  : kWeather,
        @"value" : @(enabled)
    }];

    NSArray *weatherLayers = @[
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherTemp,
            @"title" : OALocalizedString(@"map_settings_weather_temp"),
            @"value" : @(_app.data.weatherTemp),
            @"image" : @"ic_custom_thermometer"
        },
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherPressure,
            @"title" : OALocalizedString(@"map_settings_weather_pressure"),
            @"value" : @(_app.data.weatherPressure),
            @"image" : @"ic_custom_air_pressure"
        },
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherWind,
            @"title" : OALocalizedString(@"map_settings_weather_wind"),
            @"value" : @(_app.data.weatherWind),
            @"image" : @"ic_custom_wind"
        },
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherCloud,
            @"title" : OALocalizedString(@"map_settings_weather_cloud"),
            @"value" : @(_app.data.weatherCloud),
            @"image" : @"ic_custom_clouds"
        },
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherPrecip,
            @"title" : OALocalizedString(@"map_settings_weather_precip"),
            @"value" : @(_app.data.weatherPrecip),
            @"image" : @"ic_custom_precipitation"
        }];

    NSString *selectedContourLinesName = OALocalizedString(@"shared_string_none");
    OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
    OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
    if ([tempContourLinesParam.value isEqualToString:@"true"])
        selectedContourLinesName = OALocalizedString(@"map_settings_weather_temp");
    else if ([pressureContourLinesParam.value isEqualToString:@"true"])
        selectedContourLinesName = OALocalizedString(@"map_settings_weather_pressure");

    NSArray *contourLines = @[
        @{
            @"type"  : [OAIconTitleValueCell getCellIdentifier],
            @"name"  : kWeatherContourLines,
            @"title" : OALocalizedString(@"map_settings_weather_isolines"),
            @"value" : selectedContourLinesName,
            @"image" : @"ic_custom_contour_lines"
        }];
    
    NSMutableArray *data = [NSMutableArray array];

    [data addObject:mainSwitch];
    if (enabled)
    {
        [data addObject:weatherLayers];
        [data addObject:contourLines];
    }

    _data = data;
    
    tblView.estimatedRowHeight = kEstimatedRowHeight;
    tblView.rowHeight = UITableViewAutomaticDimension;
}

-(void) initData
{
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data[section] count];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kLayersSection)
        return OALocalizedString(@"map_settings_weather_layers");
    return @"";
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kContoursSection)
        return OALocalizedString(@"weather_cloud_data_description");
    return @"";
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
    header.textLabel.font = [UIFont systemFontOfSize:13.];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            BOOL enabled = [item[@"value"] boolValue];
            cell.textView.text = enabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = enabled ? @"ic_custom_umbrella.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = enabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:enabled];
            [cell.switchView addTarget:self action:@selector(turnWeatherOnOff:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            NSString *valueText;
            BOOL iconEnabled;
            if ([item[@"name"] isEqualToString:kWeatherContourLines])
            {
                valueText = item[@"value"];
                iconEnabled = ![valueText isEqualToString:OALocalizedString(@"shared_string_none")];
            }
            else
            {
                BOOL isOn = [item[@"value"] boolValue];
                valueText = isOn ? OALocalizedString(@"shared_string_on") : OALocalizedString(@"shared_string_off");
                iconEnabled = isOn;
            }
            cell.descriptionView.text = valueText;
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.leftIconView.tintColor = iconEnabled ? UIColorFromRGB(nav_bar_day) : UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"name"] isEqualToString:kWeather])
        return nil;

    return indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
    [tblView deselectRowAtIndexPath:indexPath animated:NO];
}

- (EOAWeatherLayerType)getWeatherLayerType:(NSString *)type
{
    if ([type isEqualToString:kWeatherTemp])
        return EOAWeatherLayerTypeTemperature;
    else if ([type isEqualToString:kWeatherPressure])
        return EOAWeatherLayerTypePresssure;
    else if ([type isEqualToString:kWeatherWind])
        return EOAWeatherLayerTypeWind;
    else if ([type isEqualToString:kWeatherCloud])
        return EOAWeatherLayerTypeCloud;
    else if ([type isEqualToString:kWeatherPrecip])
        return EOAWeatherLayerTypePrecipitation;
    else
        return EOAWeatherLayerTypeContours;
}

- (void) onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
//    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
//    {
        [vwController hide:YES animated:YES];
        OAWeatherLayerSettingsViewController *vc = [[OAWeatherLayerSettingsViewController alloc] initWithLayerType:[self getWeatherLayerType:item[@"name"]]];
        [OARootViewController.instance.mapPanel showScrollableHudViewController:vc];
//    }
}

- (void) turnWeatherOnOff:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        [(OAWeatherPlugin *) [OAPlugin getPlugin:OAWeatherPlugin.class] weatherChanged:switchView.isOn];
        if (switchView.isOn)
        {
            [tblView beginUpdates];
            [self setupView];
            [tblView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
        else
        {
            [tblView beginUpdates];
            [tblView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [self setupView];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.0;
    else if (section == kLayersSection)
        return kLayersHeaderHeight;
    else
        return 36.0;
}

@end
