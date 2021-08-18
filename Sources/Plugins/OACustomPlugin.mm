//
//  OACustomPlugin.m
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACustomPlugin.h"
#import "OAWorldRegion.h"
#import "OAJsonHelper.h"
#import "OASettingsHelper.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAIndexConstants.h"
#import "OAResourcesUIHelper.h"
#import "OAProfileSettingsItem.h"
#import "OAPoiUiFilterSettingsItem.h"
#import "OASettingsItem.h"
#import "OAPluginSettingsItem.h"
#import "OAQuickActionsSettingsItem.h"
#import "OAQuickActionRegistry.h"
#import "OAMapSourcesSettingsItem.h"
#import "OATileSource.h"
#import "OAMapCreatorHelper.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAAvoidRoadInfo.h"
#import "OAAvoidSpecificRoads.h"
#import "OrderedDictionary.h"
#import "OACustomRegion.h"
#import "OAPOIFiltersHelper.h"
#import "OAQuickSearchHelper.h"
#import "OASuggestedDownloadsItem.h"

#include <OsmAndCore/ResourcesManager.h>

@interface OACustomPlugin () <OASettingsImportExportDelegate>

@end

@implementation OACustomPlugin
{
    
    NSString *_pluginId;
    NSInteger _version;
    
    NSDictionary<NSString *, NSString *> *_names;
    NSDictionary<NSString *, NSString *> *_descriptions;
    NSDictionary<NSString *, NSString *> *_iconNames;
    NSDictionary<NSString *, NSString *> *_imageNames;
    
    UIImage *_icon;
    UIImage *_image;
    
    NSArray<OASuggestedDownloadsItem *> *_suggestedDownloadItems;
    NSArray<OAWorldRegion *> *_customRegions;
}

- (instancetype) initWithJson:(NSDictionary *)json
{
    self = [super init];
    if (self)
    {
        _customRegions = [NSArray array];
        _pluginId = json[@"pluginId"];
        _version = json[@"version"] ? [json[@"version"] integerValue] : -1;
        [self readAdditionalDataFromJson:json];
        [self readDependentFilesFromJson:json];
        [self loadResources];
    }
    return self;
}

- (NSString *)getId
{
    return _pluginId;
}

- (NSString *)getVersion
{
    return [NSString stringWithFormat:@"%ld", _version];
}

- (NSString *)getName
{
    return [OAJsonHelper getLocalizedResFromMap:_names defValue:OALocalizedString(@"custom_osmand_plugin_name")];
}

- (NSString *)getDescription
{
    return [OAJsonHelper getLocalizedResFromMap:_descriptions defValue:@""];
}

- (NSArray<OAWorldRegion *> *)getDownloadMaps
{
    return _customRegions;
}

- (BOOL)initPlugin
{
    NSString *pluginItemsFile = self.getPluginItemsFile;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if ([fileManager fileExistsAtPath:pluginItemsFile])
        [self addPluginItemsFromFile:pluginItemsFile];
    return YES;
}

- (void)disable
{
    [super disable];
    [self removePluginItems:nil];
}

- (NSString *) getPluginDir
{
    return [[OsmAndApp.instance.dataPath stringByAppendingPathComponent:PLUGINS_DIR] stringByAppendingPathComponent:_pluginId];
}

- (NSString *) getPluginItemsFile
{
    return [self.getPluginDir stringByAppendingPathComponent:[@"items" stringByAppendingPathExtension:@"osf"]];
}

- (NSString *) getPluginResDir
{
    NSString *pluginDir = self.getPluginDir;
    if (self.resourceDirName.length > 0)
    {
        return [pluginDir stringByAppendingPathComponent:self.resourceDirName];
    }
    return pluginDir;
}

- (UIImage *) getIconForFile:(NSString *)path fileNames:(NSDictionary<NSString *, NSString *> *)fileNames
{
    __block UIImage *res = nil;
    [fileNames enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *value = obj;
        if ([value hasPrefix:@"@"])
            value = [value substringFromIndex:1];
        if ([path hasSuffix:value])
        {
            res = [UIImage imageWithContentsOfFile:path];
            *stop = YES;
        }
    }];
    return res;
}

- (UIImage *)getLogoResource
{
    return _icon ? : super.getLogoResource;
}

- (UIImage *)getAssetResourceImage
{
    return _image ? : super.getAssetResourceImage;
}

