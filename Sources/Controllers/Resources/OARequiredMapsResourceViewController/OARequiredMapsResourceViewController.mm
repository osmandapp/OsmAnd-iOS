//
//  OARequiredMapsResourceViewController.mm
//  OsmAnd
//
//  Oleksandr Panchenko on 02.04.2024.
//  Copyright (c) 2024 OsmAnd. All rights reserved.
//

#import "OARequiredMapsResourceViewController.h"
#import "Localization.h"
#import "OAWorldRegion.h"
#import "OATableDataModel.h"
#import "OASimpleTableViewCell.h"
#import "OAResourcesUIHelper.h"
#import "OAManageResourcesViewController.h"
#import "OsmAndApp.h"

#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"
#import "MissingMapsCalculator.h"
#import "OARouteCalculationParams.h"
#import "OAProgressTitleCell.h"

#include <OsmAndCore/WorldRegions.h>
#include <routePlannerFrontEnd.h>

@interface OARequiredMapsResourceViewController ()

@end

@implementation OARequiredMapsResourceViewController
{
    NSArray<OAWorldRegion *> * _missingMaps;
    NSArray<OAWorldRegion *> * _mapsToUpdate;
    NSArray<OAWorldRegion *> * _potentiallyUsedMaps;
    
    NSArray<OAResourceItem *> * _resourcesItems;
    NSMutableArray<OAResourceItem *> * _selectedResourcesItems;
    
    OATableDataModel *_data;
    BOOL _isActiveOnlineCalculateRequest;
    BOOL _isOnlineCalculateFinished;
    NSString *_footerText;
    CLLocation *_startPoint;
    CLLocation *_endPoint;
}

#pragma mark - Initialization

- (instancetype)initWithWorldRegion:(NSArray<OAWorldRegion *> *)missingMaps
                       mapsToUpdate:(NSArray<OAWorldRegion *> *)mapsToUpdate
                potentiallyUsedMaps:(NSArray<OAWorldRegion *> *)potentiallyUsedMaps
{
    self = [super init];
    if (self)
    {
        _missingMaps = missingMaps;
        _mapsToUpdate = mapsToUpdate;
        _potentiallyUsedMaps = potentiallyUsedMaps;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.editing = YES;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView setContentInset:UIEdgeInsetsZero];
    self.tableView.sectionHeaderTopPadding = 34;
    self.bottomButton.hidden = YES;
    
    [self configureResourceItems];
    [self reloadDataWithAnimated:NO completion:nil];
    [self updateBottomButtons];
}

#pragma mark - Base UI

