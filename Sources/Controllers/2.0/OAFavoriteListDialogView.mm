//
//  OAFavoriteListDialogView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAFavoriteListDialogView.h"
#import "OAPointTableViewCell.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


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


@interface OAFavoriteListDialogView () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation OAFavoriteListDialogView
{
    NSMutableArray *_groupsAndFavorites;
    NSMutableArray *_sortedFavoriteItems;
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

- (instancetype) initWithFrame:(CGRect)frame sortingType:(int)sortingType
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
            
            _sortingType = sortingType;
            [self commonInit];
        }
    }
    return self;
}

- (void) commonInit
{
    _isDecelerating = NO;
    _tableView.contentInset = UIEdgeInsetsMake(-16, 0, -22, 0);
    
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
    f.size.height = _tableView.contentSize.height - 38;
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
    
    [_sortedFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
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
    
    if (_sortingType == 1 && [_sortedFavoriteItems count] > 0) {
        NSArray *sortedArray = [_sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
        }];
        [_sortedFavoriteItems setArray:sortedArray];
    }
    
    if (_isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (void)refreshVisibleRows
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
                if (_sortingType == 1)
                {
                    if (i.section == 0)
                        item = [_sortedFavoriteItems objectAtIndex:i.row];
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

- (void) generateData
{
    OsmAndAppInstance app = [OsmAndApp instance];
    _groupsAndFavorites = [[NSMutableArray alloc] init];
    _sortedFavoriteItems = [[NSMutableArray alloc] init];
    
    NSMutableArray *headerViews = [NSMutableArray array];
    
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
                OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
                favData.favorite = favorite;
                [itemData.groupItems addObject:favData];
                [_sortedFavoriteItems addObject:favData];
            }
            
            if (_sortingType == 0) { // Alphabetic
                NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                    return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
                }];
                [itemData.groupItems setArray:sortedArrayItems];
            }
            
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
            OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
            favData.favorite = favorite;
            [itemData.groupItems addObject:favData];
            [_sortedFavoriteItems addObject:favData];
        }
        
        if (_sortingType == 0) { // Alphabetic
            NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
            }];
            [itemData.groupItems setArray:sortedArrayItems];
        }
        
        [_groupsAndFavorites insertObject:itemData atIndex:0];
    }
    
    NSArray *sortedArray = [_sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    [_sortedFavoriteItems setArray:sortedArray];
    
    [_tableView reloadData];
}

- (void) setupView
{
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [_tableView reloadData];
}

- (void) switchSorting
{
    _sortingType = 1 - _sortingType;
    [self generateData];
    [self updateDistanceAndDirection:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_sortingType == 1)
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
    if (_sortingType == 1)
    {
        return OALocalizedString(@"favorites");
    }
    else
    {
        FavTableGroup *group = _groupsAndFavorites[section];
        return group.groupName;
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_sortingType == 1)
        return [self getSortedNumberOfRowsInSection:section];
    
    return [self getUnsortedNumberOfRowsInSection:section];
}

- (NSInteger) getSortedNumberOfRowsInSection:(NSInteger)section
{
    return _sortedFavoriteItems.count;
}

- (NSInteger) getUnsortedNumberOfRowsInSection:(NSInteger)section
{
    return ((FavTableGroup*)[_groupsAndFavorites objectAtIndex:section]).groupItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_sortingType == 1)
        return [self getSortedcellForRowAtIndexPath:indexPath];
    
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) getSortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
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
        OAFavoriteItem* item = [_sortedFavoriteItems objectAtIndex:indexPath.row];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
        
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        cell.titleIcon.image = favCol.icon;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
    }
    
    return cell;
}


- (UITableViewCell*) getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];
    
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
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
        
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        cell.titleIcon.image = favCol.icon;
        
        [cell.distanceView setText:item.distance];
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

    if (_sortingType == 1)
        [self didSelectRowAtIndexPathSorter:indexPath];
    else
        [self didSelectRowAtIndexPathUnsorter:indexPath];
}

- (void) didSelectRowAtIndexPathSorter:(NSIndexPath *)indexPath
{
    OAFavoriteItem* item = [_sortedFavoriteItems objectAtIndex:indexPath.row];
    if (self.delegate)
        [self.delegate onFavoriteSelected:item];
}

- (void) didSelectRowAtIndexPathUnsorter:(NSIndexPath *)indexPath
{
    FavTableGroup* groupData = [_groupsAndFavorites objectAtIndex:indexPath.section];
    OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
    if (self.delegate)
        [self.delegate onFavoriteSelected:item];
}

@end
