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
#import "OAMapPanelViewController.h"
#import "OAMapStyleSettings.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAWeatherPlugin.h"
#import "OAMapHudViewController.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OAAppData.h"

#define kLayersSection 1
#define kContoursSection 2
#define kLayersHeaderHeight 56.

#define kWeather @"weather"
#define kWeatherContourLines @"weather_contour_lines"

@interface OAMapSettingsWeatherScreen () <OAWeatherLayerSettingsDelegate>

@end

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
        
        title = OALocalizedString(@"shared_string_weather");
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
        @"type" : [OASwitchTableViewCell getCellIdentifier],
        @"name"  : kWeather,
        @"value" : @(enabled)
    }];

    NSArray *weatherLayers = @[
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherTemp,
            @"title" : OALocalizedString(@"map_settings_weather_temp"),
            @"value" : @(_app.data.weatherTemp),
            @"image" : @"ic_custom_thermometer"
        },
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherPressure,
            @"title" : OALocalizedString(@"map_settings_weather_pressure"),
            @"value" : @(_app.data.weatherPressure),
            @"image" : @"ic_custom_air_pressure"
        },
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherWind,
            @"title" : OALocalizedString(@"map_settings_weather_wind"),
            @"value" : @(_app.data.weatherWind),
            @"image" : @"ic_custom_wind"
        },
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherCloud,
            @"title" : OALocalizedString(@"map_settings_weather_cloud"),
            @"value" : @(_app.data.weatherCloud),
            @"image" : @"ic_custom_clouds"
        },
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherPrecip,
            @"title" : OALocalizedString(@"map_settings_weather_precip"),
            @"value" : @(_app.data.weatherPrecip),
            @"image" : @"ic_custom_precipitation"
        },
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherWindAnimation,
            @"title" : OALocalizedString(@"map_settings_weather_wind_animation"),
            @"value" : @(_app.data.weatherWindAnimation),
            @"image" : @"ic_custom_wind"
        }];

    NSString *selectedContourLinesName = OALocalizedString(@"shared_string_none");
    NSString *contourName = _app.data.contourName;
    BOOL isEnabled = [_styleSettings isAnyWeatherContourLinesEnabled] || contourName.length > 0;
    if (isEnabled)
    {
        if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_TEMP_CONTOUR_LINES_ATTR] || [contourName isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
            selectedContourLinesName = OALocalizedString(@"map_settings_weather_temp");
        else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRESSURE_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
            selectedContourLinesName = OALocalizedString(@"map_settings_weather_pressure");
        else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_CLOUD_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
            selectedContourLinesName = OALocalizedString(@"map_settings_weather_cloud");
        else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_WIND_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
            selectedContourLinesName = OALocalizedString(@"map_settings_weather_wind");
        else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
            selectedContourLinesName = OALocalizedString(@"map_settings_weather_precip");
    }

    NSArray *contourLines = @[
        @{
            @"type"  : [OAValueTableViewCell getCellIdentifier],
            @"name"  : kWeatherContourLines,
            @"title" : OALocalizedString(@"shared_string_contours"),
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
        return OALocalizedString(@"shared_string_layers");
    return @"";
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
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
    [header.textLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
    header.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL enabled = [item[@"value"] boolValue];
            cell.titleLabel.text = enabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");

            NSString *imgName = enabled ? @"ic_custom_umbrella.png" : @"ic_custom_hide.png";
            cell.leftIconView.image = [UIImage templateImageNamed:imgName];
            cell.leftIconView.tintColor = enabled ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:enabled];
            [cell.switchView addTarget:self action:@selector(turnWeatherOnOff:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
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
            cell.valueLabel.text = valueText;
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.leftIconView.tintColor = iconEnabled ? [UIColor colorNamed:ACColorNameIconColorSelected]: [UIColor colorNamed:ACColorNameIconColorDisabled];
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
    else if ([type isEqualToString:kWeatherWindAnimation])
        return EOAWeatherLayerTypeWindAnimation;
    else
        return EOAWeatherLayerTypeContours;
}

- (void) onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    [vwController hide:YES animated:YES];
    OAWeatherLayerSettingsViewController *vc = [[OAWeatherLayerSettingsViewController alloc] initWithLayerType:[self getWeatherLayerType:item[@"name"]]];
    vc.delegate = self;
    [OARootViewController.instance.mapPanel showScrollableHudViewController:vc];
}

- (void) turnWeatherOnOff:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        [(OAWeatherPlugin *) [OAPluginsHelper getPlugin:OAWeatherPlugin.class] weatherChanged:switchView.isOn];
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

#pragma mark - OAWeatherLayerSettingsDelegate

- (void)onDoneWeatherLayerSettings:(BOOL)show
{
    if (show)
        [[OARootViewController instance].mapPanel showWeatherLayersScreen];
}

@end
