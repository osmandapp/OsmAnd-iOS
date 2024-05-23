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
#import "OAMapViewController.h"
#import "OAFavoritesHelper.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAReverseGeocoder.h"
#import "OsmAndApp.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OrderedDictionary.h"
#import "Localization.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kName = @"name";
static NSString * const kDialog = @"dialog";
static NSString * const kCategoryName = @"category_name";
static NSString * const kCategoryColor = @"category_color";

static OAQuickActionType *TYPE;

@implementation OAFavoriteAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    CLLocation *latLon = [self getMapLocation];
    NSString *title = self.getParams[kName];
    if (!title || title.length == 0)
        title = [[OAReverseGeocoder instance] lookupAddressAtLat:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
    
    [self addFavorite:latLon.coordinate.latitude lon:latLon.coordinate.longitude title:title autoFill:![self.getParams[kDialog] boolValue]];
}

- (void)addFavoriteWithDialog:(double)lat lon:(double)lon title:(NSString *)title {
    if (self.getParams[kCategoryColor])
        [[NSUserDefaults standardUserDefaults] setInteger:[self.getParams[kCategoryColor] integerValue] forKey:kFavoriteDefaultColorKey];
    if (self.getParams[kCategoryName])
        [[NSUserDefaults standardUserDefaults] setObject:self.getParams[kCategoryName] forKey:kFavoriteDefaultGroupKey];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    if ([OAFavoritesHelper hasFavoriteAt:point])
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
    NSString *groupName = self.getParams[kCategoryName] ? self.getParams[kCategoryName] : @"";
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

    if ([self isItemExists:title])
        title = [self getNewItemName:title];

    OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:title category:groupName];
    [point setColor:color];
    [OAFavoritesHelper addFavorite:point];
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
            {
                [params setValue:item[@"value"] forKey:kDialog];
            }
            else if ([item[@"key"] isEqualToString:kName])
            {
                [params setValue:item[@"title"] forKey:kName];
            }
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

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsFavoriteActionId stringId:@"fav.add" cl:self.class] name:OALocalizedString(@"ctx_mnu_add_fav")] iconName:@"ic_custom_favorites"] secondaryIconName:@"ic_custom_compound_action_add"] category:EOAQuickActionTypeCategoryCreateCategory];
    return TYPE;
}

@end
