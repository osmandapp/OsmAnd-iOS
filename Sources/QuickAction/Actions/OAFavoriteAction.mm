//
//  OAFavoriteAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAFavoriteAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OAFavoriteViewController.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define KEY_NAME @"name"
#define KEY_DIALOG @"dialog"
#define KEY_CATEGORY_NAME @"category_name"
#define KEY_CATEGORY_COLOR @"category_color"

@implementation OAFavoriteAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeFavorite];
}

- (void)execute
{
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
    NSString *title = self.getParams[KEY_NAME];
    if (!title || title.length == 0)
        title = [[OAReverseGeocoder instance] lookupAddressAtLat:latLon.latitude lon:latLon.longitude];
    
    [self addFavorite:latLon.latitude lon:latLon.longitude title:title autoFill:![self.getParams[KEY_DIALOG] boolValue]];
}

- (void)addFavoriteWithDialog:(double)lat lon:(double)lon title:(NSString *)title {
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
    [mapPanel targetPointAddFavorite];
}

- (void) addFavorite:(double)lat lon:(double)lon title:(NSString *)title autoFill:(BOOL)autoFill
{
    if (autoFill)
        [self addFavoriteSilent:lat lon:lon title:title];
    else
        [self addFavoriteWithDialog:lat lon:lon title:title];
}

- (void) addFavoriteSilent:(double)lat lon:(double)lon title:(NSString *)title
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAFavoriteItem *fav = [[OAFavoriteItem alloc] init];
    NSString *groupName = self.getParams[KEY_CATEGORY_NAME];
    NSString *colorStr = self.getParams[KEY_CATEGORY_COLOR];
    UIColor* color_;
    if (colorStr && colorStr.length > 0)
    {
        color_ = UIColorFromRGB([colorStr longLongValue]);
    }
    else
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        color_ = favCol.color;
    }
    CGFloat r,g,b,a;
    [color_ getRed:&r
             green:&g
              blue:&b
             alpha:&a];
    
    if ([self isItemExists:title])
        title = [self getNewItemName:title];
    
    QString titleStr = QString::fromNSString(title);
    QString group = QString::fromNSString(groupName ? groupName : @"");
    fav.favorite = app.favoritesCollection->createFavoriteLocation(OsmAnd::LatLon(lat, lon), titleStr, group, OsmAnd::FColorRGB(r,g,b));
    
    [app saveFavoritesToPermamentStorage];
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
