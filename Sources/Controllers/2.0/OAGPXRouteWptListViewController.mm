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
#import "OAGpxRouteWptItem.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMultiselectableHeaderView.h"
#import "OAGpxRoutePoint.h"
#import "OAGPXRouteDocument.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteWaypointTableViewCell.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@implementation OAGPXRouteWptListViewController
{
    OsmAndAppInstance _app;
    OAGPXRouter *_gpxRouter;

    NSInteger _sectionsCount;
    NSInteger _sectionIndexGroups;
    NSInteger _sectionIndexActive;
    NSInteger _sectionIndexInactive;
    
    OAAutoObserverProxy *_locationUpdateObserver;
    
    BOOL isDecelerating;
    BOOL isMoving;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpxRouter = [OAGPXRouter sharedInstance];
        
        isDecelerating = NO;
        isMoving = NO;
    }
    return self;
}

- (void)updateDistanceAndDirection
{
    if (isDecelerating || isMoving)
        return;
    
    [self refreshFirstWaypointRow];
}

- (void)refreshFirstWaypointRow
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            if (i.section == _sectionIndexActive && i.row == 0)
            {
                [self.tableView beginUpdates];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
                if ([cell isKindOfClass:[OAGPXRouteWaypointTableViewCell class]])
                {
                    OAGpxRouteWptItem* item = [self getWptItem:i];
                    if (item)
                    {
                        OAGPXRouteWaypointTableViewCell* c = (OAGPXRouteWaypointTableViewCell *)cell;
                        [self updateWaypointCell:c item:item indexPath:i];
                    }
                }
                [self.tableView endUpdates];
                break;
            }
        }
    });
}

- (void)refreshVisibleRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAGPXRouteWaypointTableViewCell class]])
            {
                OAGpxRouteWptItem* item = [self getWptItem:i];
                if (item)
                {
                    OAGPXRouteWaypointTableViewCell* c = (OAGPXRouteWaypointTableViewCell *)cell;
                    [self updateWaypointCell:c item:item indexPath:i];
                }
            }
        }
        [self.tableView endUpdates];
    });
}

- (void)refreshAllRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        
        [_gpxRouter.routeDoc.activePoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem* item, NSUInteger idx, BOOL *stop) {
            
            NSIndexPath *i = [NSIndexPath indexPathForRow:idx inSection:_sectionIndexActive];
            OAGPXRouteWaypointTableViewCell *cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView cellForRowAtIndexPath:i];
            [self updateWaypointCell:cell item:item indexPath:i];
        }];

        [_gpxRouter.routeDoc.inactivePoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem* item, NSUInteger idx, BOOL *stop) {
            
            NSIndexPath *i = [NSIndexPath indexPathForRow:idx inSection:_sectionIndexInactive];
            OAGPXRouteWaypointTableViewCell *cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView cellForRowAtIndexPath:i];
            [self updateWaypointCell:cell item:item indexPath:i];
        }];

        [self.tableView endUpdates];
    });
}

- (void)doViewAppear
{
    [self generateData];
    
    [self setEditing:YES];

    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_gpxRouter.locationUpdatedObservable];
}

- (void)doViewDisappear
{
    [self setEditing:NO];

    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
}

-(void)generateData
{
    _sectionsCount = 2;
    
    NSInteger index = 0;
    _sectionIndexGroups = -1;
    //_sectionIndexGroups = index++;
    _sectionIndexActive = index++;
    _sectionIndexInactive = index;
    
    [self.tableView reloadData];
}

- (void)resetData
{
    //
}

- (void)updateWaypointCell:(OAGPXRouteWaypointTableViewCell *)cell item:(OAGpxRouteWptItem *)item indexPath:(NSIndexPath *)indexPath
{
    cell.separatorInset = UIEdgeInsetsMake(0.0, cell.titleLabel.frame.origin.x, 0.0, 0.0);
    
    [cell.titleLabel setText:item.point.name];
    if (item.point.type.length > 0)
        [cell.descLabel setText:[NSString stringWithFormat:@"%@, %@", item.distance, item.point.type]];
    else
        [cell.descLabel setText:item.distance];
    
    if (indexPath.section == _sectionIndexActive)
    {
        if (indexPath.row == 0)
        {
            cell.leftIcon.image = [UIImage imageNamed:@"ic_trip_directions"];
            cell.leftIcon.transform = CGAffineTransformMakeRotation(item.direction);
            cell.descIcon.image = [UIImage imageNamed:@"ic_trip_location"];
            [cell hideRightButton:NO];
            [cell hideDescIcon:NO];
            
            cell.topVDotsVisible = NO;
            cell.bottomVDotsVisible = YES;
        }
        else
        {
            cell.leftIcon.image = [UIImage imageNamed:@"ic_coordinates"];
            cell.leftIcon.transform = CGAffineTransformIdentity;
            [cell hideRightButton:YES];
            [cell hideDescIcon:YES];
            
            cell.topVDotsVisible = YES;
            cell.bottomVDotsVisible = indexPath.row < [self getWptArray:indexPath].count - 1;
        }
    }
    else
    {
        cell.leftIcon.image = [UIImage imageNamed:@"ic_coordinates_disable"];
        cell.leftIcon.transform = CGAffineTransformIdentity;
        [cell hideRightButton:YES];
        [cell hideDescIcon:YES];
    }
    
    [cell hideVDots:(indexPath.section == _sectionIndexInactive || isMoving)];
}

