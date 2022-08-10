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
#import "OATitleDescrRightIconTableViewCell.h"
#import "OADeleteButtonTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OsmAndApp.h"
#import "OAWeatherHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAResourcesUIHelper.h"
#import <Reachability.h>

@interface OAWeatherForecastViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, OAWeatherCacheSettingsDelegate, OAWeatherForecastDetails>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleWithSearchConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleNoSearchConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewWithSearchConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewNoSearchConstraint;

@end

@implementation OAWeatherForecastViewController
{
    OsmAndAppInstance _app;
    OAWeatherHelper *_weatherHelper;
    MBProgressHUD *_progressHUD;
    BOOL _editMode;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_selectedIndexPath;

    NSMutableArray<NSMutableDictionary *> *_data;
    NSArray<OAWorldRegion *> *_filteredRegions;
    NSMutableArray<OAWorldRegion *> *_regionsSelected;
    NSMutableArray<OAWorldRegion *> *_regionsWithOfflineMaps;
    NSMutableArray<OAWorldRegion *> *_regionsOtherCountries;

    NSObject *_searchDataLock;
    NSArray<OAWorldRegion *> *_searchResults;
    NSString *_searchText;

    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
    OAAutoObserverProxy *_weatherForecastDownloadingObserver;
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

    _weatherSizeCalculatedObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                       andObserve:[OAWeatherHelper sharedInstance].weatherSizeCalculatedObserver];
    _weatherForecastDownloadingObserver =
            [[OAAutoObserverProxy alloc] initWith:self
                                      withHandler:@selector(onWeatherForecastDownloading:withKey:andValue:)
                                       andObserve:[OAWeatherHelper sharedInstance].weatherForecastDownloadingObserver];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    NSPredicate *onlyWeatherPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return [OAWeatherHelper shouldHaveWeatherForecast:evaluatedObject];
    }];

    NSComparator regionComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
        return [region1.name localizedCaseInsensitiveCompare:region2.name];
    };

    _filteredRegions = [[_app.worldRegion.flattenedSubregions filteredArrayUsingPredicate:onlyWeatherPredicate] sortedArrayUsingComparator:regionComparator];

    [self setupView];
    self.searchBar.delegate = self;
    [self updateSearchBarVisible];

    self.editButton.hidden = [_weatherHelper getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateInProgress), @(EOAWeatherForecastDownloadStateFinished)]].count == 0;

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_weatherSizeCalculatedObserver)
    {
        _weatherSizeCalculatedObserver =
                [[OAAutoObserverProxy alloc] initWith:self
                                          withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                           andObserve:[OAWeatherHelper sharedInstance].weatherSizeCalculatedObserver];
    }
    if (!_weatherForecastDownloadingObserver)
    {
        _weatherForecastDownloadingObserver =
                [[OAAutoObserverProxy alloc] initWith:self
                                          withHandler:@selector(onWeatherForecastDownloading:withKey:andValue:)
                                           andObserve:[OAWeatherHelper sharedInstance].weatherForecastDownloadingObserver];
    }

    if (!_editMode)
        [self updateCacheSize];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_weatherSizeCalculatedObserver)
    {
        [_weatherSizeCalculatedObserver detach];
        _weatherSizeCalculatedObserver = nil;
    }
    if (_weatherForecastDownloadingObserver)
    {
        [_weatherForecastDownloadingObserver detach];
        _weatherForecastDownloadingObserver = nil;
    }
}

