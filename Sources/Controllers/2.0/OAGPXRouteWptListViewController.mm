//
//  OAGPXRouteWptListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteWptListViewController.h"
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
#import "OAIconTextTableViewCell.h"
#import "MGSwipeButton.h"
#import "MGSwipeTableCell.h"
#import "OAGPXRouteGroupsViewController.h"

#import "OsmAndApp.h"
#import <MBProgressHUD.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

@interface OAGPXRouteWptListViewController () <MGSwipeTableCellDelegate, UIActionSheetDelegate, OAGPXRouteGroupsViewControllerDelegate>

@end

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
    
    NSIndexPath *indexPathForSwipingCell;
    NSIndexPath *_activeIndexPath;
    
    BOOL _isAnimating;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _isAnimating = NO;
        _gpxRouter = [OAGPXRouter sharedInstance];
        
        isDecelerating = NO;
        isMoving = NO;
    }
    return self;
}

- (void)updateDistanceAndDirection
{
    if (isDecelerating || isMoving || indexPathForSwipingCell || _isAnimating)
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

- (void)refreshSwipeButtons
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //[self.tableView beginUpdates];
        
        [_gpxRouter.routeDoc.activePoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem* item, NSUInteger idx, BOOL *stop) {
            
            NSIndexPath *i = [NSIndexPath indexPathForRow:idx inSection:_sectionIndexActive];
            OAGPXRouteWaypointTableViewCell *cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView cellForRowAtIndexPath:i];
            [cell refreshButtons:YES];
        }];
        
        [_gpxRouter.routeDoc.inactivePoints enumerateObjectsUsingBlock:^(OAGpxRouteWptItem* item, NSUInteger idx, BOOL *stop) {
            
            NSIndexPath *i = [NSIndexPath indexPathForRow:idx inSection:_sectionIndexInactive];
            OAGPXRouteWaypointTableViewCell *cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView cellForRowAtIndexPath:i];
            [cell refreshButtons:YES];
        }];
        
        //[self.tableView endUpdates];
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
    
    if (_gpxRouter.routeDoc.groups.count == 0)
    {
        _sectionIndexGroups = -1;
    }
    else
    {
        _sectionIndexGroups = index++;
        _sectionsCount++;
    }
    
    _sectionIndexActive = index++;
    _sectionIndexInactive = index;
    
    [self.tableView reloadData];
}

- (void)resetData
{
    //
}

- (void)callFirstPointMenu
{
    _activeIndexPath = [NSIndexPath indexPathForRow:0 inSection:_sectionIndexActive];
    OAGpxRouteWptItem* item = [self getWptItem:_activeIndexPath];
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:item.point.name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Deactivate" otherButtonTitles:@"Sort waypoints", nil];
    sheet.delegate = self;
    sheet.tag = 0;
    [sheet showInView:self.view];
}

- (void)doSort
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        progressHUD.removeFromSuperViewOnHide = YES;
        progressHUD.labelText = [OALocalizedString(@"sorting") stringByAppendingString:@"..."];
        [topView addSubview:progressHUD];
        
        [progressHUD showAnimated:YES whileExecutingBlock:^{
            
            [_gpxRouter sortRoute];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                int i = 0;
                for (OAGpxRouteWptItem *item in _gpxRouter.routeDoc.activePoints)
                {
                    item.point.index = i++;
                    [item.point applyRouteInfo];
                }
                
                [_gpxRouter refreshRoute:YES];
                [_gpxRouter.routeChangedObservable notifyEvent];
                
                if (self.delegate)
                    [self.delegate routePointsChanged];
                
                [self.tableView reloadData];
            });
        }];
    });
    
}

