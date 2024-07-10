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
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAFavoritesHelper.h"
#import "OrderedDictionary.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kName = @"name";
static NSString * const kCategoryName = @"category_name";
static NSString * const kCategoryColor =  @"category_color";

static QuickActionType *TYPE;

@implementation OAGPXAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsGpxActionId
                                            stringId:@"gpx.add"
                                                  cl:self.class]
               name:OALocalizedString(@"add_gpx_waypoint")]
              iconName:@"ic_custom_favorites"]
             secondaryIconName:@"ic_custom_compound_action_add"]
            category:QuickActionTypeCategoryCreateCategory];
}

- (void)execute
{
    CLLocation *latLon = [self getMapLocation];
    NSString *title = self.getParams[kName];
    if (!title || title.length == 0)
        title = [[OAReverseGeocoder instance] lookupAddressAtLat:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
    
    [self addWaypoint:latLon.coordinate.latitude lon:latLon.coordinate.longitude title:title autoFill:![self.getParams[kDialog] boolValue]];
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
    if (self.getParams[kCategoryColor])
        [[NSUserDefaults standardUserDefaults] setInteger:[self.getParams[kCategoryColor] integerValue] forKey:kFavoriteDefaultColorKey];
    if (self.getParams[kCategoryName])
        [[NSUserDefaults standardUserDefaults] setObject:self.getParams[kCategoryName] forKey:kFavoriteDefaultGroupKey];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    if ([OAFavoritesHelper hasFavoriteAt:point])
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
    NSString *groupName = self.getParams[kCategoryName];
    UIColor* color;
    if (self.getParams[kCategoryColor])
    {
        NSInteger defaultColor = [OADefaultFavorite getValidBuiltInColorNumber:[self.getParams[kCategoryColor] integerValue]];
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
    for (OAFavoriteItem *point in [OAFavoritesHelper getFavoriteItems])
    {
        if ([name isEqualToString:[point getName]])
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
                          @"key" : kDialog,
                          @"title" : OALocalizedString(@"quick_action_interim_dialog"),
                          @"value" : @([self.getParams[kDialog] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"shared_string_options")];
    [data setObject:@[@{
                          @"type" : [OAInputTableViewCell getCellIdentifier],
                          @"key" : kName,
                          @"title" : self.getParams[kName] ? self.getParams[kName] : @"",
                          @"hint" : OALocalizedString(@"quick_action_template_name"),
                          @"img" : @"ic_custom_text_field_name"
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_fav_name_descr")
                          }
                      ] forKey:kSectionNoName];
    
    NSInteger defaultColor = [OADefaultFavorite getValidBuiltInColorNumber:[self.getParams[kCategoryColor] integerValue]];
    OAFavoriteColor *color = [OADefaultFavorite builtinColors][defaultColor];
    
    [data setObject:@[@{
                          @"type" : [OAValueTableViewCell getCellIdentifier],
                          @"key" : kCategoryName,
                          @"title" : OALocalizedString(@"fav_group"),
                          @"value" : self.getParams[kCategoryName] ? self.getParams[kCategoryName] : OALocalizedString(@"favorites_item"),
                          @"color" : @(defaultColor),
                          @"img" : @"ic_custom_folder"
                          },
                      @{
                          @"type" : [OAValueTableViewCell getCellIdentifier],
                          @"key" : kCategoryColor,
                          @"title" : OALocalizedString(@"shared_string_color"),
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
            if ([item[@"key"] isEqualToString:kDialog])
                [params setValue:item[@"value"] forKey:kDialog];
            else if ([item[@"key"] isEqualToString:kName])
                [params setValue:item[@"title"] forKey:kName];
            else if ([item[@"key"] isEqualToString:kCategoryName])
            {
                [params setValue:item[@"value"] forKey:kCategoryName];
                [params setValue:item[@"color"] forKey:kCategoryColor];
            }
        }
    }
    self.params = [NSDictionary dictionaryWithDictionary:params];
    return YES;
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
