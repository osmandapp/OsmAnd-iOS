//
//  OAMapUnderlayAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapUnderlayAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAMapSource.h"
#import "Localization.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAMapStyleSettings.h"
#import "OAQuickActionType.h"
#import "OAResourcesUIHelper.h"

#define KEY_UNDERLAYS @"underlays"
#define KEY_NO_UNDERLAY @"no_underlay"

static OAQuickActionType *TYPE;

@implementation OAMapUnderlayAction
{
    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_hidePolygonsParameter;
    NSArray<OAResourceItem *> *_onlineMapSources;
}

- (instancetype) init
{
    self = [super initWithActionType:self.class.TYPE];
    if (self)
    {
        _styleSettings = [OAMapStyleSettings sharedInstance];
        _hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];

        _onlineMapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
    }
    return self;
}

- (void) execute
{
    NSArray<NSArray<NSString *> *> *sources = [self loadListFromParams];
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeUnderlay];
            [bottomSheet show];
            return;
        }
        
        NSInteger index = -1;
        OAMapSource *currSource = [OsmAndApp instance].data.underlayMapSource;
        NSString *currentSource = currSource.name ? currSource.name : KEY_NO_UNDERLAY;
        BOOL noUnderlay = currSource.name == nil;
        
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            NSArray *source = sources[idx];
            if ([source[source.count - 1] isEqualToString:currentSource] || ([source.firstObject isEqualToString:currentSource] && noUnderlay))
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

- (void) executeWithParams:(NSArray<NSString *> *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *variant = params.firstObject;
    NSString *name = params.count > 1 ? params[params.count - 1] : @"";
    BOOL hasUnderlay = ![variant isEqualToString:KEY_NO_UNDERLAY];
    if (hasUnderlay)
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
        [self hidePolygons:YES];
        app.data.underlayMapSource = newMapSource;
    }
    else
    {
        [self hidePolygons:NO];
        app.data.underlayMapSource = nil;
    }
    // indicate change with toast?
}

- (void) hidePolygons:(BOOL)hide
{
    NSString *newValue = hide ? @"true" : @"false";
    if (![_hidePolygonsParameter.value isEqualToString:newValue])
    {
        _hidePolygonsParameter.value = hide ? @"true" : @"false";
        [_styleSettings save:_hidePolygonsParameter];
    }
}

- (NSString *) getTranslatedItemName:(NSString *)item
{
    if ([item isEqualToString:KEY_NO_UNDERLAY])
        return OALocalizedString(@"quick_action_no_underlay");
    else
        return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_add_underlay");
}

- (NSString *) getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *) getDescrTitle
{
    return OALocalizedString(@"map_underlays");
}

- (NSString *) getListKey
{
    return KEY_UNDERLAYS;
}

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

- (OrderedDictionary *) getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    NSArray<NSArray <NSString *> *> *sources = [self loadListFromParams];
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
                     @"title" : OALocalizedString(@"quick_action_add_underlay"),
                     @"type" : @"OAButtonCell",
                     @"target" : @"addMapUnderlay"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"map_underlays")];
    return data;
}

- (BOOL) fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    for (NSArray *arr in model.allValues)
    {
        for (NSDictionary *item in arr)
        {
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
        }
    }
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return [super fillParams:model];
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:16 stringId:@"mapunderlay.change" class:self.class name:OALocalizedString(@"change_map_underlay") category:CONFIGURE_MAP iconName:@"ic_custom_underlay_map" secondaryIconName:nil];
       
    return TYPE;
}

- (NSArray *)loadListFromParams
{
    NSString *json = self.getParams[self.getListKey];
    if (!json || json.length == 0)
        return @[];
    
    NSError *jsonError;
    NSData* jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
    
    NSMutableArray *paramsArray = [NSMutableArray new];
    for (NSDictionary *overlay in jsonDict)
        [paramsArray addObject:@[overlay[@"first"], overlay[@"second"]]];
    return paramsArray;
}

- (void)saveListToParams:(NSArray<NSArray <NSString *> *> *)list
{
    NSArray *myArray = list;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:myArray options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    params[self.getListKey] = jsonString;
    [super setParams:[NSMutableDictionary dictionaryWithDictionary:params]];
}

@end
