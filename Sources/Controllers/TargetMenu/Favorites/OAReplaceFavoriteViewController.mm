//
//  OAReplaceFavoriteViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 12.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAReplaceFavoriteViewController.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "OAAutoObserverProxy.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"
#import "OsmAndApp.h"
#import "OAPointTableViewCell.h"
#import "OASegmentTableViewCell.h"
#import "OAGPXDocument.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define kVerticalMargin 16.
#define kHorizontalMargin 16.
#define kGPXCellTextLeftOffset 62.

typedef NS_ENUM(NSInteger, EOASortingMode) {
    EOADistance = 0,
    EOANameAscending,
    EOANameDescending
};

@interface OAReplaceFavoriteViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@end

@implementation OAReplaceFavoriteViewController
{
    OsmAndAppInstance _app;
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<OAFavoriteItem *> *_allFavorites;
    NSArray<OAGpxWptItem *> *_allWaypoints;
    EOASortingMode _sortingMode;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    NSTimeInterval _lastUpdateTime;
    OAGPXDocument *_gpxDocument;
    EOAReplacePointType _replaceItemType;
}

- (instancetype)initWithItemType:(EOAReplacePointType)replaceItemType gpxDocument:(OAGPXDocument *)gpxDocument
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _replaceItemType = replaceItemType;
        _gpxDocument = gpxDocument;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    if (_replaceItemType == EOAReplacePointTypeFavorite)
    {
        _allFavorites = [OAFavoritesHelper getFavoriteItems];
    }
    else if (_replaceItemType == EOAReplacePointTypeWaypoint)
    {
        NSMutableArray *arr = [NSMutableArray array];
        for (OAWptPt *point in _gpxDocument.points)
        {
            OAGpxWptItem *itemData = [[OAGpxWptItem alloc] init];
            itemData.point = point;
            [self setDistanceAndDirections:itemData];
            [arr addObject:itemData];
        }

        _allWaypoints = arr;
    }
    [self updateDistanceAndDirection:YES];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _sortingMode = EOADistance;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.tableView.contentInset = UIEdgeInsetsMake(-16, 0, 0, 0);
    
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"fav_replace");
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *pointsSection = [NSMutableArray new];

    [pointsSection addObject:@{
        @"type" : [OASegmentTableViewCell getCellIdentifier],
        @"title0" : OALocalizedString(@"by_dist"),
        @"title1" : OALocalizedString(@"shared_a_z"),
        @"title2" : OALocalizedString(@"shared_z_a"),
        @"key" : @"segment_control"
    }];

    if (_replaceItemType == EOAReplacePointTypeFavorite)
    {
        NSArray *sortedFavorites = [self sortFavoritesData:_allFavorites];
        for (OAFavoriteItem *favorite in sortedFavorites) {
            NSString *name = [favorite getDisplayName];
            NSString *distance = favorite.distance;

            [pointsSection addObject:@{
                    @"type": [OAPointTableViewCell getCellIdentifier],
                    @"title": name ? name : @"",
                    @"distance": distance ? distance : @"",
                    @"direction": [NSNumber numberWithFloat:favorite.direction],
                    @"item": favorite,
            }];
        }
    }
    else if (_replaceItemType == EOAReplacePointTypeWaypoint)
    {
        NSArray *sortedWaypoints = [self sortWaypointsData:_allWaypoints];
        for (OAGpxWptItem *waypoint in sortedWaypoints) {
            NSString *name = waypoint.point.name;
            NSString *distance = waypoint.distance;

            [pointsSection addObject:@{
                    @"type": [OAPointTableViewCell getCellIdentifier],
                    @"title": name ? name : @"",
                    @"distance": distance ? distance : @"",
                    @"direction": [NSNumber numberWithFloat:waypoint.direction],
                    @"item": waypoint,
            }];
        }
    }
    [data addObject:pointsSection];
    _data = data;
}

- (NSArray<OAFavoriteItem *> *)sortFavoritesData:(NSArray<OAFavoriteItem *> *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        switch (_sortingMode) {
            case EOADistance:
            {
                NSNumber *distance1 = @(obj1.distanceMeters);
                NSNumber *distance2 = @(obj2.distanceMeters);
                return [distance1 compare:distance2];
            }
            case EOANameAscending:
            {
                NSString *title1 = [obj1 getDisplayName];
                NSString *title2 = [obj2 getDisplayName];
                return [title1 compare:title2 options:NSCaseInsensitiveSearch];
            }
            case EOANameDescending:
            {
                NSString *title1 = [obj1 getDisplayName];
                NSString *title2 = [obj2 getDisplayName];
                return [title2 compare:title1 options:NSCaseInsensitiveSearch];
            }
            default:
                break;
        }
    }];
    return sortedData;
}

