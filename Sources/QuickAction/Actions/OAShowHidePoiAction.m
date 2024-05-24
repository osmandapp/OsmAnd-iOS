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
#import "OAQuickActionType.h"
#import "OAButtonTableViewCell.h"
#import "OASimpleTableViewCell.h"

#define KEY_FILTERS @"filters"

static OAQuickActionType *TYPE;

@implementation OAShowHidePoiAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAPOIFiltersHelper *pf = [OAPOIFiltersHelper sharedInstance];
    NSArray<OAPOIUIFilter *> *poiFilters = [self loadPoiFilters];
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (![self isCurrentFilters])
    {
        [pf clearSelectedPoiFilters];
        
        for (OAPOIUIFilter *filter in poiFilters)
        {
            if (filter.isStandardFilter)
                [filter removeUnsavedFilterByName];
    
            [pf addSelectedPoiFilter:filter];
        }
    } else
    {
        [pf clearSelectedPoiFilters];
    }
    [mapVC updatePoiLayer];
    
    [[OsmAndApp instance].mapSettingsChangeObservable notifyEvent];
}

- (NSString *) getIconResName
{
    OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
    NSArray<NSString *> *filtersIds = [NSArray new];
    
    NSString *filtersIdsJson = self.getParams[KEY_FILTERS];
    if (filtersIdsJson && [filtersIdsJson trim].length != 0)
        filtersIds = [NSArray arrayWithArray:[filtersIdsJson componentsSeparatedByString:@","]];
    
    if ([filtersIds count] == 0)
        return [super getIconResName];
    
    OAPOIUIFilter *filter = [helper getFilterById:filtersIds[0]];
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
    NSSet<OAPOIUIFilter *> *selected = [OAPOIFiltersHelper sharedInstance].getSelectedPoiFilters;
    
    if (poiFilters.count != selected.count)
        return NO;
    
    return [selected isEqualToSet:[NSSet setWithArray:poiFilters]];
    
}

-(NSArray<OAPOIUIFilter *> *) loadPoiFilters
{
    OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
    NSArray<NSString *> *filters = [NSArray new];
    
    NSString *filtersId = self.getParams[KEY_FILTERS];
    
    if (filtersId && [filtersId trim].length != 0)
        filters = [NSArray arrayWithArray:[filtersId componentsSeparatedByString:@","]];
    
    
    NSMutableArray<OAPOIUIFilter *> *poiFilters = [NSMutableArray new];
    
    for (NSString *f in filters)
    {
        OAPOIUIFilter *filter = [helper getFilterById:f];
        
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
    [params setObject:[NSString stringWithString:filters] forKey:KEY_FILTERS];
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
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:5 stringId:@"poi.showhide" class:self.class name:OALocalizedString(@"toggle_poi") category:CONFIGURE_MAP iconName:@"ic_custom_poi" secondaryIconName:nil];
       
    return TYPE;
}

@end
