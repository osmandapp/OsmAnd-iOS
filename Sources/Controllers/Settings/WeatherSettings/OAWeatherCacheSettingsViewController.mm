//
//  OAWeatherCacheSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 01.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherCacheSettingsViewController.h"
#import "MBProgressHUD.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OsmAndApp.h"
#import "OAWeatherHelper.h"
#import "OAWorldRegion.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAWeatherCacheSettingsViewController () <UIViewControllerTransitioningDelegate>

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
    NSComparator _regionsComparator;
}

#pragma mark - Initialization

- (instancetype)initWithCacheType:(EOAWeatherCacheType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
    }
    return self;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
    }
    return self;
}

- (void)commonInit
{
    _weatherHelper = [OAWeatherHelper sharedInstance];

    _regionsComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
        NSString *name1 = [OAWeatherHelper checkAndGetRegionName:region1];
        NSString *name2 = [OAWeatherHelper checkAndGetRegionName:region2];
        return [name1 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedAscending
                : [name2 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedDescending
                    : [name1 localizedCaseInsensitiveCompare:name2];
    };
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);

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
                    OAWorldRegion *region = countryData[@"region"];
                        [_weatherHelper calculateCacheSize:region onComplete:^()
                        {
                            uint64_t size = [_weatherHelper getOfflineForecastSize:region forUpdate:NO];
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

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (_region)
        return OALocalizedString(@"shared_string_updates_size");
    else if (_type == EOAWeatherOnlineData)
        return OALocalizedString(@"weather_online_cache");
    else if (_type == EOAWeatherOfflineData)
        return OALocalizedString(@"weather_offline_forecast");

    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *infoCells = [NSMutableArray array];
    NSString *sizeTitle = @"";
    CGFloat size = 0.;
    if (_region)
    {
        sizeTitle = OALocalizedString(@"shared_string_total");
        size = [_weatherHelper getOfflineForecastSize:_region forUpdate:NO];
    }
    else if (_type == EOAWeatherOnlineData)
    {
        sizeTitle = OALocalizedString(@"shared_string_size");
        size = _weatherHelper.onlineCacheSize;
    }
    else if (_type == EOAWeatherOfflineData)
    {
        sizeTitle = OALocalizedString(@"shared_string_total_size");
        size = [_weatherHelper getOfflineWeatherForecastCacheSize];
    }

    NSString *sizeString = _region != nil || size > 0
            ? [NSByteCountFormatter stringFromByteCount:size
                                             countStyle:NSByteCountFormatterCountStyleFile]
            : OALocalizedString(@"calculating_progress");

    [infoCells addObject:@{
            @"key": @"size",
            @"title": sizeTitle,
            @"value": sizeString,
            @"type": [OAValueTableViewCell getCellIdentifier]
    }];
    [data addObject:@{ @"cells": infoCells }];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSDictionary *> *clearCells = [NSMutableArray array];
    NSString *clearTitle = @"";
    if (_region)
        clearTitle = OALocalizedString(@"shared_string_delete");
    else if (_type == EOAWeatherOnlineData)
        clearTitle = OALocalizedString(@"shared_string_clear");
    else if (_type == EOAWeatherOfflineData)
        clearTitle = OALocalizedString(@"shared_string_delete_all");
    [_type == EOAWeatherOnlineData ? clearCells : infoCells addObject:@{
            @"key": @"clear",
            @"title": clearTitle,
            @"type": [OASimpleTableViewCell getCellIdentifier]
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

        OsmAndAppInstance app = [OsmAndApp instance];
        NSArray<NSString *> *regionIds = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];
        NSArray<OAWorldRegion *> *regions = [[app.worldRegion getFlattenedSubregions:regionIds] sortedArrayUsingComparator:_regionsComparator];
        if ([regionIds containsObject:app.worldRegion.regionId])
            regions = [@[app.worldRegion] arrayByAddingObjectsFromArray:regions];

        for (OAWorldRegion *region in regions)
        {
            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
            if ([regionIds containsObject:regionId])
            {
                NSMutableDictionary *regionData = [NSMutableDictionary dictionary];
                regionData[@"key"] = [@"region_cell_" stringByAppendingString:regionId];
                regionData[@"type"] = [OARightIconTableViewCell getCellIdentifier];
                regionData[@"region"] = region;
                regionData[@"description"] = [NSByteCountFormatter stringFromByteCount:[_weatherHelper getOfflineForecastSize:region forUpdate:NO]
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

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return  _data[section][@"header"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
        }
        if (cell)
        {
            BOOL isClear = [item[@"key"] isEqualToString:@"clear"];
            cell.selectionStyle = isClear && _clearButtonActive ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = isClear ? _clearButtonActive ? [UIColor colorNamed:ACColorNameButtonBgColorDisruptive] : [UIColor colorNamed:ACColorNameTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.textStackView.alignment = isClear && _type == EOAWeatherOnlineData ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
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
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
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

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
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

        UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_clear")
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
}

#pragma mark - Additions

- (void)updateCacheSize
{
    if (_region)
    {
        [_weatherHelper calculateCacheSize:_region onComplete:^() {
            if (_sizeIndexPath)
            {
                uint64_t size = [_weatherHelper getOfflineForecastSize:_region forUpdate:NO];
                NSMutableArray<NSDictionary *> *cells = _data[_sizeIndexPath.section][@"cells"];
                NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size
                                                                      countStyle:NSByteCountFormatterCountStyleFile];
                cells[_sizeIndexPath.row] = @{
                    @"key": @"size",
                    @"title": OALocalizedString(@"shared_string_total"),
                    @"value": sizeString,
                    @"type": [OAValueTableViewCell getCellIdentifier]
                };
                _clearButtonActive = size > 0;
                
                NSArray<NSIndexPath *> *indexPaths = _clearIndexPath != nil ? @[_sizeIndexPath, _clearIndexPath] : @[_sizeIndexPath];
                [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
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
                            @"title": OALocalizedString(_type == EOAWeatherOnlineData ? @"shared_string_size" : @"shared_string_total_size"),
                            @"value": sizeString,
                            @"type": [OAValueTableViewCell getCellIdentifier]
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
    BOOL isOffline = _type == EOAWeatherOfflineData;
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
            if (isOffline)
            {
                [_weatherHelper removeLocalForecast:region.regionId region:region refreshMap:YES];
            }
            else
            {
                [_weatherHelper clearCache:YES regionIds:@[[OAWeatherHelper checkAndGetRegionId:region]] region:_region];
            }
        }
        else
        {
            if (isOffline)
            {
                NSArray<NSString *> *regionIds = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];
                OsmAndAppInstance app = [OsmAndApp instance];
                for (OAWorldRegion *region in [@[app.worldRegion] arrayByAddingObjectsFromArray:app.worldRegion.flattenedSubregions])
                {
                    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
                    if ([regionIds containsObject:regionId])
                    {
                        [_weatherHelper removeLocalForecast:region.regionId region:region refreshMap:YES];
                    }
                }
            }
            else
            {
                [_weatherHelper clearCache:NO regionIds:nil region:nil];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self generateData];
            [self.tableView reloadData];
        });
    } completionBlock:^{
        if (selectedRegionList)
        {
            NSMutableArray<NSMutableDictionary *> *countryCells = _data[_selectedRegionIndexPath.section][@"cells"];
            if (countryCells.count > 0)
            {
                _selectedRegionIndexPath = nil;
            }
            else
            {
                [self dismissViewController];
            }
        }
        else
        {
            [self dismissViewController];
        }
        if (self.cacheDelegate)
            [self.cacheDelegate onCacheClear];
    }];
}

@end
