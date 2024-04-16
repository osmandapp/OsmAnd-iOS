//
//  OAHistorySettingsViewController.m
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAHistorySettingsViewController.h"
#import "OAExportItemsViewController.h"
#import "OAAppSettings.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARTargetPoint.h"
#import "OASearchUICore.h"
#import "OASearchResult.h"
#import "OASearchHistoryTableItem.h"
#import "OADistanceDirection.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAQuickSearchHelper.h"
#import "OATargetPointsHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAPointDescription.h"
#import "OAExportSettingsType.h"
#import "OAAutoObserverProxy.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import <CoreLocation/CoreLocation.h>

@implementation OAHistorySettingsViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OAHistoryHelper *_historyHelper;
    OATableDataModel *_data;
    BOOL _isLogHistoryOn;
    BOOL _decelerating;
    BOOL _isTableViewEditing;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(EOAHistorySettingsType)historyType editing:(BOOL)isEditing
{
    self = [super init];
    if (self)
    {
        _historyType = historyType;
        _isTableViewEditing = isEditing;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _historyHelper = [OAHistoryHelper sharedInstance];
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    switch (_historyType)
    {
        case EOAHistorySettingsTypeSearch:
            _isLogHistoryOn = [_settings.searchHistory get];
            break;
        case EOAHistorySettingsTypeNavigation:
            _isLogHistoryOn = [_settings.navigationHistory get];
            break;
        case EOAHistorySettingsTypeMapMarkers:
            _isLogHistoryOn = [_settings.mapMarkersHistory get];
            break;

        default:
            break;
    }
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onHistoryItemsDeleted:withKey:)
                                                 andObserve:_historyHelper.historyPointsRemoveObservable]];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setEditing:_isTableViewEditing animated:NO];
    self.tableView.allowsMultipleSelectionDuringEditing = _isTableViewEditing;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _decelerating = NO;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (self.tableView.editing)
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"),
                OALocalizedString(@"shared_string_select"),
                @([self.tableView indexPathsForSelectedRows].count).stringValue];
    }

    if (_historyType == EOAHistorySettingsTypeSearch)
        return OALocalizedString(@"shared_string_search_history");
    else if (_historyType == EOAHistorySettingsTypeNavigation)
        return OALocalizedString(@"navigation_history");
    else if (_historyType == EOAHistorySettingsTypeMapMarkers)
        return OALocalizedString(@"map_markers_history");

    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _isLogHistoryOn && self.tableView.editing ? OALocalizedString(@"shared_string_cancel") : nil;
}


- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    if (_isLogHistoryOn)
    {
        NSString *title = @"";
        if (self.tableView.editing)
            title = [self isAllSelected] ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");
        else if ([self sectionsCount] > 1)
            title = OALocalizedString(@"shared_string_edit");
        return @[[self createRightNavbarButton:title
                                      iconName:nil
                                        action:@selector(onRightNavbarButtonPressed)
                                          menu:nil]];
    }
    return nil;
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (UILayoutConstraintAxis)getBottomAxisMode
{
    return UILayoutConstraintAxisHorizontal;
}

- (NSString *)getTopButtonTitle
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_export") : @"";
}

