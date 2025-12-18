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
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAPluginPopupViewController.h"
#import "OAManageResourcesViewController.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OAAppData.h"

#define kCellTypeMap @"MapCell"

typedef NS_ENUM(NSInteger, EOAMapSettingsWikipediaSection)
{
    EOAMapSettingsWikipediaSectionVisibility = 0,
    EOAMapSettingsWikipediaSectionLanguages,
    EOAMapSettingsWikipediaSectionOnlinePreview,
    EOAMapSettingsWikipediaSectionAvailable
};

@interface OAMapSettingsWikipediaScreen () <OAWikipediaScreenDelegate, DownloadingCellResourceHelperDelegate>

@end

@implementation OAMapSettingsWikipediaScreen
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;
    OAMapViewController *_mapViewController;
    DownloadingCellResourceHelper *_downloadingCellResourceHelper;

    OAWikipediaPlugin *_wikiPlugin;
    NSArray<OARepositoryResourceItem *> *_mapItems;

    NSObject *_dataLock;
    BOOL _wikipediaEnabled;
    NSArray<NSArray <NSDictionary *> *> *_data;
    OAAppSettings *_settings;
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
        _settings = OAAppSettings.sharedManager;
        
        [self.tblView registerNib:[UINib nibWithNibName:OAButtonTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OAButtonTableViewCell.reuseIdentifier];
        [self.tblView registerNib:[UINib nibWithNibName:OASwitchTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OASwitchTableViewCell.reuseIdentifier];
        
        [self setupDownloadingCellHelper];
        [self updateResources];
    }
    return self;
}

- (void)setupDownloadingCellHelper
{
    __weak __typeof(self) weakSelf = self;
    _downloadingCellResourceHelper = [DownloadingCellResourceHelper new];
    _downloadingCellResourceHelper.hostViewController = weakSelf.vwController;
    [_downloadingCellResourceHelper setHostTableView:weakSelf.tblView];
    _downloadingCellResourceHelper.delegate = weakSelf;
    _downloadingCellResourceHelper.rightIconStyle = DownloadingCellRightIconTypeHideIconAfterDownloading;
}

- (void) updateResources
{
    CLLocationCoordinate2D coordinate = [OAResourcesUIHelper getMapLocation];
    _mapItems = (NSArray<OARepositoryResourceItem *> *) [OAResourcesUIHelper findIndexItemsAt:coordinate type:OsmAndResourceType::WikiMapRegion includeDownloaded:NO limit:-1 skipIfOneDownloaded:YES];
    [self initData];
    [self.tblView reloadData];
}

- (NSArray<NSArray <NSDictionary *> *> *)data
{
    return _data;
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@[
        @{
            @"type": [OASwitchTableViewCell reuseIdentifier],
            @"key": @"wikipediaSwitch",
            @"title": _wikipediaEnabled ? OALocalizedString(@"shared_string_enabled")
            : OALocalizedString(@"rendering_value_disabled_name"),
            @"img": _wikipediaEnabled ? @"ic_custom_show" : @"ic_custom_hide",
            @"isSelected": @(_wikipediaEnabled)
        }
    ]];

    if (_wikipediaEnabled)
    {
        [dataArr addObject:@[@{
            @"type": [OAValueTableViewCell reuseIdentifier],
            @"img": @"ic_custom_map_languge",
            @"title": OALocalizedString(@"shared_string_language")
        }]];
        BOOL isOffline = [_settings.wikiDataSourceType get] == EOAWikiDataSourceTypeOffline;
        DataSourceType dataSourceType = isOffline ? DataSourceTypeOffline : DataSourceTypeOnline;
        BOOL wikiShowImagePreviews = [_settings.wikiShowImagePreviews get];
        [dataArr addObject:@[
            @{
                @"type": [OAButtonTableViewCell reuseIdentifier],
                @"icon": [DataSourceTypeWrapper iconForType:dataSourceType],
                @"title": OALocalizedString(@"poi_source"),
                @"tintColor": isOffline ? [UIColor colorNamed:ACColorNameIconColorDisabled] : [UIColor colorNamed:ACColorNameIconColorSelected]
            },
            @{
                @"type": [OASwitchTableViewCell reuseIdentifier],
                @"key": @"wikiShowImagePreviews",
                @"img": wikiShowImagePreviews ? @"ic_custom_photo" : @"ic_custom_photo_disable",
                @"title": OALocalizedString(@"show_image_previews"),
                @"isSelected": @(wikiShowImagePreviews)
            }
        ]];
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

    _data = [dataArr copy];
}

