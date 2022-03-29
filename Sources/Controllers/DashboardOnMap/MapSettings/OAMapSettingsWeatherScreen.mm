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
#import "OASwitchTableViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAMapStyleSettings.h"
#import "OASettingSwitchCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OAIconTextDescButtonCell.h"
#import "OAButtonCell.h"
#import "OAColors.h"
#import "OALocalResourceInformationViewController.h"
#import "OAOnlineTilesEditingViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAResourcesUIHelper.h"
#import "OADateTimePickerTableViewCell.h"
#import "OAMapStyleSettings.h"
#import "OAMapLayers.h"
#import "OACustomPickerTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

#define kWeather @"weather"
#define kWeatherTemp @"weather_temp"
#define kWeatherTempAlpha @"weather_temp_alpha"
#define kWeatherTempUnit @"weather_temp_unit"
#define kWeatherPressure @"weather_pressure"
#define kWeatherPressureAlpha @"weather_pressure_alpha"
#define kWeatherPressureUnit @"weather_pressure_unit"
#define kWeatherWind @"weather_wind"
#define kWeatherWindAlpha @"weather_wind_alpha"
#define kWeatherWindUnit @"weather_wind_unit"
#define kWeatherCloud @"weather_cloud"
#define kWeatherCloudAlpha @"weather_cloud_alpha"
#define kWeatherCloudUnit @"weather_cloud_unit"
#define kWeatherPrecip @"weather_precip"
#define kWeatherPrecipAlpha @"weather_precip_alpha"
#define kWeatherPrecipUnit @"weather_precip_unit"

#define kWeatherAlphas @"weather_alphas"
#define kWeatherContourLines @"weather_contour_lines"
#define kWeatherTempUnits @"weather_temp_units"
#define kWeatherPressureUnits @"weather_pressure_units"
#define kWeatherWindUnits @"weather_wind_units"
#define kWeatherCloudUnits @"weather_cloud_units"
#define kWeatherPrecipUnits @"weather_precip_units"

#define kClearGeoCacheButton @"clear_geo_cache_button"
#define kClearRasterCacheButton @"clear_reaster1_cache_button"

#define kCellTypeTitleSlider @"title_slider_cell"
#define kCellTypeSwitch @"switch_cell"
#define kCellTypeValue @"valueCell"
#define kCellTypeButton @"button_cell"
#define kCellTypeIconSwitch @"icon_switch_cell"
#define kCellTypeMap @"icon_text_desc_button_cell"
#define kCellTypeDateTimePicker @"date_time_picker_cell"
#define kCellTypeValuePicker @"value_picker_cell"

#define kContourLines @"contourLines"
#define kTempContourLines @"weatherTempContours"
#define kPressureContourLines @"weatherPressureContours"

#define kContourLinesTag 1000
#define kWeatherTempUnitTag 1001
#define kWeatherPressureUnitTag 1002
#define kWeatherWindUnitTag 1003
#define kWeatherCloudUnitTag 1004
#define kWeatherPrecipUnitTag 1005

@interface OAMapSettingsWeatherScreen() <OACustomPickerTableViewCellDelegate>

@end

@implementation OAMapSettingsWeatherScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapStyleSettings *_styleSettings;
    
    NSArray *_data;

    BOOL _showTempUnits;
    BOOL _showPressureUnits;
    BOOL _showWindUnits;
    BOOL _showCloudUnits;
    BOOL _showPrecipUnits;
    NSInteger _tempUnitsRowIndex;
    NSInteger _pressureUnitsRowIndex;
    NSInteger _windUnitsRowIndex;
    NSInteger _cloudUnitsRowIndex;
    NSInteger _precipUnitsRowIndex;
    NSInteger _unitsSectionIndex;
    BOOL _showAlphas;
    NSInteger _alphasSectionIndex;
    BOOL _showContourLinesPicker;
    NSArray<NSString *> *_countourLinesPickerValues;
    NSInteger _countourLinesSectionIndex;
    NSInteger _buttonsSectionIndex;
    NSInteger _clearGeoCacheButtonIndex;
    NSInteger _clearRasterCacheButtonIndex;

    unsigned long long _geoDbSize;
    unsigned long long _rasterDbSize;
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
        
        title = OALocalizedString(@"map_settings_weather");
        settingsScreen = EMapSettingsScreenWeather;
        
        vwController = viewController;
        tblView = tableView;
        
        _showTempUnits = NO;
        _showPressureUnits = NO;
        _showWindUnits = NO;
        _showCloudUnits = NO;
        _showPrecipUnits = NO;
        _tempUnitsRowIndex = -1;
        _pressureUnitsRowIndex = -1;
        _windUnitsRowIndex = -1;
        _cloudUnitsRowIndex = -1;
        _precipUnitsRowIndex = -1;
        _unitsSectionIndex = -1;
        
        _showAlphas = NO;
        _alphasSectionIndex = -1;

        _showContourLinesPicker = NO;
        _countourLinesPickerValues = @[OALocalizedString(@"shared_string_none"),
                                       OALocalizedString(@"map_settings_weather_temp"),
                                       OALocalizedString(@"map_settings_weather_pressure")];

        _countourLinesSectionIndex = -1;
        _buttonsSectionIndex = -1;
        _clearGeoCacheButtonIndex = -1;
        _clearRasterCacheButtonIndex = -1;

        [self commonInit];
        [self initData];

        [self calculateCacheSize];
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

