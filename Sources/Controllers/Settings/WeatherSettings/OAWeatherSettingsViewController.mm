//
//  OAWeatherSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherSettingsViewController.h"
#import "OAWeatherBandSettingsViewController.h"
#import "OAWeatherCacheSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OATableViewCellSwitch.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"

@interface OAWeatherSettingsViewController () <OAWeatherBandSettingsDelegate, OAWeatherCacheSettingsDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWeatherSettingsViewController
{
    OAWeatherHelper *_weatherHelper;
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_selectedIndexPath;
    NSIndexPath *_onlineDataIndexPath;
    NSIndexPath *_useOfflineDataIndexPath;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"weather_plugin");
    self.subtitleLabel.text = OALocalizedString(@"shared_string_settings");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _weatherHelper = [OAWeatherHelper sharedInstance];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;

    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCacheSize:NO onComplete:^{
        [self updateCacheSize:YES onComplete:nil];
    }];
}

- (void)updateCacheSize:(BOOL)localData onComplete:(void (^)())onComplete
{
    if ((localData && _useOfflineDataIndexPath) || (!localData && _onlineDataIndexPath))
    {
        [_weatherHelper calculateFullCacheSize:localData onComplete:^(unsigned long long dbsSize)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableArray<NSDictionary *> *cells = _data[localData ? _useOfflineDataIndexPath.section : _onlineDataIndexPath.section][@"cells"];
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:dbsSize countStyle:NSByteCountFormatterCountStyleFile];
                cells[localData ? _useOfflineDataIndexPath.row : _onlineDataIndexPath.row] = @{
                        @"key": localData ? @"offline_forecast" : @"online_cache",
                        @"title": OALocalizedString(localData ? @"weather_offline_forecast" : @"shared_string_online_cache"),
                        @"value": sizeString,
                        @"type": [OAValueTableViewCell getCellIdentifier]
                };

                [self.tableView reloadRowsAtIndexPaths:@[localData ? _useOfflineDataIndexPath : _onlineDataIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];

                if (onComplete)
                    onComplete();
            });
        }];
    }
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *measurementCells = [NSMutableArray array];
    for (OAWeatherBand *band in _weatherHelper.bands)
    {
        [measurementCells addObject:@{
                @"key": [@"band_" stringByAppendingString:[band getMeasurementName]],
                @"band": band,
                @"type": [OAValueTableViewCell getCellIdentifier]
        }];
    }
    [data addObject:@{
            @"header": OALocalizedString(@"measurement_units"),
            @"cells": measurementCells
    }];

    NSMutableArray<NSDictionary *> *forecastData = [NSMutableArray array];
    [forecastData addObject:@{
            @"key": @"offline_forecast_only",
            @"title": OALocalizedString(@"weather_offline_forecast_only"),
            @"selected": @([OsmAndApp instance].data.weatherUseOfflineData),
            @"type": [OATableViewCellSwitch getCellIdentifier]
    }];
    [data addObject:@{
            @"cells": forecastData,
            @"footer": OALocalizedString(@"weather_offline_forecast_only_desc")
    }];

    NSMutableArray<NSDictionary *> *cacheData = [NSMutableArray array];
    [data addObject:@{
            @"header": OALocalizedString(@"shared_string_data"),
            @"cells": cacheData,
            @"footer": OALocalizedString(@"weather_data_provider")
    }];

    NSString *onlineCacheSizeString = _weatherHelper.onlineCacheSize > 0
            ? [NSByteCountFormatter stringFromByteCount:_weatherHelper.onlineCacheSize
                                             countStyle:NSByteCountFormatterCountStyleFile]
            : OALocalizedString(@"calculating_progress");
    [cacheData addObject:@{
            @"key": @"online_cache",
            @"title": OALocalizedString(@"shared_string_online_cache"),
            @"value": onlineCacheSizeString,
            @"type": [OAValueTableViewCell getCellIdentifier]
    }];
    _onlineDataIndexPath = [NSIndexPath indexPathForRow:cacheData.count - 1 inSection:data.count - 1];

    NSString *offlineCacheSizeString = _weatherHelper.offlineCacheSize > 0
            ? [NSByteCountFormatter stringFromByteCount:_weatherHelper.offlineCacheSize
                                             countStyle:NSByteCountFormatterCountStyleFile]
            : OALocalizedString(@"calculating_progress");
    [cacheData addObject:@{
            @"key": @"offline_forecast",
            @"title": OALocalizedString(@"weather_offline_forecast"),
            @"value": offlineCacheSizeString,
            @"type": [OAValueTableViewCell getCellIdentifier]
    }];
    _useOfflineDataIndexPath = [NSIndexPath indexPathForRow:cacheData.count - 1 inSection:data.count - 1];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionData = _data[section];
    return sectionData[@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *sectionData = _data[section];
    return sectionData[@"footer"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + ([item[@"key"] hasPrefix:@"band"] ? kPaddingToLeftOfContentWithIcon : kPaddingOnSideOfContent), 0., 0.);

            NSString *title;
            NSString *iconName;
            NSString *value;
            if ([item[@"key"] hasPrefix:@"band"])
            {
                OAWeatherBand *band = (OAWeatherBand *) item[@"band"];
                title = [band getMeasurementName];
                iconName = [band getIcon];

                NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
                formatter.locale = NSLocale.autoupdatingCurrentLocale;

                NSUnit *unit = [band getBandUnit];
                if (band.bandIndex == WEATHER_BAND_TEMPERATURE)
                    value = unit.name != nil ? unit.name : [formatter displayStringFromUnit:unit];
                else
                    value = [formatter displayStringFromUnit:unit];
            }
            else
            {
                title = item[@"title"];
                iconName = item[@"icon"];
                value = item[@"value"];
            }

            cell.titleLabel.text = title;
            cell.valueLabel.text = value;
            
            BOOL hasLeftIcon = iconName && iconName.length > 0;
            cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:iconName] : nil;
            [cell leftIconVisibility:hasLeftIcon];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATableViewCellSwitch getCellIdentifier]])
    {
        OATableViewCellSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellSwitch getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellSwitch getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellSwitch *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);

            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = [item[@"selected"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _selectedIndexPath = indexPath;
    if ([item[@"key"] hasPrefix:@"band"])
    {
        OAWeatherBandSettingsViewController *controller =
                [[OAWeatherBandSettingsViewController alloc] initWithWeatherBand:item[@"band"]];
        controller.bandDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"online_cache"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOnlineData];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"offline_forecast"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOfflineData];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        if ([item[@"key"] isEqualToString:@"offline_forecast_only"])
            [[OsmAndApp instance].data setWeatherUseOfflineData:switchView.isOn];
    }
}

#pragma mark - OAWeatherBandSettingsDelegate

- (void)onBandUnitChanged
{
    if (_selectedIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    [self updateCacheSize:NO onComplete:^{
        [self updateCacheSize:YES onComplete:nil];
    }];
}

@end
