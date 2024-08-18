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
#import "OASwitchTableViewCell.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASizes.h"
#import "OAAppData.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"
#import "GeneratedAssetSymbols.h"

#define kBandsSectionIndex 0
#define kUseOfflineDataSectionIndex 1

@interface OAWeatherSettingsViewController () <OAWeatherBandSettingsDelegate, OAWeatherCacheSettingsDelegate>

@end

@implementation OAWeatherSettingsViewController
{
    OAWeatherHelper *_weatherHelper;
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_selectedIndexPath;
    NSIndexPath *_onlineDataIndexPath;
    NSIndexPath *_useOfflineDataIndexPath;
}

#pragma mark - Initialization

- (void)commonInit
{
    _weatherHelper = [OAWeatherHelper sharedInstance];
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCacheSize:NO onComplete:^{
        [self updateCacheSize:YES onComplete:nil];
    }];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"weather_plugin");
}

- (NSString *)getSubtitle
{
    return OALocalizedString(@"shared_string_settings");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil iconName:@"ic_navbar_reset" action:@selector(onRightNavbarButtonPressed) menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"reset_to_default");
    return @[rightButton];
}

- (void)onRightNavbarButtonPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"reset_to_default") message:OALocalizedString(@"reset_plugin_to_default") preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.barButtonItem = self.navigationItem.rightBarButtonItem;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil];

    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_reset") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
    {
        [[OsmAndApp instance].data resetWeatherSettings];
        [self generateData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kBandsSectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kUseOfflineDataSectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];

    [alert addAction:resetAction];
    [alert addAction:cancelAction];
    alert.preferredAction = resetAction;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table data

- (void)generateData
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
            @"type": [OASwitchTableViewCell getCellIdentifier]
    }];
    [data addObject:@{
            @"cells": forecastData,
            @"footer": OALocalizedString(@"weather_offline_forecast_only_desc")
    }];

    NSMutableArray<NSDictionary *> *cacheData = [NSMutableArray array];
    [data addObject:@{
            @"header": OALocalizedString(@"data_settings"),
            @"cells": cacheData,
            @"footer": OALocalizedString(@"weather_data_provider")
    }];

    NSString *onlineCacheSizeString = _weatherHelper.onlineCacheSize > 0
            ? [NSByteCountFormatter stringFromByteCount:_weatherHelper.onlineCacheSize
                                             countStyle:NSByteCountFormatterCountStyleFile]
            : OALocalizedString(@"calculating_progress");
    [cacheData addObject:@{
            @"key": @"online_cache",
            @"title": OALocalizedString(@"weather_online_cache"),
            @"value": onlineCacheSizeString,
            @"type": [OAValueTableViewCell getCellIdentifier]
    }];
    _onlineDataIndexPath = [NSIndexPath indexPathForRow:cacheData.count - 1 inSection:data.count - 1];
    
    uint64_t offlineCacheSize = [_weatherHelper getOfflineWeatherForecastCacheSize];

    NSString *offlineCacheSizeString = offlineCacheSize > 0
            ? [NSByteCountFormatter stringFromByteCount:offlineCacheSize
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

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _data[section][@"header"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _data[section][@"footer"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
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
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
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

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _selectedIndexPath = indexPath;
    if ([item[@"key"] hasPrefix:@"band"])
    {
        OAWeatherBandSettingsViewController *controller =
                [[OAWeatherBandSettingsViewController alloc] initWithWeatherBand:item[@"band"]];
        controller.bandDelegate = self;
        [self showModalViewController:controller];
    }
    else if ([item[@"key"] isEqualToString:@"online_cache"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOnlineData];
        controller.cacheDelegate = self;
        [self showModalViewController:controller];
    }
    else if ([item[@"key"] isEqualToString:@"offline_forecast"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOfflineData];
        controller.cacheDelegate = self;
        [self showModalViewController:controller];
    }
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

#pragma mark - Additions

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
                        @"title": OALocalizedString(localData ? @"weather_offline_forecast" : @"weather_online_cache"),
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
