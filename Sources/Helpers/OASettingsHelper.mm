//
//  OASettingsHelper.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"
#import "OASettingsItem.h"
#import "OASettingsImporter.h"
#import "OASettingsExporter.h"
#import "OASettingsItemType.h"
#import "OARootViewController.h"
#import "OAIndexConstants.h"
#import "OAPluginSettingsItem.h"
#import "OARendererRegistry.h"
#import "Localization.h"
#import "OAImportSettingsViewController.h"
#import "OAExportSettingsCategory.h"
#import "OASettingsCategoryItems.h"
#import "OrderedDictionary.h"
#import "OAQuickActionRegistry.h"
#import "OAPOIFiltersHelper.h"
#import "OAAvoidSpecificRoads.h"
#import "OAFavoritesHelper.h"
#import "OAGPXUIHelper.h"
#import "OAGPXDatabase.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAPlugin.h"
#import "OADestinationsHelper.h"
#import "OAHistoryHelper.h"
#import "OAResourcesUIHelper.h"
#import "OAFileSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OASettingsItem.h"
#import "OAResourcesUIHelper.h"
#import "OASQLiteTileSource.h"
#import "OAFileNameTranslationHelper.h"
#import "OsmAndApp.h"
#import "OACustomPlugin.h"

#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "OASettingsItem.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAPoiUiFilterSettingsItem.h"
#import "OAQuickActionsSettingsItem.h"
#import "OAResourcesSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OADataSettingsItem.h"
#import "OAPluginSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAGlobalSettingsItem.h"
#import "OAFavoritesSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAFavoritesHelper.h"
#import "OAMarkersSettingsItem.h"
#import "OAHistoryMarkersSettingsItem.h"
#import "OADestination.h"
#import "OAGpxSettingsItem.h"
#import "OASearchHistorySettingsItem.h"
#import "OATileSource.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

NSString *const kSettingsHelperErrorDomain = @"SettingsHelper";

NSInteger const kSettingsHelperErrorCodeNoTypeField = 1;
NSInteger const kSettingsHelperErrorCodeIllegalType = 2;
NSInteger const kSettingsHelperErrorCodeUnknownFileSubtype = 3;
NSInteger const kSettingsHelperErrorCodeUnknownFilePath = 4;
NSInteger const kSettingsHelperErrorCodeEmptyJson = 5;

@interface OASettingsHelper() <OASettingsImportExportDelegate>

@end

@implementation OASettingsHelper
{
    __weak OAImportSettingsViewController *_importDataVC;
}

+ (OASettingsHelper *) sharedInstance
{
    static OASettingsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OASettingsHelper alloc] init];
    });
    return _sharedInstance;
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    [self collectSettings:settingsFile latestChanges:latestChanges version:version delegate:self onComplete:nil];
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate
{
    [self collectSettings:settingsFile latestChanges:latestChanges version:version delegate:delegate onComplete:nil];
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version onComplete:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile latestChanges:latestChanges version:version];
    [task executeWithCompletionBlock:onComplete];
}

- (void) collectSettings:(NSString *)settingsFile latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate onComplete:(void(^)(BOOL succeed, NSArray<OASettingsItem *> *items))onComplete
{
    OAImportSettingsViewController* incomingURLViewController = [[OAImportSettingsViewController alloc] init];
    [OARootViewController.instance.navigationController pushViewController:incomingURLViewController animated:YES];
    _importDataVC = incomingURLViewController;
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile latestChanges:latestChanges version:version];
    task.delegate = delegate;
    [task executeWithCompletionBlock:onComplete];
}
 
- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems
{
    [self checkDuplicates:settingsFile items:items selectedItems:selectedItems delegate:self];
}

- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems delegate:(id<OASettingsImportExportDelegate>)delegate
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items selectedItems:selectedItems];
    task.delegate = delegate;
    [task execute];
}

- (void) checkDuplicates:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems onComplete:(OAOnDuplicatesChecked)onComplete
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items selectedItems:selectedItems];
    task.onDuplicatesChecked = onComplete;
    [task execute];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version
{
    [self importSettings:settingsFile items:items latestChanges:latestChanges version:version delegate:self];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version delegate:(id<OASettingsImportExportDelegate>)delegate
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items latestChanges:latestChanges version:version];
    task.delegate = delegate;
    [task execute];
}

