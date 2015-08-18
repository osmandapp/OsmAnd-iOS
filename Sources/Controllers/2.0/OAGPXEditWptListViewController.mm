//
//  OAGPXEditWptListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXEditWptListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGPXListViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAIconTextTableViewCell.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAGPXEditWptListViewController ()
{
    OsmAndAppInstance _app;
    BOOL isDecelerating;
}

@property (strong, nonatomic) NSDictionary* groupedPoints;
@property (strong, nonatomic) NSArray* unsortedPoints;
@property (strong, nonatomic) NSArray* groups;

@end

@implementation OAGPXEditWptListViewController

- (id)initWithLocationMarks:(NSArray *)locationMarks
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        [self setPoints:locationMarks];
        
        isDecelerating = NO;
    }
    return self;
}

- (void)setPoints:(NSArray *)locationMarks
{
    NSMutableArray *arr = [NSMutableArray array];
    for (OAGpxWpt *p in locationMarks)
    {
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = p;
        [arr addObject:item];
    }
    
    self.unsortedPoints = arr;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([self.tableView isEditing])
        return;
    
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
        return;
    
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
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
    
    [self.tableView reloadData];
}

- (void)resetData
{
    [self.tableView setEditing:NO];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.unsortedPoints.count == 0)
        return 1;
    
    return self.groups.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return nil;
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return 1;
    
    return ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[section]]).count;
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
            
            if (!cell.titleIcon.hidden) {
                cell.titleIcon.hidden = YES;
                CGRect f = cell.titleView.frame;
                cell.titleView.frame = CGRectMake(f.origin.x - 23.0, f.origin.y, f.size.width + 23.0, f.size.height);
                cell.directionImageView.frame = CGRectMake(cell.directionImageView.frame.origin.x - 23.0, cell.directionImageView.frame.origin.y, cell.directionImageView.frame.size.width, cell.directionImageView.frame.size.height);
                cell.distanceView.frame = CGRectMake(cell.distanceView.frame.origin.x - 23.0, cell.distanceView.frame.origin.y, cell.distanceView.frame.size.width, cell.distanceView.frame.size.height);
            }
        }
        return cell;
    }
    
    return nil;
}

-(OAGpxWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    return ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[indexPath.section]])[indexPath.row];
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
    if (!decelerate)
        isDecelerating = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
        return;
    
    OAGpxWptItem* item = [self getWptItem:indexPath];
    [[OARootViewController instance].mapPanel openTargetViewWithWpt:item pushed:NO];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
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


@end

