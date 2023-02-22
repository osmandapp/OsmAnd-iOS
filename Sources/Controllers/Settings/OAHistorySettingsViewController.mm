//
//  OAHistorySettingsViewController.m
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAHistorySettingsViewController.h"
#import "OAGlobalSettingsViewController.h"
#import "OAExportItemsViewController.h"
#import "OAAppSettings.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARTargetPoint.h"
#import "OAQuickSearchListItem.h"
#import "OASearchResult.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OATargetPointsHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAPointDescription.h"
#import "OAOsmAndFormatter.h"
#import "OAExportSettingsType.h"
#import "OAAutoObserverProxy.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Utilities.h>

@implementation OAHistorySettingsViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OAHistoryHelper *_historyHelper;
    OATableDataModel *_data;
    BOOL _isLogHistoryOn;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(EOAHistorySettingsType)historyType
{
    self = [super init];
    if (self)
    {
        _historyType = historyType;
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

#pragma mark - Base setup UI

- (void)setupBottomFonts
{
    self.topButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17.];
    self.bottomButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17.];
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
    return _isLogHistoryOn && self.tableView.editing ? OALocalizedString(@"shared_string_cancel") : @"";
}

- (NSString *)getRightNavbarButtonTitle
{
    if (_isLogHistoryOn)
    {
        if (self.tableView.editing)
            return [self isAllSelected] ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");
        else if ([self sectionsCount] > 1)
            return OALocalizedString(@"shared_string_edit");
    }
    return @"";
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (BOOL)isChevronIconVisible
{
    return !self.tableView.editing;
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

- (void)updateDistanceAndDirection:(OAHistoryItem *)historyItem
{
    CLLocation *newLocation = _app.locationServices.lastKnownLocation;
    if (newLocation)
    {
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
                (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                        ? newLocation.course : newHeading;

        OsmAnd::LatLon latLon(historyItem.latitude, historyItem.longitude);
        const auto &position31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        CLLocation *location = [[CLLocation alloc] initWithLatitude:OsmAnd::Utilities::get31LatitudeY(position31.y)
                                                          longitude:OsmAnd::Utilities::get31LongitudeX(position31.x)];

        double distanceMeters = OsmAnd::Utilities::distance(
                newLocation.coordinate.longitude,
                newLocation.coordinate.latitude,
                location.coordinate.longitude,
                location.coordinate.latitude
        );
        NSString *distance = [OAOsmAndFormatter getFormattedDistance:distanceMeters];
        if (!distance)
            distance = [OAOsmAndFormatter getFormattedDistance:0];
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:location];
        CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

        historyItem.distanceMeters = distanceMeters;
        historyItem.distance = distance;
        historyItem.direction = direction;
    }
}

- (void)generateData
{
    _data = [OATableDataModel model];

    if (!self.tableView.editing)
    {
        OATableSectionData *switchSection = [_data createNewSection];
        [switchSection addRowFromDictionary:@{
            kCellTitleKey : [self getTitle],
            kCellTypeKey : [OASwitchTableViewCell getCellIdentifier] }
        ];
    }

    if (_isLogHistoryOn)
    {
        NSMutableDictionary<NSNumber *, NSDictionary<NSString *, NSString *> *> *historyDetails = [NSMutableDictionary dictionary];
        NSMutableArray<OAHistoryItem *> *sortedHistoryItems = [NSMutableArray array];

        if (_historyType == EOAHistorySettingsTypeMapMarkers)
        {
            sortedHistoryItems = [NSMutableArray arrayWithArray:[_historyHelper getPointsHavingTypes:_historyHelper.destinationTypes limit:0]];
        }
        else
        {
            NSMutableArray<OASearchResult *> *searchResults = [NSMutableArray array];
            if (self.delegate)
            {
                if (_historyType == EOAHistorySettingsTypeSearch)
                    [searchResults addObjectsFromArray:[self.delegate getSearchHistoryResults]];
                else if (_historyType == EOAHistorySettingsTypeNavigation)
                    [searchResults addObjectsFromArray:[self.delegate getNavigationHistoryResults]];
            }
            for (OASearchResult *searchResult in searchResults)
            {
                OAHistoryItem *historyItem = [self.delegate getHistoryEntry:searchResult];
                if (historyItem)
                {
                    [sortedHistoryItems addObject:historyItem];
                    NSString *iconName = [OAQuickSearchListItem getIconName:searchResult];
                    historyDetails[@(historyItem.hId)] = @{
                        @"name" : [OAQuickSearchListItem getName:searchResult],
                        @"iconName" : iconName ? iconName : @"ic_custom_marker"
                    };
                }
            }
        }

        if (_historyType == EOAHistorySettingsTypeNavigation)
        {
            OARTargetPoint *pointToStartBackup = _app.data.pointToStartBackup;
            OARTargetPoint *pointToNavigateBackup = _app.data.pointToNavigateBackup;
            if (pointToNavigateBackup)
            {
                OATableSectionData *prevRouteSection = [_data createNewSection];
                [prevRouteSection setHeaderText:OALocalizedString(@"previous_route")];

                OAHistoryItem *historyitem = [[OAHistoryItem alloc] initWithPointDescription:pointToNavigateBackup.pointDescription];
                historyitem.name = pointToNavigateBackup.pointDescription.name;
                historyitem.latitude = pointToNavigateBackup.point.coordinate.latitude;
                historyitem.longitude = pointToNavigateBackup.point.coordinate.longitude;
                [prevRouteSection addRowFromDictionary:@{
                    kCellKeyKey : @"prevRoute",
                    kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                    kCellTitleKey : pointToStartBackup ? pointToStartBackup.pointDescription.name : OALocalizedString(@"shared_string_my_location"),
                    kCellDescrKey : pointToNavigateBackup.pointDescription.name,
                    kCellIconNameKey : @"ic_custom_point_to_point",
                    @"historyItem" : historyitem
                }];
            }
        }

        if (sortedHistoryItems.count > 0)
        {
            [self sortSearchResults:sortedHistoryItems];

            NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
            NSDate *today = [calendar startOfDayForDate:[NSDate date]];
            NSDate *sevenDaysAgo = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:0];
            NSMutableDictionary<NSString *, NSMutableArray<OAHistoryItem *> *> *monthGroups = [NSMutableDictionary dictionary];

            OATableSectionData *lastSection = [_data createNewSection];
            lastSection.headerText = OALocalizedString(@"last_seven_days");

            for (OAHistoryItem *historyItem in sortedHistoryItems)
            {
                [self updateDistanceAndDirection:historyItem];
                NSDate *historyItemDate = [calendar startOfDayForDate:historyItem.date];
                if ([historyItemDate isEqualToDate:today] || [[historyItemDate laterDate:sevenDaysAgo] isEqualToDate:historyItemDate])
                {
                    OATableRowData *rowData = [lastSection createNewRow];
                    rowData.cellType = [OASimpleTableViewCell getCellIdentifier];
                    [rowData setObj:historyItem forKey:@"historyItem"];
                    if (historyDetails.count > 0)
                    {
                        rowData.title = historyDetails[@(historyItem.hId)][@"name"];
                        rowData.iconName = historyDetails[@(historyItem.hId)][@"iconName"];
                    }
                }
                else
                {
                    NSDateComponents *components = [calendar components:NSCalendarUnitMonth fromDate:historyItemDate];
                    NSString *monthName = [[[NSDateFormatter alloc] init] monthSymbols][components.month - 1];
                    NSMutableArray<OAHistoryItem *> *groupHistoryItems = monthGroups[monthName];
                    if (!groupHistoryItems)
                    {
                        groupHistoryItems = [NSMutableArray array];
                        monthGroups[monthName] = groupHistoryItems;
                    }
                    [groupHistoryItems addObject:historyItem];
                }
            }
            for (NSString *monthName in monthGroups.allKeys)
            {
                OATableSectionData *monthSection = [_data createNewSection];
                monthSection.headerText = monthName;
                NSMutableArray<OAHistoryItem *> *groupHistoryItems = monthGroups[monthName];
                for (OAHistoryItem *historyItem in groupHistoryItems)
                {
                    OATableRowData *rowData = [monthSection createNewRow];
                    rowData.cellType = [OASimpleTableViewCell getCellIdentifier];
                    [rowData setObj:historyItem forKey:@"historyItem"];
                    if (historyDetails.count > 0)
                    {
                        rowData.title = historyDetails[@(historyItem.hId)][@"name"];
                        rowData.iconName = historyDetails[@(historyItem.hId)][@"iconName"];
                    }
                }
            }
        }
    }
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
    else if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
        }
        if (cell)
        {
            cell.selectionStyle = self.tableView.editing ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

            OAHistoryItem *historyItem = [item objForKey:@"historyItem"];
            NSString *title = item.title;
            if ((!item.title || item.title.length == 0) && historyItem)
                title = historyItem.name.length > 0 ? historyItem.name : historyItem.typeName;
            cell.titleLabel.text = title;
            cell.descriptionLabel.text = historyItem && historyItem.distance ? historyItem.distance : item.descr;

            NSString *iconName = item.iconName;
            UIImage *icon;
            if (iconName)
                icon = [UIImage imageNamed:iconName];
            if (!icon && historyItem)
                icon = [historyItem icon];
            if (!icon)
            {
                if (_historyType == EOAHistorySettingsTypeSearch)
                    icon = [UIImage imageNamed:@"ic_map_pin_small"];
                else if (_historyType == EOAHistorySettingsTypeSearch)
                    icon = [UIImage imageNamed:@"ic_custom_history"];
                else if (_historyType == EOAHistorySettingsTypeMapMarkers)
                    icon = [UIImage imageNamed:@"ic_custom_marker"];
            }
            cell.leftIconView.image = icon;
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
            [self updateBottomButtons];
    }
}

