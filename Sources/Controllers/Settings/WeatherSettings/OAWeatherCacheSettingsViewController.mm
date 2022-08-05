//
//  OAWeatherCacheSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 01.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherCacheSettingsViewController.h"
#import "OARootViewController.h"
#import "OAIconTitleValueCell.h"
#import "OATextLineViewCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OsmAndApp.h"
#import "OAWeatherHelper.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

@interface OAWeatherCacheSettingsViewController () <UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWeatherCacheSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_sizeIndexPath;
    EOAWeatherCacheType _type;

    unsigned long long _geoDbSize;
    unsigned long long _rasterDbSize;
}

- (instancetype)initWithCacheType:(EOAWeatherCacheType)type
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        _type = type;
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(_type == EOAWeatherOnlineCache ? @"shared_string_online_cache" : @"weather_offline_forecast");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.sectionHeaderHeight = 34.;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCacheSize];
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *infoCells = [NSMutableArray array];
    unsigned long long size = _type == EOAWeatherOnlineCache ? _geoDbSize + _rasterDbSize : 0;
    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
    [infoCells addObject:@{
            @"key": @"size",
            @"title": OALocalizedString(_type == EOAWeatherOnlineCache ? @"res_size" : @"shared_string_total_size"),
            @"value": sizeString,
            @"type": [OAIconTitleValueCell getCellIdentifier]
    }];
    [data addObject:@{ @"cells": infoCells }];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSDictionary *> *clearCells = [NSMutableArray array];
    [_type == EOAWeatherOnlineCache ? clearCells : infoCells addObject:@{
            @"key": @"clear",
            @"title": OALocalizedString(_type == EOAWeatherOnlineCache ? @"poi_clear" : @"shared_string_delete_all"),
            @"type": [OATextLineViewCell getCellIdentifier]
    }];

    if (clearCells.count > 0)
        [data addObject:@{ @"cells": clearCells }];

    /*if (_type == EOAWeatherOfflineForecast)
    {
        NSMutableArray<NSDictionary *> *countryCells = [NSMutableArray array];
        NSArray *countries = [NSArray array];
        for (id country in countries)
        {
            [countryCells addObject:@{
                    @"key": @"country",
                    @"title": @"country",
                    @"description": @"size",
                    @"type": [OATitleDescrRightIconTableViewCell getCellIdentifier]
            }];
        }
        [data addObject:@{
                @"header": OALocalizedString(@"shared_string_countries"),
                @"cells": countryCells
        }];
    }*/

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (void)updateCacheSize
{
    [[OAWeatherHelper sharedInstance] calculateCacheSize:^(unsigned long long geoDbSize, unsigned long long rasterDbSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _geoDbSize = geoDbSize;
            _rasterDbSize = rasterDbSize;

            if (_sizeIndexPath)
            {
                NSMutableArray<NSDictionary *> *cells = _data[_sizeIndexPath.section][@"cells"];
                unsigned long long size = _type == EOAWeatherOnlineCache ? _geoDbSize + _rasterDbSize : 0;
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
                cells[_sizeIndexPath.row] = @{
                        @"key": @"size",
                        @"title": OALocalizedString(_type == EOAWeatherOnlineCache ? @"res_size" : @"shared_string_total_size"),
                        @"value": sizeString,
                        @"type": [OAIconTitleValueCell getCellIdentifier]
                };

                [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        });
    }];
}

- (void) clearCache
{
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC showProgressHUD];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        const auto weatherResourcesManager = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager();
        if (weatherResourcesManager)
            weatherResourcesManager->clearDbCache(true, true);

        [mapVC.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapVC.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapVC.mapLayers.weatherContourLayer updateWeatherLayer];

        dispatch_async(dispatch_get_main_queue(), ^{
            [mapVC hideProgressHUD];
            [self updateCacheSize];
            if (self.cacheDelegate)
                [self.cacheDelegate onCacheClear:_type];
        });
    });

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
    return _data[section][@"header"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showLeftIcon:NO];
            [cell showRightIcon:NO];
            cell.textView.font = [UIFont systemFontOfSize:17.];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_red);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.textView.textAlignment = _type == EOAWeatherOnlineCache ? NSTextAlignmentCenter : NSTextAlignmentNatural;
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleDescrRightIconTableViewCell getCellIdentifier]])
    {
        OATitleDescrRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescrRightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *) nib[0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_red);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];
            cell.iconView.image = [UIImage templateImageNamed:@"icon_remove"];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"clear"])
    {
        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_clear_online_cache")
                                                    message:OALocalizedString(@"weather_clear_online_cache")
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];

        UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"poi_clear")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action)
                                                                 {
                                                                     [self clearCache];
                                                                 }
        ];

        [alert addAction:cancelAction];
        [alert addAction:clearCacheAction];

        alert.preferredAction = clearCacheAction;

        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
