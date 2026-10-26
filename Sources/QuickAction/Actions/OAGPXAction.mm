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
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAFavoritesHelper.h"
#import "OrderedDictionary.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

static QuickActionType *TYPE;

@implementation OAGPXAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsGpxActionId
                                            stringId:@"gpx.add"
                                                  cl:self.class]
                 name:OALocalizedString(@"quick_action_track_waypoint")]
                nameAction:OALocalizedString(@"shared_string_add")]
               iconName:ACImageNameIcCustomFavorites]
              secondaryIconName:ACImageNameIcCustomCompoundActionAdd]
             category:QuickActionTypeCategoryMyPlaces]
            forceUseExtendedName];
}

- (void)execute
{
    CLLocation *latLon = [self getMapLocation];
    NSString *title = self.getParams[kName];
    BOOL autoFill = ![self.getParams[kDialog] boolValue];
    if (title.length > 0)
    {
        [self addWaypoint:latLon.coordinate.latitude lon:latLon.coordinate.longitude title:title autoFill:autoFill];
        return;
    }

    [OAReverseGeocoder.instance lookupAddressAtLat:latLon.coordinate.latitude
                                               lon:latLon.coordinate.longitude
                                          objectId:0
                                        completion:^(NSString *address) {
        [self addWaypoint:latLon.coordinate.latitude lon:latLon.coordinate.longitude title:address autoFill:autoFill];
    }];
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
    CLLocationCoordinate2D point = CLLocationCoordinate2DMake(lat, lon);
    if ([OAFavoritesHelper hasFavoriteAt:point])
        return;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.title = title;
    targetPoint.type = OATargetFavorite;
    targetPoint.location = point;
    targetPoint.values = @{[self getActionTypeId] : self.getParams};
    [mapPanel showContextMenu:targetPoint];
    [mapPanel targetPointAddWaypoint];
}

- (void) addWaypointSilent:(double)lat lon:(double)lon title:(NSString *)title
{
    NSString *groupName = [[OAFavoriteGroup convertDisplayNameToGroupIdName:self.getParams[kCategoryName] ?: @""] trim];
    if ([groupName isEqualToString:OALocalizedString(@"shared_string_waypoints")])
        groupName = @"";

    UIColor *color = self.getParams[kWptColor] ? UIColorFromARGB([self.getParams[kWptColor] intValue]) : [OADefaultFavorite getColorFromBuiltInNumberOrARGB:[self.getParams[kCategoryColor] integerValue]];

    OASGpxUtilitiesPointsGroup *group = [OASavingTrackHelper sharedInstance].currentTrack.pointsGroups[groupName];
    if (group.color != 0)
        color = UIColorFromARGB(group.color);

    OAGpxWptItem* wpt = [[OAGpxWptItem alloc] init];
    OASWptPt *p = [[OASWptPt alloc] init];
    p.name = title;
    p.lat = lat;
    p.lon = lon;
    p.category = groupName;
    p.time = (long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSString *iconName = group.iconName.length > 0 ? group.iconName : self.getParams[kWptIcon];
    if (iconName.length > 0)
        [p setIconNameIconName:iconName];

    NSString *backgroundIconName = group.backgroundType.length > 0 ? group.backgroundType : self.getParams[kWptBackgroundType];
    if (backgroundIconName.length > 0)
        [p setBackgroundTypeBackType:backgroundIconName];

    wpt.point = p;
    wpt.color = color;
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapVC = mapPanel.mapViewController;
    [mapVC addNewWpt:wpt.point gpxFileName:nil];
    wpt.groups = mapVC.foundWptGroups;
    
    if (wpt.point)
    {
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
                          @"img" : ACImageNameIcCustomTextFieldName
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_fav_name_descr")
                          }
                      ] forKey:kSectionNoName];
    
    UIColor *color = self.getParams[kWptColor] ? UIColorFromARGB([self.getParams[kWptColor] intValue]) : [OADefaultFavorite getColorFromBuiltInNumberOrARGB:[self.getParams[kCategoryColor] integerValue]];
    NSMutableDictionary *appearanceRow = [@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"key" : kAppearance,
        @"title" : OALocalizedString(@"shared_string_appearance"),
        @"color" : @([color toARGBNumber])
    } mutableCopy];
    [appearanceRow setValue:(self.getParams[kWptColor] || self.getParams[kCategoryColor]) ? @([color toARGBNumber]) : nil forKey:kAppearanceColor];
    [appearanceRow setValue:self.getParams[kWptIcon] forKey:kAppearanceIcon];
    [appearanceRow setValue:self.getParams[kWptBackgroundType] forKey:kAppearanceBackground];
    
    [data setObject:@[@{
                          @"type" : [OAValueTableViewCell getCellIdentifier],
                          @"key" : kCategoryName,
                          @"title" : OALocalizedString(@"fav_group"),
                          @"value" : self.getParams[kCategoryName] ? self.getParams[kCategoryName] : OALocalizedString(@"favorites_item"),
                          @"color" : @([color toARGBNumber]),
                          @"img" : ACImageNameIcCustomFolder
                          },
                      appearanceRow,
                      @{
                          @"footer" : OALocalizedString(@"quick_action_select_group")
                          }
                      ] forKey:[NSString stringWithFormat:@"%@_1", kSectionNoName]];
    
    return [OrderedDictionary dictionaryWithDictionary:data];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    [params removeObjectsForKeys:@[kAppearanceColor, kAppearanceIcon, kAppearanceBackground]];
    if (params[kCategoryColor])
        params[kCategoryColor] = @([[OADefaultFavorite getColorFromBuiltInNumberOrARGB:[params[kCategoryColor] integerValue]] toARGBNumber]);

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
            }
            else if ([item[@"key"] isEqualToString:kAppearance])
            {
                [params setValue:item[kAppearanceColor] forKey:kWptColor];
                [params setValue:item[kAppearanceIcon] forKey:kWptIcon];
                [params setValue:item[kAppearanceBackground] forKey:kWptBackgroundType];
            }
        }
    }
    self.params = [NSDictionary dictionaryWithDictionary:params];
    return YES;
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

@end
