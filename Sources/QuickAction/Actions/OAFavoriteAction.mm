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
#import "OrderedDictionary.h"
#import "Localization.h"
#import "OAQuickActionType.h"
#import "OAIconTitleValueCell.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define KEY_NAME @"name"
#define KEY_DIALOG @"dialog"
#define KEY_CATEGORY_NAME @"category_name"
#define KEY_CATEGORY_COLOR @"category_color"

static OAQuickActionType *TYPE;

@implementation OAFavoriteAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
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
    if (self.getParams[KEY_CATEGORY_COLOR])
        [[NSUserDefaults standardUserDefaults] setInteger:[self.getParams[KEY_CATEGORY_COLOR] integerValue] forKey:kFavoriteDefaultColorKey];
    if (self.getParams[KEY_CATEGORY_NAME])
        [[NSUserDefaults standardUserDefaults] setObject:self.getParams[KEY_CATEGORY_NAME] forKey:kFavoriteDefaultGroupKey];
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
    NSString *groupName = self.getParams[KEY_CATEGORY_NAME];
    UIColor* color;
    if (self.getParams[KEY_CATEGORY_COLOR])
    {
        NSInteger defaultColor = [OADefaultFavorite getValidBuiltInColorNumber:[self.getParams[KEY_CATEGORY_COLOR] integerValue]];
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        color = favCol.color;
    }
    else
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        color = favCol.color;
    }
    CGFloat r,g,b,a;
    [color getRed:&r
             green:&g
              blue:&b
             alpha:&a];
    
    if ([self isItemExists:title])
        title = [self getNewItemName:title];
    
    QString elevation = QString::null;
    QString time = QString::fromNSString([OAFavoriteItem toStringDate:[NSDate date]]);
    
    QString titleStr = QString::fromNSString(title);
    QString group = QString::fromNSString(groupName ? groupName : @"");
    QString description = QString::null;
    QString address = QString::null;
    QString icon = QString::null;
    QString background = QString::null;
    
    auto favorite = app.favoritesCollection->createFavoriteLocation(OsmAnd::LatLon(lat, lon), elevation, time, titleStr, description, address, group, icon, background, OsmAnd::FColorRGB(r,g,b));
    OAFavoriteItem *fav = [[OAFavoriteItem alloc] initWithFavorite:favorite];
    
    [app saveFavoritesToPermamentStorage];
}

- (BOOL) isItemExists:(NSString *)name
{
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
    {
        if ([name isEqualToString:localFavorite->getTitle().toNSString()])
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

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"shared_string_options")];
    [data setObject:@[@{
                          @"type" : @"OATextInputIconCell",
                          @"key" : KEY_NAME,
                          @"title" : self.getParams[KEY_NAME] ? self.getParams[KEY_NAME] : @"",
                          @"hint" : OALocalizedString(@"quick_action_template_name"),
                          @"img" : @"ic_custom_text_field_name"
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_name_footer")
                          }
                      ] forKey:kSectionNoName];
    
    NSInteger defaultColor = [OADefaultFavorite getValidBuiltInColorNumber:[self.getParams[KEY_CATEGORY_COLOR] integerValue]];
    OAFavoriteColor *color = [OADefaultFavorite builtinColors][defaultColor];
    
    [data setObject:@[@{
                          @"type" : [OAIconTitleValueCell getCellIdentifier],
                          @"key" : KEY_CATEGORY_NAME,
                          @"title" : OALocalizedString(@"fav_group"),
                          @"value" : self.getParams[KEY_CATEGORY_NAME] ? self.getParams[KEY_CATEGORY_NAME] : OALocalizedString(@"favorites"),
                          @"color" : @(defaultColor),
                          @"img" : @"ic_custom_folder"
                          },
                      @{
                          @"type" : [OAIconTitleValueCell getCellIdentifier],
                          @"key" : KEY_CATEGORY_COLOR,
                          @"title" : OALocalizedString(@"fav_color"),
                          @"value" : color ? color.name : @"",
                          @"color" : @(defaultColor)
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_select_group")
                          }
                      ] forKey:[NSString stringWithFormat:@"%@_1", kSectionNoName]];
    
    return [OrderedDictionary dictionaryWithDictionary:data];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            else if ([item[@"key"] isEqualToString:KEY_NAME])
                [params setValue:item[@"title"] forKey:KEY_NAME];
            else if ([item[@"key"] isEqualToString:KEY_CATEGORY_NAME])
            {
                [params setValue:item[@"value"] forKey:KEY_CATEGORY_NAME];
                [params setValue:item[@"color"] forKey:KEY_CATEGORY_COLOR];
            }
        }
    }
    self.params = [NSDictionary dictionaryWithDictionary:params];
    return YES;
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:3 stringId:@"fav.add" class:self.class name:OALocalizedString(@"ctx_mnu_add_fav") category:CREATE_CATEGORY iconName:@"ic_custom_favorites" secondaryIconName:@"ic_custom_compound_action_add"];
       
    return TYPE;
}

@end