- (void)updateWaypointCell:(OAGPXRouteWaypointTableViewCell *)cell item:(OAGpxRouteWptItem *)item indexPath:(NSIndexPath *)indexPath
{
    cell.separatorInset = UIEdgeInsetsMake(0.0, cell.titleLabel.frame.origin.x, 0.0, 0.0);
    
    [cell.titleLabel setText:item.point.name];

    NSMutableString *desc = [NSMutableString string];
    if (item.distance.length > 0)
    {
        [desc appendString:item.distance];
    }
    if (item.point.type.length > 0)
    {
        if (desc.length > 0)
            [desc appendString:@", "];
        [desc appendString:item.point.type];
    }
    
    [cell.descLabel setText:desc];
    
    [cell.rightButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    if (indexPath.section == _sectionIndexActive)
    {
        if (indexPath.row == 0)
        {
            cell.leftIcon.image = [UIImage imageNamed:@"ic_trip_directions"];
            cell.leftIcon.transform = CGAffineTransformMakeRotation(item.direction);
            cell.descIcon.image = [UIImage imageNamed:@"ic_trip_location"];
            
            [cell hideRightButton:NO];
            [cell.rightButton addTarget:self action:@selector(callFirstPointMenu) forControlEvents:UIControlEventTouchUpInside];
            
            [cell hideDescIcon:NO];
            
            cell.topVDotsVisible = NO;
            cell.bottomVDotsVisible = [self getWptArray:indexPath].count > 1;
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

- (void)moveToInactive:(OAGpxRouteWptItem *)item
{
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        [self refreshVisibleRows];
        [self refreshSwipeButtons];

        _isAnimating = NO;

        [_gpxRouter updateDistanceAndDirection:YES];
    }];
    
    [self.tableView beginUpdates];
    NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:_sectionIndexInactive];
    
    @synchronized(_gpxRouter.routeDoc.syncObj)
    {
        [[self getWptArray:_activeIndexPath] removeObjectAtIndex:_activeIndexPath.row];
        [_gpxRouter.routeDoc.inactivePoints insertObject:item atIndex:0];
    }
    
    [self.tableView moveRowAtIndexPath:_activeIndexPath toIndexPath:destination];
    [self.tableView endUpdates];
    
    [CATransaction commit];
    
    [self updatePointsArray];
}

- (void)moveToActive:(OAGpxRouteWptItem *)item
{
    _isAnimating = YES;

    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        [self refreshVisibleRows];
        [self refreshSwipeButtons];
        
        _isAnimating = NO;
        
        [_gpxRouter updateDistanceAndDirection:YES];
    }];
    
    [self.tableView beginUpdates];
    NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:_sectionIndexActive];
    
    @synchronized(_gpxRouter.routeDoc.syncObj)
    {
        [[self getWptArray:_activeIndexPath] removeObjectAtIndex:_activeIndexPath.row];
        [_gpxRouter.routeDoc.activePoints insertObject:item atIndex:0];
    }
    
    [self.tableView moveRowAtIndexPath:_activeIndexPath toIndexPath:destination];
    [self.tableView endUpdates];
    
    item.point.visited = NO;
    
    [CATransaction commit];
    
    [self updatePointsArray];
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
    if (section == _sectionIndexGroups)
        return OALocalizedString(@"gpx_trip_groups");
    else if (section == _sectionIndexActive)
        return OALocalizedString(@"gpx_waypoints");
    else if (section == _sectionIndexInactive)
        return OALocalizedString(@"gpx_deactivated");
    else
        return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _sectionIndexGroups)
        return 1;
    else if (section == _sectionIndexActive)
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
        static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 2;
        }
        
        if (cell)
        {
            cell.iconView.image = [UIImage imageNamed:@"ic_group"];
            NSMutableString *groupsStr = [NSMutableString string];
            for (NSString *name in _gpxRouter.routeDoc.groups)
            {
                if (groupsStr.length > 0)
                    [groupsStr appendString:@", "];
                [groupsStr appendString:name];
            }
            cell.textView.text = groupsStr;
        }
        return cell;
    }
    else
    {
        OAGPXRouteWaypointTableViewCell* cell;
        cell = (OAGPXRouteWaypointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAGPXRouteWaypointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXRouteWaypointCell" owner:self options:nil];
            cell = (OAGPXRouteWaypointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.delegate = self;
            cell.allowsSwipeWhenEditing = YES;
            OAGpxRouteWptItem* item = [self getWptItem:indexPath];            
            [self updateWaypointCell:cell item:item indexPath:indexPath];
        }
        return cell;
    }
    
    return nil;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexGroups)
        return NO;
    
    if ([self getWptArray:indexPath].count < 1 || (indexPath.section == _sectionIndexActive && indexPath.row == 0))
        return NO;
    
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexGroups)
        return NO;

    if ([self getWptArray:indexPath].count < 1 || (indexPath.section == _sectionIndexActive && indexPath.row == 0))
        return NO;
    
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OAGpxRouteWptItem* item = [self getWptItem:sourceIndexPath];

    @synchronized(_gpxRouter.routeDoc.syncObj)
    {
        [[self getWptArray:sourceIndexPath] removeObjectAtIndex:sourceIndexPath.row];
        [[self getWptArray:destinationIndexPath] insertObject:item atIndex:destinationIndexPath.row];
    }

    if (destinationIndexPath.section == _sectionIndexActive)
    {
        item.point.disabled = NO;
        item.point.visited = NO;
    }
    else if (destinationIndexPath.section == _sectionIndexInactive)
    {
        item.point.disabled = YES;
    }
    
    [self refreshSwipeButtons];
    
    [self updatePointsArray];
}

