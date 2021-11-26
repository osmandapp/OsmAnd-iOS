//
//  OAMapSettingsWikipediaScreen.m
//  OsmAnd
//
//  Created by Skalii on 01.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsWikipediaScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAWikipediaPlugin.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomFooterView.h"
#import "OASettingSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaLanguagesViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"

#define kCellTypeMap @"MapCell"

typedef NS_ENUM(NSInteger, EOAMapSettingsWikipediaSection)
{
    EOAMapSettingsWikipediaSectionVisibility = 0,
    EOAMapSettingsWikipediaSectionLanguages,
    EOAMapSettingsWikipediaSectionAvailable
};

@interface OAMapSettingsWikipediaScreen () <OAWikipediaScreenDelegate>

@end

@implementation OAMapSettingsWikipediaScreen
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;
    OAMapViewController *_mapViewController;

    OAWikipediaPlugin *_wikiPlugin;
    NSArray<OARepositoryResourceItem *> *_mapItems;

    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;

    NSObject *_dataLock;
    BOOL _wikipediaEnabled;
    NSArray<NSArray <NSDictionary *> *> *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];
        settingsScreen = EMapSettingsScreenWikipedia;
        vwController = viewController;
        tblView = tableView;
        _wikiPlugin = (OAWikipediaPlugin *) [OAPlugin getPlugin:OAWikipediaPlugin.class];
        _dataLock = [[NSObject alloc] init];
        _wikipediaEnabled = [[OAPOIFiltersHelper sharedInstance] isPoiFilterSelectedByFilterId:[OAPOIFiltersHelper getTopWikiPoiFilterId]];
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)dealloc
{
    if (_downloadTaskProgressObserver)
    {
        [_downloadTaskProgressObserver detach];
        _downloadTaskProgressObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
}

- (void)commonInit
{
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:) andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onDownloadTaskFinished:withKey:andValue:) andObserve:_app.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onLocalResourcesChanged:withKey:) andObserve:_app.localResourcesChangedObservable];
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@[@{@"type": [OASettingSwitchCell getCellIdentifier]}]];

    if (_wikipediaEnabled)
    {
        [dataArr addObject:@[@{
                        @"type": [OAIconTitleValueCell getCellIdentifier],
                        @"img": @"ic_custom_map_languge",
                        @"title": OALocalizedString(@"language")
                }]];
    }

    if (_mapItems.count > 0)
    {
        NSMutableArray *availableMapsArr = [NSMutableArray new];

        for (OARepositoryResourceItem *item in _mapItems)
        {
            [availableMapsArr addObject:@{
                    @"type": kCellTypeMap,
                    @"img": @"ic_custom_wikipedia",
                    @"item": item,
            }];
        }

        [dataArr addObject:availableMapsArr];
    }

    _data = dataArr;
}

- (void)setupView
{
    title = OALocalizedString(@"product_title_wiki");

    self.tblView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16., 0., 0.);
    [self.tblView.tableFooterView removeFromSuperview];
    self.tblView.tableFooterView = nil;
    [self.tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    self.tblView.estimatedRowHeight = kEstimatedRowHeight;

    [self updateAvailableMaps];
}

- (void)onRotation
{
    self.tblView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16., 0., 0.);
    [self.tblView reloadData];
}

- (void)updateAvailableMaps
{
    CLLocationCoordinate2D coordinate = [OAResourcesUIHelper getMapLocation];
    _mapItems = [OAResourcesUIHelper findIndexItemsAt:coordinate
                                                 type:OsmAndResourceType::WikiMapRegion
                                    includeDownloaded:NO
                                                limit:-1
                                  skipIfOneDownloaded:YES];

    [self initData];
    [UIView transitionWithView:self.tblView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
        [self.tblView reloadData];
                    }
                    completion:nil];
}


- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        [_app.data setWikipedia:_wikipediaEnabled = sw.on];
        [self updateAvailableMaps];
    }
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTextForFooter:(NSInteger)section
{
    if (!_wikipediaEnabled)
        return @"";

    switch (section)
    {
        case EOAMapSettingsWikipediaSectionLanguages:
            return OALocalizedString(@"select_wikipedia_article_langs");
        case EOAMapSettingsWikipediaSectionAvailable:
            return _mapItems.count > 0 ?  OALocalizedString(@"wiki_menu_download_descr") : @"";
        default:
            return @"";
    }
}

