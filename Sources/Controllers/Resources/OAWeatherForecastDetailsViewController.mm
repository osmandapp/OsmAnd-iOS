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
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "MBProgressHUD.h"
#import "OATableViewCustomHeaderView.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadingCellResourceHelper.h"
#import "OAWeatherHelper.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OAWeatherAutoUpdateSettingsViewController.h"
#import "GeneratedAssetSymbols.h"

@interface OAWeatherForecastDetailsViewController  () <OAWeatherCacheSettingsDelegate, OAWeatherFrequencySettingsDelegate, OAWeatherAutoUpdateSettingsViewControllerDelegate, OADownloadingCellResourceHelperDelegate>

@end

@implementation OAWeatherForecastDetailsViewController
{
    OAWeatherHelper *_weatherHelper;
    OADownloadingCellResourceHelper *_downloadingCellResourceHelper;
    OAWorldRegion *_region;
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;
    NSInteger _accuracySection;

    MBProgressHUD *_progressHUD;
    NSIndexPath *_sizeIndexPath;
    NSIndexPath *_updateNowIndexPath;
    OAResourceItem *_localResourceItem;

    OAAutoObserverProxy *_weatherSizeCalculatedObserver;
}

#pragma mark - Initialization

- (instancetype)initWithRegion:(OAWorldRegion *)region localResourceItem:(OAResourceItem *)item
{
    self = [super init];
    if (self)
    {
        _region = region;
        _localResourceItem = item;
    }
    return self;
}

- (void)commonInit
{
    _weatherHelper = [OAWeatherHelper sharedInstance];
    _headers = [NSMutableDictionary dictionary];
    _footers = [NSMutableDictionary dictionary];
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onWeatherSizeCalculated:withKey:andValue:)
                                                 andObserve:[OAWeatherHelper sharedInstance].weatherSizeCalculatedObserver]];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_progressHUD];
    [self setupDownloadingCellHelper];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [_downloadingCellResourceHelper cleanCellCache];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate onUpdateForecast];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_weatherHelper calculateCacheSize:_region onComplete:nil];
    if (_downloadingCellResourceHelper)
        [_downloadingCellResourceHelper refreshCellSpinners];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_downloadingCellResourceHelper)
        [_downloadingCellResourceHelper cleanCellCache];
}

