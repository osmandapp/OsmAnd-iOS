//
//  OAFavoriteListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAPointHeaderTableViewCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAMapViewController.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMultiselectableHeaderView.h"
#import "OAEditColorViewController.h"
#import "OAEditGroupViewController.h"
#import "OARootViewController.h"
#import "OATargetInfoViewController.h"
#import "OASizes.h"
#import "OAColors.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define _(name) OAFavoriteListViewController__##name

typedef enum
{
    kFavoriteActionNone = 0,
    kFavoriteActionChangeColor = 1,
    kFavoriteActionChangeGroup = 2,
} EFavoriteAction;

#define FavoriteTableGroup _(FavoriteTableGroup)
@interface FavoriteTableGroup : NSObject
    @property BOOL isOpen;
    @property OAFavoriteGroup *favoriteGroup;
@end
@implementation FavoriteTableGroup

-(id) init {
    self = [super init];
    if (self) {
        self.isOpen = NO;
    }
    return self;
}

@end

@interface OAFavoriteListViewController () <OAMultiselectableHeaderDelegate>{
    
    BOOL isDecelerating;
}
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
    NSMutableArray<NSArray *> *_data;

    EFavoriteAction _favAction;
    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;

    CALayer *_horizontalLine;
    NSMutableArray<NSIndexPath *> *_selectedItems;
}

static UIViewController *parentController;

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
    
    _selectedItems = [[NSMutableArray alloc] init];
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
    return favoritesToolBarHeight;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
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
                    NSDictionary *groupData = _data[i.section][0];
                    NSString *cellType = groupData[@"type"];
                    if ([cellType isEqualToString:@"group"])
                    {
                        FavoriteTableGroup *group = groupData[@"group"];
                        item = [group.favoriteGroup.points objectAtIndex:i.row - 1];
                    }
                }

                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;

                    [c.titleView setText:[item getDisplayName]];
                    c = [self setupPoiIconForCell:c withFavaoriteItem:item];
                    
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
    NSMutableArray *allGroups = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];
    self.sortedFavoriteItems = [[NSMutableArray alloc] init];
    
    NSMutableArray *headerViews = [NSMutableArray array];
    NSMutableArray *tableData = [NSMutableArray array];
    
    if (![OAFavoritesHelper isFavoritesLoaded])
        [OAFavoritesHelper loadFavorites];
    
    NSArray *favorites = [NSMutableArray arrayWithArray:[OAFavoritesHelper getFavoriteGroups]];

    for (OAFavoriteGroup *group in favorites)
    {
        FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
        itemData.favoriteGroup = group;
        
        // Sort items
        NSArray *sortedArrayItems = [itemData.favoriteGroup.points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return [[[obj1 getDisplayName] lowercaseString] compare:[[obj2 getDisplayName] lowercaseString]];
        }];
        [itemData.favoriteGroup.points setArray:sortedArrayItems];
        
        for (OAFavoriteItem *item in group.points)
            [self.sortedFavoriteItems addObject:item];
        [allGroups addObject:itemData];
    }
    
    NSArray *sortedArray = [self.sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
    }];
    [self.sortedFavoriteItems setArray:sortedArray];
    
    for (FavoriteTableGroup *group in allGroups) {
        NSMutableArray *groupData = [NSMutableArray array];
        [groupData addObject:@{
            @"type" : @"group",
            @"group" : group
        }];
        [tableData addObject:groupData];
    }
    
    for (int i = 0; i < tableData.count;)
    {
        OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
        [headerView.selectAllBtn setHidden:YES];
        headerView.section = i++;
        headerView.delegate = self;
        [headerViews addObject:headerView];
    }
    
    // Generate menu items
    self.menuItems = @[@{@"type" : @"actionItem",
                         @"text": OALocalizedString(@"fav_import_title"),
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"},
                       @{@"type" : @"actionItem",
                         @"text": OALocalizedString(@"fav_export_title"),
                         @"icon": @"favorite_export_icon.png",
                         @"action": @"onExportClicked"}];
    [tableData addObject:self.menuItems];
    
    OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    [headerView setTitleText:OALocalizedString(@"import_export")];
    headerView.editable = NO;
    [headerViews addObject:headerView];
    
    _data = [NSMutableArray arrayWithArray:tableData];
    
    [self.favoriteTableView reloadData];
    
    _unsortedHeaderViews = [NSArray arrayWithArray:headerViews];
}