- (NSArray<OAResourceItem *> *) getSuggestedMaps
{
    NSMutableArray<OAResourceItem *> *suggestedMaps = [NSMutableArray new];
        
    for (OASuggestedDownloadsItem *item in _suggestedDownloadItems)
    {
        OsmAnd::ResourcesManager::ResourceType type = [OAResourceType resourceTypeByScopeId:item.scopeId];

        if (type != OsmAnd::ResourcesManager::ResourceType::Unknown)
        {
            NSMutableArray<OAResourceItem *> *foundMaps = [NSMutableArray new];
            NSString *searchType = item.searchType;
            if ([searchType isEqualToString:@"latlon"])
            {
                CLLocationCoordinate2D latLon = [OAResourcesUIHelper getMapLocation];
                [foundMaps addObjectsFromArray: [OAResourcesUIHelper getMapsForType:type latLon:latLon]];
            }
            else if ([searchType isEqualToString:@"worldregion"])
            {
                CLLocationCoordinate2D latLon = [OAResourcesUIHelper getMapLocation];
                [foundMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:type latLon:latLon]];
            }
            if (item.names && item.names.count > 0)
            {
                [foundMaps addObjectsFromArray:[OAResourcesUIHelper getMapsForType:type names:item.names limit:item.limit]];
            }
            [suggestedMaps addObjectsFromArray:foundMaps];
        }
    }
    return [NSArray arrayWithArray:suggestedMaps];
}

- (void) addPluginItemsFromFile:(NSString *)file
{
    [OASettingsHelper.sharedInstance collectSettings:file latestChanges:@"" version:1 onComplete:^(BOOL succeed, NSArray<OASettingsItem *> *items) {
        if (succeed && items.count > 0)
        {
            NSMutableArray<OASettingsItem *> *toRemove = [NSMutableArray new];
            for (OASettingsItem *item in items)
            {
                if ([item isKindOfClass:OAProfileSettingsItem.class])
                {
                    OAProfileSettingsItem *profileSettingsItem = (OAProfileSettingsItem *)item;
                    OAApplicationMode *mode = profileSettingsItem.appMode;
                    OAApplicationMode *savedMode = [OAApplicationMode valueOfStringKey:mode.stringKey def:nil];
                    if (savedMode)
                        [OAApplicationMode changeProfileAvailability:savedMode isSelected:YES];
                    [toRemove addObject:item];
                }
                else if ([item isKindOfClass:OAQuickActionsSettingsItem.class])
                {
                    [((OACollectionSettingsItem *)item) processDuplicateItems];
                    item.shouldReplace = YES;
                }
                else if (![item isKindOfClass:OAPluginSettingsItem.class])
                {
                    item.shouldReplace = YES;
                }
            }
            NSMutableArray<OASettingsItem *> *newItems = [NSMutableArray arrayWithArray:items];
            [newItems removeObjectsInArray:toRemove];
            [OASettingsHelper.sharedInstance importSettings:file items:newItems latestChanges:@"" version:1 delegate:self];
        }
    }];
}

- (void) removePluginItems:(void(^)(void))onComplete
{
    NSString *pluginItemsFile = [self getPluginItemsFile];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if ([fileManager fileExistsAtPath:pluginItemsFile])
        [self removePluginItemsFromFile:pluginItemsFile onComplete:onComplete];
}

