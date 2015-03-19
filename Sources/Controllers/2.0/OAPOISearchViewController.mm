//
//  OAPOISearchViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOISearchViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIHelper.h"

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@interface OAPOISearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray* dataArray;
@property (nonatomic) NSString* searchString;
@property (nonatomic) NSString* poiTypeName;
@property (nonatomic) NSString* categoryName;

@end

@implementation OAPOISearchViewController {

    BOOL isDecelerating;

}

-(instancetype)initWithSearchString:(NSString *)searchString
{
    self = [self init];
    if (self) {
        self.searchString = searchString;
    }
    return self;
}

- (instancetype)initWithType:(NSString *)poiTypeName
{
    self = [self init];
    if (self) {
        self.poiTypeName = poiTypeName;
    }
    return self;
}

- (instancetype)initWithCategory:(NSString *)categoryName
{
    self = [self init];
    if (self) {
        self.categoryName = categoryName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    isDecelerating = NO;
}

- (void)updateDistanceAndDirection
{
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3)
        return;
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    [self.dataArray enumerateObjectsUsingBlock:^(OAPOI* itemData, NSUInteger idx, BOOL *stop) {
        
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                          newLocation.coordinate.latitude,
                                                          itemData.longitude, itemData.latitude);
        
        
        
        itemData.distance = [app getFormattedDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.latitude longitude:itemData.longitude]];
        itemData.direction = -(itemDirection + newDirection / 180.0f * M_PI);
        
    }];
    
    if ([self.dataArray count] > 0) {
        NSArray *sortedArray = [self.dataArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
            double distance1 = 0;
            double distance2 = 0;
            
            if ([obj1 isKindOfClass:[OAPOI class]])
                distance1 = ((OAPOI *)obj1).distanceMeters;
            if ([obj2 isKindOfClass:[OAPOI class]])
                distance2 = ((OAPOI *)obj2).distanceMeters;
            
            if (distance1 > 0 || distance2 > 0) {
                return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
            
            } else {
                
                NSString *name1 = @"";
                NSString *name2 = @"";
                
                if ([obj1 isKindOfClass:[OAPOIType class]])
                    name1 = [((OAPOIType *)obj1).nameLocalized lowercaseString];
                else if ([obj1 isKindOfClass:[OAPOICategory class]])
                    name1 = [((OAPOICategory *)obj1).nameLocalized lowercaseString];

                if ([obj2 isKindOfClass:[OAPOIType class]])
                    name2 = [((OAPOIType *)obj2).nameLocalized lowercaseString];
                else if ([obj2 isKindOfClass:[OAPOICategory class]])
                    name2 = [((OAPOICategory *)obj2).nameLocalized lowercaseString];

                return [name1 compare:name2];
            }
        }];
        [self.dataArray setArray:sortedArray];
    }
    
    if (isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (void)refreshVisibleRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}


-(void)viewWillAppear:(BOOL)animated {
    
    [self generateData];
    [self setupView];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
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

    self.dataArray = [[NSMutableArray alloc] init];
    
    if (self.searchString) {
        
    } else if (self.poiTypeName) {
        
    } else if (self.categoryName) {
        
        NSArray *sortedArrayItems = [[[OAPOIHelper sharedInstance] poiTypesForCategory:_categoryName] sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
            return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
        }];
        [_dataArray arrayByAddingObjectsFromArray:sortedArrayItems];

    } else {
        
        NSArray *sortedArrayItems = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
            return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
        }];
        [_dataArray arrayByAddingObjectsFromArray:sortedArrayItems];
    }
    
}

-(void)setupView {
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    /*
    if (indexPath.section == 0) {
        
        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
        
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            
            OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            [cell.titleView setText:item.favorite->getTitle().toNSString()];
            
            UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
            
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            cell.titleIcon.image = favCol.icon;
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }
        
        return cell;
        
    } else {
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            [cell.textView setText:[item objectForKey:@"text"]];
            [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
    }
     */
    return nil;
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

}

@end
