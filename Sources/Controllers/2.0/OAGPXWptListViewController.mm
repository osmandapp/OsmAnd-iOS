//
//  OAGPXWptListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXWptListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGPXListViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMultiselectableHeaderView.h"
#import "OAIconTextTableViewCell.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAGPXWptListViewController () <OAMultiselectableHeaderDelegate>
{
    OsmAndAppInstance _app;
    BOOL isDecelerating;
}

@property (strong, nonatomic) NSArray* sortedDistPoints;
@property (strong, nonatomic) NSDictionary* groupedPoints;
@property (strong, nonatomic) NSArray* unsortedPoints;
@property (strong, nonatomic) NSArray* groups;

@end

@implementation OAGPXWptListViewController
{
    OAMultiselectableHeaderView *_sortedHeaderView;
    NSArray *_unsortedHeaderViews;
}

- (id)initWithLocationMarks:(NSArray *)locationMarks
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        [self setPoints:locationMarks];
        
        isDecelerating = NO;
        _sortingType = EPointsSortingTypeGrouped;
        
    }
    return self;
}

- (void)setPoints:(NSArray *)locationMarks
{
    NSMutableArray *arr = [NSMutableArray array];
    for (OAGpxWpt *p in locationMarks) {
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = p;
        [arr addObject:item];
    }
    
    self.unsortedPoints = arr;
}

- (void) updateDistanceAndDirection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDistanceAndDirection:NO];
    });
}

- (void) updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([self.tableView isEditing])
        return;
    
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
        return;
    
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
    {
        return;
    }
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    
    [self.unsortedPoints enumerateObjectsUsingBlock:^(OAGpxWptItem* itemData, NSUInteger idx, BOOL *stop) {
        OsmAnd::LatLon latLon(itemData.point.position.latitude, itemData.point.position.longitude);
        const auto& wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
        const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);
        
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          wptLon, wptLat);
        
        itemData.distance = [_app getFormattedDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
        itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
    }];
    
    if (_sortingType == EPointsSortingTypeDistance && [self.unsortedPoints count] > 0) {
        self.sortedDistPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
            return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
        }];
    }
    
    if (isDecelerating)
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
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OAGpxWptItem* item = [self getWptItem:i];
                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;
                    [c.titleView setText:item.point.name];
                    [c.distanceView setText:item.distance];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [self.tableView endUpdates];
    });
}

- (void)doViewAppear
{
    [self generateData];
    [self updateDistanceAndDirection:YES];

    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
}

- (void)doViewDisappear
{
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

-(void)generateData
{
    _sortedHeaderView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 32.0)];
    _sortedHeaderView.delegate = self;
    [_sortedHeaderView setTitleText:[NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_points"), self.unsortedPoints.count]];

    NSMutableSet *groups = [NSMutableSet set];
    for (OAGpxWptItem *item in self.unsortedPoints)
        [groups addObject:(item.point.type ? item.point.type : @"")];
    
    NSMutableArray *groupsArray = [[[groups allObjects]
                                    sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2)
                                    {
                                        return [obj1 localizedCaseInsensitiveCompare:obj2];
                                    }] mutableCopy];
    
    NSArray *sortedArr = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem *obj1, OAGpxWptItem *obj2) {
        return [obj1.point.name localizedCaseInsensitiveCompare:obj2.point.name];
    }];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *group in groupsArray)
        [dict setObject:[NSMutableArray array] forKey:group];
    
    for (OAGpxWptItem *item in sortedArr)
    {
        NSString *group = item.point.type;
        NSMutableArray *arr;
        if (group.length > 0)
            arr = [dict objectForKey:group];
        else
            arr = [dict objectForKey:@""];
        
        [arr addObject:item];
    }
    
    self.groups = [NSArray arrayWithArray:groupsArray];
    self.groupedPoints = [NSDictionary dictionaryWithDictionary:dict];
    
    // Sort items
    self.sortedDistPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    
    NSMutableArray *headerViews = [NSMutableArray array];
    int i = 0;
    for (NSString *groupName in groupsArray)
    {
        OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 32.0)];
        [headerView setTitleText:(groupName.length == 0 ? OALocalizedString(@"fav_no_group") : groupName)];
        headerView.section = i++;
        headerView.delegate = self;
        [headerViews addObject:headerView];
    }
    _unsortedHeaderViews = [NSArray arrayWithArray:headerViews];
    
    [self.tableView reloadData];
}