-(void)setupView
{
    self.favoriteTableView.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
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

- (IBAction) deletePressed:(id)sender
{
    if ([_selectedItems count] == 0) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select_remove")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:nil
                                message:OALocalizedString(@"fav_remove_q")
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *yesButton = [UIAlertAction
                                actionWithTitle:OALocalizedString(@"shared_string_yes")
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * _Nonnull action) {
        [self removeFavoriteItems];
    }];
    UIAlertAction *cancelButton = [UIAlertAction
                             actionWithTitle:OALocalizedString(@"shared_string_no")
                             style:UIAlertActionStyleCancel
                             handler:nil];
    [alert addAction:yesButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:nil];
 
}

- (IBAction) favoriteChangeColorClicked:(id)sender
{
    if ([_selectedItems count] == 0) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
       
        return;
    }

    _favAction = kFavoriteActionChangeColor;
    _colorController = [[OAEditColorViewController alloc] init];
    [self.navigationController pushViewController:_colorController animated:YES];
}

- (IBAction) favoriteChangeGroupClicked:(id)sender
{
    if ([_selectedItems count] == 0) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }

    _favAction = kFavoriteActionChangeGroup;

    NSMutableArray *groupNames = [NSMutableArray new];
    for (OAFavoriteGroup *group in [OAFavoritesHelper getFavoriteGroups])
    {
        NSString *groupName = [OAFavoriteGroup getDisplayName:group.name];
        if (groupName.length > 0 && group.name.length != 0)
            [groupNames addObject:groupName];
    }
        
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:nil groups:groupNames];
    [self.navigationController pushViewController:_groupController animated:YES];
}

- (void) setupColor
{
    if ([_selectedItems count] == 0)
        return;

    if (_colorController.saveChanges)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:_colorController.colorIndex];

        for (NSIndexPath *indexPath in _selectedItems)
        {
            OAFavoriteItem* item;
            if (self.directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                NSDictionary *groupData = _data[indexPath.section][0];
                NSString *cellType = groupData[@"type"];
                if ([cellType isEqualToString:@"group"])
                {
                    FavoriteTableGroup* tableGroup = groupData[@"group"];
                    if (indexPath.row != 0)
                        item = [tableGroup.favoriteGroup.points objectAtIndex:indexPath.row - 1];
                    else
                        tableGroup.favoriteGroup.color = favCol.color;
                }
            }
            
            if (item)
            {
                [item setColor:favCol.color];
                
                if (indexPath.row == 1)
                {
                    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:[item getCategory]];
                    group.color = favCol.color;
                }
            }
        }
        
        [app saveFavoritesToPermamentStorage];
    }
    [self finishEditing];
    [self.favoriteTableView reloadData];
}

- (void) setupGroup
{
    if ([_selectedItems count] == 0)
        return;
    
    if (_groupController.saveChanges)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        NSMutableArray<NSIndexPath *> * sortedSelectedItems = [NSMutableArray arrayWithArray:_selectedItems];
        [sortedSelectedItems sortUsingComparator:^NSComparisonResult(NSIndexPath* obj1, NSIndexPath* obj2) {
            NSNumber *row1 = [NSNumber numberWithInteger:obj1.row];
            NSNumber *row2 = [NSNumber numberWithInteger:obj2.row];
            return [row2 compare:row1];
        }];
        
        for (NSIndexPath *indexPath in sortedSelectedItems)
        {
            OAFavoriteItem* item;
            if (self.directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                NSDictionary *groupData = _data[indexPath.section][0];
                NSString *cellType = groupData[@"type"];
                if ([cellType isEqualToString:@"group"])
                {
                    if (indexPath.row != 0)
                    {
                        FavoriteTableGroup* group = groupData[@"group"];
                        item = [group.favoriteGroup.points objectAtIndex:indexPath.row - 1];
                    }
                }
            }
            
            if (item)
            {
                [OAFavoritesHelper editFavoriteName:item newName:[item getDisplayName] group:_groupController.groupName descr:[item getDescription] address:[item getAddress]];
            }
        }
        
        [app saveFavoritesToPermamentStorage];
    }
    [self finishEditing];
    [self generateData];
}

