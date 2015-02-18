//
//  OAGPXPointListViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXPointListViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAGPXListViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


typedef enum
{
    EPointsSortingTypeNone = 0,
    EPointsSortingTypeAB,
    EPointsSortingTypeDistance
    
} EPointsSortingType;

@interface OAGPXPointListViewController () {
    
    OsmAndAppInstance _app;
    BOOL isDecelerating;

    EPointsSortingType sortingType;
}

@property (strong, nonatomic) NSArray* sortedABPoints;
@property (strong, nonatomic) NSArray* sortedDistPoints;
@property (strong, nonatomic) NSArray* unsortedPoints;

@end

@implementation OAGPXPointListViewController


- (id)initWithLocationMarks:(NSArray *)locationMarks
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        NSMutableArray *arr = [NSMutableArray array];
        for (OAGpxWpt *p in locationMarks) {
            OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
            item.point = p;
            [arr addObject:item];
        }
        self.unsortedPoints = arr;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isDecelerating = NO;
    
    sortingType = EPointsSortingTypeNone;
}

- (void)updateDistanceAndDirection
{
    if ([self.tableView isEditing])
        return;
    
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3)
        return;
    
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    // Obtain fresh location and heading
    CLLocation* newLocation = _app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f) ? newLocation.course : newHeading;
    
    [self.unsortedPoints enumerateObjectsUsingBlock:^(OAGpxWptItem* itemData, NSUInteger idx, BOOL *stop) {
        OsmAnd::LatLon latLon(itemData.point.position.latitude, itemData.point.position.longitude);
        const auto& favoritePosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
        const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
        
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          favoriteLon, favoriteLat);
        
        itemData.distance = [_app.locationFormatter stringFromDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
        itemData.direction = -(itemDirection + newDirection / 180.0f * M_PI);
        
    }];
    
    if (sortingType == EPointsSortingTypeDistance && [self.unsortedPoints count] > 0) {
        self.sortedDistPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
            return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
        }];
    }
    
    if (isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (void)refreshVisibleRows
{
    if ([self.tableView isEditing])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
    });
}

-(void)viewWillAppear:(BOOL)animated {
    
    [self generateData];
    [self setupView];
    
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:_app.locationServices.updateObserver];
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
    
}

-(void)generateData {
    
    // Sort items
    self.sortedABPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
        return [[obj1.point.name lowercaseString] compare:[obj2.point.name lowercaseString]];
    }];
    
    self.sortedDistPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    
    [self.tableView reloadData];
    
}

-(void)setupView {
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)sortBtnClicked:(id)sender
{
    if (![self.tableView isEditing]) {
        
        switch (sortingType) {
            case EPointsSortingTypeNone:
                [self.sortButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
                sortingType = EPointsSortingTypeAB;
                break;
            case EPointsSortingTypeAB:
                [self.sortButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
                sortingType = EPointsSortingTypeDistance;
                break;
            case EPointsSortingTypeDistance:
                [self.sortButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
                sortingType = EPointsSortingTypeNone;
                break;
                
            default:
                break;
        }
        
        [self generateData];
    }
}

- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Points: %d", self.unsortedPoints.count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.unsortedPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
    static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
    
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        
        OAGpxWptItem* item;
        switch (sortingType) {
            case EPointsSortingTypeNone:
                item = [self.unsortedPoints objectAtIndex:indexPath.row];
                break;
            case EPointsSortingTypeAB:
                item = [self.sortedABPoints objectAtIndex:indexPath.row];
                break;
            case EPointsSortingTypeDistance:
                item = [self.sortedDistPoints objectAtIndex:indexPath.row];
                break;
                
            default:
                break;
        }
        
        [cell.titleView setText:item.point.name];
        [cell.distanceView setText:item.distance];
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);

        if (!cell.colorView.hidden) {
            cell.colorView.hidden = YES;
            CGRect f = cell.titleView.frame;
            cell.titleView.frame = CGRectMake(f.origin.x - 23.0, f.origin.y, f.size.width + 23.0, f.size.height);
            cell.directionImageView.frame = CGRectMake(cell.directionImageView.frame.origin.x - 23.0, cell.directionImageView.frame.origin.y, cell.directionImageView.frame.size.width, cell.directionImageView.frame.size.height);
            cell.distanceView.frame = CGRectMake(cell.distanceView.frame.origin.x - 23.0, cell.distanceView.frame.origin.y, cell.distanceView.frame.size.width, cell.distanceView.frame.size.height);
        }

        
        /*
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r green:item.favorite->getColor().g blue:item.favorite->getColor().b alpha:1];
        [cell.colorView setBackgroundColor:color];
        
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red > 0.95 && green > 0.95 && blue > 0.95) {
            cell.colorView.layer.borderColor = [[UIColor blackColor] CGColor];
            cell.colorView.layer.borderWidth = 0.8;
        }
        */
        
    }
    
    return cell;
    
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
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
    if (!decelerate) {
        isDecelerating = NO;
        [self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    [self refreshVisibleRows];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
    OAFavoriteItemViewController* controller = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
    [self.navigationController pushViewController:controller animated:YES];
     */
}



@end