//
//  OAWeatherForecastViewController.mm
//  OsmAnd
//
//  Created by Skalii on 22.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherForecastViewController.h"
#import "OAWeatherCacheSettingsViewController.h"
#import "OAWeatherForecastDetailsViewController.h"
#import "MBProgressHUD.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OsmAndApp.h"
#import "OAWeatherHelper.h"
#import "OADownloadingCellResourceHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OAResourcesUIHelper.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OAManageResourcesViewController.h"
#import "GeneratedAssetSymbols.h"

@interface OAWeatherForecastViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, OATableViewCellDelegate, OAWeatherCacheSettingsDelegate, OAWeatherForecastDetails, OADownloadingCellResourceHelperDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OAWeatherForecastViewController
{
    OsmAndAppInstance _app;
    OAWeatherHelper *_weatherHelper;
    OADownloadingCellResourceHelper *_downloadingCellResourceHelper;
    MBProgressHUD *_progressHUD;
    BOOL _editMode;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_selectedIndexPath;

    NSMutableArray<NSMutableDictionary *> *_data;
    NSArray<OAWorldRegion *> *_filteredRegions;
    NSMutableArray<OAWorldRegion *> *_regionsSelected;
    NSMutableArray<OAWorldRegion *> *_regionsWithOfflineMaps;
    NSMutableArray<OAWorldRegion *> *_regionsOtherCountries;
    NSComparator _regionsComparator;

    NSObject *_searchDataLock;
    NSArray<OAWorldRegion *> *_searchResults;
    NSString *_searchText;
    
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_applyButton;
    UISearchController *_searchController;
    
    NSMutableDictionary <NSString *, OAResourceItem *> *_cachedResources;
    
    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _editMode = NO;
    _weatherHelper = [OAWeatherHelper sharedInstance];

    _searchDataLock = [[NSObject alloc] init];
    _searchResults = @[];

    _regionsSelected = [NSMutableArray array];
    _regionsWithOfflineMaps = [NSMutableArray array];
    _regionsOtherCountries = [NSMutableArray array];
    _regionsComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
        NSString *name1 = [OAWeatherHelper checkAndGetRegionName:region1];
        NSString *name2 = [OAWeatherHelper checkAndGetRegionName:region2];
        return [name1 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedAscending
                : [name2 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedDescending
                    : [name1 localizedCaseInsensitiveCompare:name2];
    };
    
    _cachedResources = [NSMutableDictionary dictionary];
    
    _weatherSizeCalculatedObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                       andObserve:_weatherHelper.weatherSizeCalculatedObserver];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.navigationItem.title = OALocalizedString(@"weather_offline_forecast");

    NSPredicate *onlyWeatherPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return [OAWeatherHelper shouldHaveWeatherForecast:evaluatedObject];
    }];
    _filteredRegions = [@[_app.worldRegion] arrayByAddingObjectsFromArray:
        [[_app.worldRegion.flattenedSubregions filteredArrayUsingPredicate:onlyWeatherPredicate] sortedArrayUsingComparator:_regionsComparator]];

    [self setupView];
    [self setupDownloadingCellHelper];
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    [self setupSearchControllerWithFilter:NO];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    _cancelButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_cancel") style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    _editButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_edit") style:UIBarButtonItemStylePlain target:self action:@selector(onEditButtonClicked:)];
    _applyButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_apply") style:UIBarButtonItemStylePlain target:self action:@selector(onEditButtonClicked:)];
    
    if ([_weatherHelper getRegionIdsForDownloadedWeatherForecast].count != 0)
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_editButton animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_weatherSizeCalculatedObserver)
    {
        _weatherSizeCalculatedObserver =
                [[OAAutoObserverProxy alloc] initWith:self
                                          withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                           andObserve:_weatherHelper.weatherSizeCalculatedObserver];
    }

    if (!_editMode)
        [self updateCacheSize];
    
    if (_downloadingCellResourceHelper)
        [_downloadingCellResourceHelper refreshCellSpinners];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_weatherSizeCalculatedObserver)
    {
        [_weatherSizeCalculatedObserver detach];
        _weatherSizeCalculatedObserver = nil;
    }
}

