//
//  OADestinationItemsListViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADestinationItemsListViewController.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAPointTableViewCell.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OADestinationItem.h"
#import "OADestinationsHelper.h"
#import "OAOsmAndFormatter.h"
#import "OAAutoObserverProxy.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

typedef NS_ENUM(NSInteger, EOASortType)
{
    EOASortTypeByName = 0,
    EOASortTypeByGroup,
    EOASortTypeByDistance
};

@interface FavTableGroup : NSObject

@property NSString *groupName;
@property NSMutableArray *groupItems;

@end

@implementation FavTableGroup

-(id)init
{
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@implementation OADestinationItemsListViewController
{
    EOADestinationPointType _type;
    EOASortType _sortingType;
    NSTimeInterval _lastUpdate;
    BOOL _decelerating;
    
    NSMutableArray *_groupsAndFavorites;
    NSMutableArray *_sortedByNameFavoriteItems;
    NSMutableArray *_sortedByDistFavoriteItems;
    
    NSMutableArray<OADestinationItem *> *_destinationItems;
}

#pragma mark - Initialization

- (instancetype)initWithDestinationType:(EOADestinationPointType)type
{
    self = [super init];
    if (self)
        _type = type;
    return self;
}

- (void)commonInit
{
    _sortingType = EOASortTypeByGroup;
    _decelerating = NO;
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:_type == EOADestinationPointTypeFavorite
                                                            ? @selector(updateDistanceAndDirectionFavorites)
                                                            : @selector(updateDistanceAndDirectionMarkers)
                                                 andObserve:[OsmAndApp instance].locationServices.updateLocationObserver]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:_type == EOADestinationPointTypeFavorite
                                                            ? @selector(updateDistanceAndDirectionFavorites)
                                                            : @selector(updateDistanceAndDirectionMarkers)
                                                 andObserve:[OsmAndApp instance].locationServices.updateHeadingObserver]];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_type == EOADestinationPointTypeFavorite)
        [self updateDistanceAndDirectionFavorites:YES];
    else
        [self updateDistanceAndDirectionMarkers:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _type == EOADestinationPointTypeFavorite ? OALocalizedString(@"select_favorite") : OALocalizedString(@"select_map_marker");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeGray;
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    if (_type != EOADestinationPointTypeMarker)
        return @[[self createRightNavbarButton:OALocalizedString(@"sort_by")
                                      iconName:nil
                                        action:@selector(onRightNavbarButtonPressed)
                                          menu:nil]];
    else
        return nil;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
    if (_type == EOADestinationPointTypeFavorite)
        [self generateFavoritesData];
    else
        [self generateMarkersData];
    
    [self.tableView reloadData];
}

- (void)generateFavoritesData
{
    _groupsAndFavorites = [[NSMutableArray alloc] init];
    _sortedByNameFavoriteItems = [[NSMutableArray alloc] init];
    _sortedByDistFavoriteItems = [[NSMutableArray alloc] init];

    for (OAFavoriteGroup *group in [OAFavoritesHelper getFavoriteGroups])
    {
        FavTableGroup *itemData = [[FavTableGroup alloc] init];
        itemData.groupName = [OAFavoriteGroup getDisplayName:group.name];
        for(OAFavoriteItem *point in group.points)
        {
            [itemData.groupItems addObject:point];
            [_sortedByNameFavoriteItems addObject:point];
            [_sortedByDistFavoriteItems addObject:point];
        }

        NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return [[obj1 getName].lowercaseString compare:[obj2 getName].lowercaseString];
        }];
        [itemData.groupItems setArray:sortedArrayItems];

        [_groupsAndFavorites addObject:itemData];
    }

    // Sort items
    NSArray *sortedArrayGroups = [_groupsAndFavorites sortedArrayUsingComparator:^NSComparisonResult(FavTableGroup* obj1, FavTableGroup* obj2) {
        return [[obj1.groupName lowercaseString] compare:[obj2.groupName lowercaseString]];
    }];
    [_groupsAndFavorites setArray:sortedArrayGroups];

    NSArray *sortedArray = [_sortedByDistFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    [_sortedByDistFavoriteItems setArray:sortedArray];

    sortedArray = [_sortedByNameFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return [[obj1 getName] compare:[obj2 getName]];
    }];
    [_sortedByNameFavoriteItems setArray:sortedArray];
}

