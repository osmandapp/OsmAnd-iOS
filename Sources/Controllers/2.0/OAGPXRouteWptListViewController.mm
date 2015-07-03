//
//  OAGPXRouteWptListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteWptListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGPXListViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMultiselectableHeaderView.h"
#import "OAIconTextTableViewCell.h"
#import "OAGpxRoutePoint.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAGPXRouteWptListViewController ()
{
    OsmAndAppInstance _app;
    BOOL isDecelerating;
}

@property (strong, nonatomic) NSArray* locationPoints;
@property (strong, nonatomic) NSMutableArray* activePoints;
@property (strong, nonatomic) NSMutableArray* inactivePoints;
@property (strong, nonatomic) NSArray* groups;

@end

@implementation OAGPXRouteWptListViewController
{
    NSInteger _sectionsCount;
    NSInteger _sectionIndexActive;
    NSInteger _sectionIndexInActive;
}

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
    for (OAGpxWpt *p in locationMarks) {
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = p;
        [arr addObject:item];
    }
    
    self.locationPoints = arr;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
        return;
    
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    
    [self.locationPoints enumerateObjectsUsingBlock:^(OAGpxWptItem* itemData, NSUInteger idx, BOOL *stop) {
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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)doViewAppear
{
    [self generateData];
    [self updateDistanceAndDirection:YES];
    
    [self setEditing:YES];

    
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
    
}

- (void)doViewDisappear
{
    [self setEditing:NO];

    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

-(void)generateData
{
    _sectionsCount = 2;
    
    NSInteger index = 0;
    _sectionIndexActive = index++;
    _sectionIndexInActive = index;
    
    self.activePoints = [NSMutableArray arrayWithArray:self.locationPoints];
    self.inactivePoints = [NSMutableArray array];
    
    [self.tableView reloadData];
}

- (void)resetData
{
    //
}

#pragma mark - UITableViewDataSource

-(OAGpxWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexActive)
        return self.activePoints[indexPath.row];
    else if (indexPath.section == _sectionIndexInActive)
        return self.inactivePoints[indexPath.row];
    else
        return nil;
}

-(NSMutableArray *)getWptArray:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexActive)
        return self.activePoints;
    else if (indexPath.section == _sectionIndexInActive)
        return self.inactivePoints;
    else
        return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sectionsCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _sectionIndexActive)
        return @"Active";
    else if (section == _sectionIndexInActive)
        return @"Inactive";
    else
        return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == _sectionIndexActive)
        return @"Waypoints which are not visited yet on the route";
    else if (section == _sectionIndexInActive)
        return @"Waypoints which have been visited or marked as visited manually";
    else
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _sectionIndexActive)
        return self.activePoints.count;
    else if (section == _sectionIndexInActive)
        return self.inactivePoints.count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
    
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        [cell.rightArrow removeFromSuperview];
    }
    
    if (cell)
    {
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

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getWptArray:indexPath].count < 1)
        return NO;
    
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getWptArray:indexPath].count < 1)
        return NO;
    
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OAGpxWptItem* item = [self getWptItem:sourceIndexPath];
    OAGpxRoutePoint *rp = (OAGpxRoutePoint *)item.point;

    [[self getWptArray:sourceIndexPath] removeObjectAtIndex:sourceIndexPath.row];
    [[self getWptArray:destinationIndexPath] insertObject:item atIndex:destinationIndexPath.row];

    if (destinationIndexPath.section == _sectionIndexActive)
    {
        rp.disabled = NO;
        rp.visited = NO;
    }
    else if (destinationIndexPath.section == _sectionIndexInActive)
    {
        rp.disabled = YES;
    }
    
    [self updatePointsArray];
}

// The following example restricts rows to relocation in their own group and prevents moves to the last row of a group (which is reserved for the add-item placeholder).

-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    /*
    NSDictionary *section = [data objectAtIndex:sourceIndexPath.section];
    NSUInteger sectionCount = [[section valueForKey:@"content"] count];
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSUInteger rowInSourceSection =
        (sourceIndexPath.section > proposedDestinationIndexPath.section) ?
        0 : sectionCount - 1;
        return [NSIndexPath indexPathForRow:rowInSourceSection inSection:sourceIndexPath.section];
    } else if (proposedDestinationIndexPath.row >= sectionCount) {
        return [NSIndexPath indexPathForRow:sectionCount - 1 inSection:sourceIndexPath.section];
    }
    */
    // Allow the proposed destination.
    return proposedDestinationIndexPath;
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

- (void)tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isDecelerating = YES;
}

- (void)tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isDecelerating = NO;
}

- (void)tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isDecelerating = NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //return UITableViewCellEditingStyleNone;

    if ([self getWptArray:indexPath].count == 0)
        return UITableViewCellEditingStyleNone;

    if (indexPath.section == _sectionIndexActive && tableView.editing)
        return UITableViewCellEditingStyleDelete;
    else if (indexPath.section == _sectionIndexInActive && tableView.editing)
        return UITableViewCellEditingStyleInsert;
    else
        return UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"To inactive";
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getWptArray:indexPath].count == 0)
        return nil;
    
    return indexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.tableView.editing)
        return;
    
    //OAGpxWptItem* item = [self getWptItem:indexPath];
    // todo
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxWptItem* item = [self getWptItem:indexPath];
    OAGpxRoutePoint *rp = (OAGpxRoutePoint *)item.point;

    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [tableView beginUpdates];
        NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:_sectionIndexInActive];
        
        [[self getWptArray:indexPath] removeObjectAtIndex:indexPath.row];
        [self.inactivePoints insertObject:item atIndex:0];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView insertRowsAtIndexPaths:@[destination] withRowAnimation:UITableViewRowAnimationAutomatic];
        //[tableView moveRowAtIndexPath:indexPath toIndexPath:destination];
        [tableView endUpdates];
    
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        [tableView beginUpdates];
        NSIndexPath *destination = [NSIndexPath indexPathForRow:self.activePoints.count inSection:_sectionIndexActive];

        [[self getWptArray:indexPath] removeObjectAtIndex:indexPath.row];
        [self.activePoints addObject:item];

        [tableView moveRowAtIndexPath:indexPath toIndexPath:destination];
        [tableView endUpdates];

        rp.visited = NO;
    }
    
    [self updatePointsArray];
}

- (void)updatePointsArray
{
    int i = 0;
    for (OAGpxWptItem *wptItem in self.activePoints)
    {
        OAGpxRoutePoint *rp = (OAGpxRoutePoint *)wptItem.point;
        rp.index = i++;
        rp.disabled = NO;
        [rp applyRouteInfo];
    }
    for (OAGpxWptItem *wptItem in self.inactivePoints)
    {
        OAGpxRoutePoint *rp = (OAGpxRoutePoint *)wptItem.point;
        rp.index = i++;
        rp.disabled = YES;
        [rp applyRouteInfo];
    }
    
    if (self.delegate)
        [self.delegate routePointsChanged];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}


@end
