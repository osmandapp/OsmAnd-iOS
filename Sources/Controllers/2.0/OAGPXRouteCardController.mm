//
//  OARouteCardController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteCardController.h"
#import "Localization.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAAutoObserverProxy.h"
#import "MGSwipeButton.h"
#import "OAUtilities.h"
#import "OAGpxRouteWptItem.h"
#import "OAGPXRouteWaypointTableViewCell.h"
#import "OARootViewController.h"

@interface OAGPXRouteCardController () <UIActionSheetDelegate>

@end

@implementation OAGPXRouteCardController
{
    OAGPXRouter *_gpxRouter;
    
    OAAutoObserverProxy *_locationUpdateObserver;

}

@synthesize activeIndexPath = _activeIndexPath;

- (instancetype)initWithSection:(NSInteger)section tableView:(UITableView *)tableView
{
    self = [super initWithSection:section tableView:tableView];
    if (self)
    {
        _gpxRouter = [OAGPXRouter sharedInstance];
    }
    return self;
}

- (void)generateData
{
    //
}

- (NSString *)headerTitle
{
    return [OALocalizedString(@"gpx_waypoints") uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *)headerButtonName
{
    return [OALocalizedString(@"show_all") uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (void)headerButtonPressed
{
    [[OARootViewController instance].mapPanel openHideDestinationCardsView];
    [[OARootViewController instance].mapPanel openTargetViewWithGPXRoute:NO segmentType:kSegmentRouteWaypoints];
}

- (NSInteger)rowsCount
{
    return (_gpxRouter.routeDoc.activePoints.count > 3 ? 3 : _gpxRouter.routeDoc.activePoints.count);
}

- (UITableViewCell *)cellForRow:(NSInteger)row
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
        cell.allowsSwipeWhenEditing = YES;
        OAGpxRouteWptItem* item = [self getItem:row];
        [self updateCell:cell item:item row:row];
    }
    return cell;
}

- (void)didSelectRow:(NSInteger)row
{
    if (row == 0)
        [self callFirstPointMenu];
    else
        [self callPointMenu:row];
}

- (id)getItem:(NSInteger)row
{
    if (row < _gpxRouter.routeDoc.activePoints.count)
        return _gpxRouter.routeDoc.activePoints[row];
    else
        return nil;
}

- (void)updateCell:(UITableViewCell *)cell item:(id)item row:(NSInteger)row
{
    OAGPXRouteWaypointTableViewCell *routeCell = (OAGPXRouteWaypointTableViewCell *)cell;
    OAGpxRouteWptItem *routeItem = item;
    
    routeCell.separatorInset = UIEdgeInsetsMake(0.0, routeCell.titleLabel.frame.origin.x, 0.0, 0.0);
    
    [routeCell.titleLabel setText:routeItem.point.name];
    
    NSMutableString *desc = [NSMutableString string];
    if (routeItem.distance.length > 0)
    {
        [desc appendString:routeItem.distance];
    }
    if (routeItem.point.type.length > 0)
    {
        if (desc.length > 0)
            [desc appendString:@", "];
        [desc appendString:routeItem.point.type];
    }
    
    [routeCell.descLabel setText:desc];
    
    [routeCell.rightButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    
    if (row == 0)
    {
        routeCell.leftIcon.image = [UIImage imageNamed:@"ic_trip_directions"];
        routeCell.leftIcon.transform = CGAffineTransformMakeRotation(routeItem.direction);
        routeCell.descIcon.image = [UIImage imageNamed:@"ic_trip_location"];
        
        [routeCell hideRightButton:NO];
        [routeCell.rightButton addTarget:self action:@selector(callFirstPointMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [routeCell hideDescIcon:NO];
        
        routeCell.topVDotsVisible = NO;
        routeCell.bottomVDotsVisible = _gpxRouter.routeDoc.activePoints.count > 1;
    }
    else
    {
        routeCell.leftIcon.image = [UIImage imageNamed:@"ic_coordinates"];
        routeCell.leftIcon.transform = CGAffineTransformIdentity;
        [routeCell hideRightButton:YES];
        [routeCell hideDescIcon:YES];
        
        routeCell.topVDotsVisible = YES;
        routeCell.bottomVDotsVisible = row < _gpxRouter.routeDoc.activePoints.count - 1;
    }

    [routeCell hideVDots:NO];
}

- (void)updateDistanceAndDirection
{
    if ([self isDecelerating] || [self isSwiping])
        return;
    
    [self refreshFirstRow];
}

- (void)onAppear
{
    [self generateData];
    
    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(updateDistanceAndDirection)
                                                         andObserve:_gpxRouter.locationUpdatedObservable];
}

- (void)onDisappear
{
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
}

- (NSArray *)getSwipeButtons:(NSInteger)row
{
    CGFloat padding = 15;
    
    MGSwipeButton *visit = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_visitedpoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     if (self.delegate)
                                         [self.delegate indexPathForSwipingCellChanged:nil];

                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     OAGpxRouteWptItem* item = [self getItem:row];
                                     [self moveToInactive:item];
                                     
                                     return YES;
                                 }];

    MGSwipeButton *driveTo = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_direction"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                              {
                                  if (self.delegate)
                                      [self.delegate indexPathForSwipingCellChanged:nil];

                                  NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                  _activeIndexPath = [indexPath copy];
                                  OAGpxRouteWptItem* item = [self getItem:row];
                                  [self moveToActive:item];
                                  
                                  return YES;
                              }];
        
    if (row == 0)
        return @[visit];
    else
        return @[visit, driveTo];
}

