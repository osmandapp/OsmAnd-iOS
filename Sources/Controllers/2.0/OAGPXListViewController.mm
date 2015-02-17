//
//  OAGPXListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAGPXListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAFavoriteItemViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAFavoriteItem.h"
#import "OAMapViewController.h"

#import "OsmAndApp.h"
#import "OsmAndCore/GpxDocument.h"
#import "OAGPXDatabase.h"


#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4



typedef enum
{
    kGPXCellTypeItem = 0,
    kGPXCellTypeMenu
    
} kGpxCellType;

#define GpxTableGroup _(GpxTableGroup)
@interface GpxTableGroup : NSObject
    @property int type;
    @property NSString* groupName;
    @property NSMutableArray*  groupItems;
@end

@implementation GpxTableGroup

-(id) init {
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end



@interface OAGPXListViewController ()

    @property (strong, nonatomic) NSMutableArray* groupsAndGPX;
    @property (strong, nonatomic) NSArray* menuItems;
    @property (strong, nonatomic) UIDocumentInteractionController* exportController;
@end

@implementation OAGPXListViewController

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self generateData];
    [self setupView];
}

-(void)generateData {
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.groupsAndGPX = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];
    
    std::shared_ptr<OsmAnd::GpxDocument> gpxCollection = app.gpxCollection;
    
//    NSString* name = gpxCollection->metadata->name.toNSString();
//    int tra = gpxCollection->tracks.count();
//    int rou = gpxCollection->routes.count();
//    int loc = gpxCollection->locationMarks.count();
//    NSString* name = gpxCollection->metadata->name.toNSString();
//    NSString* descr = gpxCollection->metadata->description.toNSString();


//    NSString* desc = gpxCollection->metadata->description.toNSString();

    
//    const auto allGPX = app.favoritesCollection->getFavoriteLocations();
//    QHash< QString, QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > > groupedFavorites;
//    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > ungroupedFavorites;
//    QSet<QString> groupNames;
//    
//    // create favorite groups
//    for(const auto& favorite : allFavorites)
//    {
//        const auto& groupName = favorite->getGroup();
//        if (groupName.isEmpty())
//            ungroupedFavorites.push_back(favorite);
//        else
//        {
//            groupNames.insert(groupName);
//            groupedFavorites[groupName].push_back(favorite);
//        }
//    }
//    
//    // Generate groups array
//    if (!groupNames.isEmpty())
//    {
//        for (const auto& groupName : groupNames)
//        {
//            FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
//            itemData.groupName = groupName.toNSString();
//            itemData.type = kGPXCellTypeItem;
//            for(const auto& favorite : groupedFavorites[groupName]) {
//                OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
//                favData.favorite = favorite;
//                [itemData.groupItems addObject:favData];
//            }
//            
//            if (self.sortingType == 0) { // Alphabetic
//                NSArray *sortedArrayItems = [itemData.groupItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
//                    return [[obj1.favorite->getTitle().toNSString() lowercaseString] compare:[obj2.favorite->getTitle().toNSString() lowercaseString]];
//                }];
//                [itemData.groupItems setArray:sortedArrayItems];
//            }
//            
//            [self.groupsAndGPX addObject:itemData];
//        }
//    }
    
    // Sort items
    NSArray *sortedArrayGroups = [self.groupsAndGPX sortedArrayUsingComparator:^NSComparisonResult(GpxTableGroup* obj1, GpxTableGroup* obj2) {
        return [[obj1.groupName lowercaseString] compare:[obj2.groupName lowercaseString]];
    }];
    [self.groupsAndGPX setArray:sortedArrayGroups];
    
    // Generate menu items
    GpxTableGroup* itemData = [[GpxTableGroup alloc] init];
    itemData.groupName = @"Import/Export";
    itemData.type = kGPXCellTypeMenu;
    self.menuItems = @[@{@"text": @"Import GPX",
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"},
                       @{@"text": @"Export GPX",
                         @"icon": @"favorite_export_icon.png",
                         @"action": @"onExportClicked"}];
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:self.menuItems];
    
    [self.gpxTableView reloadData];

}

-(void)setupView {
    
    [self.gpxTableView setDataSource:self];
    [self.gpxTableView setDelegate:self];
    self.gpxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.gpxTableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(NSArray*)getItemsForRows:(NSArray*)indexPath {
    NSMutableArray* itemList = [[NSMutableArray alloc] init];
    [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
        GpxTableGroup* groupData = [self.groupsAndGPX objectAtIndex:path.section];
        [itemList addObject:[groupData.groupItems objectAtIndex:path.row]];
    }];
    return itemList;
}


- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}

- (IBAction)goRootScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)onImportClicked {
    NSString* favoritesImportText = OALocalizedString(@"You can import your favorites as waypoints in GPX file (standard format for storing map information supported by PC, iOS, Android)\n\nTo share the GPX.gpx file you can open file from Dropbox, Email, or any other source - Use Open In function.");
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
    _exportController.name = OALocalizedString(@"OsmAnd GPX.gpx");
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    OsmAndAppInstance app = [OsmAndApp instance];
    if (alertView.tag == kAlertViewRemoveId) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            
            NSArray *selectedRows = [self.gpxTableView indexPathsForSelectedRows];
            NSArray* selectedItems = [self getItemsForRows:selectedRows];
            [selectedItems enumerateObjectsUsingBlock:^(OAFavoriteItem* obj, NSUInteger idx, BOOL *stop) {
                app.favoritesCollection->removeFavoriteLocation(obj.favorite);
            }];
            [app saveFavoritesToPermamentStorage];
            [self generateData];
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"GPX routes";
    return @"Import/Export";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.groupsAndGPX count];
    return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
        OAPointTableViewCell* cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            OAFavoriteItem* item = [self.groupsAndGPX objectAtIndex:indexPath.row];
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
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
        OAIconTextTableViewCell* cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            [cell.textView setText:[item objectForKey:@"text"]];
            [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return YES;
    else
        return NO;
}

#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.gpxTableView isEditing]) {
        OAFavoriteItem* item = [self.groupsAndGPX objectAtIndex:indexPath.row];
        OAPointTableViewCell *cell = (OAPointTableViewCell*)[self.gpxTableView cellForRowAtIndexPath:indexPath];
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r green:item.favorite->getColor().g blue:item.favorite->getColor().b alpha:1];
        [cell.colorView setBackgroundColor:color];
        return;
    }
    
    if (indexPath.section == 0) {
        OAFavoriteItem* item = [self.groupsAndGPX objectAtIndex:indexPath.row];
        
        OAFavoriteItemViewController* controller = [[OAFavoriteItemViewController alloc] initWithFavoriteItem:item];
        [self.navigationController pushViewController:controller animated:YES];
        
    } else {
        NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
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
