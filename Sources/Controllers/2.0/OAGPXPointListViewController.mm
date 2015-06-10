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
#import "OAGPXPointViewController.h"
#import "OAUtilities.h"
#import "OARootViewController.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


typedef enum
{
    EPointsSortingTypeGrouped = 0,
    EPointsSortingTypeDistance
    
} EPointsSortingType;

@interface OAGPXPointListViewController () {
    
    OsmAndAppInstance _app;
    BOOL isDecelerating;

    EPointsSortingType sortingType;
}

@property (strong, nonatomic) NSArray* sortedDistPoints;
@property (strong, nonatomic) NSDictionary* groupedPoints;
@property (strong, nonatomic) NSArray* unsortedPoints;
@property (strong, nonatomic) NSArray* groups;

@end

@implementation OAGPXPointListViewController

- (id)initWithLocationMarks:(NSArray *)locationMarks
{
    self = [super init];
    if (self)
    {
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

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"gpx_waypoints");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];

    [_favoritesButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.favoritesButtonView];
    [OAUtilities layoutComplexButton:self.gpxButtonView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isDecelerating = NO;
    
    sortingType = EPointsSortingTypeGrouped;
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
        const auto& wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
        const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);
        
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          wptLon, wptLat);
        
        itemData.distance = [_app getFormattedDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
        itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        
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

-(void)generateData
{

    NSMutableSet *groups = [NSMutableSet set];
    for (OAGpxWptItem *item in self.unsortedPoints)
        [groups addObject:(item.point.type ? item.point.type : @"")];
    
    NSMutableArray *groupsArray = [[[groups allObjects]
                                    sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2)
                                    {
                                        return [obj1 localizedCaseInsensitiveCompare:obj2];
                                    }] mutableCopy];
        
    NSArray *sortedArr = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem *obj1, OAGpxWptItem *obj2) {
        return [obj1.point.name localizedCaseInsensitiveCompare:obj2.point.name];
    }];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *group in groupsArray)
         [dict setObject:[NSMutableArray array] forKey:group];
    
    for (OAGpxWptItem *item in sortedArr)
    {
        NSString *group = item.point.type;
        NSMutableArray *arr;
        if (group.length > 0)
            arr = [dict objectForKey:group];
        else
            arr = [dict objectForKey:@""];

        [arr addObject:item];
    }
    
    if (((NSMutableArray *)[dict objectForKey:@""]).count == 0)
        [groupsArray removeObjectAtIndex:0];

    self.groups = [NSArray arrayWithArray:groupsArray];
    self.groupedPoints = [NSDictionary dictionaryWithDictionary:dict];
    
    // Sort items
    self.sortedDistPoints = [self.unsortedPoints sortedArrayUsingComparator:^NSComparisonResult(OAGpxWptItem* obj1, OAGpxWptItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    
    [self.tableView reloadData];
    
}

-(void)setupView
{
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)sortBtnClicked:(id)sender
{
    if (![self.tableView isEditing]) {
        
        switch (sortingType) {
            case EPointsSortingTypeGrouped:
                [self.sortButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
                sortingType = EPointsSortingTypeDistance;
                break;
            case EPointsSortingTypeDistance:
                [self.sortButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
                sortingType = EPointsSortingTypeGrouped;
                break;
                
            default:
                break;
        }
        
        [self generateData];
    }
}

- (IBAction)menuFavoriteClicked:(id)sender
{
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender
{
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (sortingType)
    {
        case EPointsSortingTypeGrouped:
            return self.groups.count;
            
        case EPointsSortingTypeDistance:
            return 1;
            
        default:
            return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (sortingType)
    {
        case EPointsSortingTypeGrouped:
        {
            NSString *group = self.groups[section];
            return (group.length == 0 ? OALocalizedString(@"fav_no_group") : group);
        }
        case EPointsSortingTypeDistance:
        {
            return [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"gpx_points"), self.unsortedPoints.count];
        }
            
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (sortingType)
    {
        case EPointsSortingTypeGrouped:
            return ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[section]]).count;
            
        case EPointsSortingTypeDistance:
            return self.unsortedPoints.count;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
        
    static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
    
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        
        OAGpxWptItem* item = [self getWptItem:indexPath];
        
        [cell.titleView setText:item.point.name];
        [cell.distanceView setText:item.distance];
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);

        if (!cell.titleIcon.hidden) {
            cell.titleIcon.hidden = YES;
            CGRect f = cell.titleView.frame;
            cell.titleView.frame = CGRectMake(f.origin.x - 23.0, f.origin.y, f.size.width + 23.0, f.size.height);
            cell.directionImageView.frame = CGRectMake(cell.directionImageView.frame.origin.x - 23.0, cell.directionImageView.frame.origin.y, cell.directionImageView.frame.size.width, cell.directionImageView.frame.size.height);
            cell.distanceView.frame = CGRectMake(cell.distanceView.frame.origin.x - 23.0, cell.distanceView.frame.origin.y, cell.distanceView.frame.size.width, cell.distanceView.frame.size.height);
        }
    }
    
    return cell;
    
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

-(OAGpxWptItem *)getWptItem:(NSIndexPath *)indexPath
{
    OAGpxWptItem* item;
    switch (sortingType) {
        case EPointsSortingTypeGrouped:
            item = ((NSMutableArray *)[self.groupedPoints objectForKey:self.groups[indexPath.section]])[indexPath.row];
            break;
        case EPointsSortingTypeDistance:
            item = [self.sortedDistPoints objectAtIndex:indexPath.row];
            break;
            
        default:
            break;
    }
    return item;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxWptItem* item = [self getWptItem:indexPath];
    [self.navigationController pushViewController:[OARootViewController instance].mapPanel animated:YES];
    [[OARootViewController instance].mapPanel openTargetViewWithWpt:item pushed:YES];
}



@end