- (CGFloat)getFooterHeightForSection:(NSInteger)section
{
    return [OATableViewCustomFooterView getHeight:[self getTextForFooter:section] width:tblView.frame.size.width];
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [tblView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:tblView]];
    if (indexPath)
        [tblView.delegate tableView:tblView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ((section != EOAMapSettingsWikipediaSectionVisibility && !_wikipediaEnabled) || (section == EOAMapSettingsWikipediaSectionAvailable && _mapItems.count == 0))
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = _wikipediaEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = _wikipediaEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = _wikipediaEnabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);

            [cell.switchView setOn:_wikipediaEnabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.leftIconView.tintColor = UIColorFromRGB(color_dialog_buttons_dark);
            cell.descriptionView.text = [_wikiPlugin getLanguagesSummary];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        static NSString* const repositoryResourceCell = @"repositoryResourceCell";
        static NSString* const downloadingResourceCell = @"downloadingResourceCell";
        OAResourceItem *mapItem = item[@"item"];
        NSString* cellTypeId = mapItem.downloadTask ? downloadingResourceCell : repositoryResourceCell;

        uint64_t _sizePkg = mapItem.sizePkg;
        if ((mapItem.resourceType == OsmAndResourceType::WikiMapRegion) && ![_iapHelper.wiki isActive])
            mapItem.disabled = YES;
        NSString *subtitle = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:mapItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
        if (cell == nil)
        {
            if ([cellTypeId isEqualToString:repositoryResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                UIImage* iconImage = [UIImage templateImageNamed:@"ic_custom_download"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.tintColor = UIColorFromRGB(color_primary_purple);
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else if ([cellTypeId isEqualToString:downloadingResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];

                cell.accessoryView = progressView;
            }
        }
        if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            if (!mapItem.disabled)
            {
                cell.textLabel.textColor = [UIColor blackColor];
                UIImage *iconImage = [UIImage templateImageNamed:@"ic_custom_download"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.tintColor = UIColorFromRGB(color_primary_purple);
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else
            {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.accessoryView = nil;
            }
        }

        cell.imageView.image = [UIImage templateImageNamed:@"ic_custom_wikipedia"];
        cell.imageView.tintColor = UIColorFromRGB(color_tint_gray);
        cell.textLabel.text = mapItem.title;;
        if (cell.detailTextLabel != nil)
            cell.detailTextLabel.text = subtitle;

        if ([cellTypeId isEqualToString:downloadingResourceCell])
            [self updateDownloadingCell:cell indexPath:indexPath];

        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != EOAMapSettingsWikipediaSectionVisibility ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != EOAMapSettingsWikipediaSectionVisibility)
        [self onItemClicked:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == EOAMapSettingsWikipediaSectionAvailable && _mapItems.count > 0 && _wikipediaEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_wikipediaEnabled)
        return 0.01;

    switch (section)
    {
        case EOAMapSettingsWikipediaSectionLanguages:
            return 38.0;
        case EOAMapSettingsWikipediaSectionAvailable:
            return _mapItems.count > 0 ? 56.0 : 0.01;
        default:
            return 0.01;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!_wikipediaEnabled)
        return @"";

    switch (section)
    {
        case EOAMapSettingsWikipediaSectionAvailable:
            return _mapItems.count > 0 ? OALocalizedString(@"osmand_live_available_maps") : @"";
        default:
            return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!_wikipediaEnabled)
        return nil;

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    NSString *text = [self getTextForFooter:section];
    vw.label.text = text;
    return vw;
}

#pragma mark - Selectors

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == EOAMapSettingsWikipediaSectionLanguages && [item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAWikipediaLanguagesViewController *controller = [[OAWikipediaLanguagesViewController alloc] init];
        controller.delegate = self;
        [self.vwController presentViewController:controller animated:YES completion:nil];
    }
    else if (indexPath.section == EOAMapSettingsWikipediaSectionAvailable && [item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceItem *mapItem = item[@"item"];
        if (mapItem.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:mapItem];
        }
        else if ([mapItem isKindOfClass:[OARepositoryResourceItem class]])
        {
            OARepositoryResourceItem *resItem = (OARepositoryResourceItem *) mapItem;
            if ((resItem.resourceType == OsmAndResourceType::WikiMapRegion) && ![_iapHelper.wiki isActive])
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            }
            else
            {
                [OAResourcesUIHelper offerDownloadAndInstallOf:resItem onTaskCreated:^(id<OADownloadTask> task) {
                    [self updateAvailableMaps];
                } onTaskResumed:nil];
            }
        }
    }
}

#pragma mark - Downloading cell progress methods

- (void)updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
    [self updateDownloadingCell:cell indexPath:indexPath];
}

- (void)updateDownloadingCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    OAResourceItem *mapItem = [self getItem:indexPath][@"item"];
    if (mapItem.downloadTask)
    {
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;

        float progressCompleted = mapItem.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && mapItem.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (mapItem.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            progressView.progress = 0.0f;
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
        progressView.tintColor = UIColorFromRGB(color_primary_purple);
    }
}

- (void)refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        for (int i = 0; i < _mapItems.count; i++)
        {
            OAResourceItem *item = _mapItems[i];
            if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
                [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:EOAMapSettingsWikipediaSectionAvailable]];
        }
    }
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;

        [self refreshDownloadingContent:task.key];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;

        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKey:_app.downloadsManager.keysOfDownloadTasks[0]];
                [nextTask resume];
            }
            [self updateAvailableMaps];
        }
        else
        {
            [self refreshDownloadingContent:task.key];
        }
    });
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;

        [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];

        [OAManageResourcesViewController prepareData];
        [self updateAvailableMaps];
    });
}

#pragma mark - OAWikipediaScreenDelegate

- (void)updateSelectedLanguage
{
    [self.tblView beginUpdates];
    [self.tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsWikipediaSectionLanguages] withRowAnimation:UITableViewRowAnimationFade];
    [self.tblView endUpdates];
}

@end