- (void)applyLocalization
{
    [self.editButton setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
    self.titleLabel.text = OALocalizedString(@"weather_offline_forecast");
    self.searchBar.placeholder = OALocalizedString(@"shared_string_search");
}

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];
    NSArray<NSString *> *forecastsWithDownloadState = [_weatherHelper getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateInProgress), @(EOAWeatherForecastDownloadStateFinished)]];

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
            forecastData[@"type"] = [OADeleteButtonTableViewCell getCellIdentifier];
            forecastData[@"region"] = region;

            BOOL hasStateDownload = [OAWeatherHelper getPreferenceDownloadState:region.regionId] != EOAWeatherForecastDownloadStateUndefined;
            if ([_regionsSelected containsObject:region] || (needInitEditingRegions && hasStateDownload))
            {
                forecastData[@"key"] = [@"selected_cell_" stringByAppendingString:region.regionId];
                [selectedCells addObject:forecastData];
                if (needInitEditingRegions)
                    [_regionsSelected addObject:region];
            }
            else if ([_regionsWithOfflineMaps containsObject:region])
            {
                forecastData[@"key"] = [@"with_offline_maps_cell_" stringByAppendingString:region.regionId];
                [withOfflineMapsCells addObject:forecastData];
            }
            else if ([_regionsOtherCountries containsObject:region] || (needInitEditingRegions && !hasStateDownload))
            {
                forecastData[@"key"] = [@"other_countries_cell_" stringByAppendingString:region.regionId];
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
            emptyData[@"icon_color"] = UIColorFromRGB(color_tint_gray);
            emptyData[@"button_title"] = OALocalizedString(@"shared_string_select");
            [emptyCells addObject:emptyData];

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
            updateAllData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
            updateAllData[@"title"] = OALocalizedString(@"res_update_all");
            updateAllData[@"icon"] = @"ic_custom_download";
            [updateCells addObject:updateAllData];

            [data addObject:updateSection];

            NSMutableArray<NSMutableDictionary *> *statusCells = [NSMutableArray array];
            NSMutableDictionary *statusSection = [NSMutableDictionary dictionary];
            statusSection[@"key"] = @"status_section";
            statusSection[@"header"] = OALocalizedString(@"shared_string_status");
            statusSection[@"cells"] = statusCells;

            for (OAWorldRegion *region in _filteredRegions)
            {
                if ([forecastsWithDownloadState containsObject:region.regionId])
                {
                    NSMutableDictionary *offlineForecastData = [NSMutableDictionary dictionary];
                    offlineForecastData[@"key"] = [@"status_cell_" stringByAppendingString:region.regionId];
                    offlineForecastData[@"type"] = [OATitleDescrRightIconTableViewCell getCellIdentifier];
                    offlineForecastData[@"region"] = region;
                    offlineForecastData[@"description"] = [OAWeatherHelper getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateInProgress
                            ? [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_loading")
                                                              attributes:@{
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:13.],
                                                                      NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
                                                              }]
                            : [OAWeatherHelper getStatusInfoDescription:region.regionId];
                    [statusCells addObject:offlineForecastData];
                }
            }

            [data addObject:statusSection];

            NSMutableArray<NSMutableDictionary *> *dataCells = [NSMutableArray array];
            NSMutableDictionary *dataSection = [NSMutableDictionary dictionary];
            dataSection[@"key"] = @"data_section";
            dataSection[@"header"] = OALocalizedString(@"shared_string_data");
            dataSection[@"cells"] = dataCells;

            NSMutableDictionary *totalSizeData = [NSMutableDictionary dictionary];
            totalSizeData[@"key"] = @"data_cell_size";
            totalSizeData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
            totalSizeData[@"title"] = OALocalizedString(@"shared_string_total_size");
            totalSizeData[@"icon"] = @"menu_cell_pointer";
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:0 countStyle:NSByteCountFormatterCountStyleFile];
            totalSizeData[@"description"] = sizeString;
            [dataCells addObject:totalSizeData];

            [data addObject:dataSection];

            _sizeIndexPath = [NSIndexPath indexPathForRow:dataCells.count - 1 inSection:data.count - 1];
        }
    }

    _data = data;
}

- (void)updateCacheSize
{
    if (!_sizeIndexPath)
        return;

    [_weatherHelper calculateFullCacheSize:YES onComplete:^(unsigned long long size)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *totalSizeData = _data[_sizeIndexPath.section][@"cells"][_sizeIndexPath.row];
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
            totalSizeData[@"description"] = sizeString;
            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        });
    }];
}

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    if (_editMode)
        return;

    [self updateCacheSize];
}

