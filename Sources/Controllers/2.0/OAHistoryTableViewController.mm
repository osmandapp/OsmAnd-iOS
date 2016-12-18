//
//  OAHistoryTableViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAHistoryTableViewController.h"
#import "OAPOISearchHelper.h"
#import "OsmAndApp.h"
#import <CoreLocation/CoreLocation.h>
#import "OAHistoryItem.h"

#include <OsmAndCore/Utilities.h>

@interface OAHistoryTableViewController ()

@end

@implementation OAHistoryTableViewController
{
    BOOL isDecelerating;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OAHistoryTableViewController alloc] initWithNibName:@"OAHistoryTableViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    isDecelerating = NO;
}

-(void)updateDistancesAndSort
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    if (_searchNearMapCenter)
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_myLocation);
        newLocation = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    if (!newLocation)
    {
        return;
    }
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [_dataArray enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        
        if ([item isKindOfClass:[OAHistoryItem class]])
        {
            OAHistoryItem *itemData = item;
            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                              newLocation.coordinate.latitude,
                                                              itemData.longitude, itemData.latitude);
            
            itemData.distance = [app getFormattedDistance:distance];
            itemData.distanceMeters = distance;
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.latitude longitude:itemData.longitude]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
            
            [arr addObject:item];
        }
        else
        {
            [arr addObject:item];
        }
        
    }];
    
    if ([arr count] > 0)
    {
        NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(OAHistoryItem *obj1, OAHistoryItem *obj2)
                                {
                                    return [obj2.date compare:obj1.date];
                                }];
        
        _dataArray = sortedArray;
    }
    else
    {
        _dataArray = arr;
    }
    
    if (isDecelerating)
        return;
    
    [self.tableView reloadData];
    if (_dataArray.count > 0)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getHeightForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:nil showCoordinates:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OAPOISearchHelper getNumberOfRows:_dataArray dataPoiArray:nil currentScope:EPOIScopeUndefined showCoordinates:NO showTopList:NO poiInList:NO searchRadiusIndex:0 searchRadiusIndexMax:0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getCellForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:nil currentScope:EPOIScopeUndefined poiInList:NO showCoordinates:NO foundCoords:nil showTopList:NO searchRadiusIndex:0 searchRadiusIndexMax:0 searchNearMapCenter:_searchNearMapCenter];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && indexPath.row < _dataArray.count)
    {
        [self.delegate didSelectHistoryItem:_dataArray[indexPath.row]];
    }
}

#pragma mark - UIScrollViewDelegate

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

@end
