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
        [items addObject:@{
                           @"title" : filter.getName,
                           @"type" : @"OABottomSheetActionCell",
                           @"img" : filter.getIconId
                           }];
    }
    
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:[NSArray arrayWithArray:items] forKey:OALocalizedString(@"poi_list")];
    return [OrderedDictionary dictionaryWithDictionary:data];
}

- (BOOL)fillParams:(NSDictionary *)model
{
    return YES;
}

@end
