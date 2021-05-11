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
#import "OADestinationsHelper.h"
#import "OAGPXRouteCardHeaderView.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"

#define kGpxRouteCardMaxRows 5

@implementation OAGPXRouteCardController
{
    OAGPXRouter *_gpxRouter;
    
    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_gpxRouteChangedObserver;
    
    OAAutoObserverProxy *_routePointDeactivatedObserver;
    OAAutoObserverProxy *_routePointActivatedObserver;

    BOOL _isAnimating;
    
    NSMutableArray *_items;
}

@synthesize activeIndexPath = _activeIndexPath;
@synthesize cardHeaderView = _cardHeaderView;

- (instancetype)initWithSection:(NSInteger)section tableView:(UITableView *)tableView
{
    self = [super initWithSection:section tableView:tableView];
    if (self)
    {
        _isAnimating = NO;
        
        _gpxRouter = [OAGPXRouter sharedInstance];

        _cardHeaderView = [[OAGPXRouteCardHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 60.0)];
        _cardHeaderView.title.text = [OALocalizedString(@"gpx_route") uppercaseStringWithLocale:[NSLocale currentLocale]];
        [_cardHeaderView setRightButtonTitle:[OALocalizedString(@"shared_string_modify") uppercaseStringWithLocale:[NSLocale currentLocale]]];
        [_cardHeaderView.rightButton addTarget:self action:@selector(headerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [self generateData];
    }
    return self;
}

- (void)generateData
{
    _items = [NSMutableArray arrayWithArray:_gpxRouter.routeDoc.activePoints];
}

- (void)headerButtonPressed
{
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
    [[OARootViewController instance].mapPanel openTargetViewWithGPXRoute:NO segmentType:kSegmentRouteWaypoints];
}

- (NSInteger)rowsCount
{
    return (_items.count > kGpxRouteCardMaxRows ? kGpxRouteCardMaxRows : _items.count);
}

- (UITableViewCell *)cellForRow:(NSInteger)row
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
        cell.allowsSwipeWhenEditing = YES;
        OAGpxRouteWptItem* item = [self getItem:row];
        [self updateCell:cell item:item row:row];
    }
    return cell;
}

- (void)didSelectRow:(NSInteger)row
{
    if (row > 0)
        [[OADestinationsHelper instance] moveRoutePointOnTop:row];

    OAGpxRouteWptItem* item = [self getItem:row];
    
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
    [[OARootViewController instance].mapPanel openTargetViewWithWpt:item pushed:NO showFullMenu:NO];
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
        
        [routeCell hideRightButton:YES];        
        [routeCell hideDescIcon:NO];
        
        routeCell.topVDotsVisible = NO;
        routeCell.bottomVDotsVisible = _items.count > 1;
    }
    else
    {
        routeCell.leftIcon.image = [UIImage imageNamed:@"ic_coordinates"];
        routeCell.leftIcon.transform = CGAffineTransformIdentity;
        [routeCell hideRightButton:YES];
        [routeCell hideDescIcon:YES];
        
        routeCell.topVDotsVisible = YES;
        routeCell.bottomVDotsVisible = row < _items.count - 1;
    }

    [routeCell hideVDots:NO];
}

- (void)updateDistanceAndDirection
{
    if ([self isDecelerating] || [self isSwiping] || _isAnimating)
        return;
    
    [self refreshFirstRow];
}

- (void)onGpxRouteChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [((OAGPXRouteCardHeaderView *)self.cardHeaderView) updateStatistics];
    });
}

- (void)onAppear
{
    [self generateData];
    
    _gpxRouteChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onGpxRouteChanged)
                                                          andObserve:[OAGPXRouter sharedInstance].routeChangedObservable];

    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(updateDistanceAndDirection)
                                                         andObserve:_gpxRouter.locationUpdatedObservable];
    
    _routePointDeactivatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onDeactivation:withKey:)
                                                         andObserve:_gpxRouter.routePointDeactivatedObservable];
    _routePointActivatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onActivation:withKey:)
                                                                andObserve:_gpxRouter.routePointActivatedObservable];
}