- (void) setupDownloadingCellHelper
{
    _downloadingCellResourceHelper = [[OADownloadingCellResourceHelper alloc] init];
    _downloadingCellResourceHelper.hostTableView = self.tableView;
    _downloadingCellResourceHelper.isAlwaysClickable = YES;
    _downloadingCellResourceHelper.isShevronInsteadRightIcon = YES;
}

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];
    NSArray<NSString *> *forecastsWithDownloadState = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];

    if (_editMode)
    {
        NSMutableArray<NSMutableDictionary *> *selectedCells = [NSMutableArray array];
        NSMutableDictionary *selectedSection = [NSMutableDictionary dictionary];
        selectedSection[@"key"] = @"selected_section";
        selectedSection[@"header"] = OALocalizedString(@"shared_string_selected");
        selectedSection[@"cells"] = selectedCells;
        [data addObject:selectedSection];

        NSMutableArray<NSMutableDictionary *> *withOfflineMapsCells = [NSMutableArray array];
        NSMutableDictionary *withOfflineMapsSection = [NSMutableDictionary dictionary];
        withOfflineMapsSection[@"key"] = @"with_offline_maps_section";
        withOfflineMapsSection[@"header"] = OALocalizedString(@"with_offline_maps");
        withOfflineMapsSection[@"cells"] = withOfflineMapsCells;
        [data addObject:withOfflineMapsSection];

        NSMutableArray<NSMutableDictionary *> *otherCountriesCells = [NSMutableArray array];
        NSMutableDictionary *otherCountriesSection = [NSMutableDictionary dictionary];
        otherCountriesSection[@"key"] = @"other_countries_section";
        otherCountriesSection[@"header"] = OALocalizedString(@"other_countries");
        otherCountriesSection[@"cells"] = otherCountriesCells;
        [data addObject:otherCountriesSection];

        BOOL needInitEditingRegions = _regionsSelected.count == 0 && _regionsOtherCountries.count == 0;
        BOOL isFiltering = _searchText.length > 0;
        NSArray *regions = isFiltering ? _searchResults : _filteredRegions;
        for (OAWorldRegion *region in regions)
        {
            NSMutableDictionary *forecastData = [NSMutableDictionary dictionary];
            forecastData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
            forecastData[@"region"] = region;

            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
            BOOL hasStateDownload = [forecastsWithDownloadState containsObject:regionId];
            if ([_regionsSelected containsObject:region] || (needInitEditingRegions && hasStateDownload))
            {
                forecastData[@"key"] = [@"selected_cell_" stringByAppendingString:regionId];
                [selectedCells addObject:forecastData];
                if (needInitEditingRegions)
                    [_regionsSelected addObject:region];
            }
            else if ([_regionsWithOfflineMaps containsObject:region])
            {
                forecastData[@"key"] = [@"with_offline_maps_cell_" stringByAppendingString:regionId];
                [withOfflineMapsCells addObject:forecastData];
            }
            else if ([_regionsOtherCountries containsObject:region] || (needInitEditingRegions && !hasStateDownload))
            {
                forecastData[@"key"] = [@"other_countries_cell_" stringByAppendingString:regionId];
                [otherCountriesCells addObject:forecastData];
                if (needInitEditingRegions)
                    [_regionsOtherCountries addObject:region];
            }
        }
    }
    else
    {
        if (forecastsWithDownloadState.count == 0)
        {
            NSMutableArray<NSMutableDictionary *> *emptyCells = [NSMutableArray array];
            NSMutableDictionary *emptySection = [NSMutableDictionary dictionary];
            emptySection[@"key"] = @"empty_section";
            emptySection[@"cells"] = emptyCells;

            NSMutableDictionary *emptyData = [NSMutableDictionary dictionary];
            emptyData[@"key"] = @"empty_cell";
            emptyData[@"type"] = [OALargeImageTitleDescrTableViewCell getCellIdentifier];
            emptyData[@"title"] = OALocalizedString(@"weather_miss_forecasts");
            emptyData[@"description"] = OALocalizedString(@"weather_miss_forecasts_description");
            emptyData[@"icon"] = @"ic_custom_umbrella";
            emptyData[@"icon_color"] = [UIColor colorNamed:ACColorNameIconColorDisabled];
            emptyData[@"button_title"] = OALocalizedString(@"shared_string_select");
            [emptyCells addObject:emptyData];

            NSMutableDictionary *selectData = [NSMutableDictionary dictionary];
            selectData[@"key"] = @"select_cell";
            selectData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
            selectData[@"title"] = OALocalizedString(@"shared_string_select");
            selectData[@"title_color"] = [UIColor colorNamed:ACColorNameIconColorActive];
            selectData[@"title_font"] = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            [emptyCells addObject:selectData];

            [data addObject:emptySection];
        }
        else
        {
            NSMutableArray<NSMutableDictionary *> *updateCells = [NSMutableArray array];
            NSMutableDictionary *updateSection = [NSMutableDictionary dictionary];
            updateSection[@"key"] = @"update_section";
            updateSection[@"cells"] = updateCells;

            NSMutableDictionary *updateAllData = [NSMutableDictionary dictionary];
            updateAllData[@"key"] = @"update_cell_all";
            updateAllData[@"type"] = [OARightIconTableViewCell getCellIdentifier];
            updateAllData[@"title"] = OALocalizedString(@"res_update_all");
            updateAllData[@"right_icon"] = @"ic_custom_download";
            [updateCells addObject:updateAllData];

            [data addObject:updateSection];

            NSMutableArray<NSMutableDictionary *> *statusCells = [NSMutableArray array];
            NSMutableDictionary *statusSection = [NSMutableDictionary dictionary];
            statusSection[@"key"] = @"status_section";
            statusSection[@"header"] = OALocalizedString(@"shared_string_status");
            statusSection[@"cells"] = statusCells;
            double totalSize = 0.0;
            for (OAWorldRegion *region in _filteredRegions)
            {
                NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
                if ([forecastsWithDownloadState containsObject:regionId])
                {
                    NSMutableDictionary *offlineForecastData = [NSMutableDictionary dictionary];
                    offlineForecastData[@"key"] = [@"status_cell_" stringByAppendingString:regionId];
                    offlineForecastData[@"type"] = @"downloading_cell";
                    offlineForecastData[@"region"] = region;
                    NSString *resourceId = [region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"];
                    auto task = [self getDownloadTaskFor:resourceId];
                    NSString *title = [OAWeatherHelper checkAndGetRegionName:region];
                    offlineForecastData[@"title"] = title;
                    offlineForecastData[@"description"] = task && task.state == OADownloadTaskStateRunning
                            ? [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_download_update")
                                                              attributes:@{
                                                                      NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
                                                                      NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorSecondary]
                                                              }]
                            : [OAWeatherHelper getStatusInfoDescription:regionId];
                    OAResourceItem *resourceItem = [self getResourceByRegion:region];
                    offlineForecastData[@"resource"] = resourceItem;
                    offlineForecastData[@"resourceId"] = resourceId;
                    [statusCells addObject:offlineForecastData];
                    totalSize += [_weatherHelper getOfflineForecastSize:region forUpdate:NO];
                }
            }

            [data addObject:statusSection];

            NSMutableArray<NSMutableDictionary *> *dataCells = [NSMutableArray array];
            NSMutableDictionary *dataSection = [NSMutableDictionary dictionary];
            dataSection[@"key"] = @"data_section";
            dataSection[@"header"] = OALocalizedString(@"data_settings");
            dataSection[@"cells"] = dataCells;

            NSMutableDictionary *totalSizeData = [NSMutableDictionary dictionary];
            totalSizeData[@"key"] = @"data_cell_size";
            totalSizeData[@"type"] = [OAValueTableViewCell getCellIdentifier];
            totalSizeData[@"title"] = OALocalizedString(@"shared_string_total_size");
            NSString *sizeString = totalSize > 0
                    ? [NSByteCountFormatter stringFromByteCount:totalSize
                                                     countStyle:NSByteCountFormatterCountStyleFile]
                    : OALocalizedString(@"calculating_progress");
            totalSizeData[@"value"] = sizeString;
            [dataCells addObject:totalSizeData];

            [data addObject:dataSection];

            _sizeIndexPath = [NSIndexPath indexPathForRow:dataCells.count - 1 inSection:data.count - 1];
        }
    }

    _data = data;
}

