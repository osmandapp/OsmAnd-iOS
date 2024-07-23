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
#import "OAResourcesUIHelper.h"
#import "OAButtonTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OrderedDictionary.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kLayerOsmVector = @"LAYER_OSM_VECTOR";
static NSString * const kSource = @"source";

static QuickActionType *TYPE;

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

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMapSourceActionId
                                           stringId:@"mapsource.change"
                                                 cl:self.class]
              name:OALocalizedString(@"map_source")]
             nameAction:OALocalizedString(@"shared_string_change")]
             iconName:@"ic_custom_show_on_map"]
             secondaryIconName:@"ic_custom_compound_action_change"]
            category:QuickActionTypeCategoryConfigureMap];
}

- (void)execute
{
    NSArray<NSArray<NSString *> *> *sources = self.getParams[self.getListKey];
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[kDialog] boolValue];
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
    if ([variant isEqualToString:kLayerOsmVector])
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
    if ([item isEqualToString:kLayerOsmVector])
        return OALocalizedString(@"vector_data");
    else
        return item;
    return nil;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_map_source_action");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"quick_action_map_source_title");
}

- (NSString *)getListKey
{
    return kSource;
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
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSArray <NSString *> *> *sources = self.getParams[self.getListKey];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSArray *source in sources)
    {
        [arr addObject:@{
                         @"type" : [OATitleDescrDraggableCell getCellIdentifier],
                         @"title" : source.lastObject,
                         @"value" : source.firstObject,
                         @"img" : @"ic_custom_map_style"
                         }];
    }
    [arr addObject:@{
                     @"title" : OALocalizedString(@"quick_action_map_source_action"),
                     @"type" : [OAButtonTableViewCell getCellIdentifier],
                     @"target" : @"addMapSource"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"quick_action_map_source_title")];
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
            if ([item[@"key"] isEqualToString:kDialog])
                [params setValue:item[@"value"] forKey:kDialog];
            else if ([item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
                [sources addObject:@[item[@"value"], item[@"title"]]];
        }
    }
    [params setObject:sources forKey:kSource];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return sources.count > 0;
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

- (NSArray *)loadListFromParams
{
    return [self getParams][[self getListKey]];
}

@end