- (void)resetData
{
    [self.tableView setEditing:NO];
}

- (void)doSortClick:(UIButton *)button
{
    if (![self.tableView isEditing]) {
        
        switch (_sortingType) {
            case EPointsSortingTypeGrouped:
                _sortingType = EPointsSortingTypeDistance;
                break;
            case EPointsSortingTypeDistance:
                _sortingType = EPointsSortingTypeGrouped;
                break;
                
            default:
                break;
        }
        
        [self updateSortButton:button];
        
        [self generateData];
    }
}

- (void)updateSortButton:(UIButton *)button
{
    switch (_sortingType) {
        case EPointsSortingTypeGrouped:
            [button setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
            break;
        case EPointsSortingTypeDistance:
            [button setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.unsortedPoints.count == 0)
        return 1;
    
    switch (_sortingType)
    {
        case EPointsSortingTypeGrouped:
            return self.groups.count;
            
        case EPointsSortingTypeDistance:
            return 1;
            
        default:
            return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return nil;

    switch (_sortingType)
    {
        case EPointsSortingTypeGrouped:
        {
            if (self.groups.count > section)
            {
                NSString *group = self.groups[section];
                return (group.length == 0 ? OALocalizedString(@"fav_no_group") : group);
            }
            else
            {
                return nil;
            }
        }
        case EPointsSortingTypeDistance:
        {
            return [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_points"), self.unsortedPoints.count];
        }
            
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return 1;

    switch (_sortingType)
    {
        case EPointsSortingTypeGrouped:
            return ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[section]]).count;
            
        case EPointsSortingTypeDistance:
            return self.unsortedPoints.count;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.unsortedPoints.count == 0)
    {
        static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:OALocalizedString(@"add_waypoint")];
            [cell.iconView setImage: [UIImage imageNamed:@"add_waypoint_to_track"]];
        }
        return cell;
    }
    else
    {
        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
        
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            
            OAGpxWptItem* item = [self getWptItem:indexPath];
            
            [cell.titleView setText:item.point.name];
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:[item.point getColor]];
            [cell.titleIcon setImage:favCol.icon];
            
            if (![cell.directionImageView.tintColor isEqual:UIColorFromRGB(color_elevation_chart)])
            {
                cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            }
        }
        return cell;
    }
    
    return nil;
}

-(OAGpxWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    OAGpxWptItem* item;
    switch (_sortingType) {
        case EPointsSortingTypeGrouped:
            item = ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[indexPath.section]])[indexPath.row];
            break;
        case EPointsSortingTypeDistance:
            item = [self.sortedDistPoints objectAtIndex:indexPath.row];
            break;
            
        default:
            break;
    }
    return item;
}

- (NSArray *)getSelectedItems
{
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSIndexPath *indexPath in indexPaths)
        [arr addObject:[self getWptItem:indexPath]];

    return [NSArray arrayWithArray:arr];
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        isDecelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    //[self refreshVisibleRows];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.unsortedPoints.count == 0)
    {
        if (self.delegate)
            [self.delegate callGpxEditMode];
        return;
    }

    if (self.tableView.editing)
        return;
    
    OAGpxWptItem* item = [self getWptItem:indexPath];
    [[OARootViewController instance].mapPanel openTargetViewWithWpt:item pushed:NO];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return 0.01;
    else
        return 40.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return nil;

    if (self.sortingType == EPointsSortingTypeDistance)
        return _sortedHeaderView;
    else if (_unsortedHeaderViews.count > section)
        return _unsortedHeaderViews[section];
    else
        return nil;
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
}

@end