- (void) setupDownloadingCellHelper
{
    _downloadingCellResourceHelper = [OADownloadingCellResourceHelper new];
    [_downloadingCellResourceHelper setHostTableView:self.tableView];
    _downloadingCellResourceHelper.rightIconStyle = EOADownloadingCellRightIconTypeShowIconAlways;
    _downloadingCellResourceHelper.isAlwaysClickable = YES;
    _downloadingCellResourceHelper.isBoldTitleStyle = YES;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return [OAWeatherHelper checkAndGetRegionName:_region];
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *data = [NSMutableArray array];
    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:_region];

    NSMutableArray<NSMutableDictionary *> *infoCells = [NSMutableArray array];
    [data addObject:infoCells];
    _accuracySection = data.count - 1;
    _headers[@(_accuracySection)] = [OAWeatherHelper getAccuracyDescription:regionId];

    NSMutableDictionary *updatedData = [NSMutableDictionary dictionary];
    updatedData[@"key"] = @"updated_cell";
    updatedData[@"type"] = [OAValueTableViewCell getCellIdentifier];
    updatedData[@"title"] = OALocalizedString(@"shared_string_updated");
    updatedData[@"value"] = [OAWeatherHelper getUpdatesDateFormat:regionId next:NO];
    updatedData[@"value_color"] = [UIColor colorNamed:ACColorNameTextColorPrimary];
    updatedData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [infoCells addObject:updatedData];

    NSMutableDictionary *nextUpdateData = [NSMutableDictionary dictionary];
    nextUpdateData[@"key"] = @"next_update_cell";
    nextUpdateData[@"type"] = [OAValueTableViewCell getCellIdentifier];
    nextUpdateData[@"title"] = OALocalizedString(@"shared_string_next_update");
    nextUpdateData[@"value"] = [OAWeatherHelper getUpdatesDateFormat:regionId next:YES];
    nextUpdateData[@"value_color"] = [UIColor colorNamed:ACColorNameTextColorPrimary];
    nextUpdateData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [infoCells addObject:nextUpdateData];

    NSMutableDictionary *updatesSizeData = [NSMutableDictionary dictionary];
    updatesSizeData[@"key"] = @"updates_size_cell";
    updatesSizeData[@"type"] = [OAValueTableViewCell getCellIdentifier];
    updatesSizeData[@"title"] = OALocalizedString(@"shared_string_updates_size");
    updatesSizeData[@"value"] = [NSByteCountFormatter stringFromByteCount:[[OAWeatherHelper sharedInstance] getOfflineForecastSize:_region forUpdate:YES] countStyle:NSByteCountFormatterCountStyleFile];
    
    updatesSizeData[@"value_color"] = [UIColor colorNamed:ACColorNameTextColorSecondary];
    updatesSizeData[@"selection_style"] = @(UITableViewCellSelectionStyleNone);
    [infoCells addObject:updatesSizeData];
    _sizeIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableDictionary *updateNowData = [NSMutableDictionary dictionary];
    updateNowData[@"key"] = @"update_now_cell";
    updateNowData[@"type"] = @"update_now_cell";
    updateNowData[@"title"] = OALocalizedString(@"update_now");
    updateNowData[@"resourceId"] = [_region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"];
    [infoCells addObject:updateNowData];
    _updateNowIndexPath = [NSIndexPath indexPathForRow:infoCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSMutableDictionary *> *updatesCells = [NSMutableArray array];
    [data addObject:updatesCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"update_parameters");
    _footers[@(data.count - 1)] = OALocalizedString(@"weather_updates_automatically");
    
    NSMutableDictionary *autoUpdateData = [NSMutableDictionary dictionary];
    autoUpdateData[@"key"] = @"update_only_wifi_cell";
    autoUpdateData[@"type"] = [OAValueTableViewCell getCellIdentifier];
    autoUpdateData[@"title"] = OALocalizedString(@"auto_update");
    autoUpdateData[@"value"] = [OAWeatherHelper getPreferenceWeatherAutoUpdateString:[OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId]];
    autoUpdateData[@"value_color"] = [UIColor colorNamed:ACColorNameTextColorSecondary];
    autoUpdateData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
    [updatesCells addObject:autoUpdateData];
    
    EOAWeatherAutoUpdate state = [OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId];
    if (state != EOAWeatherAutoUpdateDisabled)
    {
        NSMutableDictionary *updatesFrequencyData = [NSMutableDictionary dictionary];
        updatesFrequencyData[@"key"] = @"updates_frequency_cell";
        updatesFrequencyData[@"type"] = [OAValueTableViewCell getCellIdentifier];
        updatesFrequencyData[@"title"] = OALocalizedString(@"shared_string_updates_frequency");
        updatesFrequencyData[@"value"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:regionId]];
        updatesFrequencyData[@"value_color"] = [UIColor colorNamed:ACColorNameTextColorSecondary];
        updatesFrequencyData[@"selection_style"] = @(UITableViewCellSelectionStyleDefault);
        [updatesCells addObject:updatesFrequencyData];
        _footers[@(data.count - 1)] = OALocalizedString(@"weather_updates_automatically");
    }
    else
    {
        _footers[@(data.count - 1)] = OALocalizedString(@"weather_updates_manual");
    }

    NSMutableArray<NSMutableDictionary *> *removeCells = [NSMutableArray array];
    [data addObject:removeCells];

    NSMutableDictionary *removeForecastData = [NSMutableDictionary dictionary];
    removeForecastData[@"key"] = @"remove_forecast_cell";
    removeForecastData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    removeForecastData[@"title"] = OALocalizedString(@"weather_remove_forecast");
    removeForecastData[@"title_color"] = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
    removeForecastData[@"title_alignment"] = @(NSTextAlignmentCenter);
    removeForecastData[@"title_font"] = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
    [removeCells addObject:removeForecastData];

    _data = data;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _headers[@(section)];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _footers[@(section)];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
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
        }
        if (cell)
        {
            if ([item[@"key"] isEqualToString: @"remove_forecast_cell"])
            {
                [cell anchorContentTextStackView:EOATableViewCellContentCenterStyle];
            }

            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.textAlignment = [item.allKeys containsObject:@"title_alignment"] ? (NSTextAlignment) [item[@"title_alignment"] integerValue] : NSTextAlignmentNatural;
            cell.titleLabel.font = [item.allKeys containsObject:@"title_font"] ? item[@"title_font"] : [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"update_now_cell"])
    {
        OARightIconTableViewCell *cell = [_downloadingCellResourceHelper getOrCreateCellForResourceId:item[@"resourceId"] resourceItem:_localResourceItem];
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
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
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.font = [item.allKeys containsObject:@"title_font"] ? item[@"title_font"] : [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

            BOOL hasRightIcon = [item.allKeys containsObject:@"right_icon"];
            cell.accessoryView = nil;
            cell.rightIconView.image = hasRightIcon ? [UIImage templateImageNamed:item[@"right_icon"]] : nil;
            cell.rightIconView.tintColor = item[@"right_icon_color"];
            [cell rightIconVisibility:hasRightIcon];
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
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.selectionStyle = (UITableViewCellSelectionStyle) [item[@"selection_style"] integerValue];
            cell.accessoryType = cell.selectionStyle == UITableViewCellSelectionStyleDefault ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.textColor = item[@"value_color"];
        }
        return cell;
    }

    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    NSString *header = _headers[@(section)];
    if (header && section == _accuracySection)
    {
        return [OATableViewCustomHeaderView getHeight:header
                                                width:self.tableView.bounds.size.width
                                              xOffset:kPaddingOnSideOfContent
                                              yOffset:20.
                                                 font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]] + 15.;
    }

    return [super getCustomHeightForHeader:section];
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    if (section == _accuracySection)
    {
        customHeader.label.text = _headers[@(section)];
        customHeader.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        [customHeader setYOffset:20.];
        return customHeader;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:_region];
    if ([item[@"key"] isEqualToString:@"updates_size_cell"])
    {
        OAWeatherCacheSettingsViewController *controller = [[OAWeatherCacheSettingsViewController alloc] initWithRegion:_region];
        controller.cacheDelegate = self;
        [self showModalViewController:controller];
    }
    else if ([item[@"key"] isEqualToString:@"update_now_cell"])
    {
        NSString *resourceId = item[@"resourceId"];
        if ([_downloadingCellResourceHelper isDownloading:resourceId])
            [_weatherHelper calculateCacheSize:_region onComplete:nil];
        [_downloadingCellResourceHelper onCellClicked:resourceId];
    }
    else if ([item[@"key"] isEqualToString:@"remove_forecast_cell"])
    {
        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"weather_remove_forecast")
                                                    message:[NSString stringWithFormat:OALocalizedString(@"weather_remove_forecast_description"), [OAWeatherHelper checkAndGetRegionName:_region]]
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];

        UIAlertAction *clearCacheAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_remove")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action)
                                                                 {
                                                                     [_progressHUD showAnimated:YES whileExecutingBlock:^{
                                                                         [_localResourceItem.downloadTask stop];
                                                                         [_weatherHelper removeLocalForecast:regionId region:_region refreshMap:YES];
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
        [self showModalViewController:frequencySettingsViewController];
    }
    else if ([item[@"key"] isEqualToString:@"update_only_wifi_cell"])
    {
        OAWeatherAutoUpdateSettingsViewController *controller = [[OAWeatherAutoUpdateSettingsViewController alloc] initWithRegion:_region];
        controller.autoUpdateDelegate = self;
        [self showModalViewController:controller];
    }
}

#pragma mark - Selectors

- (void)onWeatherSizeCalculated:(id)sender withKey:(id)key andValue:(id)value
{
    if (value != _region || !_sizeIndexPath)
        return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self generateData];
        [_downloadingCellResourceHelper cleanCellCache];
        [self.tableView reloadData];
        if (self.delegate)
            [self.delegate onUpdateForecast];
    });
}

