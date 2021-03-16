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

#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define kPointCell @"OAPointTableViewCell"
#define kCellTypeSegment @"OASegmentTableViewCell"

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
    EOASortingMode _sortingMode;
    OAAutoObserverProxy* _locationServicesUpdateObserver;
    NSTimeInterval _lastUpdateTime;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _allFavorites = [OAFavoritesHelper getFavoriteItems];
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
    NSMutableArray *favoritesSection = [NSMutableArray new];

    [favoritesSection addObject:@{
        @"type" : kCellTypeSegment,
        @"title0" : OALocalizedString(@"by_dist"),
        @"title1" : OALocalizedString(@"shared_a_z"),
        @"title2" : OALocalizedString(@"shared_z_a"),
        @"key" : @"segment_control"
    }];
    
    NSArray *sortedFavorites = [self sortData:_allFavorites];
    for (OAFavoriteItem *favorite in sortedFavorites)
    {
        NSString *name = [favorite getFavoriteName];
        NSString *distance = favorite.distance;
        
        [favoritesSection addObject:@{
                @"type" : kPointCell,
                @"title" : name ? name : @"",
                @"distance" : distance ? distance : @"",
                @"direction" : [NSNumber numberWithFloat:favorite.direction],
                @"favoriteItem" : favorite,
            }];
    }
    
    [data addObject:favoritesSection];
    _data = data;
}

- (NSArray<OAFavoriteItem *> *) sortData:(NSArray<OAFavoriteItem *> *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        switch (_sortingMode) {
            case EOADistance:
            {
                NSNumber *distance1 = [NSNumber numberWithDouble:obj1.distanceMeters];
                NSNumber *distance2 = [NSNumber numberWithDouble:obj2.distanceMeters];
                return [distance1 compare:distance2];
            }
            case EOANameAscending:
            {
                NSString *title1 = [obj1 getFavoriteName];
                NSString *title2 = [obj2 getFavoriteName];
                return [title1 compare:title2 options:NSCaseInsensitiveSearch];
            }
            case EOANameDescending:
            {
                NSString *title1 = [obj1 getFavoriteName];
                NSString *title2 = [obj2 getFavoriteName];
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
        
        [_allFavorites enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
            const auto& favoritePosition31 = itemData.favorite->getPosition31();
            const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
            const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
                
            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                                newLocation.coordinate.latitude,
                                                                favoriteLon, favoriteLat);
            
            itemData.distance = [_app getFormattedDistance:distance];
            itemData.distanceMeters = distance;
            CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
         }];
        
        [self generateData];
        [self.tableView reloadData];
    });
}

#pragma mark - TableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kCellTypeSegment])
    {
        static NSString* const identifierCell = @"OASegmentTableViewCell";
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASegmentTableViewCell" owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
            [cell.segmentControl insertSegmentWithTitle:item[@"title2"] atIndex:2 animated:NO];
        }
        if (cell)
        {
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
        }
        return cell;
    }
    else if ([type isEqualToString:kPointCell])
    {
        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";

        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSDictionary* item = _data[indexPath.section][indexPath.row];
            OAFavoriteItem *favorite = item[@"favoriteItem"];

            [cell.titleView setText:item[@"title"]];
            cell = [self setupPoiIconForCell:cell withFavaoriteItem:favorite];
            
            [cell.distanceView setText:item[@"distance"]];
            cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation([item[@"direction"] floatValue]);
            cell.separatorInset = UIEdgeInsetsZero;
        }
        return cell;
    }
    
    return nil;
}

- (OAPointTableViewCell *) setupPoiIconForCell:(OAPointTableViewCell *)cell withFavaoriteItem:(OAFavoriteItem*)item
{
    [item getFavoriteColor];
    UIColor* color = [item getFavoriteColor];;
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
    
    NSString *backgroundName = [item getFavoriteBackground];
    if(!backgroundName || backgroundName.length == 0)
        backgroundName = @"circle";
    backgroundName = [NSString stringWithFormat:@"bg_point_%@", backgroundName];
    UIImage *backroundImage = [UIImage imageNamed:backgroundName];
    cell.titleIcon.image = [backroundImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.titleIcon.tintColor = favCol.color;
    
    NSString *iconName = [item getFavoriteIcon];
    if(!iconName || iconName.length == 0)
        iconName = @"special_star";
    iconName = [NSString stringWithFormat:@"mm_%@", iconName];
    UIImage *poiImage = [UIImage imageNamed:[OAUtilities drawablePath:iconName]];
    cell.titlePoiIcon.image = [poiImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.titlePoiIcon.tintColor = UIColor.whiteColor;
    cell.titlePoiIcon.hidden = NO;
    
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
    OAFavoriteItem *favorite = item[@"favoriteItem"];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate onReplaced:favorite];
    }];
}

@end