- (void)onDisappear
{
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
    
    if (_routePointDeactivatedObserver)
    {
        [_routePointDeactivatedObserver detach];
        _routePointDeactivatedObserver = nil;
    }

    if (_routePointActivatedObserver)
    {
        [_routePointActivatedObserver detach];
        _routePointActivatedObserver = nil;
    }

    if (_gpxRouteChangedObserver)
    {
        [_gpxRouteChangedObserver detach];
        _gpxRouteChangedObserver = nil;
    }
    
    if (_gpxRouter.routeDoc)
        [_gpxRouter saveRouteIfModified];
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
                                     [self deactivate:item];
                                     
                                     return YES;
                                 }];

    MGSwipeButton *driveTo = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_waypoint_up"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                              {
                                  if (self.delegate)
                                      [self.delegate indexPathForSwipingCellChanged:nil];

                                  NSIndexPath * indexPath = [NSIndexPath indexPathForRow:row inSection:self.section];
                                  _activeIndexPath = [indexPath copy];
                                  OAGpxRouteWptItem* item = [self getItem:row];
                                  [self activate:item];
                                  
                                  return YES;
                              }];
        
    if (row == 0)
        return @[visit];
    else
        return @[visit, driveTo];
}

- (void)addHistoryItem:(OAGpxRouteWptItem *)item
{
    OAHistoryItem *h = [[OAHistoryItem alloc] init];
    h.name = item.point.name;
    h.latitude = item.point.position.latitude;
    h.longitude = item.point.position.longitude;
    h.date = [NSDate date];
    h.hType = OAHistoryTypeRouteWpt;
    
    [[OAHistoryHelper sharedInstance] addPoint:h];
}

- (void)deactivate:(OAGpxRouteWptItem *)item
{
    [self addHistoryItem:item];
    [_gpxRouter.routeDoc moveToInactive:item];
}

- (void)onDeactivation:(id)observable withKey:(id)key
{
    OAGpxRouteWptItem *_item = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_items enumerateObjectsUsingBlock:^(OAGpxRouteWptItem *item, NSUInteger idx, BOOL *stop) {
            if (_item == item)
            {
                _activeIndexPath = [NSIndexPath indexPathForRow:idx inSection:self.section];
                [self doDeactivate:_item];
                *stop = YES;
            }
        }];
    });
}

- (void)doDeactivate:(OAGpxRouteWptItem *)item
{
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{

        _isAnimating = NO;

        if (_items.count > 0)
        {
            [self refreshVisibleRows];
            [self refreshSwipeButtons];
            [_gpxRouter updateDistanceAndDirection:YES];
            
            [self.tableView reloadData];
        }
    }];
    
    [self.tableView beginUpdates];
    
    [_items removeObject:item];
    
    if (_items.count == 0)
    {
        [self removeCard];
    }
    else
    {
        [self.tableView deleteRowsAtIndexPaths:@[_activeIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        if (_items.count > kGpxRouteCardMaxRows - 1)
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kGpxRouteCardMaxRows - 1 inSection:self.section]] withRowAnimation:UITableViewRowAnimationTop];
    }
    
    [self.tableView endUpdates];
    
    [CATransaction commit];
    
    [_gpxRouter.routeDoc updatePointsArray];
}

- (void)activate:(OAGpxRouteWptItem *)item
{
    [_gpxRouter.routeDoc moveToActive:item];
}

- (void)onActivation:(id)observable withKey:(id)key
{
    OAGpxRouteWptItem *_item = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_items enumerateObjectsUsingBlock:^(OAGpxRouteWptItem *item, NSUInteger idx, BOOL *stop) {
            if (_item == item)
            {
                _activeIndexPath = [NSIndexPath indexPathForRow:idx inSection:self.section];
                *stop = YES;
            }
        }];
        [self doActivate:_item];
    });
}

- (void)doActivate:(OAGpxRouteWptItem *)item
{
    _isAnimating = YES;
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        
        [self refreshVisibleRows];
        [self refreshSwipeButtons];
        
        _isAnimating = NO;

        [_gpxRouter updateDistanceAndDirection:YES];

        [self.tableView reloadData];
    }];
    
    [self.tableView beginUpdates];
    NSIndexPath *destination = [NSIndexPath indexPathForRow:0 inSection:self.section];
    
    [_items removeObject:item];
    [_items insertObject:item atIndex:0];
    
    if (_activeIndexPath)
        [self.tableView moveRowAtIndexPath:_activeIndexPath toIndexPath:destination];
    else
        [self.tableView insertRowsAtIndexPaths:@[destination] withRowAnimation:UITableViewRowAnimationBottom];
    
    [self.tableView endUpdates];
        
    [CATransaction commit];
    
    [_gpxRouter.routeDoc updatePointsArray:YES];
}

@end
