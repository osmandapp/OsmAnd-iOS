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

#include <OsmAndCore/Utilities.h>


@interface SearchHistoryTableItem : NSObject

@property (nonatomic) OAHistoryItem *item;

- (OADistanceDirection *) getEvaluatedDistanceDirection:(BOOL)decelerating;
- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

@end

@implementation SearchHistoryTableItem
{
    OADistanceDirection *_distanceDirection;
}

- (instancetype)initWithItem:(OAHistoryItem *)item
{
    self = [super init];
    if (self)
    {
        _item = item;
        _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude];
    }
    return self;
}

- (instancetype)initWithItem:(OAHistoryItem *)item mapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    self = [super init];
    if (self)
    {
        _item = item;
        _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude mapCenterCoordinate:mapCenterCoordinate];
    }
    return self;
}

-(void)setItem:(OAHistoryItem *)item
{
    _item = item;
    _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude];
}

- (OADistanceDirection *) getEvaluatedDistanceDirection:(BOOL)decelerating
{
    if (_distanceDirection)
        [_distanceDirection evaluateDistanceDirection:decelerating];
    
    return _distanceDirection;
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    if (_distanceDirection)
        [_distanceDirection setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    if (_distanceDirection)
        [_distanceDirection resetMapCenterSearch];
}


@end


@interface SearchHistoryTableGroup : NSObject

@property NSString *groupName;
@property NSMutableArray *groupItems;

@end

@implementation SearchHistoryTableGroup

- (id)init
{
    self = [super init];
    if (self)
    {
        self.groupItems = [NSMutableArray array];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    
    SearchHistoryTableGroup *item = object;
    
    return [self.groupName isEqualToString:item.groupName];
}

-(NSUInteger)hash
{
    return [self.groupName hash];
}

@end


@interface OAHistoryTableViewController () <OAMultiselectableHeaderDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray* groupsAndItems;

@end

@implementation OAHistoryTableViewController
{
    BOOL _decelerating;
    NSArray *_headerViews;
    BOOL _wasAnyDeleted;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OAHistoryTableViewController alloc] initWithNibName:@"OAHistoryTableViewController" bundle:nil];
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
    [self reloadData];
}

-(void) longTapHandler:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (![self.tableView isEditing])
    {
        _wasAnyDeleted = NO;
        
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        
        if (self.delegate)
            [self.delegate enterHistoryEditingMode];
        
        [self.tableView beginUpdates];
        [self.tableView setEditing:YES animated:YES];
        if (indexPath && gestureRecognizer.state == UIGestureRecognizerStateBegan)
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            if (self.delegate)
                [self.delegate historyItemsSelected:1];
        }

        [self.tableView endUpdates];
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
    [self generateData];
    if (self.groupsAndItems.count > 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self updateDistanceAndDirection];
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
    self.groupsAndItems = [NSMutableArray array];
    NSMutableArray *headerViews = [NSMutableArray array];
    
    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    NSArray *allItems = [helper getPointsHavingTypes:helper.searchTypes limit:0];
    
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
        
        SearchHistoryTableGroup *grp;
        for (SearchHistoryTableGroup *g in self.groupsAndItems)
            if ([g.groupName isEqualToString:groupName])
            {
                grp = g;
                break;
            }
        
        if (!grp)
        {
            grp = [[SearchHistoryTableGroup alloc] init];
            grp.groupName = groupName;
            [self.groupsAndItems addObject:grp];
        }
        
        SearchHistoryTableItem *tableItem;
        if (_searchNearMapCenter)
            tableItem = [[SearchHistoryTableItem alloc] initWithItem:item mapCenterCoordinate:myLocation];
        else
            tableItem = [[SearchHistoryTableItem alloc] initWithItem:item];
        
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
    for (SearchHistoryTableGroup *group in self.groupsAndItems)
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

-(void)setSearchNearMapCenter:(BOOL)searchNearMapCenter
{
    _searchNearMapCenter = searchNearMapCenter;
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_myLocation);
    CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    for (SearchHistoryTableGroup *group in self.groupsAndItems)
        for (SearchHistoryTableItem *dataItem in group.groupItems)
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
            SearchHistoryTableGroup *groupData = [self.groupsAndItems objectAtIndex:i.section];
            SearchHistoryTableItem *dataItem = [groupData.groupItems objectAtIndex:i.row];
            [self updateCell:cell dataItem:dataItem];
        }
        [self.tableView endUpdates];
    });
}

- (void)deleteSelected
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"hist_select_remove") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [removeAlert show];
        return;
    }
    
    UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"hist_remove_q") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_no") otherButtonTitles:OALocalizedString(@"shared_string_yes"), nil];
    [removeAlert show];
}

-(NSArray*)getItemsForRows:(NSArray*)indexPath
{
    NSMutableArray* itemList = [[NSMutableArray alloc] init];
    
    [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
        SearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:path.section];
        [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
    }];
    
    return itemList;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        NSArray* selectedItems = [self getItemsForRows:selectedRows];
        
        NSMutableArray *arr = [NSMutableArray array];
        for (SearchHistoryTableItem* dataItem in selectedItems)
            [arr addObject:dataItem.item];
        
        [[OAHistoryHelper sharedInstance] removePoints:arr];
        
        _wasAnyDeleted = YES;
        
        if (self.delegate)
        {
            [self editDone];
            [self.delegate exitHistoryEditingMode];
        }
    }
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

- (void)updateCell:(OAPointDescCell *)cell dataItem:(SearchHistoryTableItem *)dataItem
{
    [cell.titleView setText:dataItem.item.name];
    cell.titleIcon.image = [dataItem.item icon];
    [cell.descView setText:dataItem.item.typeName.length > 0 ? dataItem.item.typeName : OALocalizedString(@"history")];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
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
    return _headerViews[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((SearchHistoryTableGroup*)[self.groupsAndItems objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
    
    OAPointDescCell* cell;
    cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAPointDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointDescCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        SearchHistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
        [self updateCell:cell dataItem:dataItem];
    }
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark - Table view delegate

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
            SearchHistoryTableGroup* groupData = [self.groupsAndItems objectAtIndex:indexPath.section];
            SearchHistoryTableItem* dataItem = [groupData.groupItems objectAtIndex:indexPath.row];
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
