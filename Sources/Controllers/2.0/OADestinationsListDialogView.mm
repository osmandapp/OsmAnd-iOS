//
//  OADestinationsListDialogView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADestinationsListDialogView.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OsmAndApp.h"
#import "OADestinationItem.h"
#import "OAPointTableViewCell.h"
#import "Localization.h"

#import <OsmAndCore/Utilities.h>


@interface OADestinationsListDialogView () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation OADestinationsListDialogView

{
    NSMutableArray<OADestinationItem *> *_items;
    NSTimeInterval _lastUpdate;
    
    BOOL _isDecelerating;
    BOOL _autoHeight;
}



- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            [self commonInit];
        }
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            if (frame.size.height == -1)
            {
                self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 100);
                _autoHeight = YES;
            }
            else
            {
                self.frame = frame;
            }
            
            [self commonInit];
        }
    }
    return self;
}

- (void) commonInit
{
    _isDecelerating = NO;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, -1, 0);
    
    [self generateData];
    [self setupView];
    [self updateDistanceAndDirection:YES];
    
    if (_autoHeight)
        [self adjustHeight];
    
    /*
     OsmAndAppInstance app = [OsmAndApp instance];
     self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
     withHandler:@selector(updateDistanceAndDirection)
     andObserve:app.locationServices.updateObserver];
     */
}

- (void) adjustHeight
{
    CGRect f = self.frame;
    f.size.height = _tableView.contentSize.height - 1;
    self.frame = f;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.3 && !forceUpdate)
        return;
    
    _lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;
    
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    [_items enumerateObjectsUsingBlock:^(OADestinationItem* itemData, NSUInteger idx, BOOL *stop) {

        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          itemData.destination.longitude, itemData.destination.latitude);
        
        itemData.distance = distance;
        itemData.distanceStr = [app getFormattedDistance:distance];
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.destination.latitude longitude:itemData.destination.longitude]];
        itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
    }];
    
    if (_isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (void) refreshVisibleRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_tableView beginUpdates];
        NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [_tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OADestinationItem* item = _items[i.row];
                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;
                    
                    NSString *title = item.destination.desc ? item.destination.desc : OALocalizedString(@"ctx_mnu_direction");
                    NSString *imageName;
                    if (item.destination.parking)
                        imageName = @"ic_parking_pin_small";
                    else
                        imageName = [item.destination.markerResourceName ? item.destination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
                    
                    [c.titleView setText:title];
                    c.titleIcon.image = [UIImage imageNamed:imageName];
                    
                    [c.distanceView setText:item.distanceStr];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [_tableView endUpdates];
    });
}

- (void) generateData
{
    _items = [NSMutableArray array];
    for (OADestination *destination in [OADestinationsHelper instance].sortedDestinations)
    {
        OADestinationItem *item = [[OADestinationItem alloc] init];
        item.destination = destination;
        [_items addObject:item];
    }
    
    [_tableView reloadData];
}

- (void) setupView
{
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
    
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OADestinationItem* item = _items[indexPath.row];
        if (item)
        {
            NSString *title = item.destination.desc ? item.destination.desc : OALocalizedString(@"ctx_mnu_direction");
            NSString *imageName;
            if (item.destination.parking)
                imageName = @"ic_parking_pin_small";
            else
                imageName = [item.destination.markerResourceName ? item.destination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
            
            [cell.titleView setText:title];
            cell.titleIcon.image = [UIImage imageNamed:imageName];
            
            [cell.distanceView setText:item.distanceStr];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }
    }
    
    return cell;
}


#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        _isDecelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isDecelerating = NO;
    //[self refreshVisibleRows];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OADestinationItem* item = _items[indexPath.row];
    if (self.delegate)
        [self.delegate onDestinationSelected:item.destination];
}

@end
