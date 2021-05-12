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
#import "OAPointTableViewCell.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "OADestinationItem.h"
#import "OADestinationsHelper.h"

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

-(id) init
{
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OADestinationItemsListViewController ()

@end

@implementation OADestinationItemsListViewController
{
    EOADestinationPointType _type;
    EOASortType _sortingType;
    NSTimeInterval _lastUpdate;
    BOOL _isDecelerating;
    
    NSMutableArray *_groupsAndFavorites;
    NSMutableArray *_sortedByNameFavoriteItems;
    NSMutableArray *_sortedByDistFavoriteItems;
    
    NSMutableArray<OADestinationItem *> *_destinationItems;
}

- (instancetype) initWithDestinationType:(EOADestinationPointType)type
{
    self = [super init];
    if (self) {
        _type = type;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _sortingType = EOASortTypeByGroup;
    _isDecelerating = NO;
    
    [self generateData];
    [self setupView];
    if (_type == EOADestinationPointTypeFavorite)
        [self updateDistanceAndDirectionFavorites:YES];
    else
        [self updateDistanceAndDirectionMarkers:YES];
}


-(void) applyLocalization
{
    _titleView.text = _type == EOADestinationPointTypeFavorite ? OALocalizedString(@"select_favorite") : OALocalizedString(@"select_map_marker");
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_sortButton setTitle:OALocalizedString(@"sort_by") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.sortButton.hidden = _type == EOADestinationPointTypeMarker;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void)generateFavoritesData
{
    OsmAndAppInstance app = [OsmAndApp instance];
    _groupsAndFavorites = [[NSMutableArray alloc] init];
    _sortedByNameFavoriteItems = [[NSMutableArray alloc] init];
    _sortedByDistFavoriteItems = [[NSMutableArray alloc] init];
    
    const auto allFavorites = app.favoritesCollection->getFavoriteLocations();
    QHash< QString, QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > > groupedFavorites;
    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > ungroupedFavorites;
    QSet<QString> groupNames;
    
    // create favorite groups
    for(const auto& favorite : allFavorites)
    {
        const auto& groupName = favorite->getGroup();
        if (groupName.isEmpty())
            ungroupedFavorites.push_back(favorite);
        else
        {
            groupNames.insert(groupName);
            groupedFavorites[groupName].push_back(favorite);
        }
    }
    
    // Generate groups array
    if (!groupNames.isEmpty())
    {
        for (const auto& groupName : groupNames)
        {
            FavTableGroup* itemData = [[FavTableGroup alloc] init];
            itemData.groupName = groupName.toNSString();
            for(const auto& favorite : groupedFavorites[groupName]) {
                OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
                [itemData.groupItems addObject:favData];
                [_sortedByNameFavoriteItems addObject:favData];
                [_sortedByDistFavoriteItems addObject:favData];
            }
            
            
            NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
            }];
            [itemData.groupItems setArray:sortedArrayItems];
            
            
            [_groupsAndFavorites addObject:itemData];
        }
    }
    
    // Sort items
    NSArray *sortedArrayGroups = [_groupsAndFavorites sortedArrayUsingComparator:^NSComparisonResult(FavTableGroup* obj1, FavTableGroup* obj2) {
        return [[obj1.groupName lowercaseString] compare:[obj2.groupName lowercaseString]];
    }];
    [_groupsAndFavorites setArray:sortedArrayGroups];
    
    // Generate ungrouped array
    if (!ungroupedFavorites.isEmpty())
    {
        FavTableGroup* itemData = [[FavTableGroup alloc] init];
        itemData.groupName = OALocalizedString(@"favorites");
        
        for (const auto& favorite : ungroupedFavorites)
        {
            OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
            [itemData.groupItems addObject:favData];
            [_sortedByNameFavoriteItems addObject:favData];
            [_sortedByDistFavoriteItems addObject:favData];
        }
        
        
        NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
        }];
        [itemData.groupItems setArray:sortedArrayItems];
        
        [_groupsAndFavorites insertObject:itemData atIndex:0];
    }
    
    NSArray *sortedArray = [_sortedByDistFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    [_sortedByDistFavoriteItems setArray:sortedArray];
    
    sortedArray = [_sortedByNameFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return [obj1.favorite->getTitle().toNSString() compare:obj2.favorite->getTitle().toNSString()];
    }];
    [_sortedByNameFavoriteItems setArray:sortedArray];
}

- (void) generateMarkersData
{
    _destinationItems = [NSMutableArray array];
    for (OADestination *destination in [[OADestinationsHelper instance] sortedDestinationsWithoutParking])
    {
        OADestinationItem *item = [[OADestinationItem alloc] init];
        item.destination = destination;
        [_destinationItems addObject:item];
    }
    
    [_tableView reloadData];
}

- (void) generateData
{
    if (_type == EOADestinationPointTypeFavorite)
        [self generateFavoritesData];
    else
        [self generateMarkersData];
    
    [_tableView reloadData];
}