- (NSString *)getBottomButtonTitle
{
    return self.tableView.editing ? OALocalizedString(@"shared_string_delete") : @"";
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return [self sectionsCount] == 0 || self.tableView.indexPathsForSelectedRows.count == 0 ? EOABaseButtonColorSchemeInactive : EOABaseButtonColorSchemeGraySimple;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return [self sectionsCount] == 0 || self.tableView.indexPathsForSelectedRows.count == 0 ? EOABaseButtonColorSchemeInactive : EOABaseButtonColorSchemeGrayAttn;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    if (!self.tableView.editing && !_isTableViewEditing)
    {
        OATableSectionData *switchSection = [_data createNewSection];
        [switchSection addRowFromDictionary:@{
            kCellTitleKey : [self getTitle],
            kCellTypeKey : [OASwitchTableViewCell getCellIdentifier] }
        ];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (_isLogHistoryOn)
        {
            CLLocation *newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
            CLLocationCoordinate2D myLocation = kCLLocationCoordinate2DInvalid;
            if (newLocation)
            {
                OsmAnd::LatLon latLon = OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
                myLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
            }
            
            NSMutableArray<OASearchHistoryTableItem *> *sortedHistoryItems = [NSMutableArray array];
            if (_historyType == EOAHistorySettingsTypeMapMarkers)
            {
                NSArray<OAHistoryItem *> *mapMarkersHistoryItems = [_historyHelper getPointsHavingTypes:_historyHelper.destinationTypes limit:0];
                for (OAHistoryItem *mapMarkerHistoryItem in mapMarkersHistoryItems)
                {
                    OASearchHistoryTableItem *historyTableItem = [[OASearchHistoryTableItem alloc] initWithItem:mapMarkerHistoryItem mapCenterCoordinate:myLocation];
                    [sortedHistoryItems addObject:historyTableItem];
                }
            }
            else
            {
                if (_historyType == EOAHistorySettingsTypeSearch)
                {
                    for (OASearchResult *searchResult in [self getSearchHistoryResults])
                    {
                        OAHistoryItem *historyItem = [self getHistoryEntry:searchResult];
                        if (historyItem)
                        {
                            OASearchHistoryTableItem *historyTableItem = [[OASearchHistoryTableItem alloc] initWithItem:historyItem mapCenterCoordinate:myLocation];
                            [sortedHistoryItems addObject:historyTableItem];
                        }
                    }
                }
                else if (_historyType == EOAHistorySettingsTypeNavigation)
                {
                    for (OAHistoryItem *historyItem in [[OAHistoryHelper sharedInstance] getPointsFromNavigation:0])
                    {
                        OASearchHistoryTableItem *historyTableItem = [[OASearchHistoryTableItem alloc] initWithItem:historyItem mapCenterCoordinate:myLocation];
                        [sortedHistoryItems addObject:historyTableItem];
                    }
                }
            }
            
            OASearchHistoryTableItem *prevRouteHistoryTableitem;
            OATableRowData *prevRouteItem;
            if (_historyType == EOAHistorySettingsTypeNavigation)
            {
                OARTargetPoint *pointToStartBackup = _app.data.pointToStartBackup;
                OARTargetPoint *pointToNavigateBackup = _app.data.pointToNavigateBackup;
                if (pointToNavigateBackup)
                {
                    OATableSectionData *prevRouteSection = [_data createNewSection];
                    [prevRouteSection setHeaderText:OALocalizedString(@"previous_route")];
                    
                    OAHistoryItem *prevRouteHistoryitem = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigateBackup.pointDescription];
                    prevRouteHistoryitem.name = pointToStartBackup ? pointToStartBackup.pointDescription.name : OALocalizedString(@"shared_string_my_location");
                    prevRouteHistoryitem.latitude = pointToNavigateBackup.point.coordinate.latitude;
                    prevRouteHistoryitem.longitude = pointToNavigateBackup.point.coordinate.longitude;
                    prevRouteHistoryitem.date = [NSDate date];
                    prevRouteHistoryitem.iconName = @"ic_custom_point_to_point";
                    prevRouteHistoryTableitem = [[OASearchHistoryTableItem alloc] initWithItem:prevRouteHistoryitem mapCenterCoordinate:myLocation];
                    
                    prevRouteItem = [prevRouteSection createNewRow];
                    prevRouteItem.key = @"prevRoute";
                    prevRouteItem.cellType = [OAValueTableViewCell getCellIdentifier];
                    prevRouteItem.descr = pointToNavigateBackup.pointDescription.name;
                }
            }
            
            if (sortedHistoryItems.count > 0)
            {
                [self sortSearchResults:sortedHistoryItems];
                
                NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
                NSDate *today = [calendar startOfDayForDate:[NSDate date]];
                NSDate *sevenDaysAgo = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:0];
                NSMutableDictionary<NSString *, NSMutableArray<OASearchHistoryTableItem *> *> *monthGroups = [NSMutableDictionary dictionary];
                
                OATableSectionData *lastSection = [_data createNewSection];
                lastSection.headerText = OALocalizedString(@"last_seven_days");
                
                for (OASearchHistoryTableItem *historyTableItem in sortedHistoryItems)
                {
                    if (prevRouteItem && prevRouteHistoryTableitem && prevRouteHistoryTableitem.item.latitude == historyTableItem.item.latitude && prevRouteHistoryTableitem.item.longitude == historyTableItem.item.longitude && [prevRouteItem.descr isEqualToString:historyTableItem.item.name])
                    {
                        prevRouteHistoryTableitem.item.date = historyTableItem.item.date;
                        [prevRouteItem setObj:prevRouteHistoryTableitem forKey:@"historyItem"];
                    }
                    
                    NSDate *historyItemDate = [calendar startOfDayForDate:historyTableItem.item.date];
                    if ([historyItemDate isEqualToDate:today] || [[historyItemDate laterDate:sevenDaysAgo] isEqualToDate:historyItemDate])
                    {
                        OATableRowData *rowData = [lastSection createNewRow];
                        rowData.cellType = [OAValueTableViewCell getCellIdentifier];
                        [rowData setObj:historyTableItem forKey:@"historyItem"];
                    }
                    else
                    {
                        NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:historyItemDate];
                        NSString *monthName = [[[NSDateFormatter alloc] init] monthSymbols][components.month - 1];
                        NSMutableArray<OASearchHistoryTableItem *> *groupHistoryItems = monthGroups[monthName];
                        if (!groupHistoryItems)
                        {
                            groupHistoryItems = [NSMutableArray array];
                            monthGroups[monthName] = groupHistoryItems;
                        }
                        [groupHistoryItems addObject:historyTableItem];
                    }
                }
                for (NSString *monthName in monthGroups.allKeys)
                {
                    OATableSectionData *monthSection = [_data createNewSection];
                    monthSection.headerText = monthName;
                    NSMutableArray<OASearchHistoryTableItem *> *groupHistoryItems = monthGroups[monthName];
                    for (OASearchHistoryTableItem *historyItem in groupHistoryItems)
                    {
                        OATableRowData *rowData = [monthSection createNewRow];
                        rowData.cellType = [OAValueTableViewCell getCellIdentifier];
                        [rowData setObj:historyItem forKey:@"historyItem"];
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:self.view
                              duration:.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^
                            {
                                [self.tableView reloadData];
                                [self applyLocalization];
                                [self updateNavbar];
                                [self updateBottomButtons];
                            }
                            completion:nil];
        });
    });
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;

            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = _isLogHistoryOn;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        }
        if (cell)
        {
            cell.selectionStyle = self.tableView.editing ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            OASearchHistoryTableItem *historyItem = [item objForKey:@"historyItem"];
            cell.titleLabel.text = historyItem.item.name;
            cell.leftIconView.image = [historyItem.item icon];
            cell.valueLabel.text = historyItem.item.typeName.length > 0 ? historyItem.item.typeName : OALocalizedString(@"shared_string_history");
            OADistanceDirection *distDir = [historyItem getEvaluatedDistanceDirection:_decelerating];
            cell.descriptionLabel.text = [item.key isEqualToString:@"prevRoute"] ? item.descr : distDir.distance;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        [self applyLocalization];
        if ((self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count == 0)
            || (!self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count > 0))
        {
            [self updateNavbar];
            [self updateBottomButtons];
        }
    }
}