- (void) importSettings:(NSString *)settingsFile items:(NSArray<OASettingsItem*> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version onComplete:(OAOnImportComplete)onComplete
{
    OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:settingsFile items:items latestChanges:latestChanges version:version];
    task.onImportComplete = onComplete;
    [task execute];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles extensionsFilter:(NSString *)extensionsFilter delegate:(id<OASettingsImportExportDelegate>)delegate
{
    NSString *file = [fileDir stringByAppendingPathComponent:fileName];
    file = [file stringByAppendingPathExtension:@"osf"];
    OAExportAsyncTask *exportAsyncTask = [[OAExportAsyncTask alloc] initWithFile:file items:items exportItemFiles:exportItemFiles extensionsFilter:extensionsFilter];
    exportAsyncTask.settingsExportDelegate = delegate;
    [_exportTasks setObject:exportAsyncTask forKey:file];
    [exportAsyncTask execute];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles delegate:(id<OASettingsImportExportDelegate>)delegate
{
    [self exportSettings:fileDir fileName:fileName items:items exportItemFiles:exportItemFiles extensionsFilter:nil delegate:delegate];
}

- (void) exportSettings:(NSString *)fileDir fileName:(NSString *)fileName settingsItem:(OASettingsItem *)item exportItemFiles:(BOOL)exportItemFiles delegate:(id<OASettingsImportExportDelegate>)delegate
{
    [self exportSettings:fileDir fileName:fileName items:@[item] exportItemFiles:exportItemFiles delegate:delegate];
}

- (NSArray<OASettingsItem *> *) getFilteredSettingsItems:(NSArray<OAExportSettingsType *> *)settingsTypes addProfiles:(BOOL)addProfiles doExport:(BOOL)doExport
{
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *typesMap = [NSMutableDictionary new];
    [typesMap addEntriesFromDictionary:[self getSettingsItems:addProfiles]];
    [typesMap addEntriesFromDictionary:[self getMyPlacesItems]];
    [typesMap addEntriesFromDictionary:[self getResourcesItems]];
    
    return [self getFilteredSettingsItems:typesMap settingsTypes:settingsTypes settingsItems:@[] doExport:doExport];
}

- (NSArray<OASettingsItem *> *) getFilteredSettingsItems:(NSDictionary<OAExportSettingsType *, NSArray *> *)allSettingsMap
                                           settingsTypes:(NSArray<OAExportSettingsType *> *)settingsTypes
                                           settingsItems:(NSArray<OASettingsItem *> *)settingsItems
                                                doExport:(BOOL)doExport
{
    NSMutableArray<OASettingsItem *> *filteredSettingsItems = [NSMutableArray new];
    for (OAExportSettingsType *settingsType in settingsTypes)
    {
        NSArray *settingsDataObjects = allSettingsMap[settingsType];
        if (settingsDataObjects != nil)
        {
            [filteredSettingsItems addObjectsFromArray:[self prepareSettingsItems:settingsDataObjects settingsItems:settingsItems doExport:doExport]];
        }
    }
    return filteredSettingsItems;
}

- (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *) getSettingsByCategory:(BOOL)addProfiles
{
    MutableOrderedDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *dataList = [MutableOrderedDictionary new];
    
    NSDictionary<OAExportSettingsType *, NSArray *> *settingsItems = [self getSettingsItems:addProfiles];
    NSDictionary<OAExportSettingsType *, NSArray *> *myPlacesItems = [self getMyPlacesItems];
    NSDictionary<OAExportSettingsType *, NSArray *> *resourcesItems = [self getResourcesItems];
    
    if (settingsItems.count > 0)
        dataList[OAExportSettingsCategory.SETTINGS] = [[OASettingsCategoryItems alloc] initWithItemsMap:settingsItems];
    if (myPlacesItems.count > 0)
        dataList[OAExportSettingsCategory.MY_PLACES] = [[OASettingsCategoryItems alloc] initWithItemsMap:myPlacesItems];
    if (resourcesItems.count > 0)
        dataList[OAExportSettingsCategory.RESOURCES] = [[OASettingsCategoryItems alloc] initWithItemsMap:resourcesItems];
    
    return dataList;
}

- (NSDictionary<OAExportSettingsType *, NSArray *> *) getSettingsItems:(BOOL)addProfiles
{
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *settingsItems = [MutableOrderedDictionary new];
    
    if (addProfiles)
    {
        NSMutableArray<OAApplicationModeBean *> *appModeBeans = [NSMutableArray new];
        for (OAApplicationMode *mode in OAApplicationMode.allPossibleValues)
        {
            [appModeBeans addObject:[mode toModeBean]];
        }
        settingsItems[OAExportSettingsType.PROFILE] = appModeBeans;
    }
    settingsItems[OAExportSettingsType.GLOBAL] = @[[[OAGlobalSettingsItem alloc] init]];
    
    OAQuickActionRegistry *registry = OAQuickActionRegistry.sharedInstance;
    NSArray<OAQuickAction *> *actionsList = registry.getQuickActions;
    if (actionsList.count > 0)
        settingsItems[OAExportSettingsType.QUICK_ACTIONS] = actionsList;
    
    NSArray<OAPOIUIFilter *> *poiList = [OAPOIFiltersHelper.sharedInstance getUserDefinedPoiFilters:NO];
    if (poiList.count > 0)
        settingsItems[OAExportSettingsType.POI_TYPES] = poiList;
    
    NSArray<OAAvoidRoadInfo *> *impassableRoads = OAAvoidSpecificRoads.instance.getImpassableRoads;
    if (impassableRoads.count > 0)
        settingsItems[OAExportSettingsType.AVOID_ROADS] = impassableRoads;
    
    return settingsItems;
}

- (NSDictionary<OAExportSettingsType *, NSArray *> *)getMyPlacesItems
{
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *myPlacesItems = [MutableOrderedDictionary new];
    
    NSArray<OAFavoriteGroup *> *favoriteGroups = [OAFavoritesHelper getFavoriteGroups];
    if (favoriteGroups.count > 0)
        myPlacesItems[OAExportSettingsType.FAVORITES] = favoriteGroups;
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSArray<OAGpxFileInfo *> *gpxInfoList = [OAGPXUIHelper getSortedGPXFilesInfo:OsmAndApp.instance.gpxPath selectedGpxList:nil absolutePath:YES];
    if (gpxInfoList.count > 0)
    {
        NSMutableArray<NSString *> *files = [NSMutableArray new];
        for (OAGpxFileInfo *gpxInfo in gpxInfoList)
        {
            if ([fileManager fileExistsAtPath:gpxInfo.fileName])
                [files addObject:gpxInfo.fileName];
        }
        if (files.count > 0)
            myPlacesItems[OAExportSettingsType.TRACKS] = files;
    }
    OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    if (osmEditingPlugin)
    {
        NSArray<OAOsmNotePoint *> *notesPointList = OAOsmBugsDBHelper.sharedDatabase.getOsmBugsPoints;
        if (notesPointList.count > 0)
            myPlacesItems[OAExportSettingsType.OSM_NOTES] = notesPointList;
        NSArray<OAOpenStreetMapPoint *> *editsPointList = OAOsmEditsDBHelper.sharedDatabase.getOpenstreetmapPoints;
        if (editsPointList.count > 0)
            myPlacesItems[OAExportSettingsType.OSM_EDITS] = editsPointList;
    }
    // TODO: implement after adding Audio/video notes
//    AudioVideoNotesPlugin plugin = OsmandPlugin.getPlugin(AudioVideoNotesPlugin.class);
//    if (plugin != null) {
//        List<File> files = new ArrayList<>();
//        for (Recording rec : plugin.getAllRecordings()) {
//            File file = rec.getFile();
//            if (file != null && file.exists()) {
//                files.add(file);
//            }
//        }
//        if (!files.isEmpty()) {
//            myPlacesItems.put(ExportSettingsType.MULTIMEDIA_NOTES, files);
//        }
//    }
    NSArray<OADestination *> *mapMarkers = [OADestinationsHelper.instance sortedDestinationsWithoutParking];
    if (mapMarkers.count > 0)
    {
        // TODO: sync map markers code with Android
//        String name = app.getString(R.string.map_markers);
//        String groupId = ExportSettingsType.ACTIVE_MARKERS.name();
//        ItineraryGroup markersGroup = new ItineraryGroup(groupId, name, ItineraryGroup.ANY_TYPE);
//        markersGroup.setMarkers(mapMarkers);
        myPlacesItems[OAExportSettingsType.ACTIVE_MARKERS] = mapMarkers;
    }
    OAHistoryHelper *historyHelper = OAHistoryHelper.sharedInstance;
    NSArray<OAHistoryItem *> *markersHistory = [historyHelper getPointsHavingTypes:historyHelper.destinationTypes limit:0];
    if (markersHistory.count > 0)
    {
//        String name = app.getString(R.string.shared_string_history);
//        String groupId = ExportSettingsType.HISTORY_MARKERS.name();
//        ItineraryGroup markersGroup = new ItineraryGroup(groupId, name, ItineraryGroup.ANY_TYPE);
//        markersGroup.setMarkers(markersHistory);
        myPlacesItems[OAExportSettingsType.HISTORY_MARKERS] = markersHistory;
    }
    NSArray<OAHistoryItem *> *historyEntries = [historyHelper getPointsHavingTypes:historyHelper.searchTypes limit:0];
    if (historyEntries.count > 0)
        myPlacesItems[OAExportSettingsType.SEARCH_HISTORY] = historyEntries;
    
    return myPlacesItems;
}

- (NSDictionary<OAExportSettingsType *, NSArray *> *)getResourcesItems
{
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *resourcesItems = [MutableOrderedDictionary new];
    
    NSArray<NSString *> *mapStyleFiles = [OARendererRegistry getPathExternalRenderers];
    if (mapStyleFiles.count > 0)
        resourcesItems[OAExportSettingsType.CUSTOM_RENDER_STYLE] = mapStyleFiles;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = NO;
    NSString *routingProfilesFolder = [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:ROUTING_PROFILES_DIR];
    BOOL exists = [fileManager fileExistsAtPath:routingProfilesFolder isDirectory:&isDir];
    if (exists && isDir)
    {
        NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:routingProfilesFolder error:nil];
        NSMutableArray<NSString *> *items = [NSMutableArray array];
        for (NSString *file in files)
        {
            if ([file.pathExtension isEqualToString:@"xml"])
                [items addObject:[routingProfilesFolder stringByAppendingPathComponent:file]];
        }
        
        if (items.count > 0)
            resourcesItems[OAExportSettingsType.CUSTOM_ROUTING] = items;
    }
//    List<OnlineRoutingEngine> onlineRoutingEngines = app.getOnlineRoutingHelper().getEngines();
//    if (!Algorithms.isEmpty(onlineRoutingEngines)) {
//        resourcesItems.put(ExportSettingsType.ONLINE_ROUTING_ENGINES, onlineRoutingEngines);
//    }
    // TODO: implement export!
    NSMutableArray<OATileSource *> *tileSources = [NSMutableArray new];
    NSArray<OAResourceItem *> *tileResources = [OAResourcesUIHelper getSortedRasterMapSources:YES];
    for (OAResourceItem *res in tileResources)
    {
        if ([res isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *tileSource = (OAOnlineTilesResourceItem *) res;
            OATileSource *source = [OATileSource tileSourceFromOnlineSource:tileSource.onlineTileSource];
            [tileSources addObject:source];
        }
        else if ([res isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *sqlSource = (OASqliteDbResourceItem *) res;
            OASQLiteTileSource *sqlFile = [[OASQLiteTileSource alloc] initWithFilePath:sqlSource.path];
            OATileSource *source = [OATileSource tileSourceFromSqlSource:sqlFile];
            [tileSources addObject:source];
        }
    }
    if (tileSources.count > 0)
        resourcesItems[OAExportSettingsType.MAP_SOURCES] = tileSources;
    
    QSet<OsmAnd::ResourcesManager::ResourceType> types;
    types << OsmAnd::ResourcesManager::ResourceType::MapRegion
    << OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion
    << OsmAnd::ResourcesManager::ResourceType::HillshadeRegion
    << OsmAnd::ResourcesManager::ResourceType::SlopeRegion
    << OsmAnd::ResourcesManager::ResourceType::WikiMapRegion;
    NSArray<NSString *> *localIndexFiles = [OAResourcesUIHelper getInstalledResourcePathsByTypes:types];
    if (localIndexFiles.count > 0)
    {
        NSArray<NSString *> *sortedFiles = [localIndexFiles sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [[OAFileNameTranslationHelper getMapName:obj1.lastPathComponent] compare:[OAFileNameTranslationHelper getMapName:obj2.lastPathComponent]];
        }];
        resourcesItems[OAExportSettingsType.OFFLINE_MAPS] = sortedFiles;
    }
//    files = getFilesByType(localIndexInfoList, LocalIndexType.TTS_VOICE_DATA);
//    if (!files.isEmpty()) {
//        resourcesItems.put(ExportSettingsType.TTS_VOICE, files);
//    }
//    files = getFilesByType(localIndexInfoList, LocalIndexType.VOICE_DATA);
//    if (!files.isEmpty()) {
//        resourcesItems.put(ExportSettingsType.VOICE, files);
//    }
    
    return resourcesItems;
}

+ (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *) getSettingsToOperateByCategory:(NSArray<OASettingsItem *> *)items importComplete:(BOOL)importComplete
{
    MutableOrderedDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *exportMap = [MutableOrderedDictionary new];
    NSDictionary<OAExportSettingsType *, NSArray *> *settingsToOperate = [self getSettingsToOperate:items importComplete:importComplete];
    
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *settingsItems = [MutableOrderedDictionary new];
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *myPlacesItems = [MutableOrderedDictionary new];
    MutableOrderedDictionary<OAExportSettingsType *, NSArray *> *resourcesItems = [MutableOrderedDictionary new];
    
    [settingsToOperate enumerateKeysAndObjectsUsingBlock:^(OAExportSettingsType * _Nonnull type, NSArray * _Nonnull obj, BOOL * _Nonnull stop) {
        if (type.isSettingsCategory)
            settingsItems[type] = obj;
        else if (type.isMyPlacesCategory)
            myPlacesItems[type] = obj;
        else if (type.isResourcesCategory)
            resourcesItems[type] = obj;
    }];
    
    if (settingsItems.count > 0)
        exportMap[OAExportSettingsCategory.SETTINGS] = [[OASettingsCategoryItems alloc] initWithItemsMap:settingsItems];
    
    if (myPlacesItems.count > 0)
        exportMap[OAExportSettingsCategory.MY_PLACES] = [[OASettingsCategoryItems alloc] initWithItemsMap:myPlacesItems];
    
    if (resourcesItems.count > 0)
        exportMap[OAExportSettingsCategory.RESOURCES] = [[OASettingsCategoryItems alloc] initWithItemsMap:resourcesItems];
    
    return exportMap;
}

- (OAProfileSettingsItem *) getBaseProfileSettingsItem:(OAApplicationModeBean *)modeBean settingsItems:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem *settingsItem in settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeProfile)
        {
            OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *)settingsItem;
            OAApplicationModeBean *bean = [profileItem modeBean];
            if ([bean.stringKey isEqualToString:modeBean.stringKey] && [bean.userProfileName isEqualToString:modeBean.userProfileName])
                return profileItem;
        }
    }
    return nil;
}