- (void)callFirstPointMenu
{
    _activeIndexPath = [NSIndexPath indexPathForRow:0 inSection:self.section];
    OAGpxRouteWptItem* item = [self getItem:0];
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:item.point.name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Mark visited", nil];
    if (self.delegate)
        [self.delegate showActiveSheet:sheet];
}

- (void)callPointMenu:(NSInteger)row
{
    _activeIndexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
    OAGpxRouteWptItem* item = [self getItem:row];
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:item.point.name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Move on first place", @"Mark visited", nil];
    if (self.delegate)
        [self.delegate showActiveSheet:sheet];
}

- (void)moveToInactive:(OAGpxRouteWptItem *)item
{
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{

        if (_gpxRouter.routeDoc.activePoints.count > 0)
        {
            [self refreshVisibleRows];
            [self refreshSwipeButtons];
            [_gpxRouter updateDistanceAndDirection:YES];
        }
        
    }];
    
    [self.tableView beginUpdates];
    
    @synchronized(_gpxRouter.routeDoc.syncObj)
    {
        [_gpxRouter.routeDoc.activePoints removeObjectAtIndex:_activeIndexPath.row];
        [_gpxRouter.routeDoc.inactivePoints insertObject:item atIndex:0];
    }
    
    if (_gpxRouter.routeDoc.activePoints.count == 0)
    {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.section] withRowAnimation:UITableViewRowAnimationLeft];
        [self removeCard];
    }
    else
    {
        [self.tableView deleteRowsAtIndexPaths:@[_activeIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        if (_gpxRouter.routeDoc.activePoints.count > 2)
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:self.section]] withRowAnimation:UITableViewRowAnimationTop];
    }
    
    [self.tableView endUpdates];
    
    item.point.visited = YES;

    [CATransaction commit];
    
    [self updatePointsArray];
}

- (void)moveToActive:(OAGpxRouteWptItem *)item
{
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        [self refreshVisibleRows];
        [self refreshSwipeButtons];
        [_gpxRouter updateDistanceAndDirection:YES];
    }];
    
    [self.tableView beginUpdates];
    NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:self.section];
    
    @synchronized(_gpxRouter.routeDoc.syncObj)
    {
        [_gpxRouter.routeDoc.activePoints removeObjectAtIndex:_activeIndexPath.row];
        [_gpxRouter.routeDoc.activePoints insertObject:item atIndex:0];
    }
    
    [self.tableView moveRowAtIndexPath:_activeIndexPath toIndexPath:destination];
    [self.tableView endUpdates];
    
    item.point.visited = NO;
    
    [CATransaction commit];
    
    [self updatePointsArray];
}


- (void)updatePointsArray
{
    int i = 0;
    for (OAGpxRouteWptItem *item in _gpxRouter.routeDoc.activePoints)
    {
        item.point.index = i++;
        [item.point applyRouteInfo];
    }
    for (OAGpxRouteWptItem *item in _gpxRouter.routeDoc.inactivePoints)
    {
        item.point.index = i++;
        [item.point applyRouteInfo];
    }
    
    [_gpxRouter.routeDoc updateDistances];

    [_gpxRouter.routeDoc buildRouteTrack];
    [_gpxRouter.routeChangedObservable notifyEvent];

    // refresh top toobar
    // todo
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        OAGpxRouteWptItem* item = [self getItem:_activeIndexPath.row];
        
        if (_activeIndexPath.row == 0)
        {
            [self moveToInactive:item];
        }
        else
        {
            if (buttonIndex == 0)
                [self moveToActive:item];
            else
                [self moveToInactive:item];
        }
    }
}

@end
