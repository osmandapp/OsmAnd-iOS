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
#import "OAFavoriteItem.h"
#import "OAMapViewController.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMultiselectableHeaderView.h"
#import "OAEditColorViewController.h"
#import "OAEditGroupViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"

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

typedef enum
{
    kFavoriteActionNone = 0,
    kFavoriteActionChangeColor = 1,
    kFavoriteActionChangeGroup = 2,
} EFavoriteAction;

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

@interface OAFavoriteListViewController () <OAMultiselectableHeaderDelegate>{
    
    BOOL isDecelerating;
}

    @property (strong, nonatomic) NSMutableArray* groupsAndFavorites;
    @property (strong, nonatomic) NSArray*  menuItems;
    @property (strong, nonatomic) UIDocumentInteractionController* exportController;
    @property (strong, nonatomic) NSMutableArray*  sortedFavoriteItems;
    @property NSUInteger sortingType;
@end

@implementation OAFavoriteListViewController
{
    OAMultiselectableHeaderView *_sortedHeaderView;
    OAMultiselectableHeaderView *_menuHeaderView;
    NSArray *_unsortedHeaderViews;

    EFavoriteAction _favAction;
    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;

    CALayer *_horizontalLine;
}

static OAFavoriteListViewController *parentController;

+ (BOOL)popToParent
{
    if (!parentController)
        return NO;
    
    [OAFavoriteListViewController doPop];
    
    return YES;
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"my_favorites");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isDecelerating = NO;
    self.sortingType = 0;
    _favAction = kFavoriteActionNone;
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    _sortedHeaderView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    _sortedHeaderView.delegate = self;
    [_sortedHeaderView setTitleText:OALocalizedString(@"favorites")];
    
    _menuHeaderView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    _menuHeaderView.editable = NO;
    [_menuHeaderView setTitleText:OALocalizedString(@"import_export")];
    
    _editToolbarView.hidden = YES;

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.editToolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.editToolbarView.layer addSublayer:_horizontalLine];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _favoriteTableView;
}

-(UIView *) getBottomView
{
    return [self.favoriteTableView isEditing] ? _editToolbarView : nil;
}

-(CGFloat) getToolBarHeight
{
    return [self.favoriteTableView isEditing] ? favoritesToolBarHeight : 0;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([self.favoriteTableView isEditing])
        return;

    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
        return;
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
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
    
    [self.sortedFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
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
        
        [self.favoriteTableView beginUpdates];
        NSArray *visibleIndexPaths = [self.favoriteTableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.favoriteTableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OAFavoriteItem* item;
                if (self.directionButton.tag == 1)
                {
                    if (i.section == 0)
                        item = [self.sortedFavoriteItems objectAtIndex:i.row];
                }
                else
                {
                    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:i.section];
                    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped)
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
        [self.favoriteTableView endUpdates];

        //NSArray *visibleIndexPaths = [self.favoriteTableView indexPathsForVisibleRows];
        //[self.favoriteTableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
    });
}

-(void)viewWillAppear:(BOOL)animated {
    
    if (_favAction == kFavoriteActionChangeColor)
        [self setupColor];
    else if (_favAction == kFavoriteActionChangeGroup)
        [self setupGroup];
    else
        [self setupView];
    
    if (_favAction != kFavoriteActionNone) {
        return;
    }
    
    [self generateData];
    [self setupView];
    [self updateDistanceAndDirection:YES];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
    [self applySafeAreaMargins];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_favAction != kFavoriteActionNone) {
        _favAction = kFavoriteActionNone;
        return;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_favAction != kFavoriteActionNone)
        return;

    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }

}

