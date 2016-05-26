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
#import "OAUtilities.h"
#import <UIAlertView+Blocks.h>

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@implementation OAFavoriteViewController
{
    OsmAndAppInstance _app;
}

- (id)initWithItem:(OAFavoriteItem *)favorite
{
    self = [super initWithItem:favorite];
    if (self)
    {
        _app = [OsmAndApp instance];
        self.favorite = favorite;

        self.name = [self getItemName];
        self.desc = [self getItemDesc];
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation
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
        NSInteger defaultColor = 0;
        if ([userDefaults objectForKey:kFavoriteDefaultColorKey])
            defaultColor = [userDefaults integerForKey:kFavoriteDefaultColorKey];
        
        NSString *groupName;
        if ([userDefaults objectForKey:kFavoriteDefaultGroupKey])
            groupName = [userDefaults stringForKey:kFavoriteDefaultGroupKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        
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
        
        OAFavoriteItem* fav = [[OAFavoriteItem alloc] init];
        fav.favorite = _app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                       title,
                                                                       group,
                                                                       OsmAnd::FColorRGB(r,g,b));
        self.favorite = fav;
        [_app saveFavoritesToPermamentStorage];
    }
    return self;
}

-(BOOL)needAddress
{
    return NO;
}

- (NSString *)getTypeStr
{
    NSString *group = [self getItemGroup];
    if (group.length > 0)
    {
        return group;
    }
    else
    {
        return [self getCommonTypeStr];
    }
}

- (NSString *)getCommonTypeStr
{
    return OALocalizedString(@"favorite");
}

- (NSAttributedString *)getAttributedTypeStr
{
    return [self getAttributedTypeStr:[self getTypeStr]];
}

- (NSAttributedString *)getAttributedCommonTypeStr
{
    return [self getAttributedTypeStr:[self getCommonTypeStr]];
}

- (NSAttributedString *)getAttributedTypeStr:(NSString *)group
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    NSMutableAttributedString *stringGroup = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", group]];
    NSTextAttachment *groupAttachment = [[NSTextAttachment alloc] init];
    groupAttachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_small_group.png"] color:UIColorFromRGB(0x727272)];
    
    NSAttributedString *groupStringWithImage = [NSAttributedString attributedStringWithAttachment:groupAttachment];
    [stringGroup replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:groupStringWithImage];
    [stringGroup addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    
    [string appendAttributedString:stringGroup];

    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    return string;
}

- (void)applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"favorite");
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowFavorites:YES];
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

-(BOOL)preHide
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

- (void)okPressed
{
    if (self.savedColorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:self.savedColorIndex forKey:kFavoriteDefaultColorKey];
    if (self.savedGroupName)
        [[NSUserDefaults standardUserDefaults] setObject:self.savedGroupName forKey:kFavoriteDefaultGroupKey];
    
    [super okPressed];
}

-(void)deleteItem
{
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        
    }],
      nil] show];
}

- (void)saveItemToStorage
{
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
}

- (void)removeExistingItemFromCollection
{
    NSString *favoriteTitle = self.favorite.favorite->getTitle().toNSString();
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

- (void)removeNewItemFromCollection
{
    _app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
    [_app saveFavoritesToPermamentStorage];
}

- (NSString *)getItemName
{
    if (!self.favorite.favorite->getTitle().isNull())
    {
        return self.favorite.favorite->getTitle().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void)setItemName:(NSString *)name
{
    self.favorite.favorite->setTitle(QString::fromNSString(name));
}

- (UIColor *)getItemColor
{
    return [UIColor colorWithRed:self.favorite.favorite->getColor().r/255.0 green:self.favorite.favorite->getColor().g/255.0 blue:self.favorite.favorite->getColor().b/255.0 alpha:1.0];
}

- (void)setItemColor:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r
            green:&g
             blue:&b
            alpha:&a];
    
    self.favorite.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
}

- (NSString *)getItemGroup
{
    if (!self.favorite.favorite->getGroup().isNull())
    {
        return self.favorite.favorite->getGroup().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void)setItemGroup:(NSString *)groupName
{
    self.favorite.favorite->setGroup(QString::fromNSString(groupName));
}

- (NSArray *)getItemGroups
{
    return [[OANativeUtilities QListOfStringsToNSMutableArray:_app.favoritesCollection->getGroups().toList()] copy];
}

- (NSString *)getItemDesc
{
    if (!self.favorite.favorite->getDescription().isNull())
    {
        return self.favorite.favorite->getDescription().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void)setItemDesc:(NSString *)desc
{
    self.favorite.favorite->setDescription(QString::fromNSString(desc));
}

@end
