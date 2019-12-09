//
//  OAFavoriteImportViewController.m
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAFavoriteImportViewController.h"

#import "OAPointTableViewCell.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"

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

    _handled = NO;
    
    // Try to process as favorites
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;
    if ([url isFileURL])
    {
        // Try to import favorites
        favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(url.path));
        [[NSFileManager defaultManager] removeItemAtPath:url.path error:nil];
        if (favoritesCollection)
            _handled = YES;
        
        self = [super init];
        if (self) {
            _url = [url copy];
            _app = app;
            if (_handled)
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
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), favoriteTitle] delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles:OALocalizedString(@"fav_ignore"), OALocalizedString(@"fav_rename"), OALocalizedString(@"fav_replace"), OALocalizedString(@"fav_replace_all"), nil];
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
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"fav_rename_q") message:OALocalizedString(@"fav_enter_new_name \"%@\"", self.conflictedName) delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_ok"), nil];
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

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"fav_import_title");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_importButton setTitle:OALocalizedString(@"fav_import") forState:UIControlStateNormal];
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
        itemData.groupName = OALocalizedString(@"favorites");
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
    
    UILayoutGuide *safeArea;
       CGFloat statusBarHeight = OAUtilities.getStatusBarHeight;
       CGFloat buttonHeight = _cancelButton.frame.size.height;
       CGFloat buttonWidth = _cancelButton.frame.size.width;
       
       if (@available(iOS 11, *))
       {
           safeArea = self.view.safeAreaLayoutGuide;
       }
       else
       {
           [safeArea.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:statusBarHeight].active = YES;
           [safeArea.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
           [safeArea.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
           [safeArea.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
           [self.view addLayoutGuide:safeArea];
       }
       
       _cancelButton.translatesAutoresizingMaskIntoConstraints = false;
       [_cancelButton.widthAnchor constraintEqualToConstant:buttonWidth].active = YES;
       [_cancelButton.heightAnchor constraintEqualToConstant:buttonHeight].active = YES;
       [_cancelButton.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:0].active = YES;
       [_cancelButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:0].active = YES;
       
       _importButton.translatesAutoresizingMaskIntoConstraints = false;
       [_importButton.widthAnchor constraintEqualToConstant:buttonWidth].active = YES;
       [_importButton.heightAnchor constraintEqualToConstant:buttonHeight].active = YES;
       [_importButton.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:0].active = YES;
       [_importButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:0].active = YES;
       
       _titleView.translatesAutoresizingMaskIntoConstraints = false;
       [_titleView.widthAnchor constraintEqualToConstant:_titleView.frame.size.width].active = YES;
       [_titleView.heightAnchor constraintEqualToConstant:_titleView.frame.size.height].active = YES;
       [_titleView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor constant:0].active = YES;
       [_titleView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:0].active = YES;
       
       _headerView.translatesAutoresizingMaskIntoConstraints = false;
       [_headerView.bottomAnchor constraintEqualToAnchor:safeArea.topAnchor constant:buttonHeight].active = YES;
       [_headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0].active = YES;
       [_headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0].active = YES;
       [_headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
       
       _favoriteTableView.translatesAutoresizingMaskIntoConstraints = false;
       [_favoriteTableView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor].active = YES;
       [_favoriteTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0].active = YES;
       [_favoriteTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0].active = YES;
       [_favoriteTableView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:buttonHeight].active = YES;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.;
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
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];

        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        cell.titleIcon.image = favCol.cellIcon;
        cell.titleIcon.tintColor = favCol.color;
        
        cell.rightArrow.image = nil;
        cell.directionImageView.image = nil;
        cell.distanceView.hidden = YES;
        
        CGRect titleFrame = CGRectMake(cell.titleView.frame.origin.x, 15.0, cell.titleView.frame.size.width + 20.0, cell.titleView.frame.size.height);
        cell.titleView.frame = titleFrame;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
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
