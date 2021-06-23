//
//  OADirectionsCardController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADirectionsCardController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OADestination.h"
#import "OADirectionTableViewCell.h"
#import "OAAutoObserverProxy.h"
#import "MGSwipeButton.h"
#import "OAUtilities.h"
#import "OADestinationCell.h"
#import "OARootViewController.h"
#import "OADestinationsHelper.h"
#import "OADestinationCardHeaderView.h"
#import "OADestinationItem.h"

#import <OsmAndCore/Utilities.h>


@implementation OADirectionsCardController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_destinationRemoveObserver;
    
    NSMutableArray *_items;
    
    NSTimeInterval _lastUpdate;
    
    BOOL _isAnimating;
}

@synthesize activeIndexPath = _activeIndexPath;
@synthesize cardHeaderView = _cardHeaderView;

- (instancetype)initWithSection:(NSInteger)section tableView:(UITableView *)tableView
{
    self = [super initWithSection:section tableView:tableView];
    if (self)
    {
        _app = [OsmAndApp instance];
        _isAnimating = NO;
        
        _cardHeaderView = [[OADestinationCardHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 50.0)];
        _cardHeaderView.title.text = [OALocalizedString(@"map_markers") uppercaseStringWithLocale:[NSLocale currentLocale]];
        [_cardHeaderView.rightButton removeFromSuperview];
        
        _items = [NSMutableArray array];
        [self generateData];
    }
    return self;
}

- (void)generateData
{
    [_items removeAllObjects];
    
    NSArray<OADestination *> *destinations = [NSArray arrayWithArray:OADestinationsHelper.instance.sortedDestinations];
    
    for (OADestination *destination in destinations)
    {
        if (!destination.routePoint)
        {
            OADestinationItem *item = [[OADestinationItem alloc] init];
            item.destination = destination;
            [_items addObject:item];
        }
    }
    
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
}

- (void) reorderObjects:(NSInteger)source dest:(NSInteger)dest
{
    OADestinationItem *src = _items[source];
    OADestinationItem *dst = _items[dest];
    dst.destination.index = source;
    src.destination.index = dest;
    [_items replaceObjectAtIndex:source withObject:dst];
    [_items replaceObjectAtIndex:dest withObject:src];
    [OADestinationsHelper.instance reorderDestinations:_items];
}

- (NSInteger)rowsCount
{
    return _items.count;
}

- (UITableViewCell *)cellForRow:(NSInteger)row
{
    OADirectionTableViewCell* cell;
    cell = (OADirectionTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OADirectionTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADirectionTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OADirectionTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.allowsSwipeWhenEditing = YES;
        OADestinationItem* item = [self getItem:row];
        [self updateCell:cell item:item row:row];
    }

    return cell;
}

- (void)didSelectRow:(NSInteger)row
{
    OADestinationItem* item = [self getItem:row];
    
    if (item.destination.hidden)
        [[OADestinationsHelper instance] showOnMap:item.destination];
 
    [[OADestinationsHelper instance] moveDestinationOnTop:item.destination wasSelected:YES];
    
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
    [[OARootViewController instance].mapPanel openTargetViewWithDestination:item.destination];
}

- (id)getItem:(NSInteger)row
{
    if (row < _items.count)
        return _items[row];
    else
        return nil;
}

- (void)updateCell:(UITableViewCell *)cell item:(id)item row:(NSInteger)row
{
    OADirectionTableViewCell *dirCell = (OADirectionTableViewCell *)cell;
    OADestinationItem *destItem = item;
    
    dirCell.separatorInset = UIEdgeInsetsMake(0.0, dirCell.titleLabel.frame.origin.x, 0.0, 0.0);
    
    dirCell.leftIcon.image = [UIImage imageNamed:[destItem.destination.markerResourceName stringByAppendingString:@"_small"]];
    [dirCell.titleLabel setText:destItem.destination.desc];
    dirCell.descIcon.transform = CGAffineTransformMakeRotation(destItem.direction);
    [dirCell.descLabel setText:destItem.distanceStr];
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([self isDecelerating] || [self isSwiping] || _isAnimating)
        return;

    if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.3 && !forceUpdate)
        return;
    
    _lastUpdate = [[NSDate date] timeIntervalSince1970];

    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    for (OADestinationItem *item in _items)
    {
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          item.destination.longitude, item.destination.latitude);
        
        item.distanceStr = [_app getFormattedDistance:distance];
        item.distance = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:item.destination.latitude longitude:item.destination.longitude]];
        item.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    }
    
    [self refreshVisibleRows];
}

- (void)onAppear
{
    [self generateData];
    [self updateDistanceAndDirection:YES];
    
    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(updateDistanceAndDirection)
                                                         andObserve:_app.locationServices.updateObserver];
    
    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemove:withKey:)
                                                            andObserve:_app.data.destinationRemoveObservable];

}

- (void)onDisappear
{
    if (_destinationRemoveObserver)
    {
        [_destinationRemoveObserver detach];
        _destinationRemoveObserver = nil;
    }

    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
}

- (NSArray *)getSwipeButtons:(NSInteger)row
{
    CGFloat padding = 15;
    
    OADestinationItem* item = [self getItem:row];

    MGSwipeButton *deactivate = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     if (self.delegate)
                                         [self.delegate indexPathForSwipingCellChanged:nil];
                                     
                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     [self remove:item];
                                     
                                     return YES;
                                 }];
    return @[deactivate];
}

- (void)onDestinationRemove:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OADestination *destination = key;
        __block OADestinationItem *toDelete = nil;
        [_items enumerateObjectsUsingBlock:^(OADestinationItem *item, NSUInteger idx, BOOL *stop)
        {
            if ([item.destination isEqual:destination])
            {
                _activeIndexPath = [NSIndexPath indexPathForRow:idx inSection:self.section];
                toDelete = item;
                *stop = YES;
            }
        }];
        
        if (toDelete)
            [self doRemoveDirection:toDelete];
    });
}

- (void)remove:(OADestinationItem *)item
{
    [[OADestinationsHelper instance] addHistoryItem:item.destination];
    [[OADestinationsHelper instance] removeDestination:item.destination];
}

- (void)doRemoveDirection:(OADestinationItem *)item
{
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        if ([self hasActiveItems])
        {
            if (_items.count > 0)
            {
                [self refreshVisibleRows];
                [self refreshSwipeButtons];
            }
            
            [self.tableView reloadData];
        }
        
        _isAnimating = NO;
    }];
    
    [self.tableView beginUpdates];

    [_items removeObject:item];
    
    if (_items.count == 0)
        [self removeCard];
    else
        [self.tableView deleteRowsAtIndexPaths:@[_activeIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    [self.tableView endUpdates];
    
    [CATransaction commit];
    
    if (![self hasActiveItems] && _items.count > 0)
    {
        [[OARootViewController instance].mapPanel hideDestinationCardsView];
    }
}

- (BOOL)hasActiveItems
{
    NSInteger count = _items.count;
    for (OADestinationItem *item in _items)
    {
        if (item.destination.hidden)
            count--;
    }
    
    return count > 0;
}

@end
