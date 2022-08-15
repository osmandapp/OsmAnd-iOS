//
//  OAWeatherCacheSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 01.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherCacheSettingsViewController.h"
#import "MBProgressHUD.h"
#import "OAIconTitleValueCell.h"
#import "OATextLineViewCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OsmAndApp.h"
#import "OAWeatherHelper.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAWeatherCacheSettingsViewController () <UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWeatherCacheSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_clearIndexPath;
    NSIndexPath *_selectedRegionIndexPath;
    MBProgressHUD *_progressHUD;
    BOOL _clearButtonActive;

    OAWeatherHelper *_weatherHelper;
    OAWorldRegion *_region;
    EOAWeatherCacheType _type;
}

- (instancetype)initWithCacheType:(EOAWeatherCacheType)type
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        _type = type;
        _weatherHelper = [OAWeatherHelper sharedInstance];
    }
    return self;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        _region = region;
        _weatherHelper = [OAWeatherHelper sharedInstance];
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    if (_region)
        self.titleLabel.text = OALocalizedString(@"shared_string_updates_size");
    else if (_type == EOAWeatherOnlineData)
        self.titleLabel.text = OALocalizedString(@"shared_string_online_cache");
    else if (_type == EOAWeatherOfflineData)
        self.titleLabel.text = OALocalizedString(@"weather_offline_forecast");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.sectionHeaderHeight = 34.;
    self.tableView.sectionFooterHeight = 0.001;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [self setupView];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCacheSize];
    if (_type == EOAWeatherOfflineData)
    {
        for (NSInteger i = 0; i < _data.count; i++)
        {
            NSDictionary *sectionData = _data[i];
            if ([sectionData[@"key"] isEqualToString:@"countries_section"])
            {
                NSMutableArray<NSMutableDictionary *> *countryCells = sectionData[@"cells"];
                for (NSInteger j = 0; j < countryCells.count; j++)
                {
                    NSMutableDictionary *countryData = countryCells[j];
                    if ([countryData[@"size"] unsignedLongLongValue] == 0)
                    {
                        OAWorldRegion *region = countryData[@"region"];
                        [_weatherHelper calculateCacheSize:region onComplete:^()
                        {
                            uint64_t size = [_weatherHelper getOfflineForecastSizeInfo:region.regionId local:YES];
                            countryData[@"size"] = @(size);
                            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                                  withRowAnimation:UITableViewRowAnimationNone];
                        }];
                    }
                }
            }
        }
    }
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *infoCells = [NSMutableArray array];
    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:0 countStyle:NSByteCountFormatterCountStyleFile];
    NSString *sizeTitle = @"";
    if (_region)
        sizeTitle = OALocalizedString(@"total");
    else if (_type == EOAWeatherOnlineData)
        sizeTitle = OALocalizedString(@"res_size");
    else if (_type == EOAWeatherOfflineData)
        sizeTitle = OALocalizedString(@"shared_string_total_size");
    [infoCells addObject:@{
            @"key": @"size",
            @"title": sizeTitle,
            @"value": sizeString,
            @"type": [OAIconTitleValueCell getCellIdentifier]
    }];
    [data addObject:@{ @"cells": infoCells }];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSDictionary *> *clearCells = [NSMutableArray array];
    NSString *clearTitle = @"";
    if (_region)
        clearTitle = OALocalizedString(@"shared_string_delete");
    else if (_type == EOAWeatherOnlineData)
        clearTitle = OALocalizedString(@"poi_clear");
    else if (_type == EOAWeatherOfflineData)
        clearTitle = OALocalizedString(@"shared_string_delete_all");
    [_type == EOAWeatherOnlineData ? clearCells : infoCells addObject:@{
            @"key": @"clear",
            @"title": clearTitle,
            @"type": [OATextLineViewCell getCellIdentifier]
    }];

    if (clearCells.count > 0)
        [data addObject:@{ @"cells": clearCells }];

    _clearIndexPath = [NSIndexPath indexPathForRow:(clearCells.count > 0 ? clearCells.count : infoCells.count) - 1 inSection:data.count - 1];

    if (_type == EOAWeatherOfflineData)
    {
        NSMutableArray<NSMutableDictionary *> *countryCells = [NSMutableArray array];
        NSMutableDictionary *countriesSection = [NSMutableDictionary dictionary];
        countriesSection[@"key"] = @"countries_section";
        countriesSection[@"header"] = OALocalizedString(@"shared_string_countries");
        countriesSection[@"cells"] = countryCells;
        [data addObject:countriesSection];

        NSArray<NSString *> *regionIds = [_weatherHelper getTempForecastsWithDownloadStates:@[
                @(EOAWeatherForecastDownloadStateFinished),
                @(EOAWeatherForecastDownloadStateInProgress)]
        ];
        for (OAWorldRegion *region in [OsmAndApp instance].worldRegion.flattenedSubregions)
        {
            if ([regionIds containsObject:region.regionId])
            {
                NSMutableDictionary *regionData = [NSMutableDictionary dictionary];
                regionData[@"key"] = [@"region_cell_" stringByAppendingString:region.regionId];
                regionData[@"type"] = [OATitleDescrRightIconTableViewCell getCellIdentifier];
                regionData[@"region"] = region;
                regionData[@"size"] = @([_weatherHelper getOfflineForecastSizeInfo:region.regionId local:YES]);
                [countryCells addObject:regionData];
            }
        }
    }

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (void)updateCacheSize
{
    if (_region)
    {
        [_weatherHelper calculateCacheSize:_region onComplete:^() {
            if (_sizeIndexPath)
            {
                uint64_t size = [_weatherHelper getOfflineForecastSizeInfo:_region.regionId local:YES];
                NSMutableArray<NSDictionary *> *cells = _data[_sizeIndexPath.section][@"cells"];
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size
                                                                      countStyle:NSByteCountFormatterCountStyleFile];
                cells[_sizeIndexPath.row] = @{
                        @"key": @"size",
                        @"title": OALocalizedString(@"total"),
                        @"value": sizeString,
                        @"type": [OAIconTitleValueCell getCellIdentifier]
                };
                _clearButtonActive = size > 0;

                [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath, _clearIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }];
    }
    else
    {
        [_weatherHelper calculateFullCacheSize:_type == EOAWeatherOfflineData onComplete:^(unsigned long long size)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_sizeIndexPath)
                {
                    NSMutableArray<NSDictionary *> *cells = _data[_sizeIndexPath.section][@"cells"];
                    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
                    cells[_sizeIndexPath.row] = @{
                            @"key": @"size",
                            @"title": OALocalizedString(_type == EOAWeatherOnlineData ? @"res_size" : @"shared_string_total_size"),
                            @"value": sizeString,
                            @"type": [OAIconTitleValueCell getCellIdentifier]
                    };
                    _clearButtonActive = size > 0;

                    [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath, _clearIndexPath]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            });
        }];
    }
}

