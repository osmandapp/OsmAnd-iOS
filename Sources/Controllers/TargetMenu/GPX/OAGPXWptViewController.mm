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
#import "OACollapsableWaypointsView.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/GpxDocument.h>
#include "Localization.h"
#include "OARootViewController.h"
#include "OASelectedGPXHelper.h"


@implementation OAGPXWptViewController
{
    OsmAndAppInstance _app;
    NSString *_gpxFileName;
}

- (id) initWithItem:(OAGpxWptItem *)wpt headerOnly:(BOOL)headerOnly
{
    self = [super initWithItem:wpt];
    if (self)
    {
        _app = [OsmAndApp instance];
        if (!wpt.docPath)
        {
            wpt.docPath = [[OASelectedGPXHelper instance] getSelectedGpx:wpt.point].path;
        }
        self.wpt = wpt;

        if (!headerOnly)
        {
            [super setupCollapableViewsWithData:wpt lat:wpt.point.position.latitude lon:wpt.point.position.longitude];
        }

        self.groupTitle = self.wpt.docPath == nil ? OALocalizedString(@"track_recording_name") : [self.wpt.docPath.lastPathComponent stringByDeletingPathExtension];
        self.groupColor = self.wpt.color;
        
        self.name = [self getItemName];
        self.desc = [self getItemDesc];

        self.topToolbarType = ETopToolbarTypeMiddleFixed;
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation gpxFileName:(NSString *)gpxFileName
{
    self = [super initWithLocation:location andTitle:formattedLocation];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        _gpxFileName = gpxFileName;
        
        // Create wpt
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger defaultColor = 0;
        if ([userDefaults objectForKey:kWptDefaultColorKey])
            defaultColor = [userDefaults integerForKey:kWptDefaultColorKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        UIColor* color = favCol.color;

        NSString *groupName;
        if ([userDefaults objectForKey:kWptDefaultGroupKey])
            groupName = [userDefaults stringForKey:kWptDefaultGroupKey];
        
        OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
        OAWptPt* p = [[OAWptPt alloc] init];
        p.name = formattedLocation;
        p.position = location;
        p.type = groupName;
        p.time = (long)[[NSDate date] timeIntervalSince1970];
        wpt.point = p;
        wpt.color = color;
        
        self.wpt = wpt;
        
        self.topToolbarType = ETopToolbarTypeMiddleFixed;
        [super setupCollapableViewsWithData:wpt lat:wpt.point.position.latitude lon:wpt.point.position.longitude];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleGradient.frame = self.navBar.frame;
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        self.titleGradient.frame = self.navBar.frame;
    } completion:nil];
}

- (void) setupDeleteButtonIcon
{
    [self.deleteButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
}

- (NSString *) getGpxFileName
{
    return [[_gpxFileName lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"gpx_waypoint");
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportsForceClose
{
    return YES;
}

- (BOOL)shouldEnterContextModeManually
{
    return YES;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    if (self.newItem)
        self.titleView.text = OALocalizedString(@"add_waypoint_short");
    else
        self.titleView.text = OALocalizedString(@"edit_waypoint_short");
}

- (BOOL) isItemExists:(NSString *)name
{
    return NO;
}

-(BOOL) preHide
{
    if (self.newItem && !self.actionButtonPressed)
        return NO;
    else
        return [super preHide];
}

- (void) okPressed
{
    if (self.savedColorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:self.savedColorIndex forKey:kWptDefaultColorKey];
    if (self.savedGroupName)
        [[NSUserDefaults standardUserDefaults] setObject:self.savedGroupName forKey:kWptDefaultGroupKey];
    
    [super okPressed];
}

-(BOOL) supportEditing
{
    return YES;//![self.wpt.point isKindOfClass:[OAGpxRoutePoint class]];
}

-(void)activateEditing
{
    [[OARootViewController instance].mapPanel targetPointEditWaypoint:self.wpt];
}

-(void) deleteItem
{
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        [_mapViewController deleteFoundWpt];
        
        if (self.delegate)
            [self.delegate btnDeletePressed];

    }],
      nil] show];
}

- (void) saveItemToStorage
{
    if (self.wpt.point.wpt != nullptr)
    {
        [OAGPXDocument fillWpt:self.wpt.point.wpt usingWpt:self.wpt.point];
        [_mapViewController saveFoundWpt];
        
        if (self.wptDelegate && [self.wptDelegate respondsToSelector:@selector(changedWptItem)])
            [self.wptDelegate changedWptItem];
    }
}

- (void) removeExistingItemFromCollection
{
}

- (void) removeNewItemFromCollection
{
    [_mapViewController deleteFoundWpt];
    
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (NSString *) getItemName
{
    return self.wpt.point.name;
}

- (void) setItemName:(NSString *)name
{
    self.wpt.point.name = name;
}

- (UIColor *) getItemColor
{
    return self.wpt.color ? self.wpt.color : ((OAFavoriteColor *) OADefaultFavorite.builtinColors.firstObject).color;
}

- (void) setItemColor:(UIColor *)color
{
    self.wpt.color = color;
    [self saveItemToStorage];
}

- (NSString *) getItemGroup
{
    return (self.wpt.point.type ? self.wpt.point.type : @"");
}

- (void) setItemGroup:(NSString *)groupName
{
    self.wpt.point.type = groupName;
    [self saveItemToStorage];
   
    if (![self.wpt.groups containsObject:groupName] && groupName.length > 0)
        self.wpt.groups = [self.wpt.groups arrayByAddingObject:groupName];
}

- (NSArray *) getItemGroups
{
    return self.wpt.groups;
}

- (NSString *) getItemDesc
{
    return self.wpt.point.desc;
}

- (void) setItemDesc:(NSString *)desc
{
    self.wpt.point.desc = desc;
}

- (NSDate *) getTimestamp
{
    long timestamp = self.wpt.point.time;
    if (timestamp > 0)
        return [NSDate dateWithTimeIntervalSince1970:timestamp];
    else
        return nil;
}

@end