- (void) removePluginItemsFromFile:(NSString *)file onComplete:(void(^)(void))onComplete
{
    [OASettingsHelper.sharedInstance collectSettings:file latestChanges:@"" version:1 onComplete:^(BOOL succeed, NSArray<OASettingsItem *> *items) {
            if (succeed && items.count > 0)
            {
                for (OASettingsItem *item in items)
                {
                    if ([item isKindOfClass:OAQuickActionsSettingsItem.class])
                    {
                        OAQuickActionsSettingsItem *quickActionsSettingsItem = (OAQuickActionsSettingsItem *) item;
                        NSArray<OAQuickAction *> *quickActions = quickActionsSettingsItem.items;
                        OAQuickActionRegistry *actionRegistry = OAQuickActionRegistry.sharedInstance;
                        for (OAQuickAction *action in quickActions)
                        {
                            OAQuickAction *savedAction = [actionRegistry getQuickAction:action.getType name:action.getName params:action.getParams];
                            if (savedAction)
                                [actionRegistry deleteQuickAction:savedAction];
                            [actionRegistry.quickActionListChangedObservable notifyEvent];
                        }
                    }
                    else if ([item isKindOfClass:OAMapSourcesSettingsItem.class])
                    {
                        OAMapSourcesSettingsItem *mapSourcesSettingsItem = (OAMapSourcesSettingsItem *) item;
                        NSArray<OATileSource *> *mapSources = mapSourcesSettingsItem.items;
                        
                        for (OATileSource *tileSource in mapSources)
                        {
                            NSString *tileSourceName = tileSource.name;
                            if (tileSource.isSql)
                                tileSourceName = [tileSourceName stringByAppendingPathExtension:SQLITE_EXT];
                            
                            NSArray<OAResourceItem *> *installedSources = [OAResourcesUIHelper getSortedRasterMapSources:YES];
                            OAResourceItem *savedTileSource = nil;
                            for (OAMapSourceResourceItem *res in installedSources)
                            {
                                if ([res.mapSource.name isEqualToString:tileSourceName])
                                {
                                    savedTileSource = res;
                                    break;
                                }
                            }
                            if (savedTileSource)
                            {
                                if ([savedTileSource isKindOfClass:OASqliteDbResourceItem.class])
                                {
                                    OASqliteDbResourceItem *sqLiteTileSource = (OASqliteDbResourceItem *) savedTileSource;
                                    [OAMapCreatorHelper.sharedInstance removeFile:sqLiteTileSource.fileName];
                                }
                                else if ([savedTileSource isKindOfClass:OAOnlineTilesResourceItem.class])
                                {
                                    OAOnlineTilesResourceItem *onlineTileSource = (OAOnlineTilesResourceItem *) savedTileSource;
                                    OsmAndApp.instance.resourcesManager->uninstallTilesResource(onlineTileSource.onlineTileSource->name);
                                }
                            }
                        }
                    }
                    else if ([item isKindOfClass:OAPoiUiFilterSettingsItem.class])
                    {
                        OAPoiUiFilterSettingsItem *poiUiFiltersSettingsItem = (OAPoiUiFilterSettingsItem *) item;
                        NSArray<OAPOIUIFilter *> *poiUIFilters = poiUiFiltersSettingsItem.items;
                        OAPOIFiltersHelper *poiHelper = OAPOIFiltersHelper.sharedInstance;
                        for (OAPOIUIFilter *filter in poiUIFilters)
                        {
                            [poiHelper removePoiFilter:filter];
                        }
                        [poiHelper reloadAllPoiFilters];
                        [poiHelper loadSelectedPoiFilters];
                        [OAQuickSearchHelper.instance refreshCustomPoiFilters];
                    }
                    else if ([item isKindOfClass:OAAvoidRoadsSettingsItem.class])
                    {
                        OAAvoidRoadsSettingsItem *avoidRoadsSettingsItem = (OAAvoidRoadsSettingsItem *) item;
                        NSArray<OAAvoidRoadInfo *> *avoidRoadInfos = avoidRoadsSettingsItem.items;
                        for (OAAvoidRoadInfo *avoidRoad in avoidRoadInfos)
                        {
                            [OAAvoidSpecificRoads.instance removeImpassableRoad:avoidRoad];
                        }
                    }
                    else if ([item isKindOfClass:OAProfileSettingsItem.class])
                    {
                        OAProfileSettingsItem *profileSettingsItem = (OAProfileSettingsItem *) item;
                        OAApplicationMode *mode = profileSettingsItem.appMode;
                        OAApplicationMode *savedMode = [OAApplicationMode valueOfStringKey:mode.stringKey def:nil];
                        if (savedMode != nil)
                            [OAApplicationMode changeProfileAvailability:savedMode isSelected:NO];
                    }
                }
                if (onComplete)
                    onComplete();
            }
    }];
}

- (void) readAdditionalDataFromJson:(NSDictionary *)json
{
    _iconNames = json[@"icon"];
    _imageNames = json[@"image"];
    _names = json[@"name"];
    _descriptions = json[@"description"];
    
    NSArray *regionsJson = json[@"regionsJson"];
    if (regionsJson != nil)
    {
        _customRegions = [_customRegions arrayByAddingObjectsFromArray:[self.class collectRegionsFromJson:regionsJson]];
    }
}

- (void) writeAdditionalDataToJson:(NSMutableDictionary *)json
{
    if (_iconNames)
        json[@"icon"] = _iconNames;
    if (_imageNames)
        json[@"image"] = _imageNames;
    if (_names)
        json[@"name"] = _names;
    if (_descriptions)
        json[@"description"] = _descriptions;
    
    NSMutableArray *regionsJson = [NSMutableArray new];
    for (OAWorldRegion *region in self.getFlatCustomRegions)
    {
        if ([region isKindOfClass:OACustomRegion.class])
        {
            [regionsJson addObject:((OACustomRegion *)region).toJson];
        }
    }
    json[@"regionsJson"] = regionsJson;
}