-(void)generateData
{
    OsmAndAppInstance app = [OsmAndApp instance];
    self.groupsAndFavorites = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];
    self.sortedFavoriteItems = [[NSMutableArray alloc] init];
    
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
        itemData.groupName = OALocalizedString(@"favorites");
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

    int i = 0;
    for (FavoriteTableGroup *group in self.groupsAndFavorites)
    {
        OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
        [headerView setTitleText:group.groupName];
        headerView.section = i++;
        headerView.delegate = self;
        [headerViews addObject:headerView];
    }

    // Generate menu items
    FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
    itemData.groupName = OALocalizedString(@"import_export");
    itemData.type = kFavoriteCellTypeMenu;
    self.menuItems = @[@{@"text": OALocalizedString(@"fav_import_title"),
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"},
                       @{@"text": OALocalizedString(@"fav_export_title"),
                         @"icon": @"favorite_export_icon.png",
                         @"action": @"onExportClicked"}];
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:self.menuItems];
    [self.groupsAndFavorites addObject:itemData];

    OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    [headerView setTitleText:OALocalizedString(@"import_export")];
    headerView.editable = NO;
    [headerViews addObject:headerView];

    [self.favoriteTableView reloadData];

    _unsortedHeaderViews = [NSArray arrayWithArray:headerViews];

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

- (IBAction)sortByDistance:(id)sender
{
    if (![self.favoriteTableView isEditing])
    {
        if (self.directionButton.tag == 0)
        {
            self.directionButton.tag = 1;
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
            self.sortingType = 1;
        }
        else
        {
            self.directionButton.tag = 0;
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];
            self.sortingType = 0;
        }
        [self generateData];
        [self updateDistanceAndDirection:YES];
    }
}

- (IBAction)deletePressed:(id)sender
{
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_select_remove") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [removeAlert show];
        return;
    }
    
    UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_no") otherButtonTitles:OALocalizedString(@"shared_string_yes"), nil];
    removeAlert.tag = kAlertViewRemoveId;
    [removeAlert show];
}

- (IBAction)favoriteChangeColorClicked:(id)sender
{
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }

    _favAction = kFavoriteActionChangeColor;
    _colorController = [[OAEditColorViewController alloc] init];
    [self.navigationController pushViewController:_colorController animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender
{
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }

    _favAction = kFavoriteActionChangeGroup;

    OsmAndAppInstance app = [OsmAndApp instance];
    NSArray *groups = [[OANativeUtilities QListOfStringsToNSMutableArray:app.favoritesCollection->getGroups().toList()] copy];
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:nil groups:groups];
    [self.navigationController pushViewController:_groupController animated:YES];
}

- (void)setupColor
{
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
        return;

    if (_colorController.saveChanges)
    {
        OsmAndAppInstance app = [OsmAndApp instance];

        for (NSIndexPath *indexPath in selectedRows)
        {
            OAFavoriteItem* item;
            if (self.directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
                if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped)
                    item = [groupData.groupItems objectAtIndex:indexPath.row];
            }
            
            if (item)
            {
                OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:_colorController.colorIndex];
                CGFloat r,g,b,a;
                [favCol.color getRed:&r
                               green:&g
                                blue:&b
                               alpha:&a];
                
                item.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
            }
        }
        
        [app saveFavoritesToPermamentStorage];
    }
    
    [self editButtonClicked:nil];
    [self generateData];
}

- (void)setupGroup
{
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
        return;
    
    if (_groupController.saveChanges)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        
        for (NSIndexPath *indexPath in selectedRows)
        {
            OAFavoriteItem* item;
            if (self.directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
                if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped)
                    item = [groupData.groupItems objectAtIndex:indexPath.row];
            }
            
            if (item)
            {
                QString group;
                if (_groupController.groupName.length > 0)
                    group = QString::fromNSString(_groupController.groupName);
                else
                    group = QString::null;
                
                item.favorite->setGroup(group);
            }
        }
        
        [app saveFavoritesToPermamentStorage];
    }
    
    [self editButtonClicked:nil];
    [self generateData];
}

-(NSArray*)getItemsForRows:(NSArray*)indexPath
{
    NSMutableArray* itemList = [[NSMutableArray alloc] init];
    if (self.directionButton.tag == 1) { // Sorted
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop)
        {
            [itemList addObject:[self.sortedFavoriteItems objectAtIndex:path.row]];
        }];
    }
    else
    {
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
            FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:path.section];
            [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
        }];
    }
    return itemList;
}

