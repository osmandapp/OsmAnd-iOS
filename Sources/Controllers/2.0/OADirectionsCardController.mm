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
    
    NSMutableArray *_items;
    
    NSTimeInterval _lastUpdate;
}

@synthesize activeIndexPath = _activeIndexPath;

- (instancetype)initWithSection:(NSInteger)section tableView:(UITableView *)tableView
{
    self = [super initWithSection:section tableView:tableView];
    if (self)
    {
        _app = [OsmAndApp instance];
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
}

- (NSString *)headerTitle
{
    return [OALocalizedString(@"directions") uppercaseStringWithLocale:[NSLocale currentLocale]];
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
    [self showDirection:item];
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
        dirCell.leftIcon.image = [UIImage imageNamed:destItem.destination.markerResourceName];
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
    if ([self isDecelerating] || [self isSwiping])
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
    
    MGSwipeButton *deactivate = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     if (self.delegate)
                                         [self.delegate indexPathForSwipingCellChanged:nil];
                                     
                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     OADestinationItem* item = [self getItem:row];
                                     [self removeDirection:item];
                                     
                                     return YES;
                                 }];
    
    return @[deactivate];
}

- (void)removeDirection:(OADestinationItem *)item
{
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        if (_items.count > 0)
        {
            [self refreshVisibleRows];
            [self refreshSwipeButtons];
        }
    }];
    
    [self.tableView beginUpdates];

    [[OARootViewController instance].mapPanel removeDestination:item.destination];
    
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

- (void)showDirection:(OADestinationItem *)item
{
    [[OADestinationsHelper instance] moveDestinationOnTop:item.destination];
}

- (void)updateDirections
{
    // refresh top toobar
    // todo
}

@end