- (NSString *)getTopButtonTitle
{
    uint64_t sizePkgSum = 0;
    for (OAResourceItem *item in _selectedResourcesItems)
    {
        if ([item isKindOfClass:OARepositoryResourceItem.class])
            sizePkgSum += ((OARepositoryResourceItem *) item).sizePkg;
        else
            sizePkgSum += [OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize;
    }
    
    return sizePkgSum != 0 ? [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"shared_string_download"), [NSByteCountFormatter stringFromByteCount:sizePkgSum countStyle:NSByteCountFormatterCountStyleFile]] : OALocalizedString(@"shared_string_download");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:_selectedResourcesItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (NSString *)getTitle
{
    return OALocalizedString(@"required_maps");
}

- (void)onRightNavbarButtonPressed
{
    [self selectAllCells:_selectedResourcesItems.count == 0];
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    BOOL hasSelection = _selectedResourcesItems.count != 0;
    return hasSelection ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (void)registerCells
{
    for (NSString *identifier in @[[OASimpleTableViewCell getCellIdentifier],
                                   [OAButtonTableViewCell getCellIdentifier],
                                   [OAProgressTitleCell getCellIdentifier]])
    {
        [self addCell:identifier];
    }
}

- (void)generateData
{
    if (_resourcesItems.count > 0)
    {
        _data = [[OATableDataModel alloc] init];
        OATableSectionData *mainSection = [_data createNewSection];
        if (_isActiveOnlineCalculateRequest)
        {
            OATableRowData *progressOnlineRouting = [mainSection createNewRow];
            progressOnlineRouting.cellType = [OAProgressTitleCell getCellIdentifier];
            progressOnlineRouting.title = OALocalizedString(@"getting_list_required_maps");
            return;
        }
        mainSection.footerText = [self getFooterText];
        for (int i = 0; i < _resourcesItems.count; i++)
        {
            OATableRowData *resourceRow = [mainSection createNewRow];
            resourceRow.cellType = [OASimpleTableViewCell getCellIdentifier];
        }
        
        if ([self isAvailableCalculateOnlineSection] && !_isOnlineCalculateFinished)
        {
            OATableSectionData *calculateOnlineSection = [_data createNewSection];
            OATableRowData *calculateOnlineTitleRow = [calculateOnlineSection createNewRow];
            calculateOnlineTitleRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            calculateOnlineTitleRow.title = OALocalizedString(@"calculate_online_title");
            
            OATableRowData *calculateOnlineButtonRow = [calculateOnlineSection createNewRow];
            calculateOnlineButtonRow.cellType = [OAButtonTableViewCell getCellIdentifier];
            calculateOnlineButtonRow.title = OALocalizedString(@"calculate_online");
        }

        if (_potentiallyUsedMaps.count > 0)
        {
            OATableSectionData *ignoreMissingMapsSection = [_data createNewSection];

            OATableRowData *ignoreMissingMapsTitleRow = [ignoreMissingMapsSection createNewRow];
            ignoreMissingMapsTitleRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            ignoreMissingMapsTitleRow.title = OALocalizedString(@"missing_maps_ignore_details");

            OATableRowData *ignoreMissingMapsButtonRow = [ignoreMissingMapsSection createNewRow];
            ignoreMissingMapsButtonRow.cellType = [OAButtonTableViewCell getCellIdentifier];
            ignoreMissingMapsButtonRow.title = OALocalizedString(@"missing_maps_ignore");
        }
    }
}
- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if (indexPath.section == 0 && [item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        [self selectDeselectItem:indexPath];
    }
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_isActiveOnlineCalculateRequest)
    {
        return 1;
    }
    return section == 0 ? _resourcesItems.count : 2;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if (indexPath.section == 0)
    {
        if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
        {
            OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:item.cellType];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            
            [cell leftEditButtonVisibility:NO];
            [cell leftIconVisibility:YES];
            [cell titleVisibility:YES];
            [cell descriptionVisibility:YES];
            
            OAResourceItem * item = _resourcesItems[indexPath.row];
            BOOL selected = [_selectedResourcesItems containsObject:item];
            NSString *resourceId = [item.resourceId.toNSString() stringByDeletingPathExtension];
            cell.leftIconView.image = [UIImage imageNamed:[self containsInMapsToUpdate:resourceId] ? @"ic_custom_update_map" : @"ic_custom_download_map"];
            cell.leftIconView.tintColor = selected ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.leftIconView.contentMode = UIViewContentModeCenter;
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
            NSString *title = item.title;
            if (item.worldRegion && item.worldRegion.superregion)
            {
                NSString *countryName = [OAResourcesUIHelper getCountryName:item];
                if (countryName)
                    title = [NSString stringWithFormat:@"%@, %@", item.title, countryName];
            }
            cell.titleLabel.text = title;
            
            UIView *bgColorView = [UIView new];
            bgColorView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            [cell setSelectedBackgroundView:bgColorView];
            
            NSString *size;
            if ([item isKindOfClass:OARepositoryResourceItem.class])
                size = [NSByteCountFormatter stringFromByteCount:((OARepositoryResourceItem *) item).sizePkg countStyle:NSByteCountFormatterCountStyleFile];
            else
                size = [NSByteCountFormatter stringFromByteCount:[OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize countStyle:NSByteCountFormatterCountStyleFile];
            
            cell.descriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", size, [item getDate]];
            return cell;
        }
        else if ([item.cellType isEqualToString:[OAProgressTitleCell getCellIdentifier]])
        {
            OAProgressTitleCell *cell = [self.tableView dequeueReusableCellWithIdentifier:item.cellType];
            cell.titleLabel.text = item.title;
            [cell.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            [cell.activityIndicator startAnimating];
            return cell;
        }
    }
    else
    {
        if ([item.cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
        {
            OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:item.cellType];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.separatorInset = UIEdgeInsetsMake(0., 20, 0., 0.);
            cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            
            cell.button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            
            [cell.button setTitle:item.title forState:UIControlStateNormal];
            [cell.button setTitleColor:[UIColor colorNamed:ACColorNameTextColorActive] forState:UIControlStateHighlighted];
            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];

            if ([item.title isEqualToString:OALocalizedString(@"calculate_online")])
            {
                [cell.button addTarget:self action:@selector(onCalculateOnlineButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([item.title isEqualToString:OALocalizedString(@"missing_maps_ignore")])
            {
                [cell.button addTarget:self action:@selector(onIgnoreMissingMapsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            }

            return cell;
        }
        else if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
        {
            OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:item.cellType];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            [cell leftEditButtonVisibility:NO];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:YES];
            [cell descriptionVisibility:NO];
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.text = item.title;
            [cell.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
            
            UIView *bgColorView = [UIView new];
            bgColorView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            [cell setSelectedBackgroundView:bgColorView];
            
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if (indexPath.section == 0 && [item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]]) {
        OAResourceItem *item = _resourcesItems[indexPath.row];
        BOOL selected = [_selectedResourcesItems containsObject:item];
        [cell setSelected:selected animated:YES];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    return indexPath.section == 0 && [item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectDeselectItem:indexPath];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (_data.sectionCount > 0)
        return [_data sectionDataForIndex:section].footerText;
    return nil;
}

#pragma mark - Private methods

- (NSString *)getCountryName:(OAWorldRegion *)reg
{
    NSString *countryName;
    
    OAWorldRegion *worldRegion = [OsmAndApp instance].worldRegion;
    OAWorldRegion *region = reg;
    
    if (region.superregion)
    {
        while (region.superregion != worldRegion && region.superregion != nil)
            region = region.superregion;
        
        if ([region.regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()])
            countryName = region.name;
        else if (reg.superregion.superregion != worldRegion)
            countryName = reg.superregion.name;
    }
    
    return countryName;
}

- (NSString *)configureFooterTextForRegions:(NSArray<OAWorldRegion *> *)regions
{
    // Maps that will also be used: "Hamburg, Germany", "Saarland, Germany", "Saxony, Germany".
    NSMutableString *description = [NSMutableString string];
    if (regions.count > 0)
    {
        for (NSInteger i = 0; i < regions.count; i++)
        {
            OAWorldRegion *region = regions[i];
            NSString *title = region.localizedName?:region.nativeName;
            if (region.superregion)
            {
                NSString *countryName = [self getCountryName:region];
                if (countryName)
                {
                    if (title)
                        title = [NSString stringWithFormat:@"\"%@, %@\"", title, countryName];
                    else
                        title = [NSString stringWithFormat:@"\"%@\"", countryName];
                }
            }
            if (title)
            {
                [description appendFormat:@"%@%@",(description.length > 0 ? @", " : @""), title];
            }
        }
        if (description.length > 0)
        {
            [description appendString:@"."];
        }
    }
    return [NSString stringWithFormat:OALocalizedString(@"required_maps_list"), description];
}

- (NSString *)getFooterText
{
    if (_potentiallyUsedMaps.count > 0)
    {
        return [self configureFooterTextForRegions:_potentiallyUsedMaps];
    }
    return @"";
}

- (void)selectAllCells:(BOOL)shouldSelect
{
    if (shouldSelect)
    {
        _selectedResourcesItems = [_resourcesItems mutableCopy];
    }
    else
    {
        [_selectedResourcesItems removeAllObjects];
    }
    
    for (NSInteger i = 0; i < _resourcesItems.count; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^(void) {
        [self.tableView reloadData];
    }
                    completion:nil];
    [self updateBottomButtons];
    [self setupNavbarButtons];
}

- (void)configureResourceItems
{
    _resourcesItems = @[];
    _selectedResourcesItems = [NSMutableArray array];
    
    NSArray<OAResourceItem *> *_missingMapsResources = [OAResourcesUIHelper getMapRegionResourcesToDownloadForRegions:_missingMaps];
    NSArray<OAResourceItem *> *_mapsToUpdateResources = [OAResourcesUIHelper getMapRegionResourcesToUpdateForRegions:_mapsToUpdate];
    
    NSArray<OAResourceItem *> *resources = [NSArray arrayWithArray:[_missingMapsResources arrayByAddingObjectsFromArray:_mapsToUpdateResources]];
    
    if (resources.count > 0)
    {
        _resourcesItems = resources;
        _selectedResourcesItems = [resources mutableCopy];
        [self.tableView reloadData];
    }
}

- (BOOL)containsInMapsToUpdate:(NSString *)substring
{
    for (OAWorldRegion *region in _mapsToUpdate)
    {
        return [region.downloadsIdPrefix rangeOfString:substring].location != NSNotFound;
    }
    return NO;
}

#pragma mark - Actions

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    OAResourceItem *item = _resourcesItems[indexPath.row];
    if ([_selectedResourcesItems containsObject:item])
        [_selectedResourcesItems removeObject:item];
    else
        [_selectedResourcesItems addObject:item];
    
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^(void) {
        [self.tableView reloadData];
    }
                    completion:nil];
    [self updateBottomButtons];
    [self setupNavbarButtons];
}

- (void)onIgnoreMissingMapsButtonPressed:(id)sender
{
    [OAAppSettings sharedManager].ignoreMissingMaps = YES;
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

- (void)onCalculateOnlineButtonPressed:(id)sender
{
    if (AFNetworkReachabilityManager.sharedManager.isReachable)
    {
        auto missingMapsCalculator = [MissingMapsCalculator new];
        OARouteCalculationResult *prevRoute = [OARoutingHelper.sharedInstance getRoute];
        if (prevRoute != nil
            && prevRoute.missingMapsPoints != nil
            && prevRoute.missingMapsRoutingContext != nullptr) {
            _isActiveOnlineCalculateRequest = YES;
            [self selectAllCells:NO];
            [self reloadDataWithAnimated:NO completion:nil];
            [self.navigationItem setRightBarButtonItemsisEnabled:NO tintColor:[UIColor colorNamed:ACColorNameButtonBgColorDisabled]];
            __weak __typeof(self) weakSelf = self;
            [OAResourcesUIHelper onlineCalculateRequestWithRouteCalculationResult:prevRoute completion:^(NSArray<CLLocation *> *locations, NSError *error) {
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;
                [strongSelf onlineCalculateFinishState];
                if (!error && locations.count > 0)
                {
                    bool oldRouting = [[OAAppSettings sharedManager].useOldRouting get];
                    if ([missingMapsCalculator checkIfThereAreMissingMaps:prevRoute.missingMapsRoutingContext start:prevRoute.missingMapsPoints.firstObject targets:locations checkHHEditions:!oldRouting])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf updateRoutingResourcesWithMissingMaps:missingMapsCalculator.missingMaps
                                                                 mapsToUpdate:missingMapsCalculator.mapsToUpdate
                                                          potentiallyUsedMaps:missingMapsCalculator.potentiallyUsedMaps];
                            [prevRoute setMissingMaps:missingMapsCalculator.missingMaps
                                         mapsToUpdate:missingMapsCalculator.mapsToUpdate
                                             usedMaps:missingMapsCalculator.potentiallyUsedMaps ctx:prevRoute.missingMapsRoutingContext points:prevRoute.missingMapsPoints];
                            [missingMapsCalculator clearResult];
                            [strongSelf selectAllCells:YES];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf reloadDataWithAnimated:NO completion:nil];
                            [strongSelf selectAllCells:YES];
                        });
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf reloadDataWithAnimated:NO completion:nil];
                        [strongSelf selectAllCells:YES];
                    });
                }
            }];
        }
    }
    else
    {
        [OAResourcesUIHelper showNoInternetAlert];
    }
}

