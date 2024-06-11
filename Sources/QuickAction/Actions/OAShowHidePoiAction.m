//
//  OAShowHidePoiAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHidePoiAction.h"
#import "OAAppSettings.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OsmAndApp.h"
#import "OAButtonTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHidePoiAction
{
    OAPOIFiltersHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHidePoiActionId
                                           stringId:@"poi.showhide"
                                                 cl:self.class]
              name:OALocalizedString(@"toggle_poi")]
             iconName:@"ic_custom_poi"]
            category:EOAQuickActionTypeCategoryConfigureMap];
}

- (void)commonInit
{
    _helper = [OAPOIFiltersHelper sharedInstance];
}

- (void)execute
{
    NSArray<OAPOIUIFilter *> *poiFilters = [self loadPoiFilters];
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (![self isCurrentFilters])
    {
        [_helper clearSelectedPoiFilters];
        
        for (OAPOIUIFilter *filter in poiFilters)
        {
            if (filter.isStandardFilter)
                [filter removeUnsavedFilterByName];
    
            [_helper addSelectedPoiFilter:filter];
        }
    } else
    {
        [_helper clearSelectedPoiFilters];
    }
    [mapVC updatePoiLayer];
    
    [[OsmAndApp instance].mapSettingsChangeObservable notifyEvent];
}

- (NSString *) getIconResName
{
    NSArray<NSString *> *filtersIds = [NSArray new];
    
    NSString *filtersIdsJson = self.getParams[kFilters];
    if (filtersIdsJson && [filtersIdsJson trim].length != 0)
        filtersIds = [NSArray arrayWithArray:[filtersIdsJson componentsSeparatedByString:@","]];
    
    if ([filtersIds count] == 0)
        return [super getIconResName];
    
    OAPOIUIFilter *filter = [_helper getFilterById:filtersIds[0]];
    if (!filter)
        return [super getIconResName];
    
    id iconRes = [filter getIconResource];
    if ([iconRes isKindOfClass:NSString.class])
        return [NSString stringWithFormat:@"mx_%@", (NSString *)iconRes];
    else
        return [super getIconResName];
}

- (UIImage *)getActionIcon
{
    NSString *actionIconName = [self getIconResName];
    return [actionIconName isEqualToString:self.actionType.iconName] ? [UIImage templateImageNamed:actionIconName] : [UIImage mapSvgImageNamed:actionIconName];
}

- (BOOL)isActionWithSlash
{
    return [self isCurrentFilters];
}

- (BOOL) isCurrentFilters
{
    NSArray<OAPOIUIFilter *> *poiFilters = [self loadPoiFilters];
    NSSet<OAPOIUIFilter *> *selected = _helper.getSelectedPoiFilters;
    
    if (poiFilters.count != selected.count)
        return NO;
    
    return [selected isEqualToSet:[NSSet setWithArray:poiFilters]];
    
}

- (NSArray<OAPOIUIFilter *> *)loadPoiFilters
{
    NSArray<NSString *> *filters = [NSArray new];
    
    NSString *filtersId = self.getParams[kFilters];
    
    if (filtersId && [filtersId trim].length != 0)
        filters = [NSArray arrayWithArray:[filtersId componentsSeparatedByString:@","]];
    
    
    NSMutableArray<OAPOIUIFilter *> *poiFilters = [NSMutableArray new];
    
    for (NSString *f in filters)
    {
        OAPOIUIFilter *filter = [_helper getFilterById:f];
        
        if (filter)
            [poiFilters addObject:filter];
    }
    
    return [NSArray arrayWithArray:poiFilters];
}

- (OrderedDictionary *)getUIModel
{
    NSMutableArray *items = [NSMutableArray new];
    NSArray<OAPOIUIFilter *> *filters = [self loadPoiFilters];
    for (OAPOIUIFilter *filter in filters)
    {
        NSString *iconId = filter.getIconId ? filter.getIconId : @"user_defined";
        [items addObject:@{
                           @"title" : filter.getName,
                           @"value" : filter.filterId,
                           @"type" : [OASimpleTableViewCell getCellIdentifier],
                           @"img" : iconId
                           }];
    }
    [items addObject:@{
                       @"title" : OALocalizedString(@"quick_action_add_category"),
                       @"type" : [OAButtonTableViewCell getCellIdentifier],
                       @"target" : @"addCategory"
                       }];
    
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:[NSArray arrayWithArray:items] forKey:OALocalizedString(@"quick_action_poi_list")];
    return [OrderedDictionary dictionaryWithDictionary:data];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSArray *items = model[OALocalizedString(@"quick_action_poi_list")];
    NSMutableString *filters = [NSMutableString new];
    for (NSInteger i = 0; i < items.count; i ++)
    {
        NSDictionary *item = items[i];
        if ([item[@"type"] isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
            continue;
        
        [filters appendString:item[@"value"]];
        // Last item is a button
        if (i < items.count - 2)
            [filters appendString:@","];
    }
    [params setObject:[NSString stringWithString:filters] forKey:kFilters];
    self.params = [NSDictionary dictionaryWithDictionary:params];
    return filters && filters.length > 0;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_show_poi_descr");
}

- (NSString *)getActionStateName
{
    return [NSString stringWithFormat:@"%@ %@", ![self isCurrentFilters] ? OALocalizedString(@"recording_context_menu_show") : OALocalizedString(@"rendering_category_hide"), self.getName];
}

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
