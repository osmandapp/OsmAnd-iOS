//
//  OAPluginInstalledViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 22.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPluginInstalledViewController.h"
#import "OATextMultilineTableViewCell.h"
#import "OAPlugin.h"
#import "OAColors.h"
#import "OAProducts.h"
#import "OADownloadsManager.h"
#import "Localization.h"
#import "OAResourcesUIHelper.h"
#import "OAIAPHelper.h"
#import "OAApplicationMode.h"
#import "OAAutoObserverProxy.h"
#import "OASwitchTableViewCell.h"
#import "OAPluginPopupViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OADownloadTask.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#define kSidePadding 20.0
#define kTopPadding 6
#define kBottomPadding 32
#define kIconWidth 48

#define kCellTypeMap @"MapCell"
#define kCellTypeMultyMap @"MultyMapCell"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAPluginInstalledViewController () <UITableViewDelegate, UITableViewDataSource, DownloadingCellResourceHelperDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *disableButton;
@property (weak, nonatomic) IBOutlet UIButton *enableButton;

@end

typedef NS_ENUM(NSInteger, EOAPluginSectionType) {
    EOAPluginSectionTypeDescription = 0,
    EOAPluginSectionTypeSuggestedMaps,
    EOAPluginSectionTypeSuggestedProfiles
};

@implementation OAPluginInstalledViewController
{
    OsmAndAppInstance _app;
    NSString *_pluginId;
    OAPlugin *_plugin;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<OAResourceItem *> *_suggestedMaps;
    NSArray<OAMultipleResourceItem *> *_mapMultipleItems;
    NSArray<OAResourceItem *> *_multipleDownloadingItems;
    NSMutableArray<OAMultipleResourceItem *> *_collectedRegionMultipleMapItems;
    NSMutableArray<OARepositoryResourceItem *> *_collectedRegionMaps;
    NSString *_collectiongPreviousRegionId;
    NSArray<OAApplicationMode *> *_addedAppModes;
    
    OAIAPHelper *_iapHelper;
    DownloadingCellResourceHelper *_downloadingCellResourceHelper;
    DownloadingCellMultipleResourceHelper * _downloadingCellMultipleResourceHelper;
    NSObject *_dataLock;
}

- (instancetype) initWithPluginId:(NSString *)pluginId
{
    self = [super init];
    if (self) {
        _pluginId = pluginId;
        _plugin = [OAPluginsHelper getPluginById:_pluginId];
        _iapHelper = [OAIAPHelper sharedInstance];
        _app = OsmAndApp.instance;
        _dataLock = [[NSObject alloc] init];
        _suggestedMaps = @[];
        _addedAppModes = @[];
    }
    return self;
}

- (void)applyLocalization
{
    [self.enableButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
    [self.disableButton setTitle:OALocalizedString(@"shared_string_turn_off") forState:UIControlStateNormal];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    [self setupDownloadingCellHelper];
    
    self.enableButton.layer.cornerRadius = 9.;
    self.disableButton.layer.cornerRadius = 9.;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
    
    [self setupView];

    self.disableButton.titleLabel.font =  [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.enableButton.titleLabel.font =  [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureNavigationBar];
    
    if (_downloadingCellResourceHelper)
        [_downloadingCellResourceHelper refreshCellSpinners];
    if (_downloadingCellMultipleResourceHelper)
        [_downloadingCellMultipleResourceHelper refreshCellSpinners];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (_downloadingCellResourceHelper)
        [_downloadingCellResourceHelper cleanCellCache];
}

- (void)configureNavigationBar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.tableView.backgroundColor;
    appearance.shadowColor = self.tableView.backgroundColor;
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];

    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_close") style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:cancelButton animated:YES];
}

- (NSString *)descriptionText
{
    return OALocalizedString(@"new_plugin_added");
}

- (NSString *)descriptionBoldText
{
    return _plugin.getName;
}