- (NSArray *) getItemsForRows:(NSArray<NSIndexPath *>*)indexPath
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
            NSDictionary *groupData = _data[path.section][0];
            FavoriteTableGroup* group = groupData[@"group"];
            if (path.row != 0)
            {
                [itemList addObject:[group.favoriteGroup.points objectAtIndex:path.row - 1]];
            }
        }];
    }
    return itemList;
}

- (void) startEditing
{
    [self.favoriteTableView setEditing:YES animated:YES];
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    _editToolbarView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        [self.tabBarController.tabBar setHidden:YES];
        [self applySafeAreaMargins];
    }];
    
    [self.editButton setImage:[UIImage imageNamed:@"icon_edit_active"] forState:UIControlStateNormal];
    [self.backButton setHidden:YES];
    [self.directionButton setHidden:YES];
    [self.favoriteTableView reloadData];
}

- (void) finishEditing
{
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight - _editToolbarView.bounds.size.height, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    [UIView animateWithDuration:.3 animations:^{
        [self.tabBarController.tabBar setHidden:NO];
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    } completion:^(BOOL finished) {
        _editToolbarView.hidden = YES;
        [self applySafeAreaMargins];
    }];

    [self.editButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
    [self.backButton setHidden:NO];

    if (self.directionButton.tag == 1)
        [self.directionButton setImage:[UIImage imageNamed:@"icon_direction_active"] forState:UIControlStateNormal];
    else
        [self.directionButton setImage:[UIImage imageNamed:@"icon_direction"] forState:UIControlStateNormal];

    [self.directionButton setHidden:NO];
    [self.favoriteTableView setEditing:NO animated:YES];
    [_selectedItems removeAllObjects];
}

- (IBAction)editButtonClicked:(id)sender
{
    [self.favoriteTableView beginUpdates];
    if ([self.favoriteTableView isEditing])
        [self finishEditing];
    else
        [self startEditing];
    [self.favoriteTableView endUpdates];
}

- (IBAction) shareButtonClicked:(id)sender
{
    // Share selected favorites
    if ([_selectedItems count] == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_export_select")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
       
        return;
    }

    NSArray* selectedFavoriteItems = [self getItemsForRows:_selectedItems];
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> exportCollection(new OsmAnd::FavoriteLocationsGpxCollection());
    [selectedFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* obj, NSUInteger idx, BOOL *stop) {
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
    [self finishEditing];
    [self generateData];
}

- (IBAction)goRootScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)onImportClicked {
    NSString* favoritesImportText = OALocalizedString(@"fav_import_desc");
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                message:favoritesImportText
                                preferredStyle:UIAlertControllerStyleAlert];

     UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

     [alert addAction:defaultAction];
     [self presentViewController:alert animated:YES completion:nil];
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
    _exportController.name = @"OsmAnd favourites.gpx";
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
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
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_data.count == 1)
        return 44;
    NSDictionary *item = _data[section][0];
    NSString *cellType = item[@"type"];
    return [cellType isEqualToString:@"actionItem"] || self.directionButton.tag == 1 ? 44 : 16;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.favoriteTableView.numberOfSections - 1)
        return 60.;
    return  44.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.directionButton.tag == 1)
        return [self getSortedNumberOfRowsInSection:section];
    return [self getUnsortedNumberOfRowsInSection:section];
}

-(NSInteger)getSortedNumberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.sortedFavoriteItems count];
    return _data.lastObject.count;
}

