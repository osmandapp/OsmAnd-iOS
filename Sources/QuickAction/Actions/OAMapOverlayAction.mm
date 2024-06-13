//
//  OAMapOverlayAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapOverlayAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAMapSource.h"
#import "Localization.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OAResourcesUIHelper.h"
#import "OAButtonTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kOverlays = @"overlays";
static NSString * const kNoOverlay = @"no_overlay";

static QuickActionType *TYPE;

@implementation OAMapOverlayAction
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
    TYPE = [[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMapOverlayActionId
                                           stringId:@"mapoverlay.change"
                                                 cl:self.class]
              name:OALocalizedString(@"quick_action_map_overlay")]
             iconName:@"ic_custom_overlay_map"]
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
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeOverlay];
            [bottomSheet show];
            return;
        }
        
        NSInteger index = -1;
        OAMapSource *currSource = [OsmAndApp instance].data.overlayMapSource;
        NSString *currentSource = currSource.name ? currSource.name : kNoOverlay;
        BOOL noOverlay = currSource.name == nil;
        
        for (NSInteger idx = 0; idx < sources.count; idx++)
        {
            NSArray *source = sources[idx];
            if ([source[source.count - 1] isEqualToString:currentSource] || ([source.firstObject isEqualToString:currentSource] && noOverlay))
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
    BOOL hasOverlay = ![variant isEqualToString:kNoOverlay];
    if (hasOverlay)
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
        app.data.overlayMapSource = newMapSource;
    }
    else
    {
        app.data.overlayMapSource = nil;
    }
    // indicate change with toast?
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    if ([item isEqualToString:kNoOverlay])
        return OALocalizedString(@"no_overlay");
    else
        return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_map_overlay_action");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"quick_action_map_overlay_title");
}

- (NSString *)getListKey
{
    return kOverlays;
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
    
    NSArray<NSArray<NSString *> *> *sources = self.getParams[self.getListKey];
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
                     @"title" : OALocalizedString(@"quick_action_map_overlay_action"),
                     @"type" : [OAButtonTableViewCell getCellIdentifier],
                     @"target" : @"addMapOverlay"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"quick_action_map_overlay_title")];
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
    [params setObject:sources forKey:kOverlays];
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
