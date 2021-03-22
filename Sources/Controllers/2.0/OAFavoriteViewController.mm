//
//  OAFavoriteViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAFavoriteViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"
#import "OAFavoritesHelper.h"
#import "OAUtilities.h"
#import "OACollapsableView.h"
#import "OACollapsableWaypointsView.h"
#import <UIAlertView+Blocks.h>

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

@implementation OAFavoriteViewController
{
    OsmAndAppInstance _app;
}

- (id) initWithItem:(OAFavoriteItem *)favorite headerOnly:(BOOL)headerOnly
{
    self = [super initWithItem:favorite];
    if (self)
    {
        _app = [OsmAndApp instance];
        self.favorite = favorite;

        self.name = [self getItemName];
        self.desc = [self getItemDesc];
        
        if (!headerOnly)
        {
            [super setupCollapableViewsWithData:favorite lat:favorite.getLatitude lon:favorite.getLongitude];
        }
        
        self.groupTitle = [self.favorite getFavoriteGroupDisplayName];
        
        if (!OAFavoritesHelper.isFavoritesLoaded)
            [OAFavoritesHelper loadFavorites];
        
        OAFavoriteGroup *favoriteGroup = [OAFavoritesHelper getGroupByName:[self.favorite getFavoriteGroup]];
        self.groupColor = favoriteGroup.color;

        self.topToolbarType = ETopToolbarTypeMiddleFixed;
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation headerOnly:(BOOL)headerOnly
{
    self = [super initWithLocation:location andTitle:formattedLocation];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
        QString title = QString::fromNSString(formattedLocation);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *groupName;
        if ([userDefaults objectForKey:kFavoriteDefaultGroupKey])
            groupName = [userDefaults stringForKey:kFavoriteDefaultGroupKey];
        
        NSInteger defaultColor = [[userDefaults objectForKey:kFavoriteDefaultColorKey] integerValue];
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][[OADefaultFavorite getValidBuiltInColorNumber:defaultColor]];
        
        UIColor* color_ = favCol.color;
        CGFloat r,g,b,a;
        [color_ getRed:&r
                 green:&g
                  blue:&b
                 alpha:&a];
        
        QString group;
        if (groupName)
            group = QString::fromNSString(groupName);
        else
            group = QString::null;
        
        QString description = QString::null;
        QString address = QString::null;
        QString icon = QString::null;
        QString background = QString::null;

        auto favorite = _app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                        title,
                                                                        description,
                                                                        address,
                                                                        group,
                                                                        icon,
                                                                        background,
                                                                        OsmAnd::FColorRGB(r,g,b));
        
        OAFavoriteItem* fav = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        
        self.favorite = fav;
        [_app saveFavoritesToPermamentStorage];
        
        if (!headerOnly)
        {
            [super setupCollapableViewsWithData:fav lat:location.latitude lon:location.longitude];
        }
        
        self.groupTitle = [self.favorite getFavoriteGroupDisplayName];
        
        if (!OAFavoritesHelper.isFavoritesLoaded)
            [OAFavoritesHelper loadFavorites];
        
        OAFavoriteGroup *favoriteGroup = [OAFavoritesHelper getGroupByName:[self.favorite getFavoriteGroup]];
        self.groupColor = favoriteGroup.color;

        self.topToolbarType = ETopToolbarTypeMiddleFixed;
    }
    return self;

}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportsForceClose
{
    return YES;
}

- (BOOL)shouldEnterContextModeManually
{
    return YES;
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"favorites");
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"favorites");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    [settings setShowFavorites:YES];
    self.titleGradient.frame = self.navBar.frame;
    self.deleteButton.hidden = YES;
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        self.titleGradient.frame = self.navBar.frame;
    } completion:nil];
}

- (BOOL) isItemExists:(NSString *)name
{
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
        if ((localFavorite != self.favorite.favorite) &&
            [name isEqualToString:localFavorite->getTitle().toNSString()])
        {
            return YES;
        }
    
    return NO;
}

-(BOOL) preHide
{
    if (self.newItem && !self.actionButtonPressed)
    {
        [self removeNewItemFromCollection];
        return YES;
    }
    else
    {
        return [super preHide];
    }
}

- (void) okPressed
{
    if (self.savedColorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:self.savedColorIndex forKey:kFavoriteDefaultColorKey];
    if (self.savedGroupName)
        [[NSUserDefaults standardUserDefaults] setObject:self.savedGroupName forKey:kFavoriteDefaultGroupKey];
    
    [super okPressed];
}

-(void) deleteItem
{
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        
    }],
      nil] show];
}

- (void) saveItemToStorage
{
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
}

- (void) removeExistingItemFromCollection
{
    NSString *favoriteTitle = [self.favorite getFavoriteName];
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
    {
        if ((localFavorite != self.favorite.favorite) &&
            [favoriteTitle isEqualToString:localFavorite->getTitle().toNSString()])
        {
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(localFavorite);
            break;
        }
    }
}

- (void) removeNewItemFromCollection
{
    _app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
    [_app saveFavoritesToPermamentStorage];
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    return [self getAttributedTypeStr:group color:self.groupColor];
}

- (NSString *) getItemName
{
    return [self.favorite getDisplayName];
}

- (NSString *) getItemGroup
{
    return [self.favorite getFavoriteGroupDisplayName];
}

- (NSString *) getItemDesc
{
    return [self.favorite getFavoriteDesc];
}

- (UIImage *) getIcon
{
    NSString *poiIconName = [self.favorite getFavoriteIcon];
    if (!poiIconName || [poiIconName isEqualToString:@""])
        poiIconName = @"mm_special_star";
    else
        poiIconName = [NSString stringWithFormat:@"mm_%@", poiIconName];
    UIImage *poiIcon = [UIImage imageNamed:[OAUtilities drawablePath:poiIconName]];
    return poiIcon;
}

- (UIImage *) getBackgroundIcon
{
    NSDictionary *icons = @{
        @"circle" : @"bg_point_circle",
        @"octagon" : @"bg_point_octagon",
        @"square" : @"bg_point_square",
    };
    
    NSString *selectedIcon = [self.favorite getFavoriteBackground];
    if (!selectedIcon || [selectedIcon isEqualToString:@""])
        selectedIcon = @"circle";
    NSString *poiBackgroundIconName = icons[selectedIcon];
    UIImage *backroundImage = [UIImage imageNamed:poiBackgroundIconName];
    return backroundImage;
}

@end