- (NSArray<OAGpxWptItem *> *)sortWaypointsData:(NSArray<OAGpxWptItem *> *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem *obj1, OAGpxWptItem *obj2) {
        switch (_sortingMode) {
            case EOADistance:
            {
                NSNumber *distance1 = @(obj1.distanceMeters);
                NSNumber *distance2 = @(obj2.distanceMeters);
                return [distance1 compare:distance2];
            }
            case EOANameAscending:
            {
                NSString *title1 = obj1.point.name;
                NSString *title2 = obj2.point.name;
                return [title1 compare:title2 options:NSCaseInsensitiveSearch];
            }
            case EOANameDescending:
            {
                NSString *title1 = obj1.point.name;
                NSString *title2 = obj2.point.name;
                return [title2 compare:title1 options:NSCaseInsensitiveSearch];
            }
            default:
                break;
        }
    }];
    return sortedData;
}

#pragma mark - Actions

- (void) segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        if (segment.selectedSegmentIndex == 0)
            _sortingMode = EOADistance;
        else if (segment.selectedSegmentIndex == 1)
            _sortingMode = EOANameAscending;
        else if (segment.selectedSegmentIndex == 2)
            _sortingMode = EOANameDescending;
        
        [self updateDistanceAndDirection:YES];
    }
}

- (void) updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSDate date] timeIntervalSince1970] - _lastUpdateTime < 0.3 && !forceUpdate)
            return;
        _lastUpdateTime = [[NSDate date] timeIntervalSince1970];
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        if (!newLocation)
            return;
        
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        if (_replaceItemType == EOAReplacePointTypeFavorite)
        {
            [_allFavorites enumerateObjectsUsingBlock:^(OAFavoriteItem *itemData, NSUInteger idx, BOOL *stop) {
                const auto &favoritePosition31 = itemData.favorite->getPosition31();
                const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
                const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);

                const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                        newLocation.coordinate.latitude,
                        favoriteLon, favoriteLat);

                itemData.distance = [OAOsmAndFormatter getFormattedDistance:distance];
                itemData.distanceMeters = distance;
                CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
                itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
            }];
        }
        else
        if (_replaceItemType == EOAReplacePointTypeWaypoint)
        {
            [_allWaypoints enumerateObjectsUsingBlock:^(OAGpxWptItem *itemData, NSUInteger idx, BOOL *stop) {
                [self setDistanceAndDirections:itemData];
            }];
        }
        
        [self generateData];
        [self.tableView reloadData];
    });
}

- (void)setDistanceAndDirections:(OAGpxWptItem *)itemData
{
    OsmAnd::LatLon latLon(itemData.point.position.latitude, itemData.point.position.longitude);
    const auto wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
    const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
            newLocation.coordinate.latitude,
            wptLon, wptLat);

    itemData.distance = [OAOsmAndFormatter getFormattedDistance:distance];
    itemData.distanceMeters = distance;
    CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
            (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                    ? newLocation.course
                    : newHeading;
    itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
}

#pragma mark - TableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OASegmentTableViewCell getCellIdentifier]])
    {
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
            [cell.segmentControl insertSegmentWithTitle:item[@"title2"] atIndex:2 animated:NO];
        }
        if (cell)
        {
            [cell.segmentControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAPointTableViewCell getCellIdentifier]])
    {
        OAPointTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointTableViewCell *) nib[0];
        }
        
        if (cell)
        {
            [cell.titleView setText:item[@"title"]];
            cell = [self setupPoiIconForCell:cell withPointItem:item[@"item"]];
            
            [cell.distanceView setText:item[@"distance"]];
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation([item[@"direction"] floatValue]);
            cell.separatorInset = UIEdgeInsetsZero;
        }
        return cell;
    }
    
    return nil;
}

- (OAPointTableViewCell *)setupPoiIconForCell:(OAPointTableViewCell *)cell withPointItem:(id)item
{
    if ([item isKindOfClass:[OAFavoriteItem class]])
        cell.titleIcon.image = [(OAFavoriteItem *)item getCompositeIcon];
    else if ([item isKindOfClass:[OAGpxWptItem class]])
        cell.titleIcon.image = [(OAGpxWptItem *)item getCompositeIcon];
    return cell;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate)
        {
            if (_replaceItemType == EOAReplacePointTypeFavorite)
                [self.delegate onFavoriteReplaced:item[@"item"]];
            else if (_replaceItemType == EOAReplacePointTypeWaypoint)
                [self.delegate onWaypointReplaced:item[@"item"]];
        }
    }];
}

@end
