//
//  OAFavoriteListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAFavoriteItemViewController.h"
#import "OAFavoriteItem.h"
#import "OAMapViewController.h"
#import "OAGPXListViewController.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define _(name) OAFavoriteListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4
typedef enum
{
    kFavoriteCellTypeGrouped = 0,
    kFavoriteCellTypeUngrouped,
    kFavoriteCellTypeMenu
}
kFavoriteCellType;

#define FavoriteTableGroup _(FavoriteTableGroup)
@interface FavoriteTableGroup : NSObject
    @property int type;
    @property NSString* groupName;
    @property NSMutableArray*  groupItems;
@end
@implementation FavoriteTableGroup

-(id) init {
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAFavoriteListViewController () {
    
    BOOL isDecelerating;
}

    @property (strong, nonatomic) NSMutableArray* groupsAndFavorites;
    @property (strong, nonatomic) NSArray*  menuItems;
    @property (strong, nonatomic) UIDocumentInteractionController* exportController;
    @property (strong, nonatomic) NSMutableArray*  sortedFavoriteItems;
    @property NSUInteger sortingType;
@end

@implementation OAFavoriteListViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    isDecelerating = NO;

    self.sortingType = 0;
    OsmAndAppInstance app = [OsmAndApp instance];

    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void)updateDistanceAndDirection
{
    if ([self.favoriteTableView isEditing])
        return;

    
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
    
    [self.sortedFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
        const auto& favoritePosition31 = itemData.favorite->getPosition31();
        const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
        const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
            
        const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                            newLocation.coordinate.latitude,
                                                            favoriteLon, favoriteLat);
        

        
        itemData.distance = [app.locationFormatter stringFromDistance:distance];
        itemData.distanceMeters = distance;
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
        itemData.direction = -(itemDirection + newDirection / 180.0f * M_PI);
        
     }];
    
    if (self.sortingType == 1 && [self.sortedFavoriteItems count] > 0) {
        NSArray *sortedArray = [self.sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
        }];
        [self.sortedFavoriteItems setArray:sortedArray];
    }

    if (isDecelerating)
        return;
    
    [self refreshVisibleRows];
}

- (void)refreshVisibleRows
{
    if ([self.favoriteTableView isEditing])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *visibleIndexPaths = [self.favoriteTableView indexPathsForVisibleRows];
        [self.favoriteTableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
        //[self.favoriteTableView reloadData];
        
    });
}

-(void)viewWillAppear:(BOOL)animated {
    
    [self generateData];
    [self setupView];
    
    [super viewWillAppear:animated];
}

-(void)generateData {
    OsmAndAppInstance app = [OsmAndApp instance];
    self.groupsAndFavorites = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];
    self.sortedFavoriteItems = [[NSMutableArray alloc] init];
    
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
            FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
            itemData.groupName = groupName.toNSString();
            itemData.type = kFavoriteCellTypeGrouped;
            for(const auto& favorite : groupedFavorites[groupName]) {
                OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
                favData.favorite = favorite;
                [itemData.groupItems addObject:favData];
                [self.sortedFavoriteItems addObject:favData];
            }
            
            if (self.sortingType == 0) { // Alphabetic
                NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                    return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
                }];
                [itemData.groupItems setArray:sortedArrayItems];
            }
            
            [self.groupsAndFavorites addObject:itemData];
        }
    }
    
    // Sort items
    NSArray *sortedArrayGroups = [self.groupsAndFavorites sortedArrayUsingComparator:^NSComparisonResult(FavoriteTableGroup* obj1, FavoriteTableGroup* obj2) {
        return [[obj1.groupName lowercaseString] compare:[obj2.groupName lowercaseString]];
    }];
    [self.groupsAndFavorites setArray:sortedArrayGroups];
    
    // Generate ungrouped array
    if (!ungroupedFavorites.isEmpty())
    {
        FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
        itemData.groupName = @"Favorites";
        itemData.type = kFavoriteCellTypeUngrouped;
        
        for (const auto& favorite : ungroupedFavorites)
        {
            OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
            favData.favorite = favorite;
            [itemData.groupItems addObject:favData];
            [self.sortedFavoriteItems addObject:favData];
        }
        
        if (self.sortingType == 0) { // Alphabetic
            NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
                return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
            }];
            [itemData.groupItems setArray:sortedArrayItems];
        }
        
        [self.groupsAndFavorites insertObject:itemData atIndex:0];
    }
    
    NSArray *sortedArray = [self.sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    [self.sortedFavoriteItems setArray:sortedArray];

    
    // Generate menu items
    FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
    itemData.groupName = @"Import/Export";
    itemData.type = kFavoriteCellTypeMenu;
    self.menuItems = @[@{@"text": @"Import favorites",
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"},
                       @{@"text": @"Export favorites",
                         @"icon": @"favorite_export_icon.png",
                         @"action": @"onExportClicked"}];
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:self.menuItems];
    [self.groupsAndFavorites addObject:itemData];
    
    [self.favoriteTableView reloadData];

}

