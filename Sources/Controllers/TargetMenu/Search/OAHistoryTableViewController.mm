//
//  OAHistoryTableViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAHistoryTableViewController.h"
#import "OsmAndApp.h"
#import <CoreLocation/CoreLocation.h>
#import "OAHistoryItem.h"
#import "OAMultiselectableHeaderView.h"
#import "OAHistoryHelper.h"
#import "Localization.h"
#import "OAPointDescCell.h"
#import "OAUtilities.h"
#import "OADistanceDirection.h"
#import "OARootViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OAFilledButtonCell.h"
#import "OASearchHistoryTableItem.h"
#import "OASearchHistoryTableGroup.h"
#import "OAHistorySettingsViewController.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/Utilities.h>

@interface OAHistoryTableViewController () <OAMultiselectableHeaderDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray* groupsAndItems;

@end

@implementation OAHistoryTableViewController
{
    OAAppSettings *_settings;
    OATableDataModel *_data;
    BOOL _decelerating;
    NSArray *_headerViews;
    BOOL _wasAnyDeleted;
    BOOL _isSearchLoggingDisabled;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"OAHistoryTableViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapHandler:)];
    longPressGesture.delegate = self;
    [self.tableView addGestureRecognizer:longPressGesture];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50.0;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _decelerating = NO;
    _settings = [OAAppSettings sharedManager];
    _isSearchLoggingDisabled = ![_settings.searchHistory get];
    [self reloadData];
}

- (void)longTapHandler:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (![self.tableView isEditing] && gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (_isSearchLoggingDisabled)
        {
            OATableRowData *item = [_data itemForIndexPath:indexPath];
            if ([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]] || [item.cellType isEqualToString:[OAFilledButtonCell getCellIdentifier]])
                return;
        }
        
        OASearchHistoryTableGroup *groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
        OASearchHistoryTableItem *dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
        BOOL isFromNavigation = dataItem.item.fromNavigation;
        OAHistorySettingsViewController *historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:isFromNavigation ? EOAHistorySettingsTypeNavigation : EOAHistorySettingsTypeSearch editing:YES];
        [self.navigationController pushViewController:historyViewController animated:YES];
        
        // TODO: Remove the commented-out code below and any associated obsolete logic related to the table view's editing mode. https://github.com/osmandapp/OsmAnd-Issues/issues/2431
        
//        _wasAnyDeleted = NO;
//        
//        if (self.delegate)
//            [self.delegate enterHistoryEditingMode];
//        
//        [self.tableView beginUpdates];
//        [self.tableView setEditing:YES animated:YES];
//        if (indexPath && gestureRecognizer.state == UIGestureRecognizerStateBegan)
//        {
//            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
//            if (self.delegate)
//                [self.delegate historyItemsSelected:1];
//        }
//        
//        [self.tableView endUpdates];
    }
}

- (void)editDone
{
    [self.tableView beginUpdates];
    [self.tableView setEditing:NO animated:YES];
    [self.tableView endUpdates];
    
    if (_wasAnyDeleted)
    {
        _wasAnyDeleted = NO;
        [self generateData];
        [self updateDistanceAndDirection];
    }
}

-(void)reloadData
{
    if (_isSearchLoggingDisabled)
    {
        [self generateData];
        [self.tableView reloadData];
    }
    else
    {
        [self generateData];
        if (self.groupsAndItems.count > 0)
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [self updateDistanceAndDirection];
    }
}

- (NSTimeInterval)beginningOfToday
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    [components setNanosecond:0];
    NSDate *today = [cal dateFromComponents:components];
    
    return [today timeIntervalSince1970];
}

-(void)generateData
{
    [self generateData:YES];
}

