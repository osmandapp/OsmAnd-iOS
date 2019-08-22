//
//  OAMapSourceAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSourceAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAMapSource.h"
#import "Localization.h"
#import "OAAppData.h"

#define LAYER_OSM_VECTOR @"type_default"
#define KEY_SOURCE @"source"

@implementation OAMapSourceAction

- (instancetype) init
{
    self = [super initWithType:EOAQuickActionTypeMapSource];
    if (self)
    {
        [super commonInit];
    }
    return self;
}

- (void)execute
{
    NSArray<NSArray<NSString *> *> *sources = self.loadListFromParams;
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            // TODO Show bottom sheet with map styles
            return;
        }
        
        OsmAndAppInstance app = [OsmAndApp instance];
        OAMapSource *currSource = app.data.lastMapSource;
        NSInteger index = -1;
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            if ([sources[idx].firstObject isEqualToString:currSource.variant])
            {
                index = idx;
                break;
            }
        }
        
        NSArray<NSString *> *nextSource = sources[0];
        
        if (index >= 0 && index < sources.count - 1)
            nextSource = sources[index + 1];
        
        [self executeWithParams:nextSource.firstObject];
    }
}

- (void)executeWithParams:(NSString *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    if ([params isEqualToString:LAYER_OSM_VECTOR])
    {
        OAMapSource *mapSource = app.data.prevOfflineSource;
        if (!mapSource)
        {
            mapSource = [OAAppData defaults].lastMapSource;
            [app.data setPrevOfflineSource:mapSource];
        }
        app.data.lastMapSource = mapSource;
    }
    else
    {
        OAMapSource *newMapSource = nil;
        for (OAMapSource *mapSource in self.onlineMapSources)
        {
            if ([mapSource.variant isEqualToString:params])
            {
                newMapSource = mapSource;
                break;
            }
        }
        app.data.lastMapSource = newMapSource;
    }
//     indicate change with toast?
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    if ([item isEqualToString:LAYER_OSM_VECTOR])
        return OALocalizedString(@"offline_vector_maps");
    else
        return item;
    return nil;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"add_map_source");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"map_sources");
}

- (NSString *)getListKey
{
    return KEY_SOURCE;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    self.params = @{KEY_DIALOG : @(NO), KEY_SOURCE : @"[[\"bing_earth\", \"Bing Earth\"], [\"bing_hybrid\", \"Bing hybtid\"], [\"type_default\", \"OsmAnd Vector Tiles\"]]"};
    return YES;
}

@end
