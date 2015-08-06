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

#import <OsmAndCore/Utilities.h>

@interface OADestinationItem : NSObject

@property (nonatomic) OADestination *destination;
@property (nonatomic, assign) CGFloat distance;
@property (nonatomic) NSString *distanceStr;
@property (nonatomic, assign) CGFloat direction;

@end

@implementation OADestinationItem

@end


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
        _cardHeaderView.title.text = [OALocalizedString(@"directions") uppercaseStringWithLocale:[NSLocale currentLocale]];
        [_cardHeaderView.rightButton removeFromSuperview];
        
        _items = [NSMutableArray array];
        [self generateData];
    }
    return self;
}

- (void)generateData
{
    [_items removeAllObjects];
    
    for (OADestination *destination in _app.data.destinations)
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

    [_items sortUsingComparator:^NSComparisonResult(OADestinationItem *obj1, OADestinationItem *obj2) {
        
        const auto distance1 = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          obj1.destination.longitude, obj1.destination.latitude);
        const auto distance2 = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                           newLocation.coordinate.latitude,
                                                           obj2.destination.longitude, obj2.destination.latitude);
        if (distance2 > distance1)
            return NSOrderedAscending;
        else if (distance2 < distance1)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
}

- (NSInteger)rowsCount
{
    return _items.count;
}

- (UITableViewCell *)cellForRow:(NSInteger)row
{
    OADirectionTableViewCell* cell;
    cell = (OADirectionTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OADirectionTableViewCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADirectionCell" owner:self options:nil];
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
    [[OADestinationsHelper instance] moveDestinationOnTop:item.destination];
    
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
    
    if (destItem.destination.parking)
    {
        dirCell.leftIcon.image = [UIImage imageNamed:@"ic_parking_pin_small"];
        [dirCell.titleLabel setText:destItem.destination.desc];
        dirCell.descIcon.transform = CGAffineTransformMakeRotation(destItem.direction);
        
        NSMutableString *descText = [NSMutableString string];
        if (destItem.distanceStr)
        {
            [descText appendString:destItem.distanceStr];
        }
        NSString *parkingStr = [OADestinationCell parkingTimeStr:destItem.destination shortText:NO];
        if (parkingStr)
        {
            if (descText.length > 0)
                [descText appendString:@", "];
            [descText appendString:parkingStr];
        }
        
        [dirCell.descLabel setText:descText];
    }
    else
    {
        dirCell.leftIcon.image = [UIImage imageNamed:[destItem.destination.markerResourceName stringByAppendingString:@"_small"]];
        [dirCell.titleLabel setText:destItem.destination.desc];
        dirCell.descIcon.transform = CGAffineTransformMakeRotation(destItem.direction);
        [dirCell.descLabel setText:destItem.distanceStr];
    }
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

    MGSwipeButton *show = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"waypoint_map_enable"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     [self showOnMap:item.destination];
                                     
                                     return YES;
                                 }];
    
    MGSwipeButton *hide = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"waypoint_map_disable"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                           {
                               NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                               _activeIndexPath = [indexPath copy];
                               [self hideOnMap:item.destination];
                               
                               return YES;
                           }];

    MGSwipeButton *deactivate = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     if (self.delegate)
                                         [self.delegate indexPathForSwipingCellChanged:nil];
                                     
                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     [self remove:item];
                                     
                                     return YES;
                                 }];
    
    if (item.destination.hidden)
        return @[deactivate, show];
    else
        return @[deactivate, hide];
}

- (void)showOnMap:(OADestination *)destination
{
    [[OADestinationsHelper instance] showOnMap:destination];
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
}

- (void)hideOnMap:(OADestination *)destination
{
    [[OADestinationsHelper instance] hideOnMap:destination];
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
}

- (void)onDestinationRemove:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_items enumerateObjectsUsingBlock:^(OADestinationItem *item, NSUInteger idx, BOOL *stop)
        {
            if ([item.destination isEqual:destination])
            {
                _activeIndexPath = [NSIndexPath indexPathForRow:idx inSection:self.section];
                [self doRemoveDirection:item];
                *stop = YES;
            }
        }];
    });
}

- (void)remove:(OADestinationItem *)item
{
    [[OADestinationsHelper instance] removeDestination:item.destination];
}

- (void)doRemoveDirection:(OADestinationItem *)item
{
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        if (_items.count > 0)
        {
            [self refreshVisibleRows];
            [self refreshSwipeButtons];
        }
        
        [self.tableView reloadData];
        
        _isAnimating = NO;
    }];
    
    [self.tableView beginUpdates];

    [_items removeObject:item];
    
    if (_items.count == 0)
    {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.section] withRowAnimation:UITableViewRowAnimationLeft];
        [self removeCard];
    }
    else
    {
        [self.tableView deleteRowsAtIndexPaths:@[_activeIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    [self.tableView endUpdates];
    
    [CATransaction commit];
}

- (void)updateDirections
{
    // refresh top toobar
    // todo
}

@end
