//
//  OAGPXAction.m
//  OsmAnd
//
//  Created by Paul on 8/8/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAGPXAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OAFavoriteViewController.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"

#include <OsmAndCore/Utilities.h>

#define KEY_NAME @"name"
#define KEY_DIALOG @"dialog"
#define KEY_CATEGORY_NAME @"category_name"
#define KEY_CATEGORY_COLOR @"category_color"

@implementation OAGPXAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeGPX];
}

- (void)execute
{
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
    NSString *title = self.getParams[KEY_NAME];
    if (!title || title.length == 0)
        title = [[OAReverseGeocoder instance] lookupAddressAtLat:latLon.latitude lon:latLon.longitude];
    
    [self addWaypoint:latLon.latitude lon:latLon.longitude title:title autoFill:![self.getParams[KEY_DIALOG] boolValue]];
}

- (void) addWaypoint:(double)lat lon:(double)lon title:(NSString *)title autoFill:(BOOL)autoFill
{
    if (autoFill)
        [self addWaypointSilent:lat lon:lon title:title];
    else
        [self addWaypointWithDialog:lat lon:lon title:title];
}

- (void)addWaypointWithDialog:(double)lat lon:(double)lon title:(NSString *)title
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    if ([mapVC hasFavoriteAt:point])
        return;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.title = title;
    targetPoint.type = OATargetFavorite;
    targetPoint.location = point;
    
    [mapPanel showContextMenu:targetPoint];
    [mapPanel targetPointAddWaypoint];
}

- (void) addWaypointSilent:(double)lat lon:(double)lon title:(NSString *)title
{
    NSString *groupName = self.getParams[KEY_CATEGORY_NAME];
    NSString *colorStr = self.getParams[KEY_CATEGORY_COLOR];
    UIColor* color;
    if (colorStr && colorStr.length > 0)
    {
        color = UIColorFromRGB([colorStr longLongValue]);
    }
    else
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        color = favCol.color;
    }
    
    OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
    OAGpxWpt* p = [[OAGpxWpt alloc] init];
    p.name = title;
    p.position = CLLocationCoordinate2DMake(lat, lon);
    p.type = groupName;
    p.time = (long)[[NSDate date] timeIntervalSince1970];
    wpt.point = p;
    wpt.color = color;
    
    if (wpt.point.wpt != nullptr)
    {
        [OAGPXDocument fillWpt:wpt.point.wpt usingWpt:wpt.point];
        [[OARootViewController instance].mapPanel.mapViewController saveFoundWpt];
    }
}

- (BOOL) isItemExists:(NSString *)name
{
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
        if ([name isEqualToString:localFavorite->getTitle().toNSString()])
        {
            return YES;
        }
    
    return NO;
}

- (NSString *) getNewItemName:(NSString *)name
{
    NSString *newName;
    for (int i = 2; i < 100000; i++) {
        newName = [NSString stringWithFormat:@"%@ (%d)", name, i];
        if (![self isItemExists:newName])
            break;
    }
    return newName;
}

@end