- (void) setupView
{
    [self fetchResources];
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    NSMutableArray *descriptionSection = [NSMutableArray new];
    [descriptionSection addObject: @{
        @"sectionType" : [NSNumber numberWithInt:EOAPluginSectionTypeDescription],
        @"type" : [OATextMultilineTableViewCell getCellIdentifier],
        @"text" : _plugin.getDescription
    }];
    [data addObject:descriptionSection];
    
    NSMutableArray *suggestedMapsSection = [NSMutableArray new];
    for (OARepositoryResourceItem* item in _suggestedMaps)
    {
        [suggestedMapsSection addObject: @{
            @"sectionType" : [NSNumber numberWithInt:EOAPluginSectionTypeSuggestedMaps],
            @"type" : kCellTypeMap,
            @"item" : item,
            @"resourceId" : item.resourceId.toNSString()
        }];
    }
    for (OAMultipleResourceItem* item in _mapMultipleItems)
    {
        [suggestedMapsSection addObject:@{
            @"type" : kCellTypeMultyMap,
            @"item" : item,
            @"resourceId" : [item getResourceId]
        }];
    }

    if (suggestedMapsSection.count > 0)
        [data addObject:suggestedMapsSection];
    
    _addedAppModes = [_plugin getAddedAppModes];
    NSMutableArray *addedAppModesSection = [NSMutableArray new];
    for (OAApplicationMode* mode in _addedAppModes)
    {
        [OAApplicationMode changeProfileAvailability:mode isSelected:YES];
        [addedAppModesSection addObject: @{
            @"sectionType" : [NSNumber numberWithInt:EOAPluginSectionTypeSuggestedProfiles],
            @"type" : [OASwitchTableViewCell getCellIdentifier],
            @"mode" : mode
        }];
    }
    if (addedAppModesSection.count > 0)
        [data addObject:addedAppModesSection];
    
    _data = [NSArray arrayWithArray:data];
}

- (void)setupDownloadingCellHelper
{
    __weak OAPluginInstalledViewController *weakSelf = self;
    _downloadingCellResourceHelper = [DownloadingCellResourceHelper new];
    _downloadingCellResourceHelper.hostViewController = weakSelf;
    [_downloadingCellResourceHelper setHostTableView:weakSelf.tableView];
    _downloadingCellResourceHelper.delegate = weakSelf;
    _downloadingCellResourceHelper.rightIconStyle = DownloadingCellRightIconTypeHideIconAfterDownloading;
    
    _downloadingCellMultipleResourceHelper = [DownloadingCellMultipleResourceHelper new];
    _downloadingCellMultipleResourceHelper.hostViewController = weakSelf;
    [_downloadingCellMultipleResourceHelper setHostTableView:weakSelf.tableView];
    _downloadingCellMultipleResourceHelper.delegate = weakSelf;
    _downloadingCellMultipleResourceHelper.rightIconStyle = DownloadingCellRightIconTypeHideIconAfterDownloading;
}

- (NSArray<NSArray <NSDictionary *> *> *)data
{
    return _data;
}

- (void)fetchResources
{
    NSArray<OAResourceItem *> *allSuggestedMaps = [_plugin getSuggestedMaps];
    NSMutableArray<OAResourceItem *> *regularMaps = [NSMutableArray new];
    NSMutableArray<OAResourceItem *> *srtmMaps = [NSMutableArray new];
    
    for (OAResourceItem *map in allSuggestedMaps)
    {
        if (map.resourceType == OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion)
            [srtmMaps addObject:map];
        else
            [regularMaps addObject:map];
    }
    
    _suggestedMaps = [NSArray arrayWithArray:regularMaps];
    
    NSArray *sortedSrtmMaps = [srtmMaps sortedArrayUsingComparator:^NSComparisonResult(OARepositoryResourceItem* obj1, OARepositoryResourceItem* obj2) {
        return [obj1.worldRegion.localizedName.lowercaseString compare:obj2.worldRegion.localizedName.lowercaseString];
    }];
    
    _collectedRegionMultipleMapItems = [NSMutableArray new];
    _collectedRegionMaps = [NSMutableArray new];
    _collectiongPreviousRegionId = nil;
    
    for (OARepositoryResourceItem *map in sortedSrtmMaps)
    {
        if (!_collectiongPreviousRegionId)
        {
            [self startCollectingNewItem:_collectedRegionMaps map:map collectiongPreviousRegionId:_collectiongPreviousRegionId];
        }
        else if (!_collectiongPreviousRegionId || ![map.worldRegion.regionId isEqualToString:_collectiongPreviousRegionId])
        {
            [self saveCollectedItemIfNeeded];
            [self startCollectingNewItem:_collectedRegionMaps map:map collectiongPreviousRegionId:_collectiongPreviousRegionId];
        }
        else
        {
            [self appendToCollectingItem:map];
        }
    }
    [self saveCollectedItemIfNeeded];
    
    _mapMultipleItems = [NSArray arrayWithArray:_collectedRegionMultipleMapItems];
    [self generateData];
    [_downloadingCellResourceHelper cleanCellCache];
    [_downloadingCellMultipleResourceHelper cleanCellCache];
    [self.tableView reloadData];
}