- (void)onTopButtonPressed
{
    if (_selectedResourcesItems.count > 0)
    {
        if (AFNetworkReachabilityManager.sharedManager.isReachable)
        {
            if (self.onTapDownloadButtonCallback)
                self.onTapDownloadButtonCallback();
            OAMultipleResourceItem *item = [[OAMultipleResourceItem alloc] initWithType:OsmAndResourceType::MapRegion items:_selectedResourcesItems];
            [OAResourcesUIHelper offerMultipleDownloadAndInstallOf:item selectedItems:_selectedResourcesItems onTaskCreated:nil onTaskResumed:nil];
            
            [self dismissViewController];
        }
        else
        {
            [OAResourcesUIHelper showNoInternetAlert];
        }
    }
}

- (void)updateRoutingResourcesWithMissingMaps:(NSArray<OAWorldRegion *> *)missingMaps
                                 mapsToUpdate:(NSArray<OAWorldRegion *> *)mapsToUpdate
                          potentiallyUsedMaps:(NSArray<OAWorldRegion *> *)potentiallyUsedMaps;
{
    _missingMaps = missingMaps;
    _mapsToUpdate = mapsToUpdate;
    _potentiallyUsedMaps = potentiallyUsedMaps;
    
    [self configureResourceItems];
    [self reloadDataWithAnimated:NO completion:nil];
    [self updateBottomButtons];
}

- (void)onlineCalculateFinishState
{
    _isActiveOnlineCalculateRequest = NO;
    _isOnlineCalculateFinished = YES;
}

- (BOOL)isAvailableCalculateOnlineSection
{
    OAApplicationMode *currentMode = [OAAppSettings sharedManager].applicationMode.get;
    return [@[OAApplicationMode.CAR, OAApplicationMode.BICYCLE] containsObject:currentMode];
}

@end