-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section == _sectionIndexGroups)
        return [NSIndexPath indexPathForRow:0 inSection:_sectionIndexActive];
    
    // Allow the proposed destination.
    return proposedDestinationIndexPath;
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        OAGpxRouteWptItem* item = [self getWptItem:_activeIndexPath];
        
        if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            [self moveToInactive:item];
        }
        else
        {
            if (actionSheet.tag == 0)
                [self doSort];
            else
                [self moveToActive:item];
        }
    }
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
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
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

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _sectionIndexGroups)
        return indexPath;

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
    
    if (indexPath.section == _sectionIndexGroups)
    {
        OAGPXRouteGroupsViewController *groupsController = [[OAGPXRouteGroupsViewController alloc] init];
        groupsController.delegate = self;
        [[OARootViewController instance].navigationController pushViewController:groupsController animated:YES];
    }
    else
    {
        if (indexPath.section == _sectionIndexActive && indexPath.row == 0)
        {
            [self callFirstPointMenu];
        }
        else
        {
            _activeIndexPath = [indexPath copy];
            OAGpxRouteWptItem* item = [self getWptItem:indexPath];
            UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:item.point.name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:(indexPath.section == _sectionIndexActive ? @"Deactivate" : nil) otherButtonTitles:@"Move on first place", nil];
            sheet.delegate = self;
            sheet.tag = 1;
            [sheet showInView:self.view];
        }
    }
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
    
    [_gpxRouter refreshRoute:YES];
    [_gpxRouter.routeChangedObservable notifyEvent];

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

#pragma mark Swipe Delegate

-(BOOL) swipeTableCell:(MGSwipeTableCell*) cell canSwipe:(MGSwipeDirection) direction;
{
    return YES;
}

-(NSArray*) swipeTableCell:(MGSwipeTableCell*) cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings*) swipeSettings expansionSettings:(MGSwipeExpansionSettings*) expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    
    if (direction == MGSwipeDirectionRightToLeft)
    {
        //expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 10.0;
        
        CGFloat padding = 15;

        NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
        
        MGSwipeButton *deactivate = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_visitedpoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
        {
            indexPathForSwipingCell = nil;
            NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
            _activeIndexPath = [indexPath copy];
            OAGpxRouteWptItem* item = [self getWptItem:indexPath];
            [self moveToInactive:item];

            return YES;
        }];
        
        MGSwipeButton *driveTo = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_waypoint_up"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
        {
            indexPathForSwipingCell = nil;
            NSIndexPath * indexPath = [self.tableView indexPathForCell:sender];
            _activeIndexPath = [indexPath copy];
            OAGpxRouteWptItem* item = [self getWptItem:indexPath];
            [self moveToActive:item];

            return YES;
        }];

        MGSwipeButton *sort = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_sort"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                               {
                                   [self doSort];

                                   return YES;
                               }];

        if (indexPath.section == _sectionIndexInactive)
            return @[driveTo];
        if (indexPath.section == _sectionIndexActive && indexPath.row == 0)
            return @[deactivate, sort];
        else
            return @[deactivate, driveTo];
    }
    
    return nil;
    
}

-(void) swipeTableCell:(MGSwipeTableCell*) cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (gestureIsActive || state != MGSwipeStateNone)
    {
        indexPathForSwipingCell = indexPath;
        cell.showsReorderControl = NO;
    }
    else if ([indexPath isEqual:indexPathForSwipingCell])
    {
        indexPathForSwipingCell = nil;
        cell.showsReorderControl = YES;
    }
    else
    {
        cell.showsReorderControl = YES;
    }
}

#pragma mark - OAGPXRouteGroupsViewControllerDelegate

-(void)routeGroupsChanged
{
    [self updatePointsArray];

    [self generateData];
    
    [_gpxRouter updateDistanceAndDirection:YES];
}

@end