-(void)generateData:(BOOL)doReload
{
    _data = [[OATableDataModel alloc] init];
    
    if (_isSearchLoggingDisabled)
    {
        OATableSectionData *existingBackupSection = [_data createNewSection];
        [existingBackupSection addRowFromDictionary:@{
            kCellTypeKey: OALargeImageTitleDescrTableViewCell.getCellIdentifier,
            kCellTitleKey: OALocalizedString(@"search_history_disabled"),
            kCellDescrKey: OALocalizedString(@"enable_search_history"),
            kCellIconNameKey: @"ic_custom_history_disabled_48"
        }];
        [existingBackupSection addRowFromDictionary:@{
            kCellTypeKey: OAFilledButtonCell.getCellIdentifier,
            kCellKeyKey: @"onHistorySettingsButtonPressed",
            kCellTitleKey: OALocalizedString(@"shared_string_settings")
        }];
    }
    else
    {
        self.groupsAndItems = [NSMutableArray array];
        NSMutableArray *headerViews = [NSMutableArray array];
        
        OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
        NSArray *allItems = [helper getPointsHavingTypes:helper.searchTypes exceptNavigation:NO limit:0];
        
        NSTimeInterval todayBeginTime = [self beginningOfToday];
        NSTimeInterval yesterdayBeginTime = todayBeginTime - 60 * 60 * 24;
        
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"LLLL - yyyy"];
        
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_myLocation);
        CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        
        for (OAHistoryItem *item in allItems)
        {
            NSString *groupName;
            NSTimeInterval time = [item.date timeIntervalSince1970];
            if (time < yesterdayBeginTime)
            {
                groupName = [fmt stringFromDate:item.date];
            }
            else if (time < todayBeginTime)
            {
                groupName = @"1";
            }
            else
            {
                groupName = @"0";
            }
            
            OASearchHistoryTableGroup *grp;
            for (OASearchHistoryTableGroup *g in self.groupsAndItems)
                if ([g.groupName isEqualToString:groupName])
                {
                    grp = g;
                    break;
                }
            
            if (!grp)
            {
                grp = [[OASearchHistoryTableGroup alloc] init];
                grp.groupName = groupName;
                [self.groupsAndItems addObject:grp];
            }
            
            OASearchHistoryTableItem *tableItem;
            if (_searchNearMapCenter)
                tableItem = [[OASearchHistoryTableItem alloc] initWithItem:item mapCenterCoordinate:myLocation];
            else
                tableItem = [[OASearchHistoryTableItem alloc] initWithItem:item];
            
            [grp.groupItems addObject:tableItem];
        }
        
        // Sort items
        /*
         NSArray *sortedArrayGroups = [self.groupsAndItems sortedArrayUsingComparator:^NSComparisonResult(SearchHistoryTableGroup* obj1, SearchHistoryTableGroup* obj2) {
         return [obj1.groupName localizedCaseInsensitiveCompare:obj2.groupName];
         }];
         [self.groupsAndItems setArray:sortedArrayGroups];
         */
        
        int i = 0;
        for (OASearchHistoryTableGroup *group in self.groupsAndItems)
        {
            // add header
            OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
            if ([group.groupName isEqualToString:@"0"])
                [headerView setTitleText:OALocalizedString(@"today")];
            else if ([group.groupName isEqualToString:@"1"])
                [headerView setTitleText:OALocalizedString(@"yesterday")];
            else
                [headerView setTitleText:group.groupName];
            
            headerView.section = i++;
            headerView.delegate = self;
            [headerViews addObject:headerView];
        }
        
        if (doReload)
            [self.tableView reloadData];
        
        _headerViews = [NSArray arrayWithArray:headerViews];
    }
}

-(void)setSearchNearMapCenter:(BOOL)searchNearMapCenter
{
    _searchNearMapCenter = searchNearMapCenter;
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_myLocation);
    CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    for (OASearchHistoryTableGroup *group in self.groupsAndItems)
        for (OASearchHistoryTableItem *dataItem in group.groupItems)
        {
            if (searchNearMapCenter)
                [dataItem setMapCenterCoordinate:myLocation];
            else
                [dataItem resetMapCenterSearch];
        }
}

- (void)updateDistanceAndDirection
{
    if ([self.tableView isEditing] || _decelerating)
        return;
        
    [self refreshVisibleRows];
}

- (void)refreshVisibleRows
{
    if ([self.tableView isEditing])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            OAPointDescCell *cell = (OAPointDescCell *)[self.tableView cellForRowAtIndexPath:i];
            OASearchHistoryTableGroup *groupData = [self.groupsAndItems objectAtIndex:i.section];
            OASearchHistoryTableItem *dataItem = [groupData.groupItems objectAtIndex:i.row];
            [self updateCell:cell dataItem:dataItem];
        }
        [self.tableView endUpdates];
    });
}

- (void)deleteSelected
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:OALocalizedString(@"hist_select_remove") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:OALocalizedString(@"hist_remove_q") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        NSArray* selectedItems = [self getItemsForRows:selectedRows];
        
        NSMutableArray *arr = [NSMutableArray array];
        for (OASearchHistoryTableItem* dataItem in selectedItems)
            [arr addObject:dataItem.item];
        
        [[OAHistoryHelper sharedInstance] removePoints:arr];
        
        _wasAnyDeleted = YES;
        
        if (self.delegate)
        {
            [self editDone];
            [self.delegate exitHistoryEditingMode];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(NSArray*)getItemsForRows:(NSArray*)indexPath
{
    NSMutableArray* itemList = [[NSMutableArray alloc] init];
    
    [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
        OASearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:path.section];
        [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
    }];
    
    return itemList;
}