- (void)onRowDeselected:(NSIndexPath *)indexPath
{
    [self applyLocalization];
    if ((self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count == 0)
        || (!self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count > 0))
    {
        [self updateNavbar];
        [self updateBottomButtons];
    }
}

#pragma mark - Aditions

- (void)sortSearchResults:(NSMutableArray<OASearchHistoryTableItem *> *)historyTableItems
{
    [historyTableItems sortUsingComparator:^NSComparisonResult(OASearchHistoryTableItem *h1, OASearchHistoryTableItem *h2) {
        NSTimeInterval lastTime1 = h1.item.date.timeIntervalSince1970;
        NSTimeInterval lastTime2 = h2.item.date.timeIntervalSince1970;
        return (lastTime1 < lastTime2) ? NSOrderedDescending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedAscending);
    }];
}

- (BOOL)isAllSelected
{
    NSInteger selectedCount = [self.tableView indexPathsForSelectedRows].count;
    NSInteger itemsCount = 0;
    for (NSInteger i = 0; i < [self sectionsCount]; i++)
    {
        itemsCount += [self rowsCount:i];
    }
    return itemsCount > 0 && selectedCount == itemsCount;
}

- (NSMutableArray<OASearchResult *> *)getSearchHistoryResults
{
    NSMutableArray<OASearchResult *> *searchResults = [NSMutableArray array];
    OASearchUICore *searchUICore = [[OAQuickSearchHelper instance] getCore];
    OASearchResultCollection *res = [searchUICore shallowSearch:OASearchHistoryAPI.class text:@"" matcher:nil resortAll:NO removeDuplicates:NO];
    if (res)
        [searchResults addObjectsFromArray:[res getCurrentSearchResults]];
    return searchResults;
}

