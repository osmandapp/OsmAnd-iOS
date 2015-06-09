//
//  OAGPXWptViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXWptViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OADefaultFavorite.h"
#import <UIAlertView+Blocks.h>
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAMapViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@implementation OAGPXWptViewController
{
    OsmAndAppInstance _app;
}

- (id)initWithItem:(OAGpxWptItem *)wpt
{
    self = [super initWithItem:wpt];
    if (self)
    {
        _app = [OsmAndApp instance];
        self.wpt = wpt;
        
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
        
        // Create wpt
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        int defaultColor = 0;
        if ([userDefaults objectForKey:kWptDefaultColorKey])
            defaultColor = [userDefaults integerForKey:kWptDefaultColorKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        UIColor* color = favCol.color;

        NSString *groupName;
        if ([userDefaults objectForKey:kWptDefaultGroupKey])
            groupName = [userDefaults stringForKey:kWptDefaultGroupKey];
        
        OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
        OAGpxWpt* p = [[OAGpxWpt alloc] init];
        p.name = formattedLocation;
        p.position = location;
        p.type = groupName;
        wpt.point = p;
        wpt.color = color;
        self.wpt = wpt;
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"gpx_point");
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowFavorites:YES];
}

- (BOOL) isItemExists:(NSString *)name
{
    return NO;
}

- (void)okPressed
{
    if (self.savedColorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:self.savedColorIndex forKey:kWptDefaultColorKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.savedGroupName forKey:kWptDefaultGroupKey];
    
    [super okPressed];
}

-(void)deleteItem
{
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        [_mapViewController deleteFoundWpt];
        
    }],
      nil] show];
}

- (void)saveItemToStorage
{
    [OAGPXDocument fillWpt:self.wpt.point.wpt usingWpt:self.wpt.point];
    [_mapViewController saveFoundWpt];
    
    if (self.wptDelegate && [self.wptDelegate respondsToSelector:@selector(changedWptItem)])
        [self.wptDelegate changedWptItem];
}

- (void)removeExistingItemFromCollection
{
}

- (void)removeNewItemFromCollection
{
}

- (NSString *)getItemName
{
    return self.wpt.point.name;
}

- (void)setItemName:(NSString *)name
{
    self.wpt.point.name = name;
}

- (UIColor *)getItemColor
{
    return self.wpt.color;
}

- (void)setItemColor:(UIColor *)color
{
    self.wpt.color = color;
    [self saveItemToStorage];
}

- (NSString *)getItemGroup
{
    return self.wpt.point.type;
}

- (void)setItemGroup:(NSString *)groupName
{
    self.wpt.point.type = groupName;
}

- (NSArray *)getItemGroups
{
    // todo
    //return [[OANativeUtilities QListOfStringsToNSMutableArray:_app.favoritesCollection->getGroups().toList()] copy];
    return @[];
}

- (NSString *)getItemDesc
{
    return self.wpt.point.desc;
}

- (void)setItemDesc:(NSString *)desc
{
    self.wpt.point.desc = desc;
}

@end
