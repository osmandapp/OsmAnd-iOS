//
//  OAWeatherCacheSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 01.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherCacheSettingsViewController.h"
#import "MBProgressHUD.h"
#import "OATableViewCellSimple.h"
#import "OATableViewCellRightIcon.h"
#import "OATableViewCellValue.h"
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
    self.subtitleLabel.hidden = YES;
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
                    OAWorldRegion *region = countryData[@"region"];
                    if (![_weatherHelper isOfflineForecastSizesInfoCalculated:[OAWeatherHelper checkAndGetRegionId:region]])
                    {
                        [_weatherHelper calculateCacheSize:region onComplete:^()
                         {
                            uint64_t size = [_weatherHelper getOfflineForecastSizeInfo:[OAWeatherHelper checkAndGetRegionId:region] local:YES];
                            countryData[@"description"] = [NSByteCountFormatter stringFromByteCount:size
                                                                                         countStyle:NSByteCountFormatterCountStyleFile];
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
    NSString *sizeTitle = @"";
    CGFloat size = 0.;
    if (_region)
    {
        sizeTitle = OALocalizedString(@"total");
        size = [_weatherHelper getOfflineForecastSizeInfo:_region.regionId local:YES];
    }
    else if (_type == EOAWeatherOnlineData)
    {
        sizeTitle = OALocalizedString(@"res_size");
        size = _weatherHelper.onlineCacheSize;
    }
    else if (_type == EOAWeatherOfflineData)
    {
        sizeTitle = OALocalizedString(@"shared_string_total_size");
        size = _weatherHelper.offlineCacheSize;
    }

    NSString *sizeString = _region != nil || size > 0
            ? [NSByteCountFormatter stringFromByteCount:size
                                             countStyle:NSByteCountFormatterCountStyleFile]
            : OALocalizedString(@"calculating_progress");

    [infoCells addObject:@{
            @"key": @"size",
            @"title": sizeTitle,
            @"value": sizeString,
            @"type": [OATableViewCellValue getCellIdentifier]
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
            @"type": [OATableViewCellSimple getCellIdentifier]
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
        OsmAndAppInstance app = [OsmAndApp instance];
        for (OAWorldRegion *region in [@[app.worldRegion] arrayByAddingObjectsFromArray:app.worldRegion.flattenedSubregions])
        {
            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
            if ([regionIds containsObject:regionId])
            {
                NSMutableDictionary *regionData = [NSMutableDictionary dictionary];
                regionData[@"key"] = [@"region_cell_" stringByAppendingString:regionId];
                regionData[@"type"] = [OATableViewCellRightIcon getCellIdentifier];
                regionData[@"region"] = region;
                regionData[@"description"] = [NSByteCountFormatter stringFromByteCount:[_weatherHelper getOfflineForecastSizeInfo:region.regionId local:YES]
                                                                            countStyle:NSByteCountFormatterCountStyleFile];;
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
        if ([_weatherHelper isOfflineForecastSizesInfoCalculated:[OAWeatherHelper checkAndGetRegionId:_region]])
        {
            uint64_t size = [_weatherHelper getOfflineForecastSizeInfo:[OAWeatherHelper checkAndGetRegionId:_region] local:YES];
            _clearButtonActive = size > 0;
            if (_clearIndexPath)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadRowsAtIndexPaths:@[_clearIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
        }
        else
        {
            [_weatherHelper calculateCacheSize:_region onComplete:^() {
                if (_sizeIndexPath)
                {
                    uint64_t size = [_weatherHelper getOfflineForecastSizeInfo:[OAWeatherHelper checkAndGetRegionId:_region] local:YES];
                    NSMutableArray<NSDictionary *> *cells = _data[_sizeIndexPath.section][@"cells"];
                    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size
                                                                          countStyle:NSByteCountFormatterCountStyleFile];
                    cells[_sizeIndexPath.row] = @{
                        @"key": @"size",
                        @"title": OALocalizedString(@"total"),
                        @"value": sizeString,
                        @"type": [OATableViewCellValue getCellIdentifier]
                    };
                    _clearButtonActive = size > 0;

                    NSArray<NSIndexPath *> *indexPaths = _clearIndexPath != nil ? @[_sizeIndexPath, _clearIndexPath] : @[_sizeIndexPath];
                    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                }
            }];
        }
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
                            @"type": [OATableViewCellValue getCellIdentifier]
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
            OAWorldRegion *region;
            if (selectedRegionList)
            {
                NSMutableArray<NSDictionary *> *countryCells = _data[_selectedRegionIndexPath.section][@"cells"];
                region = (OAWorldRegion *) countryCells[_selectedRegionIndexPath.row][@"region"];
            }
            else
            {
                region = _region;
            }
            [_weatherHelper clearCache:YES regionIds:@[[OAWeatherHelper checkAndGetRegionId:region]]];
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
            countryCells[_selectedRegionIndexPath.row][@"description"] = [NSByteCountFormatter stringFromByteCount:0
                                                                                                        countStyle:NSByteCountFormatterCountStyleFile];
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
    if ([item[@"type"] isEqualToString:[OATableViewCellSimple getCellIdentifier]])
    {
        OATableViewCellSimple *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellSimple getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellSimple getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellSimple *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.titleLabel.textColor = UIColorFromRGB(color_primary_red);
        }
        if (cell)
        {
            BOOL isClear = [item[@"key"] isEqualToString:@"clear"];
            cell.selectionStyle = isClear && _clearButtonActive ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = isClear ? _clearButtonActive ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer) : UIColor.blackColor;
            cell.textStackView.alignment = isClear && _type == EOAWeatherOnlineData ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATableViewCellRightIcon getCellIdentifier]])
    {
        OATableViewCellRightIcon *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellRightIcon getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellRightIcon getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellRightIcon *) nib[0];
            [cell leftIconVisibility:NO];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_red);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_remove_outlined"];
        }
        if (cell)
        {
            cell.selectionStyle = [item.allKeys containsObject:@"key"] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = [OAWeatherHelper checkAndGetRegionName:(OAWorldRegion *) item[@"region"]];
            cell.descriptionLabel.text = item[@"description"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATableViewCellValue getCellIdentifier]])
    {
        OATableViewCellValue *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellValue getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellValue getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellValue *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    return nil;
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
                    [OAWeatherHelper checkAndGetRegionName:(selectedRegionList ? ((OAWorldRegion *) item[@"region"]) : _region)]];
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