-(NSInteger)getUnsortedNumberOfRowsInSection:(NSInteger)section {
    NSDictionary *item = _data[section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        FavoriteTableGroup* groupData = item[@"group"];
        if (groupData.isOpen)
            return [groupData.favoriteGroup.points count] + 1;
        return 1;
    }
    return _data[section].count;
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
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            [cell.titleView setText:[item getDisplayName]];
            cell = [self setupPoiIconForCell:cell withFavaoriteItem:item];
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }

        return cell;
        
    }
    else
    {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
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
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        if (indexPath.row == 0)
            return [self getGroupHeaderCellForRowAtIndexPath:indexPath];
        else
            return [self getGroupElementCellForRowAtIndexPath:indexPath];
    }
    return [self getActionCellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*)getGroupHeaderCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    
    OAPointHeaderTableViewCell* cell;
    cell = (OAPointHeaderTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointHeaderTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointHeaderTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointHeaderTableViewCell *)[nib objectAtIndex:0];
        cell.folderIcon.image = [UIImage templateImageNamed:@"ic_custom_folder"];
    }
    if (cell)
    {
        OAFavoriteGroup* group = groupData.favoriteGroup;
        [cell.groupTitle setText:[OAFavoriteGroup getDisplayName:group.name]];
        cell.folderIcon.tintColor = groupData.favoriteGroup.color;
        
        cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
        [cell.openCloseGroupButton removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        if ([self.favoriteTableView isEditing])
            [cell.openCloseGroupButton setHidden:NO];
        else
            [cell.openCloseGroupButton setHidden:YES];
        
        if (groupData.isOpen)
        {
            cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_down"];
        }
        else
        {
            cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            if ([cell isDirectionRTL])
                [cell.arrowImage setImage:cell.arrowImage.image.imageFlippedForRightToLeftLayoutDirection];
        }
        cell.arrowImage.tintColor = UIColorFromRGB(color_tint_gray);
    }
    return cell;
}

- (UITableViewCell*)getGroupElementCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    
    NSInteger dataIndex = indexPath.row - 1;
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
    }
    if (cell)
    {
        OAFavoriteItem* item = [groupData.favoriteGroup.points objectAtIndex:dataIndex];
        [cell.titleView setText:[item getDisplayName]];
        cell = [self setupPoiIconForCell:cell withFavaoriteItem:item];

        [cell.distanceView setText:item.distance];
        
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
    }
    return cell;
}

- (OAPointTableViewCell *) setupPoiIconForCell:(OAPointTableViewCell *)cell withFavaoriteItem:(OAFavoriteItem*)item
{
    cell.titleIcon.image = [item getCompositeIcon];
    return cell;
}

- (UITableViewCell*)getActionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OAIconTextTableViewCell* cell;
    cell = (OAIconTextTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:[item objectForKey:@"text"]];
        [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
    }
    return cell;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        if (self.directionButton.tag == 0)
        {
            NSDictionary *item = _data[indexPath.section][0];
            NSString *cellType = item[@"type"];
            if ([cellType isEqualToString:@"group"])
                return indexPath;
            return nil;
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
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    return [cellType isEqualToString:@"group"];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row != 0 && self.directionButton.tag == 0) || self.directionButton.tag == 1)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)removeItemFromSortedFavoriteItems:(NSIndexPath *)indexPath
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
    
    [self.favoriteTableView beginUpdates];
    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[item]];
    [self.sortedFavoriteItems removeObjectAtIndex:indexPath.row];
    [self.favoriteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
    [self.favoriteTableView endUpdates];
    [app saveFavoritesToPermamentStorage];
}

- (void)removeItemFromUnsortedFavoriteItems:(NSIndexPath *)indexPath
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSInteger dataIndex = indexPath.row - 1;
    
    NSDictionary *groupData = _data[indexPath.section][0];
    FavoriteTableGroup* group = groupData[@"group"];
    OAFavoriteItem* item = [group.favoriteGroup.points objectAtIndex:dataIndex];
    
    [self.favoriteTableView beginUpdates];
    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[item]];
    [group.favoriteGroup.points removeObjectAtIndex:indexPath.row - 1];
    [self.favoriteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationLeft];
    [self.favoriteTableView endUpdates];
    [app saveFavoritesToPermamentStorage];
}

