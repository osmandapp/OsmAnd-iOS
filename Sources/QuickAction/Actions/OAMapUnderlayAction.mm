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

#define KEY_UNDERLAYS @"underlays"
#define KEY_NO_UNDERLAY @"no_underlay"

@implementation OAMapUnderlayAction

- (instancetype) init
{
    self = [super initWithType:EOAQuickActionTypeMapUnderlay];
    if (self)
    {
        [super commonInit];
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
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeUnderlay];
            [bottomSheet show];
            return;
        }
        
        NSInteger index = -1;
        NSString *name = [OsmAndApp instance].data.underlayMapSource.variant;
        NSString *currentSource = name ? name : KEY_NO_UNDERLAY;
        
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            if ([sources[idx].firstObject isEqualToString:currentSource])
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
    BOOL hasUnderlay = ![params isEqualToString:KEY_NO_UNDERLAY];
    if (hasUnderlay)
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
        app.data.underlayMapSource = newMapSource;
    }
    else
    {
        app.data.underlayMapSource = nil;
    }
    // indicate change with toast?
}

- (NSString *)getTranslatedItemName:(NSString *)item
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

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"map_underlays");
}

- (NSString *)getListKey
{
    return KEY_UNDERLAYS;
}

- (OrderedDictionary *)getUIModel
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
                     @"title" : OALocalizedString(@"quick_action_add_underlay"),
                     @"type" : @"OAButtonCell",
                     @"target" : @"addMapUnderlay"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"map_underlays")];
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
    [params setObject:sources forKey:KEY_UNDERLAYS];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return sources.count > 0;
}

@end
