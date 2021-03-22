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
#import "OAFavoritesHelper.h"
#import "OADefaultFavorite.h"
#import "OATargetInfoViewController.h"
#import "OAColors.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define kAlertConflictWarning -2
#define kAlertConflictRename -4

@interface OAFavoriteImportViewController ()
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> _favoritesCollection;
    NSURL *_url;
}

@property (strong, nonatomic) NSMutableArray<OAFavoriteGroup *> *groupsAndFavorites;

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

- (BOOL)isFavoritesValid
{
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
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
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

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"fav_import_title");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_importButton setTitle:OALocalizedString(@"fav_import") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.ignoredNames = [[NSMutableArray alloc] init];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self generateData];
    [self setupView];
    
    [super viewWillAppear:animated];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _favoriteTableView;
}

- (void) generateData
{
    self.groupsAndFavorites = [[NSMutableArray alloc] init];

    const auto allFavorites = _favoritesCollection->getFavoriteLocations();
    [self.groupsAndFavorites addObjectsFromArray:[OAFavoritesHelper getGroupedFavorites:allFavorites]];
    [self.favoriteTableView reloadData];
}

-(void) setupView
{
    [self applySafeAreaMargins];
    [self.favoriteTableView setDataSource:self];
    [self.favoriteTableView setDelegate:self];
    self.favoriteTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.favoriteTableView reloadData];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) importClicked:(id)sender
{
    if (_favoritesCollection) {
        // IOS-214
        if (![self isFavoritesValid])
            return;
        
        _app.favoritesCollection->mergeFrom(_favoritesCollection);
        [OAFavoritesHelper import:_favoritesCollection->getFavoriteLocations()];
        [_app saveFavoritesToPermamentStorage];
        [self.ignoredNames removeAllObjects];
        self.conflictedName = @"";
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction) cancelClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self getUnsortedNumberOfSectionsInTableView];
}

- (NSInteger) getUnsortedNumberOfSectionsInTableView
{
    return [self.groupsAndFavorites count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    OAFavoriteGroup *group = [self.groupsAndFavorites objectAtIndex:section];
    return [OAFavoriteGroup getDisplayName:group.name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((OAFavoriteGroup*)[self.groupsAndFavorites objectAtIndex:section]).points count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*) getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAFavoriteGroup* groupData = [self.groupsAndFavorites objectAtIndex:indexPath.section];
    
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
        OAFavoriteItem* item = [groupData.points objectAtIndex:indexPath.row];
        [cell.titleView setText:item.favorite->getTitle().toNSString()];
        
        cell.rightArrow.image = nil;
        cell.directionImageView.image = nil;
        cell.distanceView.hidden = YES;
        
        CGRect titleFrame = CGRectMake(cell.titleView.frame.origin.x, 15.0, cell.titleView.frame.size.width + 20.0, cell.titleView.frame.size.height);
        cell.titleView.frame = titleFrame;
        
        [cell.distanceView setText:item.distance];
        cell.directionImageView.image = [[UIImage imageNamed:@"ic_small_direction"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        
        UIColor* color = [item getColor];
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        
        NSString *backgroundName = [item getBackgroundIcon];
        if(!backgroundName || backgroundName.length == 0)
            backgroundName = @"circle";
        backgroundName = [NSString stringWithFormat:@"bg_point_%@", backgroundName];
        UIImage *backroundImage = [UIImage imageNamed:backgroundName];
        cell.titleIcon.image = [backroundImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.titleIcon.tintColor = favCol.color;
        
        NSString *iconName = [item getIcon];
        if(!iconName || iconName.length == 0)
            iconName = @"special_star";
        UIImage *poiImage = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:iconName]];
        cell.titlePoiIcon.image = [poiImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.titlePoiIcon.tintColor = UIColor.whiteColor;
        cell.titlePoiIcon.hidden = NO;
    }
    return cell;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