- (void) calculateCacheSize
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        unsigned long long geoDbSize = 0;
        unsigned long long rasterDbSize = 0;
        NSArray *cacheFilePaths = [fm contentsOfDirectoryAtPath:_app.cachePath error:nil];
        for (NSString *filePath in cacheFilePaths)
        {
            if ([filePath hasSuffix:@".raster.db"]) {
                rasterDbSize += [[fm attributesOfItemAtPath:[_app.cachePath stringByAppendingPathComponent:filePath] error:nil] fileSize];
            }
            if ([filePath hasSuffix:@".tiff.db"]) {
                geoDbSize += [[fm attributesOfItemAtPath:[_app.cachePath stringByAppendingPathComponent:filePath] error:nil] fileSize];
            }
        }
        _geoDbSize = geoDbSize;
        _rasterDbSize = rasterDbSize;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tblView beginUpdates];
            [self setupView];
            if (_buttonsSectionIndex != -1 && _clearGeoCacheButtonIndex != -1 && _clearRasterCacheButtonIndex != -1)
            {
                [tblView reloadRowsAtIndexPaths:@[
                    [NSIndexPath indexPathForRow:_clearGeoCacheButtonIndex inSection:_buttonsSectionIndex],
                    [NSIndexPath indexPathForRow:_clearRasterCacheButtonIndex inSection:_buttonsSectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
            }
            [tblView endUpdates];
        });
    });
}

