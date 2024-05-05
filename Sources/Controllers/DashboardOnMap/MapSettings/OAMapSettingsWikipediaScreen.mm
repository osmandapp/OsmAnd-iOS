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
#import "OsmAnd_Maps-Swift.h"
#import "OATableViewCustomFooterView.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaLanguagesViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "OADownloadingCellResourceHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#define kCellTypeMap @"MapCell"

typedef NS_ENUM(NSInteger, EOAMapSettingsWikipediaSection)
{
    EOAMapSettingsWikipediaSectionVisibility = 0,
    EOAMapSettingsWikipediaSectionLanguages,
    EOAMapSettingsWikipediaSectionAvailable
};

@interface OAMapSettingsWikipediaScreen () <OAWikipediaScreenDelegate, OADownloadingCellResourceHelperDelegate>

@end

@implementation OAMapSettingsWikipediaScreen
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;
    OAMapViewController *_mapViewController;
    OADownloadingCellResourceHelper *_downloadingCellResoucsesHelper;

    OAWikipediaPlugin *_wikiPlugin;
    NSArray<OARepositoryResourceItem *> *_mapItems;

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
        _wikiPlugin = (OAWikipediaPlugin *) [OAPluginsHelper getPlugin:OAWikipediaPlugin.class];
        _dataLock = [[NSObject alloc] init];
        _wikipediaEnabled = _app.data.wikipedia;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        
        [self setupDownloadingCellHelper];
        [self updateResources];
    }
    return self;
}

- (void)setupDownloadingCellHelper
{
    _downloadingCellResoucsesHelper =  [[OADownloadingCellResourceHelper alloc] init];
    _downloadingCellResoucsesHelper.hostViewController = self.vwController;
    _downloadingCellResoucsesHelper.hostTableView = self.tblView;
    _downloadingCellResoucsesHelper.delegate = self;
}

- (void) updateResources
{
    CLLocationCoordinate2D coordinate = [OAResourcesUIHelper getMapLocation];
    _mapItems = (NSArray<OARepositoryResourceItem *> *) [OAResourcesUIHelper findIndexItemsAt:coordinate type:OsmAndResourceType::WikiMapRegion includeDownloaded:NO limit:-1 skipIfOneDownloaded:YES];
    [self initData];
}

- (NSArray<NSArray <NSDictionary *> *> *)data
{
    return _data;
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@[@{@"type": [OASwitchTableViewCell getCellIdentifier]}]];

    if (_wikipediaEnabled)
    {
        [dataArr addObject:@[@{
                        @"type": [OAValueTableViewCell getCellIdentifier],
                        @"img": @"ic_custom_map_languge",
                        @"title": OALocalizedString(@"shared_string_language")
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
    title = OALocalizedString(@"download_wikipedia_maps");

    self.tblView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16., 0., 0.);
    [self.tblView.tableFooterView removeFromSuperview];
    self.tblView.tableFooterView = nil;
    [self.tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    self.tblView.estimatedRowHeight = kEstimatedRowHeight;

    [self updateResources];
}

- (void)onRotation
{
    self.tblView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16., 0., 0.);
    [self.tblView reloadData];
}

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        [(OAWikipediaPlugin *) [OAPluginsHelper getPlugin:OAWikipediaPlugin.class] wikipediaChanged:sw.isOn];
        _wikipediaEnabled = _app.data.wikipedia;
        [self updateResources];
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
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = _wikipediaEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");

            NSString *imgName = _wikipediaEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.leftIconView.image = [UIImage templateImageNamed:imgName];
            cell.leftIconView.tintColor = _wikipediaEnabled ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            [cell.switchView setOn:_wikipediaEnabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
            cell.valueLabel.text = [_wikiPlugin getLanguagesSummary];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceItem *mapItem = item[@"item"];
        return [_downloadingCellResoucsesHelper getOrCreateCellForResourceId:mapItem.resourceId.toNSString() resourceItem:mapItem];
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
        header.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
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
            return _mapItems.count > 0 ? OALocalizedString(@"available_maps") : @"";
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
    if (indexPath.section == EOAMapSettingsWikipediaSectionLanguages && [item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAWikipediaLanguagesViewController *controller = [[OAWikipediaLanguagesViewController alloc] initWithAppMode:[[OAAppSettings sharedManager].applicationMode get]];
        controller.wikipediaDelegate = self;
        [self.vwController showModalViewController:controller];
    }
    else if (indexPath.section == EOAMapSettingsWikipediaSectionAvailable && [item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceItem *mapItem = item[@"item"];
        [_downloadingCellResoucsesHelper onCellClicked:mapItem.resourceId.toNSString()];
        
    }
}

#pragma mark - OADownloadingCellResourceHelperDelegate

- (void)onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateResources];
    });
}

#pragma mark - OAWikipediaScreenDelegate

- (void)updateWikipediaSettings
{
    [self.tblView beginUpdates];
    [self.tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsWikipediaSectionLanguages] withRowAnimation:UITableViewRowAnimationFade];
    [self.tblView endUpdates];
}

@end