- (void)updateCacheSize
{
    [self updateCacheSize:nil];
}

- (void)updateCacheSize:(void (^)())onComplete
{
    if (!_sizeIndexPath)
        return;
    
    [_weatherHelper calculateFullCacheSize:YES onComplete:^(unsigned long long size)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_editMode || !_sizeIndexPath)
                return;

            NSMutableDictionary *totalSizeData = _data[_sizeIndexPath.section][@"cells"][_sizeIndexPath.row];
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
            totalSizeData[@"value"] = sizeString;
            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
            if (onComplete)
                onComplete();
        });
    }];
}

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    if (_editMode)
        return;

    [self updateCacheSize:^{
        OAWorldRegion *region = (OAWorldRegion *) value;
        NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
        for (NSInteger i = 0; i < _data.count; i++)
        {
            NSDictionary *section = _data[i];
            if ([section[@"key"] isEqualToString:@"status_section"])
            {
                NSIndexPath *indexPath;
                NSMutableArray *statusCells = (NSMutableArray *) section[@"cells"];
                for (NSInteger j = 0; j < statusCells.count; j++)
                {
                    NSDictionary *cell = statusCells[j];
                    NSString *regionId_ = [OAWeatherHelper checkAndGetRegionId:((OAWorldRegion *) cell[@"region"])];
                    if ([regionId_ isEqualToString:regionId])
                    {
                        indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                        break;
                    }
                }
                
                if (indexPath)
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        statusCells[indexPath.row][@"description"] = [OAWeatherHelper getStatusInfoDescription:regionId];
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    });
                }
            }
        }
    }];
}