- (void) setupView
{
    BOOL enabled = _app.data.weather;
    NSArray* mainSwitch = @[@{
        @"type" : kCellTypeIconSwitch,
        @"name"  : kWeather,
        @"value" : @(enabled)
    }];

    NSArray* datePicker = @[@{
        @"type" : kCellTypeDateTimePicker,
    }];
    
    NSArray *weatherLayerAlphas = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherAlphas,
            @"title" : @"Layers transparency",
            @"value" : _showAlphas ? @"Hide" : @"Show"
        }];
    
    if (_showAlphas)
    {
        weatherLayerAlphas = [weatherLayerAlphas arrayByAddingObjectsFromArray:@[
            @{
                @"type"  : kCellTypeTitleSlider,
                @"name"  : kWeatherTempAlpha,
                @"title" : OALocalizedString(@"map_settings_weather_temp"),
                @"value" : @(_app.data.weatherTempAlpha)
            },
            @{
                @"type"  : kCellTypeTitleSlider,
                @"name"  : kWeatherPressureAlpha,
                @"title" : OALocalizedString(@"map_settings_weather_pressure"),
                @"value" : @(_app.data.weatherPressureAlpha)
            },
            @{
                @"type"  : kCellTypeTitleSlider,
                @"name"  : kWeatherWindAlpha,
                @"title" : OALocalizedString(@"map_settings_weather_wind"),
                @"value" : @(_app.data.weatherWindAlpha)
            },
            @{
                @"type"  : kCellTypeTitleSlider,
                @"name"  : kWeatherCloudAlpha,
                @"title" : OALocalizedString(@"map_settings_weather_cloud"),
                @"value" : @(_app.data.weatherCloudAlpha)
            },
            @{
                @"type"  : kCellTypeTitleSlider,
                @"name"  : kWeatherPrecipAlpha,
                @"title" : OALocalizedString(@"map_settings_weather_precip"),
                @"value" : @(_app.data.weatherPrecipAlpha)
            }]
        ];
    }
    
    NSArray *weatherLayers = @[
        @{
            @"type"  : kCellTypeSwitch,
            @"name"  : kWeatherTemp,
            @"title" : OALocalizedString(@"map_settings_weather_temp"),
            @"value" : @(_app.data.weatherTemp)
        },
        @{
            @"type"  : kCellTypeSwitch,
            @"name"  : kWeatherPressure,
            @"title" : OALocalizedString(@"map_settings_weather_pressure"),
            @"value" : @(_app.data.weatherPressure)
        },
        @{
            @"type"  : kCellTypeSwitch,
            @"name"  : kWeatherWind,
            @"title" : OALocalizedString(@"map_settings_weather_wind"),
            @"value" : @(_app.data.weatherWind)
        },
        @{
            @"type"  : kCellTypeSwitch,
            @"name"  : kWeatherCloud,
            @"title" : OALocalizedString(@"map_settings_weather_cloud"),
            @"value" : @(_app.data.weatherCloud)
        },
        @{
            @"type"  : kCellTypeSwitch,
            @"name"  : kWeatherPrecip,
            @"title" : OALocalizedString(@"map_settings_weather_precip"),
            @"value" : @(_app.data.weatherPrecip)
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
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherContourLines,
            @"title" : OALocalizedString(@"map_settings_weather_isolines"),
            @"value" : selectedContourLinesName
        }];
    
    if (_showContourLinesPicker)
    {
        contourLines = [contourLines arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kContourLines,
                @"tag" : @(kContourLinesTag),
                @"value" : _countourLinesPickerValues
            }];
    }
    
    NSArray *buttons = @[
        @{
            @"type"  : kCellTypeButton,
            @"name"  : kClearGeoCacheButton,
            @"title" : [NSString stringWithFormat:@"%@ - %@",
                        OALocalizedString(@"map_settings_clear_geo_cache"),
                        [NSByteCountFormatter stringFromByteCount:_geoDbSize countStyle:NSByteCountFormatterCountStyleFile]],
        },
        @{
            @"type" : kCellTypeButton,
            @"name" : kClearRasterCacheButton,
            @"title" : [NSString stringWithFormat:@"%@ - %@",
                        OALocalizedString(@"map_settings_clear_raster_cache"),
                        [NSByteCountFormatter stringFromByteCount:_rasterDbSize countStyle:NSByteCountFormatterCountStyleFile]],
        }];
    
    OAWeatherBand *tempBand = [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE];
    OAWeatherBand *pressureBand = [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE];
    OAWeatherBand *windBand = [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED];
    OAWeatherBand *cloudBand = [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD];
    OAWeatherBand *precipBand = [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION];

    NSArray *weatherTempUnits = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherTempUnits,
            @"title" : OALocalizedString(@"map_settings_weather_temp"),
            @"value" : [tempBand getBandUnit]
        }];
    if (_showTempUnits)
    {
        weatherTempUnits = [weatherTempUnits arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kWeatherTempUnit,
                @"tag" : @(kWeatherTempUnitTag),
                @"value" : [tempBand getAvailableBandUnits],
                @"selected" : [tempBand getBandUnit]
            }];
    }
    NSArray *weatherPressureUnits = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherPressureUnits,
            @"title" : OALocalizedString(@"map_settings_weather_pressure"),
            @"value" : [pressureBand getBandUnit],
        }];
    if (_showPressureUnits)
    {
        weatherPressureUnits = [weatherPressureUnits arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kWeatherPressureUnit,
                @"tag" : @(kWeatherPressureUnitTag),
                @"value" : [pressureBand getAvailableBandUnits],
                @"selected" : [pressureBand getBandUnit]
            }];
    }
    NSArray *weatherWindUnits = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherWindUnits,
            @"title" : OALocalizedString(@"map_settings_weather_wind"),
            @"value" : [windBand getBandUnit]
        }];
    if (_showWindUnits)
    {
        weatherWindUnits = [weatherWindUnits arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kWeatherWindUnit,
                @"tag" : @(kWeatherWindUnitTag),
                @"value" : [windBand getAvailableBandUnits],
                @"selected" : [windBand getBandUnit]
            }];
    }
    NSArray *weatherCloudUnits = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherCloudUnits,
            @"title" : OALocalizedString(@"map_settings_weather_cloud"),
            @"value" : [cloudBand getBandUnit]
        }];
    if (_showCloudUnits)
    {
        weatherCloudUnits = [weatherCloudUnits arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kWeatherCloudUnit,
                @"tag" : @(kWeatherCloudUnitTag),
                @"value" : [cloudBand getAvailableBandUnits],
                @"selected" : [cloudBand getBandUnit]
            }];
    }
    NSArray *weatherPrecipUnits = @[
        @{
            @"type"  : kCellTypeValue,
            @"name"  : kWeatherPrecipUnits,
            @"title" : OALocalizedString(@"map_settings_weather_precip"),
            @"value" : [precipBand getBandUnit]
        }];
    if (_showPrecipUnits)
    {
        weatherPrecipUnits = [weatherPrecipUnits arrayByAddingObject:
            @{
                @"type" : kCellTypeValuePicker,
                @"name" : kWeatherPrecipUnit,
                @"tag" : @(kWeatherPrecipUnitTag),
                @"value" : [precipBand getAvailableBandUnits],
                @"selected" : [precipBand getBandUnit]
            }];
    }
    
    NSMutableArray *data = [NSMutableArray array];
    _alphasSectionIndex = -1;
    _countourLinesSectionIndex = -1;
    _tempUnitsRowIndex = -1;
    _pressureUnitsRowIndex = -1;
    _windUnitsRowIndex = -1;
    _cloudUnitsRowIndex = -1;
    _precipUnitsRowIndex = -1;
    _unitsSectionIndex = -1;
    _buttonsSectionIndex = -1;
    _clearGeoCacheButtonIndex = -1;
    _clearRasterCacheButtonIndex = -1;

    [data addObject:mainSwitch];
    if (enabled)
    {
        [data addObject:datePicker];
        [data addObject:weatherLayerAlphas];
        _alphasSectionIndex = data.count - 1;
        [data addObject:weatherLayers];
        [data addObject:contourLines];
        _countourLinesSectionIndex = data.count - 1;
        
        NSMutableArray *unitsArr = [NSMutableArray array];
        _tempUnitsRowIndex = unitsArr.count;
        [unitsArr addObjectsFromArray:weatherTempUnits];
        _pressureUnitsRowIndex = unitsArr.count;
        [unitsArr addObjectsFromArray:weatherPressureUnits];
        _windUnitsRowIndex = unitsArr.count;
        [unitsArr addObjectsFromArray:weatherWindUnits];
        _cloudUnitsRowIndex = unitsArr.count;
        [unitsArr addObjectsFromArray:weatherCloudUnits];
        _precipUnitsRowIndex = unitsArr.count;
        [unitsArr addObjectsFromArray:weatherPrecipUnits];

        [data addObject:unitsArr];
        _unitsSectionIndex = data.count - 1;
        
        [data addObject:buttons];
        for (int i = 0; i < buttons.count; i++)
        {
            NSDictionary *item = buttons[i];
            if ([item[@"name"] isEqualToString:kClearGeoCacheButton])
                _clearGeoCacheButtonIndex = i;
            else if ([item[@"name"] isEqualToString:kClearRasterCacheButton])
                _clearRasterCacheButtonIndex = i;
        }
        _buttonsSectionIndex = data.count - 1;
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
    return @"";
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kCellTypeDateTimePicker])
    {
        OADateTimePickerTableViewCell* cell;
        cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OADateTimePickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADateTimePickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];

            NSDate *currentDate = [NSDate date];
            cell.dateTimePicker.minimumDate = [currentDate dateByAddingTimeInterval:(NSTimeInterval)(-60 * 60 * 32)];
            cell.dateTimePicker.maximumDate = [currentDate dateByAddingTimeInterval:(NSTimeInterval)(60 * 60 * 32)];;
            cell.dateTimePicker.minuteInterval = 30;
            cell.dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
        }
        cell.dateTimePicker.date = OARootViewController.instance.mapPanel.mapViewController.mapLayers.weatherDate;
        [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.dateTimePicker addTarget:self action:@selector(dateTimePickerChanged:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeIconSwitch])
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
            NSString *imgName = enabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = enabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:enabled];
            [cell.switchView addTarget:self action:@selector(turnWeatherOnOff:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSwitch])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onWeatherLayerSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeTitleSlider])
    {
        OATitleSliderTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.sliderView.value = [item[@"value"] doubleValue];
            cell.valueLabel.textColor = UIColorFromRGB(color_text_footer);
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.sliderView addTarget:self action:@selector(onWeatherLayerAlphaChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.lbTime.textColor = UIColorFromRGB(color_text_footer);
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeValuePicker])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if ([item[@"name"] isEqualToString:kContourLines])
        {
            NSString *selectedContourLinesName = OALocalizedString(@"shared_string_none");
            OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
            OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
            if ([tempContourLinesParam.value isEqualToString:@"true"])
                selectedContourLinesName = OALocalizedString(@"map_settings_weather_temp");
            else if ([pressureContourLinesParam.value isEqualToString:@"true"])
                selectedContourLinesName = OALocalizedString(@"map_settings_weather_pressure");
            
            cell.dataArray = item[@"value"];
            NSInteger index = [cell.dataArray indexOfObject:selectedContourLinesName];
            if (index != NSNotFound)
                [cell.picker selectRow:index inComponent:0 animated:NO];
        }
        else
        {
            cell.dataArray = item[@"value"];
            NSInteger index = [cell.dataArray indexOfObject:item[@"selected"]];
            if (index != NSNotFound)
                [cell.picker selectRow:index inComponent:0 animated:NO];
        }
        cell.picker.tag = ((NSNumber *)item[@"tag"]).intValue;
        cell.delegate = self;
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        OAButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonCell *)[nib objectAtIndex:0];
            [cell showImage:NO];
            [cell.button setTitleColor:[UIColor colorWithRed:87.0/255.0 green:20.0/255.0 blue:204.0/255.0 alpha:1] forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _countourLinesSectionIndex || indexPath.section == _alphasSectionIndex || indexPath.section == _unitsSectionIndex)
        return indexPath;
    
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
    [tblView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kCellTypeValue])
    {
        if ([item[@"name"] isEqualToString:kWeatherAlphas])
        {
            _showAlphas = !_showAlphas;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
                NSMutableArray<NSIndexPath*> *indexPaths = [NSMutableArray array];
                for (int i = 1; i <= 5; i++)
                    [indexPaths addObject:[NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section]];
                
                if (_showAlphas)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherContourLines])
        {
            _showContourLinesPicker = !_showContourLinesPicker;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showContourLinesPicker)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherTempUnits])
        {
            _showTempUnits = !_showTempUnits;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showTempUnits)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherPressureUnits])
        {
            _showPressureUnits = !_showPressureUnits;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showPressureUnits)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherWindUnits])
        {
            _showWindUnits = !_showWindUnits;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showWindUnits)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherCloudUnits])
        {
            _showCloudUnits = !_showCloudUnits;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showCloudUnits)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
        else if ([item[@"name"] isEqualToString:kWeatherPrecipUnits])
        {
            _showPrecipUnits = !_showPrecipUnits;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tblView beginUpdates];
                [self setupView];
                NSArray<NSIndexPath*> *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
                if (_showPrecipUnits)
                    [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                else
                    [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

                [self.tblView endUpdates];
            });
        }
    }
}