#pragma mark - UITableViewDataSource

-(OAGpxRouteWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexActive)
        return _gpxRouter.routeDoc.activePoints[indexPath.row];
    else if (indexPath.section == _sectionIndexInactive)
        return _gpxRouter.routeDoc.inactivePoints[indexPath.row];
    else
        return nil;
}

-(NSMutableArray *)getWptArray:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexActive)
        return _gpxRouter.routeDoc.activePoints;
    else if (indexPath.section == _sectionIndexInactive)
        return _gpxRouter.routeDoc.inactivePoints;
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
        return OALocalizedString(@"gpx_waypoints");
    else if (section == _sectionIndexInactive)
        return OALocalizedString(@"gpx_deactivated");
    else
        return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _sectionIndexActive)
        return _gpxRouter.routeDoc.activePoints.count;
    else if (section == _sectionIndexInactive)
        return _gpxRouter.routeDoc.inactivePoints.count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexGroups)
    {
        
    }
    else
    {
        static NSString* const reusableIdentifierPoint = @"OAGPXRouteWaypointTableViewCell";
        
        OAGPXRouteWaypointTableViewCell* cell;
        cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXRouteWaypointCell" owner:self options:nil];
            cell = (OAGPXRouteWaypointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAGpxRouteWptItem* item = [self getWptItem:indexPath];            
            [self updateWaypointCell:cell item:item indexPath:indexPath];
        }
        return cell;
    }
    
    return nil;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getWptArray:indexPath].count < 1 || (indexPath.section == _sectionIndexActive && indexPath.row == 0))
        return NO;
    
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getWptArray:indexPath].count < 1 || (indexPath.section == _sectionIndexActive && indexPath.row == 0))
        return NO;
    
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OAGpxRouteWptItem* item = [self getWptItem:sourceIndexPath];

    [[self getWptArray:sourceIndexPath] removeObjectAtIndex:sourceIndexPath.row];
    [[self getWptArray:destinationIndexPath] insertObject:item atIndex:destinationIndexPath.row];

    if (destinationIndexPath.section == _sectionIndexActive)
    {
        item.point.disabled = NO;
        item.point.visited = NO;
    }
    else if (destinationIndexPath.section == _sectionIndexInactive)
    {
        item.point.disabled = YES;
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
    isMoving = YES;
    [self refreshAllRows];
}

- (void)tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isMoving = NO;
    [self refreshAllRows];
}

- (void)tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isMoving = NO;
    [self refreshAllRows];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
    //OAGpxRouteWptItem* item = [self getWptItem:indexPath];
    // todo
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxRouteWptItem* item = [self getWptItem:indexPath];

    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [tableView beginUpdates];
        NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:_sectionIndexInactive];
        
        [[self getWptArray:indexPath] removeObjectAtIndex:indexPath.row];
        [_gpxRouter.routeDoc.inactivePoints insertObject:item atIndex:0];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView insertRowsAtIndexPaths:@[destination] withRowAnimation:UITableViewRowAnimationAutomatic];
        //[tableView moveRowAtIndexPath:indexPath toIndexPath:destination];
        [tableView endUpdates];
    
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        [tableView beginUpdates];
        NSIndexPath *destination = [NSIndexPath indexPathForRow:_gpxRouter.routeDoc.activePoints.count inSection:_sectionIndexActive];

        [[self getWptArray:indexPath] removeObjectAtIndex:indexPath.row];
        [_gpxRouter.routeDoc.activePoints addObject:item];

        [tableView moveRowAtIndexPath:indexPath toIndexPath:destination];
        [tableView endUpdates];

        item.point.visited = NO;
    }
    
    [self updatePointsArray];
}

- (void)updatePointsArray
{
    int i = 0;
    for (OAGpxRouteWptItem *item in _gpxRouter.routeDoc.activePoints)
    {
        item.point.index = i++;
        item.point.disabled = NO;
        [item.point applyRouteInfo];
    }
    for (OAGpxRouteWptItem *item in _gpxRouter.routeDoc.inactivePoints)
    {
        item.point.index = i++;
        item.point.disabled = YES;
        [item.point applyRouteInfo];
    }
    
    [_gpxRouter.routeDoc updateDistances];
    
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