- (id<OADownloadTask>)getDownloadTaskFor:(NSString*)resourceId
{
    return [[[OsmAndApp instance].downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (BOOL)isUndefinedDownloadState
{
    auto state = [self getDownloadTaskFor:[_region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"]].state;
    return state != OADownloadTaskStateRunning && state != OADownloadTaskStateFinished;
}

#pragma mark - OADownloadingCellResourceHelperDelegate

- (void)onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;
        [self generateData];
        [_downloadingCellResourceHelper cleanCellCache];
        [self.tableView reloadData];
        if (self.delegate)
            [self.delegate onUpdateForecast];
    });
}

#pragma mark - OAWeatherCacheSettingsDelegate

- (void)onCacheClear
{
    [_weatherHelper calculateCacheSize:_region onComplete:nil];
    if ([self.delegate respondsToSelector:@selector(onClearForecastCache)])
        [self.delegate onClearForecastCache];
}

#pragma mark - OAWeatherAutoUpdateSettingsViewControllerDelegate

- (void)onAutoUpdateSelected
{
    [self generateData];
    [_downloadingCellResourceHelper cleanCellCache];
    [self.tableView reloadData];
}

#pragma mark - OAWeatherFrequencySettingsDelegate

- (void)onFrequencySelected
{
    NSString *regionId = [OAWeatherHelper checkAndGetRegionId:_region];
    for (NSInteger i = 0; i < _data.count; i++)
    {
        NSArray<NSMutableDictionary *> *cells = _data[i];
        for (NSInteger j = 0; j < cells.count; j++)
        {
            NSMutableDictionary *cell = cells[j];
            if ([cell[@"key"] isEqualToString:@"next_update_cell"])
            {
                cell[@"value"] = [OAWeatherHelper getUpdatesDateFormat:regionId next:YES];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([cell[@"key"] isEqualToString:@"updates_frequency_cell"])
            {
                cell[@"value"] = [OAWeatherHelper getFrequencyFormat:[OAWeatherHelper getPreferenceFrequency:regionId]];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else if ([cell[@"key"] isEqualToString:@"update_only_wifi_cell"])
            {
                cell[@"value"] = [OAWeatherHelper getPreferenceWeatherAutoUpdateString:[OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId]];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
        }
    }
}

@end
