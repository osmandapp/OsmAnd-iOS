//
//  OAWeatherForecastDetailsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 05.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherForecastDetailsViewController.h"
#import "OAWeatherCacheSettingsViewController.h"
#import "OAWeatherFrequencySettingsViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OATextLineViewCell.h"
#import "MBProgressHUD.h"
#import "OATableViewCustomHeaderView.h"
#import "OAResourcesUIHelper.h"
#import "OAWeatherHelper.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAWeatherForecastDetailsViewController  () <UITableViewDelegate, UITableViewDataSource, OAWeatherCacheSettingsDelegate, OAWeatherFrequencySettingsDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *buttonNavigationBack;
@property (weak, nonatomic) IBOutlet UILabel *labelNavigationTitle;
@property (weak, nonatomic) IBOutlet UIView *viewNavigationSeparator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OAWeatherForecastDetailsViewController
{
    OAWeatherHelper *_weatherHelper;
    OAWorldRegion *_region;
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *_data;

    MBProgressHUD *_progressHUD;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_updateNowIndexPath;
    BOOL _isHeaderBlurred;

    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
    OAAutoObserverProxy *_weatherForecastDownloadingObserver;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _weatherHelper = [OAWeatherHelper sharedInstance];
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

    self.labelNavigationTitle.text = _region.name;
    [self.buttonNavigationBack setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    self.buttonNavigationBack.tintColor = UIColorFromRGB(color_primary_purple);
    [self.view bringSubviewToFront:self.navigationBarView];
    [self.view bringSubviewToFront:self.viewNavigationSeparator];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(
            self.navigationBarView.frame.size.height - [OAUtilities getTopMargin],
            self.tableView.contentInset.left,
            self.tableView.contentInset.bottom,
            self.tableView.contentInset.bottom
    );
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self setupView];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_weatherHelper calculateCacheSize:_region onComplete:nil];
    });
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