-(void)setupView {
    
    [self.favoriteTableView setDataSource:self];
    [self.favoriteTableView setDelegate:self];
    self.favoriteTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.favoriteTableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)sortByDistance:(id)sender {
    if (![self.favoriteTableView isEditing]) {
        if (self.directionButton.tag == 0) {
            self.directionButton.tag = 1;
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
            self.sortingType = 1;
        } else {
            self.directionButton.tag = 0;
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
            self.sortingType = 0;
        }
        [self generateData];
    } else {
        
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        if ([selectedRows count] == 0) {
            UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select favorites to remove" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:nil];
            [removeAlert show];
            return;
        }
        
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Remove selected favorite items?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        removeAlert.tag = kAlertViewRemoveId;
        [removeAlert show];
        
    }
}

-(NSArray*)getItemsForRows:(NSArray*)indexPath {
    NSMutableArray* itemList = [[NSMutableArray alloc] init];
    if (self.directionButton.tag == 1) { // Sorted
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
            [itemList addObject:[self.sortedFavoriteItems objectAtIndex:path.row]];
        }];
    } else {
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
            FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:path.section];
            [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
        }];
    }
    return itemList;
}

- (IBAction)editButtonClicked:(id)sender {
    [self.favoriteTableView setEditing:![self.favoriteTableView isEditing] animated:YES];
    
    if ([self.favoriteTableView isEditing]) {
        [self.editButton setImage:[UIImage imageNamed:@"icon_edit_active"] forState:UIControlStateNormal];
        [self.backButton setHidden:YES];
        [self.shareButton setHidden:NO];
        [self.directionButton setImage:[UIImage imageNamed:@"icon_remove"] forState:UIControlStateNormal];
    }
    else {
        [self.editButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];

        [self.backButton setHidden:NO];
        [self.shareButton setHidden:YES];

        if (self.directionButton.tag == 1)
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
        else
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
    
    }
    
    //[self.favoriteTableView reloadData];
}

- (IBAction)shareButtonClicked:(id)sender {
    // Share selected favorites
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select favorites to export" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:nil];
        [removeAlert show];
        return;
    }

    NSArray* selectedItems = [self getItemsForRows:selectedRows];
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> exportCollection(new OsmAnd::FavoriteLocationsGpxCollection());
    [selectedItems enumerateObjectsUsingBlock:^(OAFavoriteItem* obj, NSUInteger idx, BOOL *stop) {
        exportCollection->copyFavoriteLocation(obj.favorite);
    }];

    if (exportCollection->getFavoriteLocationsCount() == 0)
        return;
        
    NSString* filename = [OALocalizedString(@"Exported favorites") stringByAppendingString:@".gpx"];
    NSString* fullFilename = [NSTemporaryDirectory() stringByAppendingString:filename];
    if (!exportCollection->saveTo(QString::fromNSString(fullFilename)))
        return;
        
    NSURL* favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = filename;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
    
    [self editButtonClicked:nil];
    [self generateData];

    
}

- (IBAction)menuFavoriteClicked:(id)sender {
}

