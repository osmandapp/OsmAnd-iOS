//
//  OAFavoriteImportViewController.m
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAFavoriteImportViewController.h"

#import "OAPointTableViewCell.h"
#import "OAFavoriteItemViewController.h"
#import "OAFavoriteItem.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


#define kAlertConflictWarning -2
#define kAlertConflictRename -4

typedef enum
{
    kFavoriteCellTypeGrouped = 0,
    kFavoriteCellTypeUngrouped,
    kFavoriteCellTypeMenu
}
kFavoriteCellType;

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


@interface OAFavoriteImportViewController () {
    
    OsmAndAppInstance _app;

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> _favoritesCollection;
    
    NSURL *_url;

}

@property (strong, nonatomic) NSMutableArray* groupsAndFavorites;
@property (strong, nonatomic) NSArray*  menuItems;

@end

@implementation OAFavoriteImportViewController


- (instancetype)initFor:(NSURL*)url
{
    OsmAndAppInstance app = [OsmAndApp instance];

    BOOL handled = NO;
    
    // Try to process as favorites
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;
    if ([url isFileURL])
    {
        // Try to import favorites
        favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(url.path));
        if (favoritesCollection)
            handled = YES;
        
        self = [super init];
        if (self) {
            _url = [url copy];
            _app = app;
            _favoritesCollection = favoritesCollection;
        }
        
    }
    return self;
}

-(BOOL)isFavoritesValid {
    for(const auto& favorite : _favoritesCollection->getFavoriteLocations())
    {
        NSString* favoriteTitle = favorite->getTitle().toNSString();
        for(const auto& localFavorite : _app.favoritesCollection->getFavoriteLocations())
        {
            if ([favoriteTitle isEqualToString:localFavorite->getTitle().toNSString()] && ![self.ignoredNames containsObject:favoriteTitle] ) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Favorite with name \"%@\" already exists.", favoriteTitle] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ignore", @"Rename", @"Replace", @"Replace All", nil];
                alert.tag = kAlertConflictWarning;
                [alert show];
                self.conflictedName = favoriteTitle;
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == kAlertConflictWarning) {
        
        // Cancel
        if (buttonIndex == alertView.cancelButtonIndex) {
            
            [self.ignoredNames removeAllObjects];
            self.conflictedName = @"";
            _favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(_url.path));
            
        // Ignore
        } else if (buttonIndex == 1) {
            
            [self.ignoredNames addObject:self.conflictedName];
            [self importClicked:nil];
            
        // Rename - ask name
        } else if (buttonIndex == 2) {
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Remane favorite" message:[NSString stringWithFormat:@"Please enter new name for favorite \"%@\"", self.conflictedName] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: @"OK", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            alert.tag = kAlertConflictRename;
            [alert show];
            
        // Replace current
        } else if (buttonIndex == 3) {
            
            for(const auto& localFavorite : _app.favoritesCollection->getFavoriteLocations()) {
                NSString* favoriteTitle = localFavorite->getTitle().toNSString();
                if ([favoriteTitle isEqualToString:self.conflictedName]) {
                    _app.favoritesCollection->removeFavoriteLocation(localFavorite);
                    break;
                }
            }
            [self importClicked:nil];
            
        // Replace All
        } else if (buttonIndex == 4) {
            
            for(const auto& favorite : _favoritesCollection->getFavoriteLocations()) {
                for(const auto& localFavorite : _app.favoritesCollection->getFavoriteLocations()) {
                    NSString* favoriteTitle = favorite->getTitle().toNSString();
                    NSString* localFavoriteTitle = localFavorite->getTitle().toNSString();
                    if ([localFavoriteTitle isEqualToString:favoriteTitle]) {
                        _app.favoritesCollection->removeFavoriteLocation(localFavorite);
                    }
                }
            }
            [self importClicked:nil];
        }
        
    } else if (alertView.tag == kAlertConflictRename) {
        
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSString* newFavoriteName = [alertView textFieldAtIndex:0].text;
            
            for(const auto& favorite : _favoritesCollection->getFavoriteLocations()) {
                NSString* favoriteTitle = favorite->getTitle().toNSString();
                if ([favoriteTitle isEqualToString:self.conflictedName]) {
                    favorite->setTitle(QString::fromNSString(newFavoriteName));
                    break;
                }
            }
        }
        [self importClicked:nil];
    }
    
}


- (void)viewDidLoad {

    [super viewDidLoad];
    
    self.ignoredNames = [[NSMutableArray alloc] init];

}

-(void)viewWillAppear:(BOOL)animated {
    
    [self generateData];
    [self setupView];
    
    [super viewWillAppear:animated];
}


-(void)generateData {
    
    self.groupsAndFavorites = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];

    const auto allFavorites = _favoritesCollection->getFavoriteLocations();
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
            [itemData.groupItems addObject:favData];
        }
        
        [self.groupsAndFavorites insertObject:itemData atIndex:0];
    }
    
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


- (IBAction)importClicked:(id)sender {

    if (_favoritesCollection) {
        // IOS-214
        if (![self isFavoritesValid])
            return;
        
        _app.favoritesCollection->mergeFrom(_favoritesCollection);
        [_app saveFavoritesToPermamentStorage];
        [self.ignoredNames removeAllObjects];
        self.conflictedName = @"";
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (IBAction)cancelClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self getUnsortedNumberOfSectionsInTableView];
}

-(NSInteger)getUnsortedNumberOfSectionsInTableView {
    return [self.groupsAndFavorites count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self getUnsortedTitleForHeaderInSection:section];
}

-(NSString*)getUnsortedTitleForHeaderInSection:(NSInteger)section {
    return ((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupName;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self getUnsortedNumberOfRowsInSection:section];
}

-(NSInteger)getUnsortedNumberOfRowsInSection:(NSInteger)section {
    return [((FavoriteTableGroup*)[self.groupsAndFavorites objectAtIndex:section]).groupItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*)getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FavoriteTableGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    
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
        
        cell.rightArrow.image = nil;
        cell.directionImageView.image = nil;
        cell.distanceView.hidden = YES;
        
        CGRect titleFrame = CGRectMake(cell.titleView.frame.origin.x, 15.0, cell.titleView.frame.size.width + 20.0, cell.titleView.frame.size.height);
        cell.titleView.frame = titleFrame;

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
        
    }
    
    return cell;
    
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return NO;
}


@end