- (void)setupView
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *titleCells = [NSMutableArray array];
    NSMutableDictionary *titleSection = [NSMutableDictionary dictionary];
    titleSection[@"key"] = @"title_section";
    titleSection[@"cells"] = titleCells;
    [data addObject:titleSection];

    NSMutableDictionary *forecastData = [NSMutableDictionary dictionary];
    forecastData[@"key"] = @"title_cell";
    forecastData[@"type"] = [OAMenuSimpleCellNoIcon getCellIdentifier];
    forecastData[@"title"] = _region.name;
    [titleCells addObject:forecastData];

    NSMutableArray<NSMutableDictionary *> *infoCells = [NSMutableArray array];
    NSMutableDictionary *infoSection = [NSMutableDictionary dictionary];
    infoSection[@"key"] = @"info_section";
    infoSection[@"header"] = [OAWeatherHelper getAccuracyDescription:_region.regionId];
    infoSection[@"cells"] = infoCells;
    [data addObject:infoSection];

    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
    updatedData[@"key"] = @"updated_cell";
    updatedData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    updatedData[@"title"] = OALocalizedString(@"shared_string_updated");
    updatedData[@"description"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:NO];
    updatedData[@"next_screen"] = @(NO);
    [infoCells addObject:updatedData];

    NSMutableDictionary *nextUpdateData = [NSMutableDictionary dictionary];
    nextUpdateData[@"key"] = @"next_update_cell";
    nextUpdateData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    nextUpdateData[@"title"] = OALocalizedString(@"shared_string_next_update");
    nextUpdateData[@"description"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:YES];
    nextUpdateData[@"next_screen"] = @(NO);
    [infoCells addObject:nextUpdateData];

    NSMutableDictionary *updatesSizeData = [NSMutableDictionary dictionary];
    updatesSizeData[@"key"] = @"updates_size_cell";
    updatesSizeData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    updatesSizeData[@"title"] = OALocalizedString(@"shared_string_updates_size");
    updatesSizeData[@"description"] = [NSByteCountFormatter stringFromByteCount:[[OAWeatherHelper sharedInstance] getOfflineForecastSizeInfo:_region.regionId local:YES]
                                                                     countStyle:NSByteCountFormatterCountStyleFile];
    updatesSizeData[@"next_screen"] = @(YES);
    [infoCells addObject:updatesSizeData];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableDictionary *updateNowData = [NSMutableDictionary dictionary];
    updateNowData[@"key"] = @"update_now_cell";
    updateNowData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    updateNowData[@"title"] = OALocalizedString(@"osmand_live_update_now");
    updateNowData[@"next_screen"] = @(NO);
    [infoCells addObject:updateNowData];
    _updateNowIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSMutableDictionary *> *updatesCells = [NSMutableArray array];
    NSMutableDictionary *updatesSection = [NSMutableDictionary dictionary];
    updatesSection[@"key"] = @"updates_section";
    updatesSection[@"header"] = OALocalizedString(@"update_parameters");
    updatesSection[@"footer"] = OALocalizedString(@"weather_updates_automatically");
    updatesSection[@"cells"] = updatesCells;
    [data addObject:updatesSection];

    NSMutableDictionary *updatesFrequencyData = [NSMutableDictionary dictionary];
    updatesFrequencyData[@"key"] = @"updates_frequency_cell";
    updatesFrequencyData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    updatesFrequencyData[@"title"] = OALocalizedString(@"shared_string_updates_frequency");
    updatesFrequencyData[@"description"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:_region.regionId]];
    updatesFrequencyData[@"next_screen"] = @(YES);
    [updatesCells addObject:updatesFrequencyData];

    NSMutableDictionary *updateOnlyWiFiData = [NSMutableDictionary dictionary];
    updateOnlyWiFiData[@"key"] = @"update_only_wifi_cell";
    updateOnlyWiFiData[@"type"] = [OAIconTextDividerSwitchCell getCellIdentifier];
    updateOnlyWiFiData[@"title"] = OALocalizedString(@"update_only_over_wi_fi");
    [updatesCells addObject:updateOnlyWiFiData];

    NSMutableArray<NSMutableDictionary *> *removeCells = [NSMutableArray array];
    NSMutableDictionary *removeSection = [NSMutableDictionary dictionary];
    removeSection[@"key"] = @"remove_section";
    removeSection[@"cells"] = removeCells;
    [data addObject:removeSection];

    NSMutableDictionary *removeForecastData = [NSMutableDictionary dictionary];
    removeForecastData[@"key"] = @"remove_forecast_cell";
    removeForecastData[@"type"] = [OATextLineViewCell getCellIdentifier];
    removeForecastData[@"title"] = OALocalizedString(@"weather_remove_forecast");
    [removeCells addObject:removeForecastData];

    _data = data;
}

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (value != _region || !_sizeIndexPath)
            return;

        uint64_t sizeLocal = [_weatherHelper getOfflineForecastSizeInfo:_region.regionId local:YES];
        NSMutableDictionary *totalSizeData = _data[_sizeIndexPath.section][@"cells"][_sizeIndexPath.row];
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:sizeLocal
                                                              countStyle:NSByteCountFormatterCountStyleFile];
        totalSizeData[@"description"] = sizeString;
        [self.tableView reloadRowsAtIndexPaths:@[_sizeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onWeatherForecastDownloading:(id)sender withKey:(id)key andValue:(id)value
{
    if (value != _region)
        return;

    if (_updateNowIndexPath && _sizeIndexPath)
    {
        BOOL statusSizeCalculating = ![[OAWeatherHelper sharedInstance] isOfflineForecastSizesInfoCalculated:_region.regionId];
        if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateUndefined && !statusSizeCalculating)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath];
            if (!cell.accessoryView)
            {
                [self.tableView reloadRowsAtIndexPaths:@[statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                cell = [self.tableView cellForRowAtIndexPath:statusSizeCalculating ? _sizeIndexPath : _updateNowIndexPath];
            }

            FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
            NSInteger progressDownloading = [_weatherHelper getOfflineForecastProgressInfo:_region.regionId];
            NSInteger progressDownloadDestination = [[OAWeatherHelper sharedInstance] getProgressDestination:_region.regionId];
            CGFloat progressCompleted = (CGFloat) progressDownloading / progressDownloadDestination;
            if (progressCompleted >= 0.001 && [OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress)
            {
                progressView.iconPath = nil;
                if (progressView.isSpinning)
                    [progressView stopSpinProgressBackgroundLayer];
                progressView.progress = progressCompleted - 0.001;
            }
            else if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateFinished && !statusSizeCalculating)
            {
                progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setupView];
                    [self.tableView reloadData];
                    if (self.delegate)
                        [self.delegate onUpdateForecast];
                });
            }
            else
            {
                progressView.iconPath = [UIBezierPath bezierPath];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];
                [progressView setNeedsDisplay];
            }
        });
    }
}

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"update_only_wifi_cell"])
        return [OAWeatherHelper getPreferenceWifi:_region.regionId];

    return NO;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (IBAction)backButtonClicked:(id)sender
{
    [self dismissViewController];
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

    if ([item[@"type"] isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAMenuSimpleCellNoIcon *cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *) nib[0];
            cell.backgroundColor = UIColorFromRGB(color_view_background);
            cell.descriptionView.hidden = YES;
            cell.textView.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
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
            [cell showLeftIcon:NO];
        }
        if (cell)
        {
            BOOL isUpdateNowCell = [item[@"key"] isEqualToString:@"update_now_cell"];
            BOOL isSizeCell = [item[@"key"] isEqualToString:@"updates_size_cell"];

            cell.selectionStyle = [item[@"key"] isEqualToString:@"updated_cell"] || [item[@"key"] isEqualToString:@"next_update_cell"]
                    ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            BOOL hasNextScreen = [item[@"next_screen"] boolValue];

            cell.textView.text = item[@"title"];
            cell.textView.textColor = isUpdateNowCell ? UIColorFromRGB(color_primary_purple) : UIColor.blackColor;
            cell.textView.font = isUpdateNowCell ? [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] : [UIFont systemFontOfSize:17.];

            cell.descriptionView.text = item[@"description"];
            cell.descriptionView.textColor = hasNextScreen ? UIColorFromRGB(color_text_footer) : UIColor.blackColor;

            if ((isUpdateNowCell && [OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress)
                    || (isSizeCell && ![_weatherHelper isOfflineForecastSizesInfoCalculated:_region.regionId]))
            {
                FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];
                progressView.tintColor = UIColorFromRGB(color_primary_purple);

                cell.accessoryView = progressView;
                cell.rightIconView.image = nil;
            }
            else
            {
                cell.accessoryView = nil;
                [cell showRightIcon:hasNextScreen || isUpdateNowCell];
                cell.rightIconView.image = [UIImage templateImageNamed:isUpdateNowCell ? @"ic_custom_download" : @"ic_custom_arrow_right"];
                cell.rightIconView.tintColor = isUpdateNowCell ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            }
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            [cell showIcon:NO];
            cell.dividerView.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            BOOL isOn = [self isEnabled:item[@"key"]];

            cell.switchView.on = isOn;
            cell.textView.text = item[@"title"];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_red);
        }
        if (cell)
        {
            cell.textView.textColor = UIColorFromRGB(color_primary_red);
            cell.textView.text = item[@"title"];
            cell.textView.textAlignment = NSTextAlignmentCenter;
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"footer"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"updates_size_cell"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithRegion:_region];
        controller.cacheDelegate = self;
        [self presentViewController:controller animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"update_now_cell"])
    {
        if ([OAWeatherHelper getPreferenceDownloadState:_region.regionId] == EOAWeatherForecastDownloadStateInProgress)
        {
            [_weatherHelper prepareToStopDownloading:_region.regionId];
            [_weatherHelper calculateCacheSize:_region onComplete:nil];
        }
        else
        {
            [_weatherHelper downloadForecastByRegion:_region];
        }
    }
    else if ([item[@"key"] isEqualToString:@"remove_forecast_cell"])
    {
        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"weather_remove_forecast")
                                                    message:[NSString stringWithFormat:OALocalizedString(@"weather_remove_forecast_description"), _region.name]
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];

        UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_remove")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action)
                                                                 {
                                                                     [_progressHUD showAnimated:YES whileExecutingBlock:^{
                                                                         [_weatherHelper prepareToStopDownloading:_region.regionId];
                                                                         [_weatherHelper removeLocalForecast:_region.regionId refreshMap:YES];
                                                                     } completionBlock:^{
                                                                         [self dismissViewController];
                                                                         if (self.delegate)
                                                                             [self.delegate onRemoveForecast];
                                                                     }];
                                                                 }
        ];

        [alert addAction:cancelAction];
        [alert addAction:clearCacheAction];

        alert.preferredAction = clearCacheAction;

        [self presentViewController:alert animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"updates_frequency_cell"])
    {
        OAWeatherFrequencySettingsViewController *frequencySettingsViewController =
                [[OAWeatherFrequencySettingsViewController alloc] initWithRegion:_region];
        frequencySettingsViewController.frequencyDelegate = self;
        [self presentViewController:frequencySettingsViewController animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    if ([_data[section][@"key"] isEqualToString:@"info_section"])
    {
        customHeader.label.text = _data[section][@"header"];
        customHeader.label.font = [UIFont systemFontOfSize:13];
        [customHeader setYOffset:2.];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([_data[section][@"key"] isEqualToString:@"title_section"])
    {
        return 0;
    }
    else if ([_data[section][@"key"] isEqualToString:@"info_section"])
    {
        return [OATableViewCustomHeaderView getHeight:_data[section][@"header"]
                                                width:tableView.bounds.size.width
                                              yOffset:2.
                                                 font:[UIFont systemFontOfSize:13.]] + 15.;
    }

    return UITableViewAutomaticDimension;
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"update_only_wifi_cell"])
            [OAWeatherHelper setPreferenceWifi:_region.regionId value:switchView.isOn];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y + scrollView.contentInset.top;

    if (!_isHeaderBlurred && y > 0.)
    {
        [self.navigationBarView addBlurEffect:YES cornerRadius:0. padding:0.];
        self.labelNavigationTitle.hidden = NO;
        self.viewNavigationSeparator.hidden = NO;
        _isHeaderBlurred = YES;
    }
    else if (_isHeaderBlurred && y <= 0.)
    {
        [self.navigationBarView removeBlurEffect];
        self.navigationBarView.backgroundColor = UIColorFromRGB(color_view_background);
        self.labelNavigationTitle.hidden = YES;
        self.viewNavigationSeparator.hidden = YES;
        _isHeaderBlurred = NO;
    }
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    [_weatherHelper calculateCacheSize:_region onComplete:nil];
}

#pragma mark - OAWeatherFrequencySettingsDelegate

- (void)onFrequencySelected
{
    for (NSInteger i = 0; i < _data.count; i++)
    {
        NSDictionary *section = _data[i];
        NSArray<NSMutableDictionary *> *cells = section[@"cells"];
        if ([section[@"key"] isEqualToString:@"info_section"])
        {
            for (NSInteger j = 0; j < cells.count; j++)
            {
                NSMutableDictionary *cell = cells[j];
                if ([cell[@"key"] isEqualToString:@"next_update_cell"])
                {
                    cell[@"description"] = [OAWeatherHelper getUpdatesDateFormat:_region.regionId next:YES];
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    continue;
                }
            }
        }
        else if ([section[@"key"] isEqualToString:@"updates_section"])
        {
            for (NSInteger j = 0; j < cells.count; j++)
            {
                NSMutableDictionary *cell = cells[j];
                if ([cell[@"key"] isEqualToString:@"updates_frequency_cell"])
                {
                    cell[@"description"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:_region.regionId]];
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
            }
        }
    }
}

@end
