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
#import "OAGPXDatabase.h"
#import "OAQuickActionType.h"
#import "OAIconTitleValueCell.h"
#import "OASwitchTableViewCell.h"
#import "OATextInputIconCell.h"

#include <OsmAndCore/Utilities.h>

#define KEY_NAME @"name"
#define KEY_DIALOG @"dialog"
#define KEY_CATEGORY_NAME @"category_name"
#define KEY_CATEGORY_COLOR @"category_color"

static OAQuickActionType *TYPE;

@implementation OAGPXAction

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
    [mapPanel targetPointAddWaypoint];
}

- (void) addWaypointSilent:(double)lat lon:(double)lon title:(NSString *)title
{
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
    
    OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
    OAWptPt* p = [[OAWptPt alloc] init];
    p.name = title;
    p.position = CLLocationCoordinate2DMake(lat, lon);
    p.type = groupName;
    p.time = (long)[[NSDate date] timeIntervalSince1970];
    p.wpt = std::make_shared<OsmAnd::GpxDocument::WptPt>();
    wpt.point = p;
    wpt.color = color;
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    [mapVC addNewWpt:wpt.point gpxFileName:nil];
    wpt.groups = mapVC.foundWptGroups;
    if (wpt.point.wpt != nullptr)
    {
        [OAGPXDocument fillWpt:wpt.point.wpt usingWpt:wpt.point];
        mapVC.foundWpt = p;
        [mapVC saveFoundWpt];
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

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : [OASwitchTableViewCell getCellIdentifier],
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"shared_string_options")];
    [data setObject:@[@{
                          @"type" : [OATextInputIconCell getCellIdentifier],
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
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:6 stringId:@"gpx.add" class:self.class name:OALocalizedString(@"add_gpx_waypoint") category:CREATE_CATEGORY iconName:@"ic_custom_favorites" secondaryIconName:@"ic_custom_compound_action_add"];
       
    return TYPE;
}

@end