- (OAQuickActionsSettingsItem *) getBaseQuickActionsSettingsItem:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem * settingsItem in settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeQuickActions)
            return (OAQuickActionsSettingsItem *)settingsItem;
    }
    return nil;
}
 
- (OAPoiUiFilterSettingsItem *) getBasePoiUiFiltersSettingsItem:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem * settingsItem in settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypePoiUIFilters)
            return (OAPoiUiFilterSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAMapSourcesSettingsItem *) getBaseMapSourcesSettingsItem:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem * settingsItem in settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeMapSources)
            return (OAMapSourcesSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAAvoidRoadsSettingsItem *) getBaseAvoidRoadsSettingsItem:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem * settingsItem in settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeAvoidRoads)
            return (OAAvoidRoadsSettingsItem *)settingsItem;
    }
    return nil;
}

- (id) getBaseItem:(EOASettingsItemType)settingsItemType clazz:(id)clazz settingsItems:(NSArray<OASettingsItem *> *)settingsItems
{
    for (OASettingsItem * settingsItem in settingsItems)
    {
        if (settingsItem.type == settingsItemType && [settingsItem isKindOfClass:clazz])
            return settingsItem;
    }
    return nil;
}

- (NSArray <OASettingsItem *>*) prepareSettingsItems:(NSArray *)data settingsItems:(NSArray<OASettingsItem *> *)settingsItems doExport:(BOOL)doExport
{
    NSMutableArray<OASettingsItem *> *result = [NSMutableArray array];
    NSMutableArray<OAApplicationModeBean *> *appModeBeans = [NSMutableArray array];
    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
    NSMutableArray<OAPOIUIFilter *> *poiUIFilters = [NSMutableArray array];
    NSMutableArray<OATileSource *> *tileSourceTemplates = [NSMutableArray array];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    NSMutableArray<OAFavoriteGroup *> *favoiriteItems = [NSMutableArray array];
    NSMutableArray<OAOsmNotePoint *> *osmNotesPointList = [NSMutableArray array];
    NSMutableArray<OAOpenStreetMapPoint *> *osmEditsPointList = [NSMutableArray array];
    NSMutableArray<OADestination *> *activeMarkersList = [NSMutableArray array];
    NSMutableArray<OAHistoryItem *> *historyMarkersList = [NSMutableArray array];
    NSMutableArray<OAHistoryItem *> *historyItems = [NSMutableArray array];

    for (id object in data)
    {
        if ([object isKindOfClass:OAApplicationModeBean.class])
            [appModeBeans addObject:object];
        else if ([object isKindOfClass:OAQuickAction.class])
            [quickActions addObject:object];
        else if ([object isKindOfClass:OAPOIUIFilter.class])
            [poiUIFilters addObject:object];
        else if ([object isKindOfClass:OATileSource.class])
            [tileSourceTemplates addObject:object];
        else if ([object isKindOfClass:NSString.class])
        {
            NSString *filePath = object;
            if ([filePath.lowercaseString hasSuffix:GPX_FILE_EXT])
            {
                [result addObject:[[OAGpxSettingsItem alloc] initWithFilePath:filePath error:nil]];
            }
            else
            {
                OAFileSettingsItem *toExport = [[OAFileSettingsItem alloc] initWithFilePath:filePath error:nil];
                if (toExport)
                    [result addObject:toExport];
            }
        }
        else if ([object isKindOfClass:OAAvoidRoadInfo.class])
            [avoidRoads addObject:object];
        else if ([object isKindOfClass:OAOsmNotePoint.class])
            [osmNotesPointList addObject:object];
        else if ([object isKindOfClass:OAOpenStreetMapPoint.class])
            [osmEditsPointList addObject:object];
        else if ([object isKindOfClass:OAFileSettingsItem.class])
            [result addObject:object];
        else if ([object isKindOfClass:OAFavoriteGroup.class])
            [favoiriteItems addObject:object];
        else if ([object isKindOfClass:OADestination.class])
            [activeMarkersList addObject:object];
        else if ([object isKindOfClass:OAHistoryItem.class])
        {
            if ([[OAHistoryHelper sharedInstance].destinationTypes containsObject:@(((OAHistoryItem *) object).hType)])
                [historyMarkersList addObject:object];
            else
                [historyItems addObject:object];
        }
        else if ([object isKindOfClass:OAGlobalSettingsItem.class])
            [result addObject:object];
    }
    if (appModeBeans.count > 0)
        for (OAApplicationModeBean *modeBean in appModeBeans)
        {
            if (doExport)
            {
                OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:modeBean.stringKey def:nil];
                if (mode)
                    [result addObject:[[OAProfileSettingsItem alloc] initWithAppMode:mode]];
            }
            else
            {
                [result addObject:[self getBaseProfileSettingsItem:modeBean settingsItems:settingsItems]];
            }
        }
    if (quickActions.count > 0)
    {
        OAQuickActionsSettingsItem *baseItem = [self getBaseItem:EOASettingsItemTypeQuickActions clazz:OAQuickActionsSettingsItem.class settingsItems:settingsItems];
        [result addObject:[[OAQuickActionsSettingsItem alloc] initWithItems:quickActions baseItem:baseItem]];
    }
    if (tileSourceTemplates.count > 0)
        [result addObject:[[OAMapSourcesSettingsItem alloc] initWithItems:tileSourceTemplates]];
    if (avoidRoads.count > 0)
        [result addObject:[[OAAvoidRoadsSettingsItem alloc] initWithItems:avoidRoads]];
    if (favoiriteItems.count > 0)
        [result addObject:[[OAFavoritesSettingsItem alloc] initWithItems:favoiriteItems]];
    if (poiUIFilters.count > 0)
    {
        OAPoiUiFilterSettingsItem *baseItem = [self getBaseItem:EOASettingsItemTypePoiUIFilters clazz:OAPoiUiFilterSettingsItem.class settingsItems:settingsItems];
        [result addObject:[[OAPoiUiFilterSettingsItem alloc] initWithItems:poiUIFilters baseItem:baseItem]];
    }
    if (osmNotesPointList.count > 0)
    {
        OAOsmNotesSettingsItem *baseItem = [self getBaseItem:EOASettingsItemTypeOsmNotes clazz:OAOsmNotesSettingsItem.class settingsItems:settingsItems];
        [result addObject:[[OAOsmNotesSettingsItem alloc] initWithItems:osmNotesPointList baseItem:baseItem]];
    }
    if (osmEditsPointList.count > 0)
    {
        OAOsmEditsSettingsItem  *baseItem = [self getBaseItem:EOASettingsItemTypeOsmEdits clazz:OAOsmEditsSettingsItem.class settingsItems:settingsItems];
        [result addObject:[[OAOsmEditsSettingsItem alloc] initWithItems:osmEditsPointList baseItem:baseItem]];
    }
    if (activeMarkersList.count > 0)
    {
        [result addObject:[[OAMarkersSettingsItem alloc] initWithItems:activeMarkersList]];
    }
    if (historyMarkersList.count > 0)
    {
        [result addObject:[[OAHistoryMarkersSettingsItem alloc] initWithItems:historyMarkersList]];
    }
    if (historyItems.count > 0)
    {
        [result addObject:[[OASearchHistorySettingsItem alloc] initWithItems:historyItems]];
    }
    return result;
}