- (OAHistoryItem *)getHistoryEntry:(OASearchResult *)searchResult
{
    if ([searchResult.object isKindOfClass:OAHistoryItem.class])
        return (OAHistoryItem *) searchResult.object;
    else if ([searchResult.relatedObject isKindOfClass:OAHistoryItem.class])
        return (OAHistoryItem *) searchResult.relatedObject;

    return nil;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (self.tableView.editing && !_isTableViewEditing)
    {
        [self.tableView setEditing:NO animated:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self updateUIAnimated:nil];
    }
    else
    {
        [self dismissViewController];
    }
}

- (void)onRightNavbarButtonPressed
{
    if (self.tableView.editing)
    {
        BOOL isAllSelected = [self isAllSelected];
        [self.tableView beginUpdates];
        for (NSInteger section = 0; section < [_data sectionCount]; section++)
        {
            NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
            for (NSInteger row = 0; row < rowsCount; row++)
            {
                if (isAllSelected)
                {
                    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                                  animated:YES];
                }
                else
                {
                    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                                                animated:YES
                                          scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
        [self.tableView endUpdates];
        [self applyLocalization];
        [self updateNavbar];
        [self updateBottomButtons];
   }
    else
    {
        [self.tableView setEditing:YES animated:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self updateUIAnimated:nil];
    }
}

- (void)onTopButtonPressed
{
    NSArray<NSIndexPath *> *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
    NSMutableArray<OAHistoryItem *> *selectedItems = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        OASearchHistoryTableItem *selectedItem = [[_data itemForIndexPath:indexPath] objForKey:@"historyItem"];
        if (selectedItem)
        {
            if (!selectedItem.item.date)
                selectedItem.item.date = [NSDate date];
            [selectedItems addObject:selectedItem.item];
        }
    }

    OAExportSettingsType *exportSettingsType =
            _historyType == EOAHistorySettingsTypeMapMarkers ? OAExportSettingsType.HISTORY_MARKERS
            : _historyType == EOAHistorySettingsTypeSearch ? OAExportSettingsType.SEARCH_HISTORY
            : OAExportSettingsType.NAVIGATION_HISTORY;
    OAExportItemsViewController *exportItemsViewController =
        [[OAExportItemsViewController alloc] initWithType:exportSettingsType selectedItems:selectedItems];
    [self.navigationController pushViewController:exportItemsViewController animated:YES];
}

- (void)onBottomButtonPressed
{
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths.count > 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:OALocalizedString(@"delete_history_items"), @(selectedIndexPaths.count).stringValue]
                                                                       message:[NSString stringWithFormat:OALocalizedString(@"confirm_history_item_delete"), selectedIndexPaths.count]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil
        ];
        UIAlertAction *clearAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
            NSMutableArray<OAHistoryItem *> *selectedItems = [NSMutableArray array];
            for (NSIndexPath *indexPath in selectedIndexPaths)
            {
                OATableRowData *item = [_data itemForIndexPath:indexPath];
                if ([item.key isEqualToString:@"prevRoute"])
                {
                    [[OATargetPointsHelper sharedInstance] clearBackupPoints];
                }
                else
                {
                    OASearchHistoryTableItem *selectedItem = [item objForKey:@"historyItem"];
                    if (selectedItem)
                        [selectedItems addObject:selectedItem.item];
                }
            }
            [_historyHelper removePoints:selectedItems];
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:clearAction];
        alert.preferredAction = clearAction;
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onSwitchPressed:(UISwitch *)sender
{
    BOOL isChecked = ((UISwitch *) sender).on;
    switch (_historyType)
    {
        case EOAHistorySettingsTypeSearch:
            [_settings.searchHistory set:isChecked];
            break;
        case EOAHistorySettingsTypeNavigation:
            [_settings.navigationHistory set:isChecked];
            break;
        case EOAHistorySettingsTypeMapMarkers:
            [_settings.mapMarkersHistory set:isChecked];
            break;
            
        default:
            break;
    }
    _isLogHistoryOn = !_isLogHistoryOn;
    [UIView transitionWithView:self.view
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self generateData];
                        [self.tableView reloadData];
                        [self updateNavbar];
                    }
    completion:nil];
}

- (void)onHistoryItemsDeleted:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUIAnimated:^(BOOL finished) {
            if ([self sectionsCount] == 0)
                [self onLeftNavbarButtonPressed];
        }];
    });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _decelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        _decelerating = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _decelerating = NO;
}

@end