- (void)onWeatherForecastDownloading:(id)sender withKey:(id)key andValue:(id)value
{
    if (_editMode)
        return;

    OAWorldRegion *region = (OAWorldRegion *) value;
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
                if ([((OAWorldRegion *) cell[@"region"]).regionId isEqualToString:region.regionId])
                {
                    indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                    break;
                }
            }

            if (indexPath)
            {
                BOOL statusSizeCalculating = ![[OAWeatherHelper sharedInstance] isOfflineForecastSizesInfoCalculated:region.regionId];
                if ([OAWeatherHelper getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateUndefined && !statusSizeCalculating)
                    return;

                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    if (!cell.accessoryView)
                    {
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        cell = [self.tableView cellForRowAtIndexPath:indexPath];
                    }

                    FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
                    NSInteger progressDownloading = [_weatherHelper getOfflineForecastProgressInfo:region.regionId];
                    NSInteger progressDownloadDestination = [[OAWeatherHelper sharedInstance] getProgressDestination:region.regionId];
                    CGFloat progressCompleted = (CGFloat) progressDownloading / progressDownloadDestination;
                    if (progressCompleted >= 0.001 && [OAWeatherHelper getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateInProgress)
                    {
                        progressView.iconPath = nil;
                        if (progressView.isSpinning)
                            [progressView stopSpinProgressBackgroundLayer];
                        progressView.progress = progressCompleted - 0.001;
                    }
                    else if ([OAWeatherHelper getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateFinished && !statusSizeCalculating)
                    {
                        progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                        progressView.progress = 0.;
                        if (!progressView.isSpinning)
                            [progressView startSpinProgressBackgroundLayer];

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            statusCells[indexPath.row][@"description"] = [OAWeatherHelper getStatusInfoDescription:region.regionId];
                            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        });
                    }
                    else
                    {
                        progressView.iconPath = statusSizeCalculating ? [OAResourcesUIHelper tickPath:progressView] : [UIBezierPath bezierPath];
                        progressView.progress = 0.;
                        if (!progressView.isSpinning)
                            [progressView startSpinProgressBackgroundLayer];
                        [progressView setNeedsDisplay];
                    }
                });
            }
            break;
        }
    }
}

- (void)rearrangeForecast:(NSIndexPath *)indexPath
{
    NSMutableDictionary *item = [self getItem:indexPath];
    OAWorldRegion *region = (OAWorldRegion *) item[@"region"];
    BOOL forecastWithDownloadState = [[_weatherHelper getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateInProgress), @(EOAWeatherForecastDownloadStateFinished)]] containsObject:region.regionId];

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
                item[@"key"] = [@"with_offline_maps_cell_" stringByAppendingString:region.regionId];
                [_regionsSelected removeObject:region];
                [_regionsWithOfflineMaps addObject:region];
                [_regionsOtherCountries removeObject:region];
                break;
            }
            else if (!forecastWithDownloadState && [section[@"key"] isEqualToString:@"other_countries_section"])
            {
                destinationSection = section;
                item[@"key"] = [@"other_countries_cell_" stringByAppendingString:region.regionId];
                [_regionsSelected removeObject:region];
                [_regionsWithOfflineMaps removeObject:region];
                [_regionsOtherCountries addObject:region];
                break;
            }
            else if ([section[@"key"] isEqualToString:@"selected_section"])
            {
                destinationSection = section;
                item[@"key"] = [@"selected_cell_" stringByAppendingString:region.regionId];
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

    [destinationCells sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        OAWorldRegion *item1 = obj1[@"region"];
        OAWorldRegion *item2 = obj2[@"region"];
        return [item1.name localizedCaseInsensitiveCompare:item2.name];
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
            NSComparator regionComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
                return [region1.name localizedCaseInsensitiveCompare:region2.name];
            };

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
                                                                             [_regionsOtherCountries sortUsingComparator:regionComparator];
                                                                             } completionBlock:onComplete];
                                                                     }
            ];

            [alert addAction:cancelAction];
            [alert addAction:clearCacheAction];

            alert.preferredAction = clearCacheAction;

            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            _progressHUD.labelText = title;
            [_progressHUD showAnimated:YES whileExecutingBlock:onExecuting completionBlock:onComplete];
        }
    });
}