- (void)rearrangeForecast:(NSIndexPath *)indexPath
{
    NSMutableDictionary *item = [self getItem:indexPath];
    OAWorldRegion *region = (OAWorldRegion *) item[@"region"];
    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
    BOOL forecastWithDownloadState = [[_weatherHelper getRegionIdsForDownloadedWeatherForecast] containsObject:regionId];

    NSMutableDictionary *currentSection = _data[indexPath.section];
    NSMutableDictionary *destinationSection;
    for (NSInteger i = 0; i < _data.count; i++)
    {
        if (indexPath.section != i)
        {
            NSMutableDictionary *section = _data[i];
            if (forecastWithDownloadState && [section[@"key"] isEqualToString:@"with_offline_maps_section"])
            {
                destinationSection = section;
                item[@"key"] = [@"with_offline_maps_cell_" stringByAppendingString:regionId];
                [_regionsSelected removeObject:region];
                [_regionsWithOfflineMaps addObject:region];
                [_regionsOtherCountries removeObject:region];
                break;
            }
            else if (!forecastWithDownloadState && [section[@"key"] isEqualToString:@"other_countries_section"])
            {
                destinationSection = section;
                item[@"key"] = [@"other_countries_cell_" stringByAppendingString:regionId];
                [_regionsSelected removeObject:region];
                [_regionsWithOfflineMaps removeObject:region];
                [_regionsOtherCountries addObject:region];
                break;
            }
            else if ([section[@"key"] isEqualToString:@"selected_section"])
            {
                destinationSection = section;
                item[@"key"] = [@"selected_cell_" stringByAppendingString:regionId];
                [_regionsSelected addObject:region];
                [_regionsWithOfflineMaps removeObject:region];
                [_regionsOtherCountries removeObject:region];
                break;
            }
        }
    }

    if (!destinationSection)
        return;

    NSMutableArray *destinationCells = (NSMutableArray *) destinationSection[@"cells"];
    [((NSMutableArray *) currentSection[@"cells"]) removeObject:item];
    [destinationCells addObject:item];

    [destinationCells sortUsingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
        NSString *name1 = [OAWeatherHelper checkAndGetRegionName:dict1[@"region"]];
        NSString *name2 = [OAWeatherHelper checkAndGetRegionName:dict2[@"region"]];
        return [name1 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedAscending
                : [name2 isEqualToString:OALocalizedString(@"weather_entire_world")] ? NSOrderedDescending
                    : [name1 localizedCaseInsensitiveCompare:name2];
    }];

    NSIndexPath *targetPath = [NSIndexPath indexPathForRow:[destinationCells indexOfObject:item]
                                                 inSection:[_data indexOfObject:destinationSection]];

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.tableView reloadData];
    }];
    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetPath];
    [self.tableView endUpdates];
    [CATransaction commit];
}

- (void)showProgressView:(NSString *)title
            countOfItems:(NSInteger)countOfItems
             onExecuting:(dispatch_block_t)onExecuting
              onComplete:(MBProgressHUDCompletionBlock)onComplete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (countOfItems > 0)
        {
            UIAlertController *alert =
                    [UIAlertController alertControllerWithTitle:OALocalizedString(@"weather_remove_forecast")
                                                        message:[NSString stringWithFormat:OALocalizedString(@"weather_remove_forecasts_description"), countOfItems]
                                                 preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:nil];

            UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_remove")
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action)
                                                                     {
                                                                         _progressHUD.labelText = title;
                                                                         [_progressHUD showAnimated:YES whileExecutingBlock:^{
                                                                             onExecuting();
                                                                             [_regionsOtherCountries addObjectsFromArray:_regionsWithOfflineMaps];
                                                                             [_regionsWithOfflineMaps removeAllObjects];
                                                                             [_regionsOtherCountries sortUsingComparator:_regionsComparator];
                                                                             } completionBlock:onComplete];
                                                                          [self setNeedsStatusBarAppearanceUpdate];
                                                                     }
            ];

            [alert addAction:cancelAction];
            [alert addAction:clearCacheAction];

            alert.preferredAction = clearCacheAction;

            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            if (onExecuting)
                onExecuting();
            if (onComplete)
                onComplete();
        }
    });
}

- (void)setupSearchControllerWithFilter:(BOOL)isFiltered
{
    if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorNamed:ACColorNameTextColorTertiary]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
}

