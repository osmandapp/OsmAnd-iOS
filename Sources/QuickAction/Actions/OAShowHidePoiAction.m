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

#define KEY_FILTERS @"filters"

@implementation OAShowHidePoiAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeTogglePOI];
}

- (void)execute
{
    OAPOIFiltersHelper *pf = [OAPOIFiltersHelper sharedInstance];
    NSArray<OAPOIUIFilter *> *poiFilters = [self loadPoiFilters];
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (![self isCurrentFilters])
    {
        OAPOIUIFilter *filter;
        [pf clearSelectedPoiFilters];
        
        for (OAPOIUIFilter *filter in poiFilters)
        {
            if (filter.isStandardFilter)
                [filter removeUnsavedFilterByName];
    
            [pf addSelectedPoiFilter:filter];
        }
        filter = [pf combineSelectedFilters:[NSSet setWithArray:poiFilters]];
        [mapVC showPoiOnMap:filter keyword:filter.filterId];
    } else
    {
        [pf clearSelectedPoiFilters];
        [mapVC hidePoi];
    }
    
    [[OsmAndApp instance].mapSettingsChangeObservable notifyEvent];
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
                           @"type" : @"OABottomSheetActionCell",
                           @"img" : iconId
                           }];
    }
    [items addObject:@{
                       @"title" : OALocalizedString(@"quick_action_add_poi_category"),
                       @"type" : @"OAButtonCell",
                       @"target" : @"addCategory"
                       }];
    
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:[NSArray arrayWithArray:items] forKey:OALocalizedString(@"poi_list")];
    return [OrderedDictionary dictionaryWithDictionary:data];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSArray *items = model[OALocalizedString(@"poi_list")];
    NSMutableString *filters = [NSMutableString new];
    for (NSInteger i = 0; i < items.count; i ++)
    {
        NSDictionary *item = items[i];
        if ([item[@"type"] isEqualToString:@"OAButtonCell"])
            continue;
        
        [filters appendString:item[@"value"]];
        // Last item is a button
        if (i < items.count - 2)
            [filters appendString:@","];
    }
    [params setObject:[NSString stringWithString:filters] forKey:KEY_FILTERS];
    self.params = [NSDictionary dictionaryWithDictionary:params];
    return YES;
}

@end