- (void)updateSearchBarVisible
{
    self.searchBar.text = @"";
    if (_editMode)
    {
        self.searchBar.hidden = NO;

        self.titleWithSearchConstraint.active = YES;
        self.titleNoSearchConstraint.active = NO;

        self.tableViewWithSearchConstraint.active = YES;
        self.tableViewNoSearchConstraint.active = NO;
    }
    else
    {
        self.searchBar.hidden = YES;

        self.titleWithSearchConstraint.active = NO;
        self.titleNoSearchConstraint.active = YES;

        self.tableViewWithSearchConstraint.active = NO;
        self.tableViewNoSearchConstraint.active = YES;

        [self.searchBar resignFirstResponder];
    }

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (void)cancelChangesInEditMode
{
    [_regionsSelected enumerateObjectsUsingBlock:^(OAWorldRegion *region, NSUInteger idx, BOOL * stop) {
        if ([OAWeatherHelper getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateUndefined)
        {
            [_regionsOtherCountries addObject:region];
            [_regionsSelected removeObject:region];
        }
    }];

    [_regionsSelected addObjectsFromArray:_regionsWithOfflineMaps];
    [_regionsWithOfflineMaps removeAllObjects];

    NSComparator regionComparator = ^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
        return [region1.name localizedCaseInsensitiveCompare:region2.name];
    };
    [_regionsSelected sortUsingComparator:regionComparator];
    [_regionsOtherCountries sortUsingComparator:regionComparator];
}

- (IBAction)backButtonClicked:(id)sender
{
    if (_editMode)
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
                                    self.titleLabel.text = OALocalizedString(@"weather_offline_forecast");
                                    [_backButton setTitle:nil forState:UIControlStateNormal];
                                    [_backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];

                                    [self updateSearchBarVisible];

                                    [self setupView];
                                    [self.tableView setContentOffset:CGPointZero animated:NO];
                                    [self.tableView reloadData];

                                    NSArray<NSString *> *regionIds = [_weatherHelper getTempForecastsWithDownloadStates:@[
                                            @(EOAWeatherForecastDownloadStateInProgress),
                                            @(EOAWeatherForecastDownloadStateFinished)
                                    ]];
                                    if (regionIds.count == 0)
                                    {
                                        _editButton.hidden = YES;
                                        _sizeIndexPath = nil;
                                    }
                                    else
                                    {
                                        [_editButton setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
                                        _editButton.hidden = NO;
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
    else
    {
        [self dismissViewController];
    }
}

- (IBAction)onEditButtonClicked:(id)sender
{
    NSString *progressTitle = @"";
    dispatch_block_t deletionBlock;
    dispatch_block_t downloadingBlock;
    NSInteger countOfItems = 0;

    NSMutableArray<NSString *> *forecastsToDownload = [NSMutableArray array];
    NSMutableArray<NSString *> *forecastsToDelete = [NSMutableArray array];

    if (_editMode)
    {
        NSArray<NSString *> *forecastsWithDownloadStates = [_weatherHelper getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateInProgress), @(EOAWeatherForecastDownloadStateFinished)]];
        for (OAWorldRegion *region in _regionsSelected)
        {
            if (![forecastsWithDownloadStates containsObject:region.regionId])
                [forecastsToDownload addObject:region.regionId];
        }

        for (OAWorldRegion *region in _regionsWithOfflineMaps)
        {
            if ([forecastsWithDownloadStates containsObject:region.regionId])
                [forecastsToDelete addObject:region.regionId];
        }

        countOfItems = forecastsToDelete.count;
        if (countOfItems > 0)
        {
            progressTitle = OALocalizedString(@"res_deleting");
            deletionBlock = ^{
                for (NSString *regionId in forecastsToDelete)
                {
                    [_weatherHelper prepareToStopDownloading:regionId];
                }

                [_weatherHelper removeLocalForecasts:forecastsToDelete refreshMap:YES];
                [forecastsToDelete removeAllObjects];
            };
        }

        if (forecastsToDownload.count > 0)
        {
            downloadingBlock = ^{
                if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
                {
                    [OAResourcesUIHelper showNoInternetAlert];
                    [forecastsToDownload removeAllObjects];
                }
                else if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWiFi)
                {
                    [_weatherHelper downloadForecastsByRegionIds:forecastsToDownload];
                    [forecastsToDownload removeAllObjects];
                }
                else
                {
                    NSInteger sizeUpdates = 0;
                    for (NSString *regionId in forecastsToDownload)
                    {
                        sizeUpdates += [_weatherHelper getOfflineForecastSizeInfo:regionId local:NO];
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

                                self.titleLabel.text = OALocalizedString(_editMode ? @"shared_string_edit" : @"weather_offline_forecast");
                                [_backButton setTitle:_editMode ? OALocalizedString(@"shared_string_cancel") : nil
                                             forState:UIControlStateNormal];
                                [_backButton setImage:_editMode ? nil : [UIImage templateImageNamed:@"ic_navbar_chevron"]
                                             forState:UIControlStateNormal];

                                [self setupView];
                                [self.tableView setContentOffset:CGPointZero animated:NO];
                                [self.tableView reloadData];

                                if (_editMode)
                                {
                                    [_editButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
                                    _editButton.hidden = NO;
                                    _sizeIndexPath = nil;
                                }
                                else
                                {
                                    NSArray<NSString *> *forecastsWithDownloadStates = [_weatherHelper getTempForecastsWithDownloadStates:@[
                                            @(EOAWeatherForecastDownloadStateInProgress),
                                            @(EOAWeatherForecastDownloadStateFinished)
                                    ]];
                                    if (forecastsWithDownloadStates.count > 0)
                                    {
                                        [_editButton setTitle:OALocalizedString(_editMode ? @"shared_string_apply" : @"shared_string_edit")
                                                     forState:UIControlStateNormal];
                                    }
                                    else
                                    {
                                        _sizeIndexPath = nil;
                                    }
                                    _editButton.hidden = forecastsWithDownloadStates.count == 0;
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

        _searchResults = [[startsWithResult arrayByAddingObjectsFromArray:onlyContainsResult]
                sortedArrayUsingComparator:^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
                    return [region1.name localizedCaseInsensitiveCompare:region2.name];
                }
        ];
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

    if ([item[@"type"] isEqualToString:[OATitleDescrRightIconTableViewCell getCellIdentifier]])
    {
        OATitleDescrRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescrRightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *) nib[0];

            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = [item.allKeys containsObject:@"region"] ? ((OAWorldRegion *) item[@"region"]).name : item[@"title"];
            cell.descriptionLabel.attributedText = item[@"description"];
            NSString *regionId = ((OAWorldRegion *) item[@"region"]).regionId;
            if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateInProgress
                    || ![_weatherHelper isOfflineForecastSizesInfoCalculated:regionId])
            {
                FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];
                progressView.tintColor = UIColorFromRGB(color_primary_purple);

                cell.accessoryView = progressView;
                cell.iconView.image = nil;
            }
            else
            {
                cell.accessoryView = nil;
                cell.iconView.image = [UIImage templateImageNamed:@"menu_cell_pointer"];
            }
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];

            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            BOOL isUpdateAll = [item[@"key"] isEqualToString:@"update_cell_all"];

            cell.textView.text = item[@"title"];
            cell.textView.textColor = isUpdateAll ? UIColorFromRGB(color_primary_purple) : UIColor.blackColor;
            cell.textView.font = isUpdateAll ? [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] : [UIFont systemFontOfSize:17.];
            cell.descriptionView.text = item[@"description"];

            cell.rightIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.rightIconView.tintColor = isUpdateAll ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OADeleteButtonTableViewCell getCellIdentifier]])
    {
        OADeleteButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADeleteButtonTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADeleteButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADeleteButtonTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
            cell.iconImageView.image = nil;
            [cell showIcon:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = [item.allKeys containsObject:@"region"] ? ((OAWorldRegion *) item[@"region"]).name : item[@"title"];
            NSString *imageName = [item[@"key"] hasPrefix:@"selected_"] ? @"ic_custom_delete" : @"ic_custom_plus";
            [cell.deleteButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
            cell.deleteButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.deleteButton addTarget:self action:@selector(rearrangeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showButton:YES];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];
            cell.cellImageView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.cellImageView.tintColor = item[@"icon_color"];

            NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:item[@"button_title"]];
            [buttonTitle addAttribute:NSForegroundColorAttributeName
                                value:UIColorFromRGB(color_primary_purple)
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [buttonTitle addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:15. weight:UIFontWeightSemibold]
                                range:NSMakeRange(0, buttonTitle.string.length)];
            [cell.button setAttributedTitle:buttonTitle forState:UIControlStateNormal];

            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(onEditButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _selectedIndexPath = indexPath;
    if ([item[@"key"] isEqualToString:@"update_cell_all"])
    {
        [_weatherHelper downloadForecastsByRegionIds:[_weatherHelper getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateFinished)]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupView];
            [self.tableView reloadData];
        });
    }
    else if ([item[@"key"] hasPrefix:@"status_cell_"])
    {
        NSString *regionId = ((OAWorldRegion *) item[@"region"]).regionId;
        if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
        {
            OAWeatherForecastDetailsViewController *forecastDetailsViewController = [[OAWeatherForecastDetailsViewController alloc] initWithRegion:item[@"region"]];
            forecastDetailsViewController.delegate = self;
            [self.navigationController pushViewController:forecastDetailsViewController animated:YES];
        }
        else if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateInProgress)
        {
            NSMutableString *message = [NSMutableString stringWithFormat:OALocalizedString(@"res_cancel_inst_q"),
                    [((OAWorldRegion *) item[@"region"]).name stringByAppendingString:[NSString stringWithFormat:@" - %@",
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
                                                            [_weatherHelper prepareToStopDownloading:regionId];
                                                            if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateUndefined)
                                                            {
                                                                [_weatherHelper removeLocalForecast:regionId refreshMap:NO];
                                                                [((NSMutableArray *) _data[indexPath.section][@"cells"]) removeObjectAtIndex:indexPath.row];
                                                                [_regionsOtherCountries addObject:item[@"region"]];
                                                                [_regionsOtherCountries sortUsingComparator:^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
                                                                    return [region1.name localizedCaseInsensitiveCompare:region2.name];
                                                                }];
                                                                [_regionsSelected removeObject:item[@"region"]];
                                                            }
                                                            else if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
                                                            {
                                                                [_weatherHelper calculateCacheSize:item[@"region"] onComplete:nil];
                                                            }
                                                        } completionBlock:^{
                                                            if (_regionsSelected.count > 0)
                                                            {
                                                                if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateUndefined)
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
                                                                else if ([OAWeatherHelper getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
                                                                {
                                                                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                }
                                                                [self updateCacheSize];
                                                            }
                                                            else
                                                            {
                                                                _editButton.hidden = YES;
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
        [self presentViewController:controller animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)rearrangeButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    if (button)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        [self rearrangeForecast:indexPath];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    [self updateCacheSize];
}

#pragma mark - OAWeatherForecastDetails

- (void)onRemoveForecast
{
    if (_selectedIndexPath)
    {
        [_progressHUD showAnimated:YES whileExecutingBlock:^{
            NSDictionary *item = [self getItem:_selectedIndexPath];
            [((NSMutableArray *) _data[_selectedIndexPath.section][@"cells"]) removeObjectAtIndex:_selectedIndexPath.row];
            [_regionsOtherCountries addObject:item[@"region"]];
            [_regionsOtherCountries sortUsingComparator:^NSComparisonResult(OAWorldRegion *region1, OAWorldRegion *region2) {
                return [region1.name localizedCaseInsensitiveCompare:region2.name];
            }];
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
                _editButton.hidden = YES;
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
        forecastCell[@"description"] = [OAWeatherHelper getStatusInfoDescription:((OAWorldRegion *) forecastCell[@"region"]).regionId];
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