- (void) dateTimePickerChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    if (picker)
        [OARootViewController.instance.mapPanel.mapViewController.mapLayers updateWeatherDate:picker.date];
}

- (void) turnWeatherOnOff:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        if (switchView.isOn)
        {
            _app.data.weather = YES;
            [tblView beginUpdates];
            [self setupView];
            [tblView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
        else
        {
            _app.data.weather = NO;
            [tblView beginUpdates];
            [tblView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [self setupView];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
    }
}

- (void) onWeatherLayerSwitchChanged:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    if (sw)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSString *name = [self getItem:indexPath][@"name"];
        if ([name isEqualToString:kWeatherTemp])
            _app.data.weatherTemp = sw.isOn;
        else if ([name isEqualToString:kWeatherPressure])
            _app.data.weatherPressure = sw.isOn;
        else if ([name isEqualToString:kWeatherWind])
            _app.data.weatherWind = sw.isOn;
        else if ([name isEqualToString:kWeatherCloud])
            _app.data.weatherCloud = sw.isOn;
        else if ([name isEqualToString:kWeatherPrecip])
            _app.data.weatherPrecip = sw.isOn;

        [self setupView];
    }
}

- (void) onWeatherLayerAlphaChanged:(id)sender
{
    UISlider *sl = (UISlider *)sender;
    if (sl)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sl.tag & 0x3FF inSection:sl.tag >> 10];
        NSString *name = [self getItem:indexPath][@"name"];
        if ([name isEqualToString:kWeatherTempAlpha])
            _app.data.weatherTempAlpha = sl.value;
        else if ([name isEqualToString:kWeatherPressureAlpha])
            _app.data.weatherPressureAlpha = sl.value;
        else if ([name isEqualToString:kWeatherWindAlpha])
            _app.data.weatherWindAlpha = sl.value;
        else if ([name isEqualToString:kWeatherCloudAlpha])
            _app.data.weatherCloudAlpha = sl.value;
        else if ([name isEqualToString:kWeatherPrecipAlpha])
            _app.data.weatherPrecipAlpha = sl.value;

        [tblView beginUpdates];
        [self setupView];
        [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tblView endUpdates];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void) customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    NSInteger row = -1;
    NSInteger section = -1;
    BOOL forceUpdateSettings = NO;
    if (pickerTag == kContourLinesTag)
    {
        row = 0;
        section = _countourLinesSectionIndex;
        
        OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
        OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
        if ([OALocalizedString(@"map_settings_weather_temp") isEqualToString:value])
        {
            tempContourLinesParam.value = @"true";
            [_styleSettings save:tempContourLinesParam];
            pressureContourLinesParam.value = @"false";
            [_styleSettings save:pressureContourLinesParam];
        }
        else if ([OALocalizedString(@"map_settings_weather_pressure") isEqualToString:value])
        {
            tempContourLinesParam.value = @"false";
            [_styleSettings save:tempContourLinesParam];
            pressureContourLinesParam.value = @"true";
            [_styleSettings save:pressureContourLinesParam];
        }
        else
        {
            tempContourLinesParam.value = @"false";
            [_styleSettings save:tempContourLinesParam];
            pressureContourLinesParam.value = @"false";
            [_styleSettings save:pressureContourLinesParam];
        }
    }
    else if (pickerTag == kWeatherTempUnitTag)
    {
        if ([[OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE] setBandUnit:value])
        {
            forceUpdateSettings = YES;
            row = _tempUnitsRowIndex;
            section = _unitsSectionIndex;
        }
    }
    else if (pickerTag == kWeatherPressureUnitTag)
    {
        if ([[OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE] setBandUnit:value])
        {
            forceUpdateSettings = YES;
            row = _pressureUnitsRowIndex;
            section = _unitsSectionIndex;
        }
    }
    else if (pickerTag == kWeatherWindUnitTag)
    {
        if ([[OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED] setBandUnit:value])
        {
            forceUpdateSettings = YES;
            row = _windUnitsRowIndex;
            section = _unitsSectionIndex;
        }
    }
    else if (pickerTag == kWeatherCloudUnitTag)
    {
        if ([[OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD] setBandUnit:value])
        {
            forceUpdateSettings = YES;
            row = _cloudUnitsRowIndex;
            section = _unitsSectionIndex;
        }
    }
    else if (pickerTag == kWeatherPrecipUnitTag)
    {
        if ([[OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION] setBandUnit:value])
        {
            forceUpdateSettings = YES;
            row = _precipUnitsRowIndex;
            section = _unitsSectionIndex;
        }
    }

    if (forceUpdateSettings)
        _app.resourcesManager->getWeatherResourcesManager()->setBandSettings(OAWeatherHelper.sharedInstance.getBandSettings);

    if (row != -1 && section != -1)
    {
        [tblView beginUpdates];
        [self setupView];
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
        [tblView endUpdates];
    }
}

- (void) onButtonPressed:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if (btn)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btn.tag & 0x3FF inSection:btn.tag >> 10];
        NSString *name = [self getItem:indexPath][@"name"];
        if ([name isEqualToString:kClearGeoCacheButton])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"q_clear_weather_cache") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self clearCache:YES];
            }]];
            [vwController presentViewController:alert animated:YES completion:nil];
        }
        else if ([name isEqualToString:kClearRasterCacheButton])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"q_clear_weather_cache") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self clearCache:NO];
            }]];
            [vwController presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void) clearCache:(BOOL)geoCache
{
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC showProgressHUD];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        const auto weatherResourcesManager = _app.resourcesManager->getWeatherResourcesManager();
        if (weatherResourcesManager)
            weatherResourcesManager->clearDbCache(geoCache, !geoCache);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [mapVC hideProgressHUD];
            [self calculateCacheSize];
        });
    });

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
    else
        return 36.0;
}

@end