- (void)updateSearchBarVisible
{
    if (_editMode)
    {
        self.navigationItem.searchController = _searchController;
    }
    else
    {
        [self setupSearchControllerWithFilter:NO];
        _searchController.active = NO;
        self.navigationItem.searchController = nil;
    }
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (void)cancelChangesInEditMode
{
    [_regionsSelected.copy enumerateObjectsUsingBlock:^(OAWorldRegion *region, NSUInteger idx, BOOL * stop) {
        if ([_weatherHelper isUndefinedDownloadStateFor:region])
        {
            [_regionsOtherCountries addObject:region];
            [_regionsSelected removeObject:region];
        }
    }];

    [_regionsSelected addObjectsFromArray:_regionsWithOfflineMaps];
    [_regionsWithOfflineMaps removeAllObjects];
    [_regionsSelected sortUsingComparator:_regionsComparator];
    [_regionsOtherCountries sortUsingComparator:_regionsComparator];
}

- (void)onLeftNavbarButtonPressed
{
    dispatch_block_t executingBlock = ^{
        _editMode = NO;
        _searchResults = @[];
        _searchText = @"";
        
        [self cancelChangesInEditMode];
    };
    
    MBProgressHUDCompletionBlock completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.tableView
                              duration:0.35f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^(void)
             {
                self.navigationItem.title = OALocalizedString(@"weather_offline_forecast");
                [self.navigationController.navigationBar.topItem setLeftBarButtonItem:nil animated:YES];
                
                [self updateSearchBarVisible];
                [self setupView];
                [self.tableView setContentOffset:CGPointZero animated:NO];
                [self.tableView reloadData];
                
                NSArray<NSString *> *regionIds = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];
                if (regionIds.count == 0)
                {
                    [self.navigationController.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
                    _sizeIndexPath = nil;
                }
                else
                {
                    [self.navigationController.navigationBar.topItem setRightBarButtonItem:_editButton animated:YES];
                }
            }
                            completion:^(BOOL finished)
             {
                [self updateCacheSize];
            }
            ];
        });
    };
    [self showProgressView:@""
              countOfItems:0
               onExecuting:executingBlock
                onComplete:completionBlock];
}