- (void) removeItemsFromSortedFavoriteItems
{
    NSSortDescriptor *rowDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:NO];
    NSSortDescriptor *sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:NO];
    NSArray<NSIndexPath *> *sortedArray = [_selectedItems sortedArrayUsingDescriptors:@[sectionDescriptor, rowDescriptor]];
    OsmAndAppInstance app = [OsmAndApp instance];
    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toDelete;
    for (NSIndexPath *selectedItem in sortedArray)
    {
        NSInteger dataIndex = selectedItem.row;
        
        OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:dataIndex];
        toDelete.push_back(item.favorite);
        [self.favoriteTableView beginUpdates];
        [self.sortedFavoriteItems removeObjectAtIndex:dataIndex];
        [self.favoriteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:dataIndex inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        [self.favoriteTableView endUpdates];
        [app saveFavoritesToPermamentStorage];
    }
    app.favoritesCollection->removeFavoriteLocations(toDelete);
}

- (void)removeGroupHeader:(NSIndexPath *)indexPath{
    
    NSInteger numberOfRows = [self.favoriteTableView numberOfRowsInSection:[indexPath section]];
    
    if (numberOfRows == 1)
    {
        [self.favoriteTableView beginUpdates];
        
        NSDictionary *groupData = _data[indexPath.section][0];
        FavoriteTableGroup* group = groupData[@"group"];
        [OAFavoritesHelper deleteFavoriteGroups:@[group.favoriteGroup] andFavoritesItems:nil];
        
        [_data removeObjectAtIndex:indexPath.section];
        
        [self.favoriteTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                              withRowAnimation:UITableViewRowAnimationFade];
        [self.favoriteTableView endUpdates];
    }
}

- (void) removeItemsFromUnsortedFavoriteItems
{
    NSSortDescriptor *rowDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:NO];
    NSSortDescriptor *sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:NO];
    NSArray<NSIndexPath *> *sortedArray = [_selectedItems sortedArrayUsingDescriptors:@[sectionDescriptor, rowDescriptor]];
    OsmAndAppInstance app = [OsmAndApp instance];
    
    for (NSIndexPath *selectedItem in sortedArray)
    {
        if (selectedItem.row == 0)
            [self removeGroupHeader:selectedItem];
        else
        {
            NSInteger dataIndex = selectedItem.row - 1;
            NSDictionary *groupData = _data[selectedItem.section][0];
            FavoriteTableGroup* group = groupData[@"group"];
            OAFavoriteItem* item = [group.favoriteGroup.points objectAtIndex:dataIndex];
            [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[item]];
            
            if (group.isOpen)
            {
                [self.favoriteTableView beginUpdates];
                [self.favoriteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:selectedItem.row inSection:selectedItem.section]] withRowAnimation:UITableViewRowAnimationLeft];
                [self.favoriteTableView endUpdates];
            }
            [app saveFavoritesToPermamentStorage];
        }
    }
    [self finishEditing];
}

- (void) removeFavoriteItems
{
    if (self.directionButton.tag == 0)
        [self removeItemsFromUnsortedFavoriteItems];
    else
        [self removeItemsFromSortedFavoriteItems];
}

- (void)removeFavoriteItem:(NSIndexPath *)indexPath
{
    if (self.directionButton.tag == 0)
        [self removeItemFromUnsortedFavoriteItems:indexPath];
    else
        [self removeItemFromSortedFavoriteItems:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:nil
                                    message:OALocalizedString(@"fav_remove_q")
                                    preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *yesButton = [UIAlertAction
                                    actionWithTitle:OALocalizedString(@"shared_string_yes")
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * _Nonnull action) {
            [self removeFavoriteItem:indexPath];
        }];
        UIAlertAction *cancelButton = [UIAlertAction
                                 actionWithTitle:OALocalizedString(@"shared_string_no")
                                 style:UIAlertActionStyleCancel
                                 handler:nil];
        [alert addAction:yesButton];
        [alert addAction:cancelButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
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

#pragma mark - Favorite group's item editing operations

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedItems containsObject:indexPath])
         [_selectedItems addObject:indexPath];
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedItems containsObject:indexPath])
        [_selectedItems removeObject:indexPath];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseFavoriteGroup:indexPath];
}