- (void) startCollectingNewItem:(NSMutableArray<OARepositoryResourceItem *> *)collectedRegionMaps map:(OARepositoryResourceItem *)map collectiongPreviousRegionId:(NSString *)collectiongPreviousRegionId
{
    _collectiongPreviousRegionId = map.worldRegion.regionId;
    _collectedRegionMaps = [NSMutableArray arrayWithObject:map];
}

- (void) appendToCollectingItem:(OARepositoryResourceItem *)map
{
    [_collectedRegionMaps addObject:map];
}

- (void) saveCollectedItemIfNeeded
{
    if (_collectedRegionMaps.count > 1)
    {
        OAMultipleResourceItem *regionMultipleItem = [[OAMultipleResourceItem alloc] initWithType:OsmAndResourceType::SrtmMapRegion items:[NSArray arrayWithArray:_collectedRegionMaps]];
        regionMultipleItem.worldRegion = _collectedRegionMaps[0].worldRegion;
        [_collectedRegionMultipleMapItems addObject:regionMultipleItem];
    }
}

- (void) refreshDownloadTasks
{
    for (OAMultipleResourceItem *multipleItem in _mapMultipleItems)
    {
        for (OARepositoryResourceItem *resourceItem in multipleItem.items)
            resourceItem.downloadTask = [self getDownloadTaskFor:resourceItem.resource->id.toNSString()];
    }
}

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
        [self.tableView reloadData];
    } completion:nil];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"profile_type_custom_string") : OALocalizedString(@"profile_type_base_string");
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    OAApplicationMode *am = _addedAppModes[sender.tag];
    [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
}