- (IBAction)onEditButtonClicked:(id)sender
{
    NSString *progressTitle = @"";
    dispatch_block_t deletionBlock;
    dispatch_block_t downloadingBlock;
    NSInteger countOfItems = 0;

    NSMutableArray<NSString *> *forecastsToDownload = [NSMutableArray array];
    NSMutableArray<OAWorldRegion *> *forecastRegionsToDownload = [NSMutableArray array];
    NSMutableArray<NSString *> *forecastsToDelete = [NSMutableArray array];

    if (_editMode)
    {
        NSArray<NSString *> *forecastsWithDownloadStates = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];
        for (OAWorldRegion *region in _regionsSelected)
        {
            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
            if (![forecastsWithDownloadStates containsObject:regionId])
            {
                [forecastsToDownload addObject:regionId];
                [forecastRegionsToDownload addObject:region];
            }
        }

        for (OAWorldRegion *region in _regionsWithOfflineMaps)
        {
            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
            if ([forecastsWithDownloadStates containsObject:regionId])
                [forecastsToDelete addObject:regionId];
        }

        countOfItems = forecastsToDelete.count;
        if (countOfItems > 0)
        {
            progressTitle = OALocalizedString(@"res_deleting");
            deletionBlock = ^{
                
                NSUInteger index = 0;
                for (NSString *regionId in forecastsToDelete)
                {
                    [_weatherHelper removeLocalForecasts:@[regionId] region:_regionsWithOfflineMaps[index] refreshMap:YES];
                    index++;
                }
                [forecastsToDelete removeAllObjects];
            };
        }

        if (forecastsToDownload.count > 0)
        {
            downloadingBlock = ^{
                if (!AFNetworkReachabilityManager.sharedManager.isReachable)
                {
                    [OAResourcesUIHelper showNoInternetAlert];
                    [forecastsToDownload removeAllObjects];
                    [forecastRegionsToDownload removeAllObjects];
                }
                else if (AFNetworkReachabilityManager.sharedManager.isReachableViaWiFi)
                {
                    [_weatherHelper downloadForecastsByRegionIds:forecastsToDownload];
                    [forecastsToDownload removeAllObjects];
                    [forecastRegionsToDownload removeAllObjects];
                }
                else
                {
                    NSInteger sizeUpdates = 0;
                    for (OAWorldRegion *region in forecastRegionsToDownload)
                    {
                        sizeUpdates += [_weatherHelper getOfflineForecastSize:region forUpdate:YES];
                    }
                    NSString *stringifiedSize = [NSByteCountFormatter stringFromByteCount:sizeUpdates
                                                                               countStyle:NSByteCountFormatterCountStyleFile];
                    NSMutableString *message = [NSMutableString stringWithFormat:OALocalizedString(@"res_inst_avail_cell_q"),
                            OALocalizedString(@"weather_forecast"), stringifiedSize];
                    [message appendString:@" "];
                    [message appendString:OALocalizedString(@"incur_high_charges")];
                    [message appendString:@" "];
                    [message appendString:OALocalizedString(@"proceed_q")];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                   message:message
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_install")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action)
                    {
                        [_weatherHelper downloadForecastsByRegionIds:forecastsToDownload];
                        [forecastsToDownload removeAllObjects];
                        [forecastRegionsToDownload removeAllObjects];
                    }]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            };
        }
    }

    dispatch_block_t executingBlock = ^{
        _editMode = !_editMode;
        _searchResults = @[];
        _searchText = @"";

        if (deletionBlock)
            deletionBlock();

        if (downloadingBlock)
            downloadingBlock();
    };

    MBProgressHUDCompletionBlock completionBlock = ^{
            [UIView transitionWithView:self.tableView
                              duration:0.35f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^(void)
                            {
                                [self updateSearchBarVisible];

                                self.navigationItem.title = OALocalizedString(_editMode ? @"shared_string_edit" : @"weather_offline_forecast");
                                [self.navigationController.navigationBar.topItem setLeftBarButtonItem: _editMode ? _cancelButton : nil animated:YES];
                                [self setupView];
                                [self.tableView setContentOffset:CGPointZero animated:NO];
                                [self.tableView reloadData];

                                if (_editMode)
                                {
                                    [self.navigationController.navigationBar.topItem setRightBarButtonItem:_applyButton animated:YES];
                                    _sizeIndexPath = nil;
                                }
                                else
                                {
                                    NSArray<NSString *> *forecastsWithDownloadStates = [_weatherHelper getRegionIdsForDownloadedWeatherForecast];
                                    if (forecastsWithDownloadStates.count > 0)
                                    {
                                        [self.navigationController.navigationBar.topItem setRightBarButtonItem: _editMode ? _applyButton : _editButton animated:YES];
                                    }
                                    else
                                    {
                                        _sizeIndexPath = nil;
                                    }
                                    if (forecastsWithDownloadStates.count != 0)
                                        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_editButton animated:YES];
                                    else
                                        [self.navigationController.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
                                }
                            }
                            completion: ^(BOOL finished)
                            {
                                [self updateCacheSize];
                            }
            ];
    };

    [self showProgressView:progressTitle
              countOfItems:countOfItems
               onExecuting:executingBlock
                onComplete:completionBlock];
}

