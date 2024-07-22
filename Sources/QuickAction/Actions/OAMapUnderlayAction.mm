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
#import "OAResourcesUIHelper.h"
#import "OAButtonTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kUnderlays = @"underlays";
static NSString * const kNoUnderlay = @"no_underlay";

static QuickActionType *TYPE;

@implementation OAMapUnderlayAction
{
    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_hidePolygonsParameter;
    NSArray<OAResourceItem *> *_onlineMapSources;
}

- (instancetype) init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    _hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];
    _onlineMapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMapUnderlayActionId
                                           stringId:@"mapunderlay.change"
                                                 cl:self.class]
              name:OALocalizedString(@"quick_action_map_underlay")]
             nameAction:OALocalizedString(@"shared_string_change")]
             iconName:@"ic_custom_underlay_map"]
             secondaryIconName:@"ic_custom_compound_action_change"]
            category:QuickActionTypeCategoryConfigureMap];
}

- (void) execute
{
    NSArray<NSArray<NSString *> *> *sources = self.getParams[self.getListKey];
    if (sources.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[kDialog] boolValue];
        if (showBottomSheetStyles)
        {
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeUnderlay];
            [bottomSheet show];
            return;
        }
        
        NSInteger index = -1;
        OAMapSource *currSource = [OsmAndApp instance].data.underlayMapSource;
        NSString *currentSource = currSource.name ? currSource.name : kNoUnderlay;
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
    BOOL hasUnderlay = ![variant isEqualToString:kNoUnderlay];
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
    if ([item isEqualToString:kNoUnderlay])
        return OALocalizedString(@"no_underlay");
    else
        return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_map_underlay_action");
}

- (NSString *) getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *) getDescrTitle
{
    return OALocalizedString(@"quick_action_map_underlay_title");
}

- (NSString *) getListKey
{
    return kUnderlays;
}

- (OrderedDictionary *) getUIModel
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
                     @"title" : OALocalizedString(@"quick_action_map_underlay_action"),
                     @"type" : [OAButtonTableViewCell getCellIdentifier],
                     @"target" : @"addMapUnderlay"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"quick_action_map_underlay_title")];
    return data;
}

- (BOOL) fillParams:(NSDictionary *)model
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
    [params setObject:sources forKey:kUnderlays];
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