-(void)onHistorySettingsButtonPressed
{
    OAHistorySettingsViewController* historyViewController = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    [OARootViewController.instance.navigationController pushViewController:historyViewController animated:YES];
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
    
    [self.tableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView endUpdates];

    if (self.delegate && self.tableView.editing)
        [self.delegate historyItemsSelected:(int)([self.tableView indexPathsForSelectedRows].count)];
}

- (void)updateCell:(OAPointDescCell *)cell dataItem:(OASearchHistoryTableItem *)dataItem
{
    if (_isSearchLoggingDisabled)
    {
        return;
    }
    else
    {
        [cell.titleView setText:dataItem.item.name];
        cell.titleIcon.image = [dataItem.item icon];
        [cell.descView setText:dataItem.item.typeName.length > 0 ? dataItem.item.typeName : OALocalizedString(@"shared_string_history")];
        cell.openingHoursView.hidden = YES;
        cell.timeIcon.hidden = YES;
        
        OADistanceDirection *distDir = [dataItem getEvaluatedDistanceDirection:_decelerating];
        
        [cell.distanceView setText:distDir.distance];
        if (_searchNearMapCenter)
        {
            cell.directionImageView.hidden = YES;
            cell.distanceViewLeadingOutlet.constant = 16;
        }
        else
        {
            cell.directionImageView.hidden = NO;
            cell.distanceViewLeadingOutlet.constant = 34;
            cell.directionImageView.transform = CGAffineTransformMakeRotation(distDir.direction);
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isSearchLoggingDisabled)
        return _data.sectionCount;
    else
        return [self.groupsAndItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == tableView.numberOfSections - 1)
        return tableView.sectionFooterHeight;
    else
        return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_isSearchLoggingDisabled)
        return  nil;
    else
        return _headerViews[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isSearchLoggingDisabled)
        return [_data rowCount:section];
    else
        return [((OASearchHistoryTableGroup*)[self.groupsAndItems objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isSearchLoggingDisabled)
    {
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        NSString *cellId = item.cellType;
        if ([cellId isEqualToString:OALargeImageTitleDescrTableViewCell.getCellIdentifier])
        {
            OALargeImageTitleDescrTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OALargeImageTitleDescrTableViewCell.getCellIdentifier];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OALargeImageTitleDescrTableViewCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell showButton:NO];
                cell.cellImageView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            }
            if (cell)
            {
                cell.titleLabel.text = item.title;
                cell.descriptionLabel.text = item.descr;
                [cell.cellImageView setImage:[UIImage templateImageNamed:item.iconName]];

                if (cell.needsUpdateConstraints)
                    [cell updateConstraints];
            }
            return cell;
        }
        else if ([cellId isEqualToString:OAFilledButtonCell.getCellIdentifier])
        {
            OAFilledButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:OAFilledButtonCell.getCellIdentifier];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
                cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
                cell.button.backgroundColor = [[UIColor colorNamed:ACColorNameButtonBgColorPrimary] colorWithAlphaComponent:0.1];
                [cell.button setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorPrimary] forState:UIControlStateHighlighted];
                cell.button.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
                cell.button.layer.cornerRadius = 9.;
                cell.topMarginConstraint.constant = 9.;
                cell.bottomMarginConstraint.constant = 20.;
                cell.heightConstraint.constant = 42.;
                cell.leadingConstraint.constant = 100.;
                cell.trailingConstraint.constant = 100.;
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            if (cell)
            {
                [cell.button setTitle:item.title forState:UIControlStateNormal];
                [cell.button addTarget:self action:NSSelectorFromString(item.key) forControlEvents:UIControlEventTouchUpInside];
            }
            return cell;
        }
    }
    else
    {
        OASearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
        
        OAPointDescCell* cell;
        cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAPointDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OASearchHistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
            [self updateCell:cell dataItem:dataItem];
        }
        return cell;
    }
    return nil;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isSearchLoggingDisabled)
    {
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        return !([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]] || [item.cellType isEqualToString:[OAFilledButtonCell getCellIdentifier]]);
    }
    return YES;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isSearchLoggingDisabled)
    {
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        if ([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]] || [item.cellType isEqualToString:[OAFilledButtonCell getCellIdentifier]])
            return nil;
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        if (tableView.editing)
        {
            [self.delegate historyItemsSelected:(int)([tableView indexPathsForSelectedRows].count)];
        }
        else
        {
            OASearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
            OASearchHistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
            [self.delegate didSelectHistoryItem:dataItem.item];
        }
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && tableView.editing)
        [self.delegate historyItemsSelected:(int)([tableView indexPathsForSelectedRows].count)];
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

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return !self.tableView.editing;
}

@end