- (void) selectAllItemsInGroup:(NSIndexPath *)indexPath selectHeader:(BOOL)selectHeader
{
    NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:indexPath.section];

    [self.favoriteTableView beginUpdates];
    if (selectHeader)
        for (int i = 0; i < rowsCount; i++)
        {
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
    else
        for (int i = 0; i < rowsCount; i++)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES];
        }
    [self.favoriteTableView endUpdates];
}

- (void) selectGroupForEditing:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    if (groupData.isOpen)
        [self selectAllItemsInGroup:indexPath selectHeader:YES];
    else
        for (NSInteger i = 0; i <= groupData.favoriteGroup.points.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
}

- (void) deselectGroupForEditing:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    
    if (groupData.isOpen)
    {
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:indexPath.section];
        [self selectAllItemsInGroup:indexPath selectHeader:(rowsCount != selectedRows.count && isGroupHeaderSelected)];
    }
    else
    {
        NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedItems];
        for (NSUInteger i = 0; i < tmp.count; i++)
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedItems)
        if (itemPath.section == indexPath.section)
            [self.favoriteTableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void) openCloseFavoriteGroup:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.favoriteTableView beginUpdates];
        [self.favoriteTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.favoriteTableView endUpdates];
        if ([_selectedItems containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.favoriteTableView beginUpdates];
        [self.favoriteTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.favoriteTableView endUpdates];
        
        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.directionButton.tag == 1)
        [self didSelectRowAtIndexPathSorter:indexPath];
    else
    {
        NSDictionary *item = _data[indexPath.section][0];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:@"group"])
        {
            if (indexPath.row == 0 && ![self.favoriteTableView isEditing])
                [self openCloseFavoriteGroup:indexPath];
            else if (indexPath.row == 0 && [self.favoriteTableView isEditing])
                [self selectGroupForEditing:indexPath];
            else
                [self didSelectRowAtIndexPathUnsorted:indexPath];
        }
        else
            [self didSelectRowAtIndexPathUnsorted:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.directionButton.tag == 1)
        [self didDeselectRowAtIndexPathSorted:indexPath];
    else
    {
        NSDictionary *item = _data[indexPath.section][0];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:@"group"])
        {
            if (indexPath.row == 0 && ![self.favoriteTableView isEditing])
                [self openCloseFavoriteGroup:indexPath];
            else if (indexPath.row == 0 && [self.favoriteTableView isEditing])
                [self deselectGroupForEditing:indexPath];
            else
                [self didDeselectRowAtIndexPathUnsorted:indexPath];
        }
    }
}

- (void) didSelectRowAtIndexPathSorter:(NSIndexPath *)indexPath {
    if ([self.favoriteTableView isEditing]) {
        [self addIndexPathToSelectedCellsArray:indexPath];
        return;
    }
    
    if (indexPath.section == 0) {
        OAFavoriteItem* item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];

    } else {
        NSDictionary* item = [_data.lastObject objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) didDeselectRowAtIndexPathSorted:(NSIndexPath *)indexPath {
    if ([self.favoriteTableView isEditing]) {
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        return;
    }
}

- (void) didDeselectRowAtIndexPathUnsorted:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.favoriteTableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
        }
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        
        if (indexPath.row == 0)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        else if (numberOfSelectedRowsInSection == numberOfRowsInSection && isGroupHeaderSelected)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
}

- (void) didSelectRowAtIndexPathUnsorted:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.favoriteTableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
            [self addIndexPathToSelectedCellsArray:item];
        }
        if (numberOfSelectedRowsInSection == numberOfRowsInSection && !isGroupHeaderSelected)
        {
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        }
        else
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        FavoriteTableGroup* groupData = item[@"group"];
        OAFavoriteItem* item = [groupData.favoriteGroup.points objectAtIndex:indexPath.row - 1];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];
        
    }
    else
    {
        item = _data[indexPath.section][indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)doPush
{
    parentController = self.parentViewController;
    
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
        for (NSInteger i = 0; i < rowsCount; i++)
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (NSInteger i = 0; i < rowsCount; i++)
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.favoriteTableView endUpdates];
}

@end