+ (NSDictionary<OAExportSettingsType *, NSArray *> *) getSettingsToOperate:(NSArray<OASettingsItem *> *)settingsItems importComplete:(BOOL)importComplete
{
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *settingsToOperate = [NSMutableDictionary new];
    NSMutableArray<OAApplicationModeBean *> *profiles = [NSMutableArray array];
    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
    NSMutableArray<OAPOIUIFilter *> *poiUIFilters = [NSMutableArray array];
    NSMutableArray<OATileSource *> *tileSourceTemplates = [NSMutableArray array];
    NSMutableArray<NSString *> *routingFilesList = [NSMutableArray array];
    NSMutableArray<NSString *> *renderFilesList = [NSMutableArray array];
    NSMutableArray<OAFileSettingsItem *> *tracksFilesList = [NSMutableArray array];
    NSMutableArray<OAFileSettingsItem *> *mapFilesList = [NSMutableArray array];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    NSMutableArray<OAFavoriteGroup *> *favorites = [NSMutableArray array];
    NSMutableArray<OAOsmNotePoint *> *notesPointList  = [NSMutableArray array];
    NSMutableArray<OAOpenStreetMapPoint *> *osmEditsPointList  = [NSMutableArray array];
    NSMutableArray<OADestination *> *markers = [NSMutableArray array];
    NSMutableArray<OAHistoryItem *> *historyMarkers = [NSMutableArray array];
    NSMutableArray<OAHistoryItem *> *historyEntries = [NSMutableArray array];
    NSMutableArray<OAGlobalSettingsItem *> *globalSettingsItems = [NSMutableArray array];
    for (OASettingsItem *item in settingsItems)
    {
        switch (item.type)
        {
            case EOASettingsItemTypeProfile:
            {
                [profiles addObject:[(OAProfileSettingsItem *)item modeBean]];
                break;
            }
            case EOASettingsItemTypeFile:
            {
                OAFileSettingsItem *fileItem = (OAFileSettingsItem *)item;
                if (fileItem.subtype == EOASettingsItemFileSubtypeRenderingStyle)
                    [renderFilesList addObject:fileItem.filePath];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig)
                    [routingFilesList addObject:fileItem.filePath];
                else if ([OAFileSettingsItemFileSubtype isMap:fileItem.subtype])
                    [mapFilesList addObject:fileItem];
                break;
            }
            case EOASettingsItemTypeGpx:
            {
                [tracksFilesList addObject:(OAFileSettingsItem *) item];
                break;
            }
            case EOASettingsItemTypeQuickActions:
            {
                OAQuickActionsSettingsItem *quickActionsItem = (OAQuickActionsSettingsItem *) item;
                if (importComplete)
                    [quickActions addObjectsFromArray:quickActionsItem.appliedItems];
                else
                    [quickActions addObjectsFromArray:quickActionsItem.items];
                break;
            }
            case EOASettingsItemTypePoiUIFilters:
            {
                OAPoiUiFilterSettingsItem *poiUiFilterItem = (OAPoiUiFilterSettingsItem *) item;
                if (importComplete)
                    [poiUIFilters addObjectsFromArray:poiUiFilterItem.appliedItems];
                else
                    [poiUIFilters addObjectsFromArray:poiUiFilterItem.items];
                break;
            }
            case EOASettingsItemTypeMapSources:
            {
                OAMapSourcesSettingsItem *mapSourcesItem = (OAMapSourcesSettingsItem *) item;
                if (importComplete)
                    [tileSourceTemplates addObjectsFromArray:mapSourcesItem.appliedItems];
                else
                    [tileSourceTemplates addObjectsFromArray:mapSourcesItem.items];
                break;
            }
            case EOASettingsItemTypeAvoidRoads:
            {
                OAAvoidRoadsSettingsItem *avoidRoadsItem = (OAAvoidRoadsSettingsItem *) item;
                if (importComplete)
                    [avoidRoads addObjectsFromArray:avoidRoadsItem.appliedItems];
                else
                    [avoidRoads addObjectsFromArray:avoidRoadsItem.items];
                break;
            }
            case EOASettingsItemTypeFavorites:
            {
                OAFavoritesSettingsItem *favoritesItem = (OAFavoritesSettingsItem *) item;
                if (importComplete)
                    [favorites addObjectsFromArray:favoritesItem.appliedItems];
                else
                    [favorites addObjectsFromArray:favoritesItem.items];
                break;
            }
            case EOASettingsItemTypeOsmNotes:
            {
                OAOsmNotesSettingsItem *osmNotesItem = (OAOsmNotesSettingsItem *) item;
                if (importComplete)
                    [notesPointList addObjectsFromArray:osmNotesItem.appliedItems];
                else
                    [notesPointList addObjectsFromArray:osmNotesItem.items];
                break;
            }
            case EOASettingsItemTypeOsmEdits:
            {
                OAOsmEditsSettingsItem *osmEditsItem = (OAOsmEditsSettingsItem *) item;
                if (importComplete)
                    [osmEditsPointList addObjectsFromArray:osmEditsItem.appliedItems];
                else
                    [osmEditsPointList addObjectsFromArray:osmEditsItem.items];
                break;
            }
            case EOASettingsItemTypeActiveMarkers:
            {
                OAMarkersSettingsItem *markersItem = (OAMarkersSettingsItem *) item;
                if (importComplete)
                    [markers addObjectsFromArray:markersItem.appliedItems];
                else
                    [markers addObjectsFromArray:markersItem.items];
                break;
            }
            case EOASettingsItemTypeHistoryMarkers:
            {
                OAHistoryMarkersSettingsItem *historyMarkersItem = (OAHistoryMarkersSettingsItem *) item;
                [historyMarkers addObjectsFromArray:historyMarkersItem.items];
                break;
            }
            case EOASettingsItemTypeSearchHistory:
            {
                OASearchHistorySettingsItem *searchHistorySettingsItem = (OASearchHistorySettingsItem *) item;
                [historyEntries addObjectsFromArray:searchHistorySettingsItem.items];
                break;
            }
            case EOASettingsItemTypeGlobal:
            {
                OAGlobalSettingsItem *globalItem = (OAGlobalSettingsItem *) item;
                [globalSettingsItems addObject:globalItem];
                break;
            }
            default:
                break;
        }
    }
    if (profiles.count > 0)
        settingsToOperate[OAExportSettingsType.PROFILE] = profiles;
    if (quickActions.count > 0)
        settingsToOperate[OAExportSettingsType.QUICK_ACTIONS] = quickActions;
    if (poiUIFilters.count > 0)
        settingsToOperate[OAExportSettingsType.POI_TYPES] = poiUIFilters;
    if (tileSourceTemplates.count > 0)
        settingsToOperate[OAExportSettingsType.MAP_SOURCES] = tileSourceTemplates;
    if (renderFilesList.count > 0)
        settingsToOperate[OAExportSettingsType.CUSTOM_RENDER_STYLE] = renderFilesList;
    if (routingFilesList.count > 0)
        settingsToOperate[OAExportSettingsType.CUSTOM_ROUTING] = routingFilesList;
    if (tracksFilesList.count > 0)
        settingsToOperate[OAExportSettingsType.TRACKS] = tracksFilesList;
    if (mapFilesList.count > 0)
        settingsToOperate[OAExportSettingsType.OFFLINE_MAPS] = mapFilesList;
    if (avoidRoads.count > 0)
        settingsToOperate[OAExportSettingsType.AVOID_ROADS] = avoidRoads;
    if (favorites.count > 0)
        settingsToOperate[OAExportSettingsType.FAVORITES] = favorites;
    if (notesPointList.count > 0)
        settingsToOperate[OAExportSettingsType.OSM_NOTES] = notesPointList;
    if (osmEditsPointList.count > 0)
        settingsToOperate[OAExportSettingsType.OSM_EDITS] = osmEditsPointList;
    if (markers.count > 0)
        settingsToOperate[OAExportSettingsType.ACTIVE_MARKERS] = markers;
    if (historyMarkers.count > 0)
        settingsToOperate[OAExportSettingsType.HISTORY_MARKERS] = historyMarkers;
    if (historyEntries.count > 0)
        settingsToOperate[OAExportSettingsType.SEARCH_HISTORY] = historyEntries;
    if (globalSettingsItems.count > 0)
        settingsToOperate[OAExportSettingsType.GLOBAL] = globalSettingsItems;
    return settingsToOperate;
}