- (IBAction)editButtonClicked:(id)sender
{
    [self.favoriteTableView beginUpdates];
    [self.favoriteTableView setEditing:![self.favoriteTableView isEditing] animated:YES];
    
    if ([self.favoriteTableView isEditing])
    {
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
        _editToolbarView.hidden = NO;
        [UIView animateWithDuration:.3 animations:^{
//            _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight - _editToolbarView.bounds.size.height, DeviceScreenWidth, _editToolbarView.bounds.size.height);
//            self.favoriteTableView.frame = CGRectMake(0.0, 64.0, DeviceScreenWidth, DeviceScreenHeight - 64.0 - _editToolbarView.bounds.size.height);
            [self applySafeAreaMargins];
        }];

        [self.editButton setImage:[UIImage imageNamed:@"icon_edit_active"] forState:UIControlStateNormal];
        [self.backButton setHidden:YES];
        [self.directionButton setHidden:YES];
        
    }
    else
    {
        [UIView animateWithDuration:.3 animations:^{
//            _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
//            self.favoriteTableView.frame = CGRectMake(0.0, 64.0, DeviceScreenWidth, DeviceScreenHeight - 64.0);
            [self applySafeAreaMargins];
        } completion:^(BOOL finished) {
            _editToolbarView.hidden = YES;
        }];

        [self.editButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
        [self.backButton setHidden:NO];

        if (self.directionButton.tag == 1)
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
        else
            [self.directionButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];

        [self.directionButton setHidden:NO];
        
    }
    [self.favoriteTableView endUpdates];
}

- (IBAction)shareButtonClicked:(id)sender
{
    // Share selected favorites
    NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        UIAlertView* removeAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_export_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
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
        
    NSString* filename = [@"Exported favorites" stringByAppendingString:@".gpx"];
    NSString* fullFilename = [NSTemporaryDirectory() stringByAppendingString:filename];
    if (!exportCollection->saveTo(QString::fromNSString(fullFilename)))
        return;
        
    NSURL* favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = filename;
    [_exportController presentOptionsMenuFromRect:_exportButton.frame
                                           inView:self.view
                                         animated:YES];
    
    [self editButtonClicked:nil];
    [self generateData];
}

- (IBAction)goRootScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)onImportClicked {
    NSString* favoritesImportText = OALocalizedString(@"fav_import_desc");
    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
    [importHelpAlert show];
}

-(void)onExportClicked
{
    
    if (self.sortedFavoriteItems.count == 0)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    // Share all favorites
    NSURL* favoritesUrl = [NSURL fileURLWithPath:app.favoritesStorageFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = @"OsmAnd Favorites.gpx";
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.directionButton.tag == 1)
    {
        if (section == 0)
            return _sortedHeaderView;
        else
            return _menuHeaderView;
    }
    else
    {
        return _unsortedHeaderViews[section];
    }
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

-(UITableViewCell*)getSortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";

        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            [cell.titleView setText:item.favorite->getTitle().toNSString()];

            UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
            
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            cell.titleIcon.image = favCol.icon;
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }

        return cell;
        
    }
    else
    {
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


- (UITableViewCell*)getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped)
    {
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
            UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];

            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            cell.titleIcon.image = favCol.icon;

            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            
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

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        if (self.directionButton.tag == 0)
        {
            FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
            if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {
                return indexPath;
            } else {
                return nil;
            }
        }
        else if (indexPath.section > 0)
        {
            return nil;
        }
    }
    return indexPath;
    
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.directionButton.tag == 1)
        return [self canEditSortedRowAtIndexPath:indexPath];
    
    return [self canEditUnsortedRowAtIndexPath:indexPath];
}

- (BOOL) canEditSortedRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    //[self refreshVisibleRows];
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
        return;
    }
    
    if (indexPath.section == 0) {
        OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];

    } else {
        NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void)didSelectRowAtIndexPathUnsorter:(NSIndexPath *)indexPath {
    if ([self.favoriteTableView isEditing]) {
        return;
    }
    
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {
        OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];
        
    } else {
        NSDictionary* item = [groupData.groupItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)doPush
{
    parentController = self;
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush; // kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromRight; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
}

+ (void)doPop
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal; // kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController pushViewController:parentController animated:NO];
    
    parentController = nil;
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

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:section];
    
    [self.favoriteTableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.favoriteTableView endUpdates];
}

@end