- (void)generateMarkersData
{
    _destinationItems = [NSMutableArray array];
    for (OADestination *destination in [[OADestinationsHelper instance] sortedDestinationsWithoutParking])
    {
        OADestinationItem *item = [[OADestinationItem alloc] init];
        item.destination = destination;
        [_destinationItems addObject:item];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)sectionsCount
{
    if (_sortingType != EOASortTypeByGroup || _type == EOADestinationPointTypeMarker)
        return 1;
    
    return _groupsAndFavorites.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (_type == EOADestinationPointTypeMarker)
    {
        return OALocalizedString(@"map_markers");
    }
    else if (_sortingType == EOASortTypeByName)
    {
        return OALocalizedString(@"by_name");
    }
    else if (_sortingType == EOASortTypeByDistance)
    {
        return OALocalizedString(@"by_dist");
    }
    else
    {
        FavTableGroup *group = _groupsAndFavorites[section];
        return group.groupName;
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_type == EOADestinationPointTypeMarker)
        return _destinationItems.count;
    else if (_sortingType != EOASortTypeByGroup)
        return _sortedByNameFavoriteItems.count;
    
    return ((FavTableGroup*)[_groupsAndFavorites objectAtIndex:section]).groupItems.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    if (_type == EOADestinationPointTypeMarker)
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
            OADestinationItem* item = _destinationItems[indexPath.row];
            if (item)
            {
                NSString *title = item.destination.desc ? item.destination.desc : OALocalizedString(@"map_marker");
                NSString *imageName = [item.destination.markerResourceName ? item.destination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
                
                [cell.titleView setText:title];
                cell.titleIcon.image = [UIImage imageNamed:imageName];
                
                [cell.distanceView setText:item.distanceStr];
                cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
                cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
                cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            }
        }
        return cell;
    }
    else if (_sortingType != EOASortTypeByGroup)
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
            OAFavoriteItem* item = [self getSortedFavoriteItem:indexPath];
            [cell.titleView setText:item.favorite->getTitle().toNSString()];
            cell.titleIcon.image = item.getCompositeIcon;
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }
        return cell;
    }
    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];
    
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        cell.titleIcon.image = item.getCompositeIcon;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
    }
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_type == EOADestinationPointTypeMarker)
    {
        OADestinationItem* item = _destinationItems[indexPath.row];
        if (self.delegate)
            [self.delegate onDestinationSelected:item.destination];
    }
    else if (_sortingType == EOASortTypeByGroup)
    {
        FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        if (self.delegate)
            [self.delegate onFavoriteSelected:item];
    }
    else
    {
        OAFavoriteItem* item = [self getSortedFavoriteItem:indexPath];
        if (self.delegate)
            [self.delegate onFavoriteSelected:item];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Aditions

- (void)updateDistanceAndDirectionMarkers
{
    [self updateDistanceAndDirectionMarkers:NO];
}

- (void)updateDistanceAndDirectionMarkers:(BOOL)forceUpdate
{
    @synchronized(self)
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

        [_destinationItems enumerateObjectsUsingBlock:^(OADestinationItem* itemData, NSUInteger idx, BOOL *stop) {

            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                              newLocation.coordinate.latitude,
                                                              itemData.destination.longitude, itemData.destination.latitude);

            itemData.distance = distance;
            itemData.distanceStr = [OAOsmAndFormatter getFormattedDistance:distance];
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.destination.latitude longitude:itemData.destination.longitude]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

        }];

        if (_decelerating)
            return;

        [self refreshVisibleMarkers];
    }
}

- (void)updateDistanceAndDirectionFavorites
{
    [self updateDistanceAndDirectionFavorites:NO];
}

- (void)updateDistanceAndDirectionFavorites:(BOOL)forceUpdate
{
    @synchronized(self)
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

        [_sortedByDistFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
            const auto& favoritePosition31 = itemData.favorite->getPosition31();
            const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
            const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);

            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                              newLocation.coordinate.latitude,
                                                              favoriteLon, favoriteLat);



            itemData.distance = [OAOsmAndFormatter getFormattedDistance:distance];
            itemData.distanceMeters = distance;
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

        }];

        if ([_sortedByDistFavoriteItems count] > 0) {
            NSArray *sortedArray = [_sortedByDistFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
            }];
            [_sortedByDistFavoriteItems setArray:sortedArray];
        }

        if (_decelerating)
            return;

        [self refreshVisibleFavorites];
    }
}

- (OAFavoriteItem *)getSortedFavoriteItem:(NSIndexPath *)indexPath
{
    if (_sortingType == EOASortTypeByDistance)
    {
        return _sortedByDistFavoriteItems[indexPath.row];
    }
    else if (_sortingType == EOASortTypeByName)
    {
        return _sortedByNameFavoriteItems[indexPath.row];
    }
    return nil;
}

- (void)refreshVisibleMarkers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OADestinationItem* item = _destinationItems[i.row];
                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;
                    
                    NSString *title = item.destination.desc ? item.destination.desc : OALocalizedString(@"map_marker");
                    NSString *imageName = [item.destination.markerResourceName ? item.destination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
                    
                    [c.titleView setText:title];
                    c.titleIcon.image = [UIImage imageNamed:imageName];
                    
                    [c.distanceView setText:item.distanceStr];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [self.tableView endUpdates];
    });
}

- (void)refreshVisibleFavorites
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView beginUpdates];
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OAFavoriteItem* item;
                if (_sortingType != EOASortTypeByGroup)
                {
                    if (i.section == 0)
                        item = [self getSortedFavoriteItem:i];
                }
                else
                {
                    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:i.section];
                    item = [groupData.groupItems objectAtIndex:i.row];
                }
                
                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;
                    
                    [c.titleView setText:item.favorite->getTitle().toNSString()];
                    c.titleIcon.image = item.getCompositeIcon;
                    
                    [c.distanceView setText:item.distance];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [self.tableView endUpdates];
        
        //NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        //[_tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    });
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    if (_sortingType == EOASortTypeByGroup)
        _sortingType = EOASortTypeByName;
    else if (_sortingType == EOASortTypeByName)
        _sortingType = EOASortTypeByDistance;
    else if (_sortingType == EOASortTypeByDistance)
        _sortingType = EOASortTypeByGroup;
    
    [self.tableView reloadData];
}

#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _decelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        _decelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _decelerating = NO;
    //[self refreshVisibleRows];
}

@end
