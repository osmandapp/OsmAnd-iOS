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
#import "OAMapSource.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAApplicationMode.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/ResourcesManager.h>

#define KEY_STYLES @"styles"

@implementation OAMapStyleAction
{
    NSArray<OAMapSource *> *_offlineMapSources;
}

- (instancetype) init
{
    self = [super initWithType:EOAQuickActionTypeMapStyle];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    NSDictionary *stylesTitlesOffline = @{@"default" : @"OsmAnd",
                                          @"nautical" : @"Nautical",
                                          @"Ski-map" : @"Ski map",
                                          @"UniRS" : @"UniRS",
                                          @"Touring-view_(more-contrast-and-details).render" : @"Touring view",
                                          @"LightRS" : @"LightRS",
                                          @"Topo" : @"Topo",
                                          @"Offroad by ZLZK" : @"Offroad",
                                          @"Depends-template" : @"Mapnik"};
    
    OsmAndAppInstance app = [OsmAndApp instance];
    OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode;
    NSMutableArray<OAMapSource *> *arr = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStyles;
    const auto localResources = app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStyles.push_back(localResource);
    
    for(const auto& resource : mapStyles)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        
        NSString* resourceId = resource->id.toNSString();
        
        
        OAMapSource *mapSource = [app.data lastMapSourceByResourceId:resourceId];
        if (mapSource == nil)
            mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:mode.variantKey];
        
        NSString *caption = mapStyle->title.toNSString();
        if ([caption isEqualToString:@"Ski-map"] && ![iapHelper.skiMap isActive])
            continue;
        if ([caption isEqualToString:@"nautical"] && ![iapHelper.nautical isActive])
            continue;
        
        NSString *newCaption = [stylesTitlesOffline objectForKey:caption];
        if (newCaption)
            caption = newCaption;
        
        mapSource.name = caption;
        [arr addObject:mapSource];
    }
    _offlineMapSources = [NSArray arrayWithArray:arr];
}

- (void)execute
{
    NSArray<NSString *> *mapStyles = [self getFilteredStyles];
    if (mapStyles.count > 0)
    {
        BOOL showBottomSheetStyles = [self.getParams[KEY_DIALOG] boolValue];
        if (showBottomSheetStyles)
        {
            // TODO Show bottom sheet with map styles
            return;
        }
        // Currently using online map as a source
        if ([_offlineMapSources indexOfObject:[OsmAndApp instance].data.lastMapSource] == NSNotFound)
            return;
        
        NSInteger index = -1;
        NSString *name = [OsmAndApp instance].data.lastMapSource.name;
        
        NSInteger idx = [mapStyles indexOfObject:name];
        if (idx != NSNotFound)
            index = idx;
        
        NSString *nextStyle = mapStyles[0];
        
        if (index >= 0 && index < mapStyles.count - 1)
            nextStyle = mapStyles[index + 1];
        
        [self executeWithParams:nextStyle];
    }
}

- (void)executeWithParams:(NSString *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    OAMapSource *newMapSource = nil;
    for (OAMapSource *mapSource in _offlineMapSources)
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
    NSMutableArray *list = [NSMutableArray arrayWithArray:self.loadListFromParams];
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
    return OALocalizedString(@"add_map_style");
}

- (NSString *)getDescrHint
{
    return OALocalizedString(@"quick_action_list_descr");
}

- (NSString *)getDescrTitle
{
    return OALocalizedString(@"map_styles");
}

- (NSString *)getListKey
{
    return KEY_STYLES;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    self.params = @{KEY_DIALOG : @(NO), KEY_STYLES : @"[\"OsmAnd\", \"UniRS\", \"Topo\", \"Ski map\"]"};
    return YES;
}

@end