- (IBAction)onDisablePressed:(UIButton *)sender
{
    if (_plugin)
    {
        OAProduct *product = [[OAIAPHelper sharedInstance] product:_pluginId];
        if (product)
        {
            [_iapHelper disableProduct:_pluginId];
        }
        else
        {
            [OAPluginsHelper enablePlugin:_plugin enable:NO];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onEnablePressed:(id)sender
{
    if (_plugin)
    {
        OAProduct *product = [[OAIAPHelper sharedInstance] product:_pluginId];
        if (product)
            [_iapHelper enableProduct:_pluginId];
        else
            [OAPluginsHelper enablePlugin:_plugin enable:YES];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsZero;
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
        }
        if (cell)
        {
            cell.textView.attributedText = [OAUtilities attributedStringFromHtmlString:item[@"text"] fontSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize textColor:[UIColor colorNamed:ACColorNameTextColorPrimary]];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorActive]};
            [cell.textView sizeToFit];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        OAResourceSwiftItem *mapItem = [[OAResourceSwiftItem alloc] initWithItem:[self getMapItem:indexPath]];
        return [_downloadingCellResourceHelper getOrCreateCell:item[@"resourceId"] swiftResourceItem:mapItem];
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMultyMap])
    {
        OAMultipleResourceSwiftItem *mapItem = [[OAMultipleResourceSwiftItem alloc] initWithItem:[self getMapItem:indexPath]];
        return [_downloadingCellMultipleResourceHelper getOrCreateCell:item[@"resourceId"] swiftResourceItem:mapItem];
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
        }
        OAApplicationMode *am = item[@"mode"];
        BOOL isEnabled = [OAApplicationMode.values containsObject:am];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? kPaddingToLeftOfContentWithIcon : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.leftIconView.tintColor = isEnabled ? am.getProfileColor : [UIColor colorNamed:ACColorNameIconColorDisabled];
        cell.titleLabel.text = am.toHumanString;
        cell.descriptionLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        BOOL isDefault = am == OAApplicationMode.DEFAULT;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (!isDefault)
        {
            [cell.switchView setOn:isEnabled];
            [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        [cell switchVisibility:!isDefault];
        [cell dividerVisibility:!isDefault];
        return cell;
    }
     
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (UIView *) getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment
{
    NSString *descriptionText;
    if (boldFragment && boldFragment.length > 0)
        descriptionText = [NSString stringWithFormat:@"%@\n\n%@", text, boldFragment];
    else
        descriptionText = text;
    NSAttributedString *attrString;
    if (boldFragment && boldFragment.length > 0)
    {
        attrString = [OAUtilities getStringWithBoldPart:descriptionText mainString:text boldString:boldFragment lineSpacing:0. fontSize:17. boldFontSize:34. boldColor:[UIColor colorNamed:ACColorNameTextColorPrimary] mainColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
    }
    else
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        attrString = [[NSAttributedString alloc] initWithString:descriptionText attributes:@{NSParagraphStyleAttributeName : style}];
    }
    return [OAUtilities setupTableHeaderViewWithText:attrString tintColor:UIColor.whiteColor icon:_plugin.getLogoResource iconFrameSize:48. iconBackgroundColor:[UIColor colorNamed:ACColorNameIconColorActive] iconContentMode:UIViewContentModeScaleAspectFit iconYOffset:48.];
}

- (NSInteger) getTypeForSection:(NSInteger)section
{
    if (_data[section])
    {
        NSDictionary *item = _data[section].firstObject;
        if (item)
            return [item[@"sectionType"] integerValue];
    }
    return -1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger type = [self getTypeForSection:section];
    
    if (type == EOAPluginSectionTypeSuggestedMaps)
        return OALocalizedString(@"suggested_maps");
    else if (type == EOAPluginSectionTypeSuggestedProfiles)
        return OALocalizedString(@"added_profiles");
        
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSInteger type = [self getTypeForSection:section];
    
    if (type == EOAPluginSectionTypeSuggestedMaps)
        return OALocalizedString(@"suggested_maps_descr");
    else if (type == EOAPluginSectionTypeSuggestedProfiles)
        return OALocalizedString(@"added_profiles_descr");
    
    return @"";
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *type = _data[indexPath.section][indexPath.row][@"type"];
    if ([type isEqualToString:kCellTypeMap] || [type isEqualToString:kCellTypeMultyMap])
        [self onItemPressed:indexPath];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Selectors

- (void) accessoryButtonPressed:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (!indexPath)
        return;
    
    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemPressed:indexPath];
}

- (OAResourceItem *) getMapItem:(NSIndexPath *)indexPath
{
    NSDictionary *dataItem = _data[indexPath.section][indexPath.row];
    
    if ([dataItem[@"type"] isEqualToString:kCellTypeMap])
    {
        return (OARepositoryResourceItem *)dataItem[@"item"];
    }
    else if ([dataItem[@"type"] isEqualToString:kCellTypeMultyMap])
    {
        return (OAMultipleResourceItem *)dataItem[@"item"];
    }
    return nil;
}

- (void) onItemPressed:(NSIndexPath *)indexPath
{
    NSDictionary *dataItem = _data[indexPath.section][indexPath.row];
    if ([dataItem[@"type"] isEqualToString:kCellTypeMap])
    {
        [_downloadingCellResourceHelper onCellClicked:dataItem[@"resourceId"]];
    }
    else if ([dataItem[@"type"] isEqualToString:kCellTypeMultyMap])
    {
        [_downloadingCellMultipleResourceHelper onCellClicked:dataItem[@"resourceId"]];
    }
}

#pragma mark - DownloadingCellResourceHelperDelegate

- (void) onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
        [_downloadingCellResourceHelper cleanCellCache];
        [_downloadingCellMultipleResourceHelper cleanCellCache];
        [self.tableView reloadData];
    });
}

@end