- (void)performSearchForSearchString:(NSString *)searchString
{
    @synchronized (_searchDataLock)
    {
        if (searchString == nil || [searchString length] == 0 || [[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
        {
            [self setupSearchControllerWithFilter:NO];
            _searchResults = @[];
            [self setupView];
            [self.tableView reloadData];
            return;
        }

        NSPredicate *startsWithPredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", searchString];
        NSArray<OAWorldRegion *> *startsWithResult = [_filteredRegions filteredArrayUsingPredicate:startsWithPredicate];
        if (startsWithResult.count == 0)
        {
            NSPredicate *anyStartsWithPredicate = [NSPredicate predicateWithFormat:@"ANY allNames BEGINSWITH[cd] %@", searchString];
            startsWithResult = [_filteredRegions filteredArrayUsingPredicate:anyStartsWithPredicate];
        }

        NSPredicate *onlyContainsPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) AND NOT (name BEGINSWITH[cd] %@)", searchString, searchString];
        NSArray<OAWorldRegion *> *onlyContainsResult = [_filteredRegions filteredArrayUsingPredicate:onlyContainsPredicate];
        if (onlyContainsResult.count == 0)
        {
            NSPredicate *anyOnlyContains = [NSPredicate predicateWithFormat:
                    @"(ANY allNames CONTAINS[cd] %@) AND NOT (ANY allNames BEGINSWITH[cd] %@)",
                    searchString,
                    searchString];
            onlyContainsResult = [_filteredRegions filteredArrayUsingPredicate:anyOnlyContains];
        }

        _searchResults = [[startsWithResult arrayByAddingObjectsFromArray:onlyContainsResult] sortedArrayUsingComparator:_regionsComparator];
        [self setupSearchControllerWithFilter:YES];
        [self setupView];
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    _searchText = searchText;
    [self performSearchForSearchString:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchText = @"";
    [self performSearchForSearchString:_searchText];
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
    
    if ([item[@"type"] isEqualToString:@"downloading_cell"])
    {
        OADownloadingCell *cell = [_downloadingCellResourceHelper getOrCreateCellForResourceId:item[@"resourceId"] resourceItem:item[@"resource"]];
        [cell leftIconVisibility:NO];
        [cell rightIconVisibility:NO];
        [cell descriptionVisibility:YES];
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.attributedText = item[@"description"];
        
        
        
        return cell;
    }
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.delegate = self;
        }
        if (cell)
        {
            OAWorldRegion *region = (OAWorldRegion *) item[@"region"];

            [cell leftEditButtonVisibility:_editMode];
            cell.selectionStyle = _editMode ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            cell.titleLabel.text = [item.allKeys containsObject:@"region"] ? [OAWeatherHelper checkAndGetRegionName:region] : item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.font = [item.allKeys containsObject:@"title_font"] ? item[@"title_font"] : [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            
            BOOL hasDescription = [item.allKeys containsObject:@"description"];
            [cell descriptionVisibility:hasDescription];
            cell.descriptionLabel.attributedText = hasDescription ? item[@"description"] : nil;

            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if (_editMode)
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textStackView.alignment = UIStackViewAlignmentLeading;

                NSString *imageName = [item[@"key"] hasPrefix:@"selected_"] ? @"ic_custom_delete" : @"ic_custom_plus";
                [cell.leftEditButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
                cell.leftEditButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.leftEditButton addTarget:self action:@selector(rearrangeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            }
            else
            {
                [cell.leftEditButton setImage:nil forState:UIControlStateNormal];
                BOOL isSelectCell = [item[@"key"] isEqualToString:@"select_cell"];
                cell.accessoryType = isSelectCell ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
                cell.textStackView.alignment = isSelectCell ? UIStackViewAlignmentCenter : UIStackViewAlignmentLeading;
                cell.accessoryView = nil;
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            cell.rightIconView.image = [UIImage templateImageNamed:item[@"right_icon"]];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 0., 0., 0.);
            [cell showButton:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];
            cell.cellImageView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.cellImageView.tintColor = item[@"icon_color"];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell setNeedsUpdateConstraints];

    return outCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"header"];
}

#pragma mark - UITableViewDelegate


- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _selectedIndexPath = indexPath;
    if ([item[@"key"] isEqualToString:@"update_cell_all"])
    {
        [_weatherHelper downloadForecastsByRegionIds:[_weatherHelper getRegionIdsForDownloadedWeatherForecast]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupView];
            [self.tableView reloadData];
        });
    }
    else if ([item[@"key"] hasPrefix:@"status_cell_"])
    {
        OAWorldRegion *region = (OAWorldRegion *) item[@"region"];
        NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
        if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
        {
            OAResourceItem *localResourceItem = item[@"resource"];
            if (localResourceItem) {
                OAWeatherForecastDetailsViewController *forecastDetailsViewController = [[OAWeatherForecastDetailsViewController alloc] initWithRegion:item[@"region"] localResourceItem:localResourceItem];
                forecastDetailsViewController.delegate = self;
                [self.navigationController pushViewController:forecastDetailsViewController animated:YES];
            }
        }
        else if ([self getDownloadTaskFor: [region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"]].state == OADownloadTaskStateRunning)
        {
            NSMutableString *message = [NSMutableString stringWithFormat:OALocalizedString(@"res_cancel_inst_q"),
                    [[OAWeatherHelper checkAndGetRegionName:((OAWorldRegion *) item[@"region"])] stringByAppendingString:[NSString stringWithFormat:@" - %@",
                            [OAResourceType resourceTypeLocalized:OsmAndResourceType::WeatherForecast]]]];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"data_will_be_lost")];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"proceed_q")];

            UIAlertController *alert =
                    [UIAlertController alertControllerWithTitle:message
                                                        message:nil
                                                 preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action)
                                                    {
                                                        [_progressHUD showAnimated:YES whileExecutingBlock:^{
                                                            if ([_weatherHelper isUndefinedDownloadStateFor:region])
                                                            {
                                                                [_weatherHelper removeLocalForecast:regionId region:item[@"region"] refreshMap:NO];
                                                                [((NSMutableArray *) _data[indexPath.section][@"cells"]) removeObjectAtIndex:indexPath.row];
                                                                [_regionsOtherCountries addObject:item[@"region"]];
                                                                [_regionsOtherCountries sortUsingComparator:_regionsComparator];
                                                                [_regionsSelected removeObject:item[@"region"]];
                                                            }
                                                            else if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
                                                            {
                                                                [_weatherHelper calculateCacheSize:item[@"region"] onComplete:nil];
                                                            }
                                                        } completionBlock:^{
                                                            if (_regionsSelected.count > 0)
                                                            {
                                                                if ([_weatherHelper isUndefinedDownloadStateFor:region])
                                                                {
                                                                    [CATransaction begin];
                                                                    [CATransaction setCompletionBlock:^{
                                                                        [self.tableView reloadData];
                                                                    }];
                                                                    [self.tableView beginUpdates];
                                                                    [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                    [self.tableView endUpdates];
                                                                    [CATransaction commit];
                                                                }
                                                                else if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
                                                                {
                                                                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                }
                                                                [self updateCacheSize];
                                                            }
                                                            else
                                                            {
                                                                [self.navigationController.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
                                                                _sizeIndexPath = nil;
                                                                [self setupView];
                                                                [self.tableView reloadData];
                                                            }
                                                        }];
                                                    }
            ]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no")
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([item[@"key"] isEqualToString:@"data_cell_size"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithCacheType:EOAWeatherOfflineData];
        controller.cacheDelegate = self;
        [self showModalViewController:controller];
    }
    else if ([item[@"key"] isEqualToString:@"select_cell"])
    {
        [self onEditButtonClicked:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (OAResourceItem *) getResourceByRegion:(OAWorldRegion *)region
{
    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
    if (_cachedResources[regionId])
        return _cachedResources[regionId];
    
    if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
    {
        NSString *resourceId = [region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"];
        const auto localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
        OAResourceItem *localResourceItem;
        if (localResource) {
            OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
            item.resourceId = localResource->id;
            item.resourceType = localResource->type;
            item.resource = localResource;
            item.downloadTask = [self getDownloadTaskFor:localResource->id.toNSString()];
            item.size = localResource->size;
            item.worldRegion = region;
            const auto repositoryResource = _app.resourcesManager->getResourceInRepository(item.resourceId);
            item.sizePkg = repositoryResource->packageSize;
            NSString *localResourcePath = _app.resourcesManager->getLocalResource(item.resourceId)->localPath.toNSString();
            item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResourcePath error:NULL] fileModificationDate];
            localResourceItem = item;
        } else {
            const auto& resource = _app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
            if (resource) {
                if (_app.resourcesManager->isResourceInstalled(resource->id))
                {
                    OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                    item.size = resource->size;
                    item.worldRegion = region;

                    const auto localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
                    item.resource = localResource;
                    item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];
                    localResourceItem = item;
                }
                else
                {
                    OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.resource = resource;
                    item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                    item.size = resource->size;
                    item.sizePkg = resource->packageSize;
                    item.worldRegion = region;
                    item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
                    localResourceItem = item;
                }
            }
        }
        _cachedResources[regionId] = localResourceItem;
        return localResourceItem;
    }
    return nil;
}

#pragma mark - Selectors

- (void)rearrangeButtonPressed:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_searchController resignFirstResponder];
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateSearchBarVisible];
        [self setupView];
        [self.tableView setContentOffset:CGPointZero animated:NO];
        [self.tableView reloadData];
    });
}