- (void)setupView
{
    title = [(OAWikipediaPlugin *)[OAPluginsHelper getPlugin:OAWikipediaPlugin.class] popularPlacesTitle];

    self.tblView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16., 0., 0.);
    [self.tblView.tableFooterView removeFromSuperview];
    self.tblView.tableFooterView = nil;
    [self.tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView reuseIdentifier]];
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
        UISwitch *sw = (UISwitch *)sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        
        NSString *key = item[@"key"];
        
        if ([key isEqualToString: @"wikipediaSwitch"]) {
            [(OAWikipediaPlugin *)[OAPluginsHelper getPlugin:OAWikipediaPlugin.class] wikipediaChanged:sw.isOn];
            _wikipediaEnabled = _app.data.wikipedia;
        } else if ([key isEqualToString: @"wikiShowImagePreviews"]) {
            [_settings.wikiShowImagePreviews set:sw.isOn];
            [self refreshPOI];
        }
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
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell reuseIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell reuseIdentifier]];
        [cell descriptionVisibility:NO];
        cell.titleLabel.text = item[@"title"];
        
        BOOL isSelected = ((NSNumber *)item[@"isSelected"]).boolValue;
        
        cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
        cell.leftIconView.tintColor = isSelected ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        
        [cell.switchView setOn:isSelected];
        cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell reuseIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell reuseIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell reuseIdentifier] owner:self options:nil];
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
        OAResourceSwiftItem *mapItem = [[OAResourceSwiftItem alloc] initWithItem:item[@"item"]];
        return [_downloadingCellResourceHelper getOrCreateCell:mapItem.resourceId swiftResourceItem:mapItem];
    }
    else if ([item[@"type"] isEqualToString:[OAButtonTableViewCell reuseIdentifier]])
    {
        OAButtonTableViewCell *cell =
            (OAButtonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:OAButtonTableViewCell.reuseIdentifier];

        if (cell.contentHeightConstraint == nil)
        {
            NSLayoutConstraint *constraint =
                [cell.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:48.0];
            constraint.active = YES;
            cell.contentHeightConstraint = constraint;
        }

        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        [cell descriptionVisibility:NO];

        cell.titleLabel.text = item[@"title"];
        cell.leftIconView.image = item[@"icon"];
        cell.leftIconView.tintColor = item[@"tintColor"];

        UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
        config.contentInsets = NSDirectionalEdgeInsetsZero;
        cell.button.configuration = config;

        cell.button.menu = [self createMenuForCellButton:cell];

        cell.button.showsMenuAsPrimaryAction = YES;
        cell.button.changesSelectionAsPrimaryAction = YES;

        [cell.button setContentHuggingPriority:UILayoutPriorityRequired
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [cell.button setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisHorizontal];

        return cell;
    }
    return nil;
}

- (UIMenu *)createMenuForCellButton:(OAButtonTableViewCell *)cell
{
    BOOL isOffline = [_settings.wikiDataSourceType get] == EOAWikiDataSourceTypeOffline;
    
    __weak __typeof(cell) weakCell = cell;
    __weak __typeof(self) weakSelf = self;
    UIAction *onlineAction = [UIAction actionWithTitle:[DataSourceTypeWrapper titleForType:DataSourceTypeOnline] image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [_settings.wikiDataSourceType set:EOAWikiDataSourceTypeOnline];
        weakCell.leftIconView.image = [DataSourceTypeWrapper iconForType:DataSourceTypeOnline];
        weakCell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
        [weakSelf refreshPOI];
    }];
    
    UIAction *offlineAction = [UIAction actionWithTitle:[DataSourceTypeWrapper titleForType:DataSourceTypeOffline] image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [_settings.wikiDataSourceType set:EOAWikiDataSourceTypeOffline];
        weakCell.leftIconView.image = [DataSourceTypeWrapper iconForType:DataSourceTypeOffline];
        weakCell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDisabled];
        [weakSelf refreshPOI];
    }];
    
    onlineAction.state = isOffline ? UIMenuElementStateOff : UIMenuElementStateOn;
    offlineAction.state = isOffline ? UIMenuElementStateOn : UIMenuElementStateOff;
    
    return [UIMenu composedMenuFrom:@[@[onlineAction, offlineAction]]];
}

- (void)refreshPOI
{
    [[OARootViewController instance].mapPanel refreshMap];
    [_mapViewController updatePoiLayer];
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

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView reuseIdentifier]];
    NSString *text = [self getTextForFooter:section];
    vw.label.text = text;
    return vw;
}

#pragma mark - Selectors

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == EOAMapSettingsWikipediaSectionLanguages && [item[@"type"] isEqualToString:[OAValueTableViewCell reuseIdentifier]])
    {
        OAWikipediaLanguagesViewController *controller = [[OAWikipediaLanguagesViewController alloc] initWithAppMode:[[OAAppSettings sharedManager].applicationMode get]];
        controller.wikipediaDelegate = self;
        [self.vwController showModalViewController:controller];
    }
    else if (indexPath.section == EOAMapSettingsWikipediaSectionAvailable && [item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceItem *mapItem = item[@"item"];
        [_downloadingCellResourceHelper onCellClicked:mapItem.resourceId.toNSString()];
        
    }
}

#pragma mark - DownloadingCellResourceHelperDelegate

- (void)onDownloadingCellResourceNeedUpdate:(id<OADownloadTask>)task
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateResources];
    });
}

- (void)onStopDownload:(OAResourceSwiftItem *)resourceItem
{
}

#pragma mark - OAWikipediaScreenDelegate

- (void)updateWikipediaSettings
{
    [self.tblView beginUpdates];
    [self.tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsWikipediaSectionLanguages] withRowAnimation:UITableViewRowAnimationFade];
    [self.tblView endUpdates];
}

@end
