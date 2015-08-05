//
//  OAHistoryCardController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryCardController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OADestination.h"
#import "OADirectionTableViewCell.h"
#import "OAAutoObserverProxy.h"
#import "MGSwipeButton.h"
#import "OAUtilities.h"
#import "OADestinationCell.h"
#import "OARootViewController.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OADestinationCardHeaderView.h"

#import <OsmAndCore/Utilities.h>

@interface OAHistoryCardItem : NSObject

@property (nonatomic) OAHistoryItem *item;
@property (nonatomic, assign) CGFloat distance;
@property (nonatomic) NSString *distanceStr;
@property (nonatomic, assign) CGFloat direction;

@end

@implementation OAHistoryCardItem

@end


@implementation OAHistoryCardController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy *_locationUpdateObserver;
    
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
        _cardHeaderView.title.text = [OALocalizedString(@"history") uppercaseStringWithLocale:[NSLocale currentLocale]];
        [_cardHeaderView.rightButton removeFromSuperview];
        
        _items = [NSMutableArray array];
        [self generateData];
    }
    return self;
}

- (void)generateData
{
    [_items removeAllObjects];

    NSArray *arr = [[OAHistoryHelper sharedInstance] getPointsHavingKnownType:3];
    
    for (OAHistoryItem *item in arr)
    {
        OAHistoryCardItem *cardItem = [[OAHistoryCardItem alloc] init];
        cardItem.item = item;
        [_items addObject:cardItem];
    }
    
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
    
    [_items sortUsingComparator:^NSComparisonResult(OAHistoryCardItem *obj1, OAHistoryCardItem *obj2) {
        
        const auto distance1 = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                           newLocation.coordinate.latitude,
                                                           obj1.item.longitude, obj1.item.latitude);
        const auto distance2 = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                           newLocation.coordinate.latitude,
                                                           obj2.item.longitude, obj2.item.latitude);
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
        OAHistoryCardItem* item = [self getItem:row];
        [self updateCell:cell item:item row:row];
    }
    
    return cell;
}

- (void)didSelectRow:(NSInteger)row
{
    OAHistoryCardItem* item = [self getItem:row];
    //[[OADestinationsHelper instance] moveDestinationOnTop:item.destination];
    
    [[OARootViewController instance].mapPanel openHideDestinationCardsView];
    //[[OARootViewController instance].mapPanel openTargetViewWithDestination:item.destination];
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
    OAHistoryCardItem *cardItem = item;
    
    dirCell.separatorInset = UIEdgeInsetsMake(0.0, dirCell.titleLabel.frame.origin.x, 0.0, 0.0);
    
    if (cardItem.item.hType == OAHistoryTypeParking)
    {
        dirCell.leftIcon.image = [UIImage imageNamed:@"ic_parking_pin_small"];
        [dirCell.titleLabel setText:cardItem.item.name];
        dirCell.descIcon.transform = CGAffineTransformMakeRotation(cardItem.direction);
        
        NSMutableString *descText = [NSMutableString string];
        if (cardItem.distanceStr)
        {
            [descText appendString:cardItem.distanceStr];
        }
        
        [dirCell.descLabel setText:descText];
    }
    else
    {
        dirCell.leftIcon.image = [UIImage imageNamed:@"ic_map_pin_small"];
        [dirCell.titleLabel setText:cardItem.item.name];
        dirCell.descIcon.transform = CGAffineTransformMakeRotation(cardItem.direction);
        [dirCell.descLabel setText:cardItem.distanceStr];
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
    
    for (OAHistoryCardItem *item in _items)
    {
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          item.item.longitude, item.item.latitude);
        
        item.distanceStr = [_app getFormattedDistance:distance];
        item.distance = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:item.item.latitude longitude:item.item.longitude]];
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
    
    /*
    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemove:withKey:)
                                                            andObserve:_app.data.destinationRemoveObservable];
     */
    
}

- (void)onDisappear
{
    /*
    if (_destinationRemoveObserver)
    {
        [_destinationRemoveObserver detach];
        _destinationRemoveObserver = nil;
    }
     */
    
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
}

- (NSArray *)getSwipeButtons:(NSInteger)row
{
    CGFloat padding = 15;
    
    OAHistoryCardItem* cardItem = [self getItem:row];
    
    MGSwipeButton *remove = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     if (self.delegate)
                                         [self.delegate indexPathForSwipingCellChanged:nil];
                                     
                                     NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                     _activeIndexPath = [indexPath copy];
                                     [self remove:cardItem];
                                     
                                     return YES;
                                 }];
    return @[remove];
}

- (void)onDestinationRemove:(id)observable withKey:(id)key
{
    OAHistoryItem *item = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_items enumerateObjectsUsingBlock:^(OAHistoryCardItem *cardItem, NSUInteger idx, BOOL *stop)
         {
             if ([cardItem.item isEqual:item])
             {
                 _activeIndexPath = [NSIndexPath indexPathForRow:idx inSection:self.section];
                 [self doRemoveDirection:item];
                 *stop = YES;
             }
         }];
    });
}

- (void)remove:(OAHistoryCardItem *)cardItem
{
    //[[OADestinationsHelper instance] removeDestination:item.destination];
}

- (void)doRemoveDirection:(OAHistoryItem *)item
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

@end