#pragma mark - OAWeatherForecastDetails

- (void)onRemoveForecast
{
    if (_selectedIndexPath)
    {
        [_progressHUD showAnimated:YES whileExecutingBlock:^{
            NSDictionary *item = [self getItem:_selectedIndexPath];
            [((NSMutableArray *) _data[_selectedIndexPath.section][@"cells"]) removeObjectAtIndex:_selectedIndexPath.row];
            if (_regionsOtherCountries.count > 0)
            {
                [_regionsOtherCountries addObject:item[@"region"]];
                [_regionsOtherCountries sortUsingComparator:_regionsComparator];
            }
            [_regionsSelected removeObject:item[@"region"]];
        } completionBlock:^{
            if (_regionsSelected.count > 0)
            {
                [CATransaction begin];
                [CATransaction setCompletionBlock:^{
                    [self.tableView reloadData];
                }];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[_selectedIndexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                [CATransaction commit];
                [self updateCacheSize];
            }
            else
            {
                [self.navigationController.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
                _sizeIndexPath = nil;
                [self setupView];
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)onUpdateForecast
{
    if (_selectedIndexPath)
    {
        NSMutableDictionary *forecastCell = _data[_selectedIndexPath.section][@"cells"][_selectedIndexPath.row];
        OAWorldRegion *region = (OAWorldRegion *) forecastCell[@"region"];
        NSString *regionId = [OAWeatherHelper checkAndGetRegionId:region];
        forecastCell[@"description"] = [OAWeatherHelper getStatusInfoDescription:regionId];
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    [self rearrangeForecast:indexPath];
}

#pragma mark - OADownloadingCellResourceHelperDelegate

- (void)onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
        [self.tableView reloadData];
    });
}

@end
