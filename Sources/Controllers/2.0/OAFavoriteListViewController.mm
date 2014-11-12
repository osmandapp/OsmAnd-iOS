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

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define _(name) OAFavoriteListViewController__##name

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

@interface OAFavoriteListViewController ()

    @property (strong, nonatomic) NSMutableArray* groupsAndFavorites;
    @property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAFavoriteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [self generateData];
    [self setupView];
}

-(void)generateData {
    OsmAndAppInstance app = [OsmAndApp instance];
    self.groupsAndFavorites = [[NSMutableArray alloc] init];
    
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
                [self updateDistanceAndDirectionFor:favData];
                [itemData.groupItems addObject:favData];
            }
            
            [self.groupsAndFavorites addObject:itemData];
        }
        
    }
    
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
            [self updateDistanceAndDirectionFor:favData];
            [itemData.groupItems addObject:favData];
        }
        
        [self.groupsAndFavorites addObject:itemData];
    }
    
    // Generate menu items
    FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
    itemData.groupName = @"Import/Export";
    itemData.type = kFavoriteCellTypeMenu;
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:@[@{@"text": @"Import favorites",
                                                                    @"icon": @"favorite_import_icon",
                                                                    @"action": @"onImportClicked"},
                                                                  @{@"text": @"Export favorites",
                                                                    @"icon": @"favorite_export_icon.png",
                                                                    @"action": @"onExportClicked"}]];
    [self.groupsAndFavorites addObject:itemData];

}

- (void)updateDistanceAndDirectionFor:(OAFavoriteItem*)favoriteItem
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;


 
    const auto& favoritePosition31 = favoriteItem.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
            
    const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                      newLocation.coordinate.latitude,
                                                      favoriteLon, favoriteLat);
            
    favoriteItem.distance = [app.locationFormatter stringFromDistance:distance];
    favoriteItem.direction = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];

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

- (IBAction)menuFavoriteClicked:(id)sender {
}

- (IBAction)menuGPXClicked:(id)sender {
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



#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groupsAndFavorites count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return ((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupName;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    if (groupData.type == kFavoriteCellTypeGrouped || groupData.type == kFavoriteCellTypeUngrouped) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        OAPointTableViewCell* cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            OAFavoriteItem* item = [groupData.groupItems objectAtIndex:indexPath.row];
            [cell.titleView setText:item.favorite->getTitle().toNSString()];
            [cell.colorView setBackgroundColor:[UIColor colorWithRed:item.favorite->getColor().r green:item.favorite->getColor().g blue:item.favorite->getColor().b alpha:1]];
            [cell.distanceView setText:item.distance];
        }
        
        return cell;
    } else {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
        OAIconTextTableViewCell* cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            NSDictionary* item = [groupData.groupItems objectAtIndex:indexPath.row];
            [cell.textView setText:[item objectForKey:@"text"]];
            [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
    }
    
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