- (NSArray<OAWorldRegion *> *) getFlatCustomRegions
{
    NSMutableArray<OAWorldRegion *> *l = [NSMutableArray arrayWithArray:_customRegions];
    for (OAWorldRegion *region in _customRegions)
    {
        [self collectCustomSubregionsFromRegion:region items:l];
    }
    return l;
}

- (void) collectCustomSubregionsFromRegion:(OAWorldRegion *)region items:(NSMutableArray<OAWorldRegion *> *)items
{
    [items addObjectsFromArray:region.subregions];
    for (OAWorldRegion *subregion in region.subregions)
    {
        [self collectCustomSubregionsFromRegion:subregion items:items];
    }
}
   
- (void) readDependentFilesFromJson:(NSDictionary *)json
{
    _rendererNames = json[@"rendererNames"];
    _routerNames = json[@"routerNames"];
    _resourceDirName = json[@"pluginResDir"];
}

- (void) writeDependentFilesJson:(NSMutableDictionary *)json
{
    json[@"rendererNames"] = _rendererNames;
    json[@"routerNames"] = _routerNames;
    json[@"pluginResDir"] = _resourceDirName;
}

+ (NSArray<OACustomRegion *> *)collectRegionsFromJson:(NSArray *)jsonArray
{
    NSMutableArray<OACustomRegion *> *customRegions = [NSMutableArray new];
    MutableOrderedDictionary<NSString *, OACustomRegion *> *flatRegions = [MutableOrderedDictionary new];
    for (NSDictionary *regionJson in jsonArray)
    {
        OACustomRegion *region = [OACustomRegion fromJson:regionJson];
        flatRegions[region.path] = region;
    }
    for (OACustomRegion *region in flatRegions.allValues)
    {
        if (region.parentPath.length > 0)
        {
            OACustomRegion *parentReg = flatRegions[region.parentPath];
            if (parentReg)
            {
                [parentReg addSubregion:region];
            }
        }
        else
        {
            [customRegions addObject:region];
        }
    }
    return customRegions;
}

- (void) addRouter:(NSString *)fileName
{
    if (!_routerNames)
        _routerNames = [NSMutableArray array];
    NSString *routerName = fileName.lastPathComponent;
    if (![_routerNames containsObject:routerName])
        [_routerNames addObject:routerName];
}

- (void) addRenderer:(NSString *)fileName
{
    if (!_rendererNames)
        _rendererNames = [NSMutableArray array];
    NSString *rendererName = fileName.lastPathComponent;
    if (![_rendererNames containsObject:rendererName])
        [_rendererNames addObject:rendererName];
}

- (void) loadResources
{
    NSString *pluginResDir = self.getPluginResDir;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = NO;
    BOOL exists = [fileManager fileExistsAtPath:pluginResDir isDirectory:&isDir];
    if (exists && isDir)
    {
        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:pluginResDir error:nil];
        for (NSString *resFile in files)
        {
            NSString *path = [pluginResDir stringByAppendingPathComponent:resFile];
            if (!_icon)
                _icon = [self getIconForFile:path fileNames:_iconNames];
            if (!_image)
                _image = [self getIconForFile:path fileNames:_imageNames];
        }
    }
    for (OAWorldRegion *region in _customRegions)
    {
        [self loadSubregionIndexItems:region];
    }
}

- (void) loadSubregionIndexItems:(OAWorldRegion *)region
{
    if ([region isKindOfClass:OACustomRegion.class])
        [((OACustomRegion *) region) loadDynamicIndexItems];
    
    for (OAWorldRegion *subregion in region.subregions)
    {
        [self loadSubregionIndexItems:subregion];
    }
}

- (void) updateSuggestedDownloads:(NSArray<OASuggestedDownloadsItem *> *)items
{
    _suggestedDownloadItems = [NSArray arrayWithArray:items];
}

- (void) updateDownloadItems:(NSArray<OAWorldRegion *> *)items
{
    _customRegions = [NSArray arrayWithArray:items];
}

// TODO: figure out how to port this to our download system

//private List<IndexItem> getMapsForType(LatLon latLon, DownloadActivityType type) {
//    try {
//        return DownloadResources.findIndexItemsAt(app, latLon, type);
//    } catch (IOException e) {
//        LOG.error(e);
//    }
//    return Collections.emptyList();
//}
//
//private List<IndexItem> getMapsForType(List<String> names, DownloadActivityType type, int limit) {
//    return DownloadResources.findIndexItemsAt(app, names, type, false, limit);
//}

// MARK: OASettingsImportExportDelegate

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items {
}

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    
}

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed {
}

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    // TODO: dismiss progress
}

@end