- (void)clearCache
{
    BOOL selectedRegionList = _selectedRegionIndexPath != nil;
    [_progressHUD showAnimated:YES whileExecutingBlock:^{
        if (_region || selectedRegionList)
        {
            NSString *regionId;
            if (selectedRegionList)
            {
                NSMutableArray<NSDictionary *> *countryCells = _data[_selectedRegionIndexPath.section][@"cells"];
                regionId = ((OAWorldRegion *) countryCells[_selectedRegionIndexPath.row][@"region"]).regionId;
            }
            else
            {
                regionId = _region.regionId;
            }
            [_weatherHelper clearCache:YES regionIds:@[regionId]];
            [self updateCacheSize];
        }
        else
        {
            [_weatherHelper clearCache:_type == EOAWeatherOfflineData regionIds:nil];
        }
    } completionBlock:^{
        if (selectedRegionList)
        {
            NSMutableArray<NSMutableDictionary *> *countryCells = _data[_selectedRegionIndexPath.section][@"cells"];
            countryCells[_selectedRegionIndexPath.row][@"size"] = @(0);
            [self.tableView reloadRowsAtIndexPaths:@[_selectedRegionIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            _selectedRegionIndexPath = nil;
        }
        else
        {
            [self dismissViewController];
        }
        if (self.cacheDelegate)
            [self.cacheDelegate onCacheClear];
    }];
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
            if ([item[@"key"] isEqualToString:@"clear"])
            {
                cell.selectionStyle = _clearButtonActive ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
                cell.textView.textColor = _clearButtonActive ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer);
            }
            else
            {
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.textView.textColor = UIColor.blackColor;
            }
            cell.textView.text = item[@"title"];
            cell.textView.textAlignment = _type == EOAWeatherOnlineData ? NSTextAlignmentCenter : NSTextAlignmentNatural;
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
            cell.titleLabel.text = ((OAWorldRegion *) item[@"region"]).name;
            cell.descriptionLabel.text = [NSByteCountFormatter stringFromByteCount:[item[@"size"] unsignedLongLongValue]
                                                                        countStyle:NSByteCountFormatterCountStyleFile];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_remove_outlined"];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionData = _data[section];
    return sectionData[@"header"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL selectedRegionList = [item[@"key"] hasPrefix:@"region_cell_"];
    if (selectedRegionList)
        _selectedRegionIndexPath = indexPath;

    if (([item[@"key"] isEqualToString:@"clear"] && _clearButtonActive) || [item[@"key"] hasPrefix:@"region_cell_"])
    {
        NSString *title = @"";
        NSString *message = @"";
        if (_region || selectedRegionList)
        {
            title = OALocalizedString(@"shared_string_clear_offline_cache");
            message = [NSString stringWithFormat:OALocalizedString(@"weather_clear_offline_cache_for"),
                    (selectedRegionList ? ((OAWorldRegion *) item[@"region"]).name : _region.name)];
        }
        else if (_type == EOAWeatherOnlineData)
        {
            title = OALocalizedString(@"shared_string_clear_online_cache");
            message = OALocalizedString(@"weather_clear_online_cache");
        }
        else if (_type == EOAWeatherOfflineData)
        {
            title = OALocalizedString(@"shared_string_clear_offline_cache");
            message = OALocalizedString(@"weather_clear_offline_cache");
        }

        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:title
                                                    message:message
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action)
                                                             {
                                                                 _selectedRegionIndexPath = nil;
                                                             }
       ];

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