- (void) handlePluginImport:(OAPluginSettingsItem *)pluginItem file:(NSString *)file removeFile:(BOOL)removeFile
{
    OAOnImportComplete onImportComplete = ^(BOOL succeed, NSArray<OASettingsItem *> *items) {
//        AudioVideoNotesPlugin pluginAudioVideo = OsmandPlugin.getPlugin(AudioVideoNotesPlugin.class);
//        if (pluginAudioVideo != null) {
//            pluginAudioVideo.indexingFiles(null, true, true);
//        }
        OACustomPlugin *plugin = pluginItem.plugin;
        [plugin loadResources];
        
//        if (!Algorithms.isEmpty(plugin.getDownloadMaps())) {
//            app.getDownloadThread().runReloadIndexFilesSilent();
//        }
//        if (!Algorithms.isEmpty(plugin.getRendererNames())) {
//            app.getRendererRegistry().updateExternalRenderers();
//        }
//        if (!Algorithms.isEmpty(plugin.getRouterNames())) {
//            loadRoutingFiles(app, null);
//        }
        [plugin onInstall];
        NSString *pluginId = [plugin getId];
        NSString *pluginDir = [PLUGINS_DIR stringByAppendingPathComponent:pluginId];
        NSString *fullPath = [OsmAndApp.instance.dataPath stringByAppendingPathComponent:pluginDir];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:fullPath])
            [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [self exportSettings:fullPath fileName:@"items" items:items exportItemFiles:YES extensionsFilter:@"json" delegate:nil];

        if (removeFile)
            [OAUtilities denyAccessToFile:file removeFromInbox:YES];
    };
    
    NSMutableArray<OASettingsItem *> *pluginItems = [NSMutableArray arrayWithArray:pluginItem.pluginDependentItems];
    [pluginItems insertObject:pluginItem atIndex:0];
    
    [self checkDuplicates:file items:pluginItems selectedItems:pluginItems onComplete:^(NSArray<OASettingsItem *> *duplicates, NSArray<OASettingsItem *> *items) {
        for (OASettingsItem *item in items)
            item.shouldReplace = YES;
        [self importSettings:file items:items latestChanges:@"" version:1 onComplete:onImportComplete];
    }];
}