- (IBAction)menuGPXClicked:(id)sender {
    OAGPXListViewController* favController = [[OAGPXListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)goRootScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)onImportClicked {
    NSString* favoritesImportText = OALocalizedString(@"You can import your favorites as waypoints in GPX file (standard format for storing map information supported by PC, iOS, Android)\n\nTo share the favorites.gpx file you can open file from Dropbox, Email, or any other source - Use Open In function.");
    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [importHelpAlert show];
}

-(void)onExportClicked {
    OsmAndAppInstance app = [OsmAndApp instance];
    // Share all favorites
    NSURL* favoritesUrl = [NSURL fileURLWithPath:app.favoritesStorageFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = OALocalizedString(@"OsmAnd Favorites.gpx");
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    OsmAndAppInstance app = [OsmAndApp instance];
    if (alertView.tag == kAlertViewRemoveId) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            
            NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
            NSArray* selectedItems = [self getItemsForRows:selectedRows];
            [selectedItems enumerateObjectsUsingBlock:^(OAFavoriteItem* obj, NSUInteger idx, BOOL *stop) {
                app.favoritesCollection->removeFavoriteLocation(obj.favorite);
            }];
            [app saveFavoritesToPermamentStorage];
            [self editButtonClicked:nil];
            [self generateData];
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.directionButton.tag == 1)
        return [self getSortedNumberOfSectionsInTableView];
    return [self getUnsortedNumberOfSectionsInTableView];
}

-(NSInteger)getSortedNumberOfSectionsInTableView {
    return 2;
}

-(NSInteger)getUnsortedNumberOfSectionsInTableView {
    return [self.groupsAndFavorites count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.directionButton.tag == 1)
        return [self getSortedTitleForHeaderInSection:section];
    return [self getUnsortedTitleForHeaderInSection:section];
}

-(NSString*)getSortedTitleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Favorites";
    return @"Import/Export";
}

-(NSString*)getUnsortedTitleForHeaderInSection:(NSInteger)section {
    return ((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupName;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.directionButton.tag == 1)
        return [self getSortedNumberOfRowsInSection:section];
    return [self getUnsortedNumberOfRowsInSection:section];
}

-(NSInteger)getSortedNumberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.sortedFavoriteItems count];
    return [self.menuItems count];
}

-(NSInteger)getUnsortedNumberOfRowsInSection:(NSInteger)section {
    return [((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.directionButton.tag == 1)
        return [self getSortedcellForRowAtIndexPath:indexPath];
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

-(UITableViewCell*)getSortedcellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            /*
            if ([self.favoriteTableView isEditing])
                [cell.cellViewContant setConstant:40];
            else
                [cell.cellViewContant setConstant:0];
             */
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
}


- (UITableViewCell*)getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {

        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
        
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell) {
            
            OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
            [cell.titleView setText:item.favorite->getTitle().toNSString()];
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
            } else {
                cell.colorView.layer.borderWidth = 0;
            }
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);

            /*
            if ([self.favoriteTableView isEditing])
                [cell.cellViewContant setConstant:40];
            else
                [cell.cellViewContant setConstant:0];
             */
            
        }
        
        return cell;
        
    } else {
        
        static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            NSDictionary* item = [groupData.groupItems objectAtIndex:indexPath.row];
            [cell.textView setText:[item objectForKey:@"text"]];
            [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {
        return indexPath;
    } else {
        return nil;
    }
    
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.directionButton.tag == 1)
        return [self canEditSortedRowAtIndexPath:indexPath];
    return [self canEditUnsortedRowAtIndexPath:indexPath];
}

-(BOOL)canEditSortedRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return YES;
    else
        return NO;    
}

-(BOOL)canEditUnsortedRowAtIndexPath:(NSIndexPath *)indexPath {
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped)
        return YES;
    else
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
    if (self.directionButton.tag == 1)
        [self didSelectRowAtIndexPathSorter:indexPath];
    else
        [self didSelectRowAtIndexPathUnsorter:indexPath];
}

-(void)didSelectRowAtIndexPathSorter:(NSIndexPath *)indexPath {
    if ([self.favoriteTableView isEditing]) {
        /*
        OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
        OAPointTableViewCell *cell = (OAPointTableViewCell*)[self.favoriteTableView cellForRowAtIndexPath:indexPath];
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r green:item.favorite->getColor().g blue:item.favorite->getColor().b alpha:1];
        [cell.colorView setBackgroundColor:color];
         */
        return;
    }
    
    if (indexPath.section == 0) {
        OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];

        OAFavoriteItemViewController* controller = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
        [self.navigationController pushViewController:controller animated:YES];

    } else {
        NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
    }
}

-(void)didSelectRowAtIndexPathUnsorter:(NSIndexPath *)indexPath {
    if ([self.favoriteTableView isEditing]) {
        /*
        FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        OAPointTableViewCell *cell = (OAPointTableViewCell*)[self.favoriteTableView cellForRowAtIndexPath:indexPath];
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r green:item.favorite->getColor().g blue:item.favorite->getColor().b alpha:1];
        [cell.colorView setBackgroundColor:color];
         */
        return;
    }
    
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        
        OAFavoriteItemViewController* controller = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
        [self.navigationController pushViewController:controller animated:YES];
        
    } else {
        NSDictionary* item = [groupData.groupItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}






@end