- (void)onRowDeselected:(NSIndexPath *)indexPath
{
    [self applyLocalization];
    if ((self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count == 0)
        || (!self.topButton.enabled && self.tableView.indexPathsForSelectedRows.count > 0))
        [self updateBottomButtons];
}

#pragma mark - Aditions

- (void)sortSearchResults:(NSMutableArray<OAHistoryItem *> *)historyItems
{
    [historyItems sortUsingComparator:^NSComparisonResult(OAHistoryItem *h1, OAHistoryItem *h2) {
        NSTimeInterval lastTime1 = h1.date.timeIntervalSince1970;
        NSTimeInterval lastTime2 = h2.date.timeIntervalSince1970;
        return (lastTime1 < lastTime2) ? NSOrderedAscending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedDescending);
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

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (self.tableView.editing)
    {
        [self.tableView setEditing:NO animated:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self updateUIAnimated];
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
        [self updateBottomButtons];
   }
    else
    {
        [self.tableView setEditing:YES animated:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        [self updateUIAnimated];
    }
}

- (void)onTopButtonPressed
{
    NSArray<NSIndexPath *> *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
    NSMutableArray<OAHistoryItem *> *selectedItems = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedIndexPaths)
    {
        OAHistoryItem *selectedItem = [[_data itemForIndexPath:indexPath] objForKey:@"historyItem"];
        if (selectedItem)
        {
            if (!selectedItem.date)
                selectedItem.date = [NSDate date];
            [selectedItems addObject:selectedItem];
        }
    }

    OAExportSettingsType *exportSettingsType =
        _historyType == EOAHistorySettingsTypeMapMarkers ? OAExportSettingsType.HISTORY_MARKERS : OAExportSettingsType.SEARCH_HISTORY;
    OAExportItemsViewController *exportItemsViewController =
        [[OAExportItemsViewController alloc] initWithType:exportSettingsType selectedItems:selectedItems];
    [self.navigationController pushViewController:exportItemsViewController animated:YES];
}

- (void)onBottomButtonPressed
{
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if (selectedIndexPaths.count > 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"delete_history_items")
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
                    OAHistoryItem *selectedItem = [item objForKey:@"historyItem"];
                    if (selectedItem)
                        [selectedItems addObject:selectedItem];
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
                        [self.rightNavbarButton setTitle:[self getRightNavbarButtonTitle] forState:UIControlStateNormal];
                        [self updateNavbar];
                    }
    completion:nil];
}

- (void)onHistoryItemsDeleted:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUIAnimated];
        if ([self sectionsCount] == 0)
            [self onLeftNavbarButtonPressed];
    });
}

@end