- (void)updateDistanceAndDirectionMarkers:(BOOL)forceUpdate
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
        itemData.distanceStr = [app getFormattedDistance:distance];
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.destination.latitude longitude:itemData.destination.longitude]];
        itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
    }];
    
    if (_isDecelerating)
        return;
    
    [self refreshVisibleMarkers];
}

- (void)updateDistanceAndDirectionFavorites:(BOOL)forceUpdate
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
        
        
        
        itemData.distance = [app getFormattedDistance:distance];
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
    
    if (_isDecelerating)
        return;
    
    [self refreshVisibleFavorites];
}

- (OAFavoriteItem *) getSortedFavoriteItem:(NSIndexPath *)indexPath
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

- (void) refreshVisibleMarkers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_tableView beginUpdates];
        NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [_tableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OADestinationItem* item = _destinationItems[i.row];
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

- (void)refreshVisibleFavorites
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_tableView beginUpdates];
        NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [_tableView cellForRowAtIndexPath:i];
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
                    UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
                    
                    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
                    c.titleIcon.image = favCol.icon;
                    c.titleIcon.tintColor = favCol.color;
                    
                    [c.distanceView setText:item.distance];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [_tableView endUpdates];
        
        //NSArray *visibleIndexPaths = [_tableView indexPathsForVisibleRows];
        //[_tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
    });
}

- (void) setupView
{
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [_tableView reloadData];
}

- (void)backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sortButtonPressed:(id)sender
{
    if (_sortingType == EOASortTypeByGroup)
        _sortingType = EOASortTypeByName;
    else if (_sortingType == EOASortTypeByName)
        _sortingType = EOASortTypeByDistance;
    else if (_sortingType == EOASortTypeByDistance)
        _sortingType = EOASortTypeByGroup;
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_sortingType != EOASortTypeByGroup || _type == EOADestinationPointTypeMarker)
        return [self getSortedNumberOfSectionsInTableView];
    
    return [self getUnsortedNumberOfSectionsInTableView];
}

- (NSInteger) getSortedNumberOfSectionsInTableView
{
    return 1;
}

- (NSInteger) getUnsortedNumberOfSectionsInTableView
{
    return _groupsAndFavorites.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_type == EOADestinationPointTypeMarker)
        return _destinationItems.count;
    else if (_sortingType != EOASortTypeByGroup)
        return [self getSortedNumberOfRowsInSection:section];
    
    return [self getUnsortedNumberOfRowsInSection:section];
}

- (NSInteger) getSortedNumberOfRowsInSection:(NSInteger)section
{
    return _sortedByNameFavoriteItems.count;
}

- (NSInteger) getUnsortedNumberOfRowsInSection:(NSInteger)section
{
    return ((FavTableGroup*)[_groupsAndFavorites objectAtIndex:section]).groupItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_type == EOADestinationPointTypeMarker)
        return [self getMarkerCellForIndexPath:indexPath];
    else if (_sortingType != EOASortTypeByGroup)
        return [self getSortedcellForRowAtIndexPath:indexPath];
    
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *) getMarkerCellForIndexPath:(NSIndexPath *)indexPath
{
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
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
            NSString *title = item.destination.desc ? item.destination.desc : OALocalizedString(@"ctx_mnu_direction");
            NSString *imageName = [item.destination.markerResourceName ? item.destination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
            
            [cell.titleView setText:title];
            cell.titleIcon.image = [UIImage imageNamed:imageName];
            
            [cell.distanceView setText:item.distanceStr];
            cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }
    }
    
    return cell;
}

- (UITableViewCell*) getSortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAFavoriteItem* item = [self getSortedFavoriteItem:indexPath];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
        
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        cell.titleIcon.image = favCol.cellIcon;
        cell.titleIcon.tintColor = favCol.color;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
    }
    
    return cell;
}


- (UITableViewCell*) getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];

    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
        
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        cell.titleIcon.image = favCol.cellIcon;
        cell.titleIcon.tintColor = favCol.color;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
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

    if (_type == EOADestinationPointTypeMarker)
    {
        OADestinationItem* item = _destinationItems[indexPath.row];
        if (self.delegate)
            [self.delegate onDestinationSelected:item.destination];
    }
    else if (_sortingType == EOASortTypeByGroup)
    {
        [self didSelectRowAtIndexPathUnsorted:indexPath];
    }
    else
    {
        [self didSelectRowAtIndexPathSorted:indexPath];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) didSelectRowAtIndexPathSorted:(NSIndexPath *)indexPath
{
    OAFavoriteItem* item = [self getSortedFavoriteItem:indexPath];
    if (self.delegate)
        [self.delegate onFavoriteSelected:item];
}

- (void) didSelectRowAtIndexPathUnsorted:(NSIndexPath *)indexPath
{
    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];
    OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
    if (self.delegate)
        [self.delegate onFavoriteSelected:item];
}

@end