#pragma mark - OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(OALocalizedString(@"profile_import_success")) preferredStyle:UIAlertControllerStyleAlert];
        [NSFileManager.defaultManager removeItemAtPath:_importTask.getFile error:nil];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
    _importTask = nil;
}

- (void) onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        NSMutableArray<OASettingsItem *> *pluginIndependentItems = [NSMutableArray new];
        NSMutableArray<OAPluginSettingsItem *> *pluginSettingsItems = [NSMutableArray new];
        for (OASettingsItem *item in items)
        {
            if ([item isKindOfClass:OAPluginSettingsItem.class])
                [pluginSettingsItems addObject:((OAPluginSettingsItem *) item)];
            else if (item.pluginId.length == 0)
                [pluginIndependentItems addObject:item];
        }
        for (OAPluginSettingsItem *pluginItem in pluginSettingsItems)
        {
            [self handlePluginImport:pluginItem file:_importTask.getFile removeFile:pluginIndependentItems.count == 0];
        }
        if (pluginIndependentItems.count > 0)
        {
            if (_importDataVC)
                [_importDataVC onItemsCollected:pluginIndependentItems file:[_importTask getFile]];
        }
        else if (pluginSettingsItems.count > 0)
        {
            if (_importDataVC)
            {
                [_importDataVC.navigationController popViewControllerAnimated:NO];
            }
        }
    }
    else if (empty)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"err_profile_import"), items.firstObject.name] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
}

- (void) onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
    
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items
{
    
}

@end
