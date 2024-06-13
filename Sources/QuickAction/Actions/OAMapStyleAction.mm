//
//  OAMapStyleAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapStyleAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAQuickActionSelectionBottomSheetViewController.h"
#import "OARendererRegistry.h"
#import "OAButtonTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATitleDescrDraggableCell.h"
#import "OAIndexConstants.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/UnresolvedMapStyle.h>

static NSString * const kStyles = @"styles";

static QuickActionType *TYPE;

@implementation OAMapStyleAction

- (instancetype) init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMapStyleActionId
                                           stringId:@"mapstyle.change"
                                                 cl:self.class]
              name:OALocalizedString(@"quick_action_map_style")]
             iconName:@"ic_custom_map_style"]
            category:QuickActionTypeCategoryConfigureMap];
}

- (void)commonInit
{
    NSMutableDictionary<NSString *, OAMapSource *> *sourceMapping = [NSMutableDictionary new];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStyles;
    const auto localResources = app.resourcesManager->getLocalResources();
    for (const auto& localResource : localResources)
    {
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStyles.push_back(localResource);
    }
    
    for (const auto& resource : mapStyles)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;

        NSString *resourceId = resource->id.toNSString();
        NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:mapStyle->title.toNSString()];

        OAMapSource *mapSource = [app.data lastMapSourceByResourceId:resourceId];
        if (!mapSource)
        {
            mapSource = [[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
                                                   andVariant:mode.variantKey
                                                         name:mapStyleInfo[@"title"]];
        }
        else if (![mapSource.name isEqualToString:mapStyleInfo[@"title"]])
        {
            mapSource.name = mapStyleInfo[@"title"];
        }

        if ([mapStyleInfo[@"title"] isEqualToString:WINTER_SKI_RENDER] && ![iapHelper.skiMap isActive])
            continue;
        if ([mapStyleInfo[@"title"] isEqualToString:NAUTICAL_RENDER] && ![iapHelper.nautical isActive])
            continue;

        sourceMapping[mapSource.name] = mapSource;
    }
    _offlineMapSources = [NSDictionary dictionaryWithDictionary:sourceMapping];
}

- (void)execute
{
    NSArray<NSString *> *mapStyles = [self getFilteredStyles];
    if (mapStyles.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[kDialog] boolValue];
        if (showBottomSheetStyles)
        {
            OAQuickActionSelectionBottomSheetViewController *bottomSheet = [[OAQuickActionSelectionBottomSheetViewController alloc] initWithAction:self type:EOAMapSourceTypeStyle];
            [bottomSheet show];
            return;
        }
        // Currently using online map as a source
        if ([_offlineMapSources.allValues indexOfObject:[OsmAndApp instance].data.lastMapSource] == NSNotFound)
            return;
        
        NSInteger index = -1;
        NSString *name = [OsmAndApp instance].data.lastMapSource.name;
        
        NSInteger idx = [mapStyles indexOfObject:name];
        if (idx != NSNotFound)
            index = idx;
        
        NSString *nextStyle = mapStyles[0];
        
        if (index >= 0 && index < mapStyles.count - 1)
            nextStyle = mapStyles[index + 1];
        
        [self executeWithParamsString:nextStyle];
    }
}

- (void)executeWithParamsString:(NSString *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    OAMapSource *newMapSource = nil;
    for (OAMapSource *mapSource in _offlineMapSources.allValues)
    {
        if ([mapSource.name isEqualToString:params])
        {
            newMapSource = mapSource;
            break;
        }
    }
    if (newMapSource)
        app.data.lastMapSource = newMapSource;
    
    // indicate change with toast?
}

- (NSArray<NSString *> *) getFilteredStyles
{
    NSMutableArray *list = [NSMutableArray arrayWithArray:self.getParams[self.getListKey]];
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    if (![iapHelper.skiMap isActive])
    {
        [list removeObject:@"Ski map"];
    }
    if (![iapHelper.nautical isActive])
    {
        [list removeObject:@"Nautical"];
    }
    return [NSArray arrayWithArray:list];
}

- (NSString *)getTranslatedItemName:(NSString *)item
{
    return item;
}

-(NSString *) getAddBtnText
{
    return OALocalizedString(@"quick_action_map_style_action");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"quick_action_map_style");
}

- (NSString *)getListKey
{
    return kStyles;
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
    
    NSArray<NSString *> *sources = self.getParams[self.getListKey];
    
    NSMutableArray *arr = [NSMutableArray new];
    for (NSString *source in sources)
    {
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [_offlineMapSources[source].resourceId stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]];
        
        [arr addObject:@{
                         @"type" : [OATitleDescrDraggableCell getCellIdentifier],
                         @"title" : source,
                         @"img" : imgName ? imgName : @"ic_custom_show_on_map"
                         }];
    }
    [arr addObject:@{
                     @"title" : OALocalizedString(@"quick_action_map_style_action"),
                     @"type" : [OAButtonTableViewCell getCellIdentifier],
                     @"target" : @"addMapStyle"
                     }];
    [data setObject:[NSArray arrayWithArray:arr] forKey:OALocalizedString(@"quick_action_map_styles")];
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
                     [sources addObject:item[@"title"]];
        }
    }
    [params setObject:sources forKey:kStyles];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return sources.count > 0;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_list_descr");
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
