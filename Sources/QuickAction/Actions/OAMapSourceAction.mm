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
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAQuickActionType.h"
#import "OAResourcesUIHelper.h"
#import "OAButtonCell.h"
#import "OASwitchTableViewCell.h"

#define LAYER_OSM_VECTOR @"type_default"
#define KEY_SOURCE @"source"

static OAQuickActionType *TYPE;

@implementation OAMapSourceAction
{
    NSArray<OAResourceItem *> *_onlineMapSources;
}

- (instancetype) init
{
    self = [super initWithActionType:self.class.TYPE];
    if (self)
    {
        _onlineMapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
    }
    return self;
}

- (void)execute
{
    NSArray<NSArray<NSString *> *> *sources = self.getParams[self.getListKey];
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeSource];
            [bottomSheet show];
            return;
        }
        
        OsmAndAppInstance app = [OsmAndApp instance];
        OAMapSource *currSource = app.data.lastMapSource;
        NSInteger index = -1;
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            NSArray *source = sources[idx];
            if ([source[source.count - 1] isEqualToString:currSource.name] || ([source.firstObject isEqualToString:currSource.variant] && currSource.variant.length > 0))
            {
                index = idx;
                break;
            }
        }
        
        NSArray<NSString *> *nextSource = sources[0];
        
        if (index >= 0 && index < sources.count - 1)
            nextSource = sources[index + 1];
        
        [self executeWithParams:nextSource];
    }
}

- (void)executeWithParams:(NSArray<NSString *> *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *variant = params.firstObject;
    NSString *name = params.count > 1 ? params[params.count - 1] : @"";
    if ([variant isEqualToString:LAYER_OSM_VECTOR])
    {
        OAMapSource *mapSource = app.data.prevOfflineSource;
        if (!mapSource)
        {
            mapSource = [OAAppData defaultMapSource];
            [app.data setPrevOfflineSource:mapSource];
        }
        app.data.lastMapSource = mapSource;
    }
    else
    {
        OAMapSource *newMapSource = nil;
        for (OAMapSourceResourceItem *resource in _onlineMapSources)
        {
            if ([resource.mapSource.variant isEqualToString:variant] && [resource.mapSource.name isEqualToString:name])
            {
                newMapSource = resource.mapSource;
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
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSArray <NSString *> *> *sources = self.getParams[self.getListKey];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSArray *source in sources)
    {
        [arr addObject:@{
                         @"type" : @"OATitleDescrDraggableCell",
                         @"title" : source.lastObject,
                         @"value" : source.firstObject,
                         @"img" : @"ic_custom_map_style"
                         }];
    }
    [arr addObject:@{
                     @"title" : OALocalizedString(@"add_map_source"),
                     @"type" : [OAButtonCell getCellIdentifier],
                     @"target" : @"addMapSource"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"map_sources")];
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSMutableArray *sources = [NSMutableArray new];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            else if ([item[@"type"] isEqualToString:@"OATitleDescrDraggableCell"])
                [sources addObject:@[item[@"value"], item[@"title"]]];
        }
    }
    [params setObject:sources forKey:KEY_SOURCE];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return sources.count > 0;
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:17 stringId:@"mapsource.change" class:self.class name:OALocalizedString(@"change_map_source") category:CONFIGURE_MAP iconName:@"ic_custom_show_on_map" secondaryIconName:nil];
       
    return TYPE;
}

- (NSArray *)loadListFromParams
{
    return self.getParams[self.getListKey];
}

@end
