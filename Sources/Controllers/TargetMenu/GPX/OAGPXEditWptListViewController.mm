//
//  OAGPXEditWptListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXEditWptListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGPXListViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAMultiselectableHeaderView.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAGPXEditWptListViewController ()<OAMultiselectableHeaderDelegate>
{
    OsmAndAppInstance _app;

    BOOL isDecelerating;
    BOOL isMoving;
}

@property (strong, nonatomic) NSMutableArray* unsortedPoints;

@end

@implementation OAGPXEditWptListViewController
{
    OAMultiselectableHeaderView *_headerView;
    BOOL _localEditing;
}

- (id)initWithLocationMarks:(NSArray *)locationMarks
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        [self setPoints:locationMarks];
        
        isDecelerating = NO;
        isMoving = NO;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 32.0)];
    _headerView.editable = NO;
    _headerView.checkmarkIndent = 5.0;
    _headerView.delegate = self;
}

- (void)setPoints:(NSArray *)locationMarks
{
    NSMutableArray *arr = [NSMutableArray array];
    for (OAGpxWpt *p in locationMarks)
    {
        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
        item.point = p;
        [arr addObject:item];
    }
    
    self.unsortedPoints = arr;
}

- (void)setLocalEditing:(BOOL)localEditing;
{
    _localEditing = localEditing;

    for (OAGpxWptItem *item in self.unsortedPoints)
        item.selected = NO;

    _headerView.editable = localEditing;
    if (localEditing)
    {
        [_headerView setEditing:NO animated:NO];
        [_headerView setEditing:localEditing animated:NO];
    }
    
    [self.tableView reloadData];
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ((isMoving || isDecelerating) && !forceUpdate)
        return;
    
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
        return;
    
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
    {
        return;
    }
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    
    [self.unsortedPoints enumerateObjectsUsingBlock:^(OAGpxWptItem* itemData, NSUInteger idx, BOOL *stop) {
        OsmAnd::LatLon latLon(itemData.point.position.latitude, itemData.point.position.longitude);
        const auto& wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
        const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);
        
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          wptLon, wptLat);
        
        itemData.distance = [OAOsmAndFormatter getFormattedDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
        itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
    }];
    
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

- (void)doViewAppear
{
    [self generateData];
    
    [self.tableView setEditing:YES];
    
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
}

- (void)doViewDisappear
{
    [self.tableView setEditing:NO];

    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

-(void)generateData
{
    [_headerView setTitleText:[NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_points"), self.unsortedPoints.count]];
    [self updateDistanceAndDirection:YES];
}

- (void)resetData
{
}

- (void)refreshGpxDoc
{
    if (self.delegate)
    {
        NSMutableArray* arr = [NSMutableArray array];
        for (OAGpxWptItem *item in self.unsortedPoints)
        {
            [arr addObject:item.point];
        }
        
        [self.delegate refreshGpxDocWithPoints:[NSArray arrayWithArray:arr]];
    }
}

- (NSArray *)getSelectedItems
{
    NSMutableArray *arr = [NSMutableArray array];
    for (OAGpxWptItem *item in self.unsortedPoints)
    {
        if (item.selected)
            [arr addObject:item];
    }
    return [NSArray arrayWithArray:arr];
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    for (OAGpxWptItem *item in self.unsortedPoints)
        item.selected = value;

    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"gpx_waypoints");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return 1;
    
    return self.unsortedPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.unsortedPoints.count == 0)
    {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:OALocalizedString(@"add_waypoint")];
            [cell.iconView setImage: [UIImage imageNamed:@"add_waypoint_to_track"]];
        }
        return cell;
    }
    else
    {
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAGpxWptItem* item = [self getWptItem:indexPath];
            
            NSMutableString *distanceStr = [NSMutableString string];
            if (item.distance)
                [distanceStr appendString:item.distance];

            if (item.point.type.length > 0)
            {
                if (distanceStr.length > 0)
                    [distanceStr appendString:@", "];
                [distanceStr appendString:item.point.type];
            }
            
            [cell.titleView setText:item.point.name];
            [cell.distanceView setText:distanceStr];
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);

            if (_localEditing)
            {
                cell.rightArrow.hidden = YES;
                if (!item.selected)
                    [cell.titleIcon setImage:[UIImage imageNamed:@"selection_unchecked"]];
                else
                    [cell.titleIcon setImage:[UIImage imageNamed:@"selection_checked"]];
                
                cell.titleIcon.hidden = NO;
            }
            else
            {
                cell.rightArrow.hidden = NO;
                cell.titleIcon.hidden = YES;
            }
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    
    return nil;
}

-(OAGpxWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    return self.unsortedPoints[indexPath.row];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.unsortedPoints.count > 0;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.unsortedPoints.count > 0;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OAGpxWptItem* item = [self getWptItem:sourceIndexPath];
    [self.unsortedPoints removeObject:item];
    [self.unsortedPoints insertObject:item atIndex:destinationIndexPath.row];
    
    [self refreshGpxDoc];
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
    if (!decelerate)
        isDecelerating = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isMoving = YES;
    //[self refreshAllRows];
}

- (void)tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isMoving = NO;
    //[self refreshAllRows];
}

- (void)tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    isMoving = NO;
    //[self refreshAllRows];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // Allow the proposed destination.
    return proposedDestinationIndexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_localEditing && self.unsortedPoints.count > 0)
    {
        OAGpxWptItem* item = [self getWptItem:indexPath];
        item.selected = !item.selected;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.unsortedPoints.count == 0)
    {
        if (self.delegate)
            [self.delegate callGpxEditMode];
        return;
    }
    
    OAGpxWptItem* item = [self getWptItem:indexPath];
   [[OARootViewController instance].mapPanel openTargetViewWithWpt:item pushed:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return 0.01;
    else
        return 40.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.unsortedPoints.count == 0)
        return nil;
    
    return _headerView;
}

@end

