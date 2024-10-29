//
//  OAResourcesUIHelper.m
//  OsmAnd
//
//  Created by Alexey on 03.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAResourcesUIHelper.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <MBProgressHUD.h>
#import "OALog.h"
#import "OADownloadsManager.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAManageResourcesViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASQLiteTileSource.h"
#import "OAChoosePlanHelper.h"
#import "OAJsonHelper.h"
#import "OATileSource.h"
#import "OAWorldRegion.h"
#import "OAIndexConstants.h"
#import "OAResourcesInstaller.h"
#import "OAPlugin.h"
#import "OAWeatherHelper.h"
#import "OAApplicationMode.h"
#import "OADownloadTask.h"
#import "Localization.h"
#import "OAWeatherPlugin.h"
#import "OAPluginsHelper.h"
#import "OAAppVersion.h"
#import "OAAppData.h"
#import "OARouteCalculationResult.h"
#import "OAMapSource.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/WorldRegions.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/ObfsCollection.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>

typedef OsmAnd::IncrementalChangesManager::IncrementalUpdate IncrementalUpdate;

@interface OAResourceType()

@property (nonatomic) OsmAndResourceType type;

@end

@implementation OAResourceType

+ (instancetype)withType:(OsmAndResourceType)type;
{
    OAResourceType *obj = [[OAResourceType alloc] init];
    if (obj)
    {
        obj.type = type;
    }
    return obj;
}

+ (NSString *)resourceTypeLocalized:(OsmAndResourceType)type
{
    switch (type)
    {
        case OsmAndResourceType::MapRegion:
        case OsmAndResourceType::DepthContourRegion:
            return OALocalizedString(@"shared_string_map");
        case OsmAndResourceType::DepthMapRegion:
            return OALocalizedString(@"nautical_depth");
        case OsmAndResourceType::SrtmMapRegion:
            return OALocalizedString(@"map_settings_topography");
        case OsmAndResourceType::WikiMapRegion:
            return OALocalizedString(@"download_wikipedia_maps");
        case OsmAndResourceType::RoadMapRegion:
            return OALocalizedString(@"roads");
        case OsmAndResourceType::SqliteFile:
            return OALocalizedString(@"online_map");
        case OsmAndResourceType::WeatherForecast:
            return OALocalizedString(@"weather_forecast");
        case OsmAndResourceType::HeightmapRegionLegacy:
        case OsmAndResourceType::GeoTiffRegion:
            return OALocalizedString(@"download_heightmap_maps");
        case OsmAndResourceType::Travel:
            return OALocalizedString(@"shared_string_wikivoyage");
        default:
            return OALocalizedString(@"res_unknown");
    }
}

+ (NSString *)getIconName:(OsmAndResourceType)type
{
    NSString *imageNamed;
    switch (type)
    {
        case OsmAndResourceType::VoicePack:
            imageNamed = @"ic_custom_sound";
            break;
        case OsmAndResourceType::SrtmMapRegion:
        case OsmAndResourceType::DepthContourRegion:
            imageNamed = @"ic_custom_contour_lines";
            break;
        case OsmAndResourceType::WikiMapRegion:
            imageNamed = @"ic_custom_wikipedia";
            break;
        case OsmAndResourceType::LiveUpdateRegion:
            imageNamed = @"ic_custom_upload"; //ic_custom_online
            break;
        case OsmAndResourceType::GpxFile:
            imageNamed = @"ic_custom_route";
            break;
        case OsmAndResourceType::SqliteFile:
            imageNamed = @"ic_custom_overlay_map";
            break;
        case OsmAndResourceType::MapStyle:
            imageNamed = @"ic_custom_map_style";
            break;
        case OsmAndResourceType::MapStylesPresets:
            imageNamed = @"ic_custom_options";
            break;
        case OsmAndResourceType::OnlineTileSources:
            imageNamed = @"ic_custom_map_online";
            break;
        case OsmAndResourceType::WeatherForecast:
            imageNamed = @"ic_custom_umbrella";
            break;
        case OsmAndResourceType::Travel:
            imageNamed = @"ic_custom_wikipedia";
            break;
        case OsmAndResourceType::GeoTiffRegion:
        case OsmAndResourceType::HeightmapRegionLegacy:
            imageNamed = @"ic_custom_terrain";
            break;
        default:
            imageNamed = @"ic_custom_map";
            break;
    }
    return imageNamed;
}

+ (UIImage *)getIcon:(OsmAndResourceType)type templated:(BOOL)templated
{
    NSString *imageNamed = [self.class getIconName:type];
    return templated ? [UIImage templateImageNamed:imageNamed] : [UIImage imageNamed:imageNamed];
}

+ (NSInteger)getOrderIndex:(NSNumber *)type
{
    switch ([self.class toResourceType:type isGroup:NO])
    {
        case OsmAndResourceType::MapRegion:
            return 10;
        case OsmAndResourceType::VoicePack:
            return 20;
//        case FONT_FILE:
//            return 25;
        case OsmAndResourceType::RoadMapRegion:
            return 30;
        case OsmAndResourceType::SrtmMapRegion:
            return 40;
        case OsmAndResourceType::DepthContourRegion:
        case OsmAndResourceType::DepthMapRegion:
            return 45;
        case OsmAndResourceType::WikiMapRegion:
            return 60;
//        case WIKIVOYAGE_FILE:
//            return 65;
        case OsmAndResourceType::Travel:
            return 66;
        case OsmAndResourceType::LiveUpdateRegion:
            return 70;
        case OsmAndResourceType::GpxFile:
            return 75;
        case OsmAndResourceType::SqliteFile:
            return 80;
        case OsmAndResourceType::WeatherForecast:
            return 85;
        default:
            return 1000; //HeightmapRegionLegacy, GeoTiffRegion, MapStyle, MapStylesPresets, OnlineTileSources
    }
}

+ (OsmAndResourceType)resourceTypeByScopeId:(NSString *)scopeId
{
    if ([scopeId isEqualToString:@"map"])
        return OsmAndResourceType::MapRegion;
    else if ([scopeId isEqualToString:@"voice"])
        return OsmAndResourceType::VoicePack;
//    else if ([scopeId isEqualToString:@"fonts"])
//        return OsmAnd::ResourcesManager::ResourceType::Unknown;
    else if ([scopeId isEqualToString:@"road_map"])
        return OsmAndResourceType::RoadMapRegion;
    else if ([scopeId isEqualToString:@"srtm_map"])
        return OsmAndResourceType::SrtmMapRegion;
    else if ([scopeId isEqualToString:@"depth"])
        return OsmAndResourceType::DepthContourRegion;
    else if ([scopeId isEqualToString:@"depthmap"])
        return OsmAndResourceType::DepthMapRegion;
    else if ([scopeId isEqualToString:@"wikimap"])
        return OsmAndResourceType::WikiMapRegion;
//    else if ([scopeId isEqualToString:@"wikivoyage"])
//        return OsmAnd::ResourcesManager::ResourceType::MapRegion;
    else if ([scopeId isEqualToString:@"travel"])
        return OsmAnd::ResourcesManager::ResourceType::Travel;
    else if ([scopeId isEqualToString:@"live_updates"])
        return OsmAndResourceType::LiveUpdateRegion;
    else if ([scopeId isEqualToString:@"gpx"])
        return OsmAndResourceType::GpxFile;
    else if ([scopeId isEqualToString:@"sqlite"])
        return OsmAndResourceType::SqliteFile;
    else if ([scopeId isEqualToString:@"weather_forecast"])
        return OsmAndResourceType::WeatherForecast;
    else if ([scopeId isEqualToString:@"heightmap"])
        return OsmAndResourceType::GeoTiffRegion;

    //TODO: add another types from ResourcesManager.h
    //MapStyle,
    //MapStylesPresets,
    //OnlineTileSources,

    return OsmAnd::ResourcesManager::ResourceType::Unknown;
}

+ (OsmAndResourceType)unknownType
{
    return OsmAndResourceType::Unknown;
}

+ (NSArray<NSNumber *> *)allResourceTypes
{
    return @[
            [self.class toValue:OsmAndResourceType::MapRegion],
            [self.class toValue:OsmAndResourceType::VoicePack],
            [self.class toValue:OsmAndResourceType::RoadMapRegion],
            [self.class toValue:OsmAndResourceType::SrtmMapRegion],
            [self.class toValue:OsmAndResourceType::DepthContourRegion],
            [self.class toValue:OsmAndResourceType::DepthMapRegion],
            [self.class toValue:OsmAndResourceType::WikiMapRegion],
            [self.class toValue:OsmAndResourceType::LiveUpdateRegion],
            [self.class toValue:OsmAndResourceType::GpxFile],
            [self.class toValue:OsmAndResourceType::SqliteFile],
            [self.class toValue:OsmAndResourceType::HeightmapRegionLegacy],
            [self.class toValue:OsmAndResourceType::GeoTiffRegion],
            [self.class toValue:OsmAndResourceType::MapStyle],
            [self.class toValue:OsmAndResourceType::MapStylesPresets],
            [self.class toValue:OsmAndResourceType::OnlineTileSources],
            [self.class toValue:OsmAndResourceType::WeatherForecast],
            [self.class toValue:OsmAndResourceType::Travel]
    ];
}

+ (NSArray<NSNumber *> *)mapResourceTypes
{
    return @[
            [self.class toValue:OsmAndResourceType::MapRegion],
            [self.class toValue:OsmAndResourceType::RoadMapRegion],
            [self.class toValue:OsmAndResourceType::SrtmMapRegion],
            [self.class toValue:OsmAndResourceType::WikiMapRegion],
            [self.class toValue:OsmAndResourceType::WeatherForecast]
    ];
}

+ (BOOL)isMapResourceType:(OsmAndResourceType)type
{
    return [[self.class mapResourceTypes] containsObject:[self.class toValue:type]];
}

+ (OsmAndResourceType)toResourceType:(NSNumber *)value isGroup:(BOOL)isGroup;
{
    if (![isGroup ? [self.class mapResourceTypes] : [self.class allResourceTypes] containsObject:value])
        return [self.class unknownType];

    return (OsmAndResourceType) value.intValue;
}

+ (NSNumber *)toValue:(OsmAndResourceType)type
{
    return @((int) type);
}

+ (BOOL)isSRTMResourceType:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
{
    return resource->type == OsmAndResourceType::SrtmMapRegion;
}

+ (BOOL)isSRTMResourceItem:(OAResourceItem *)item
{
    return item.resourceType == OsmAndResourceType::SrtmMapRegion;
}

+ (BOOL)isSingleSRTMResourceItem:(OAMultipleResourceItem *)item
{
    return [self.class isSRTMResourceItem:item] && item.items.count == 2 && [item.items[0].title isEqualToString:item.items[1].title];
}

+ (BOOL)isSRTMF:(OAResourceItem *)item
{
    return [self.class isSRTMResourceItem:item] && item.resourceId.endsWith(".srtmf.obf");
}

+ (BOOL)isSRTMFSettingOn
{
    return [OAAppSettings sharedManager].metricSystem.get == EOAMetricsConstant::MILES_AND_FEET;
}

+ (NSString *)getSRTMFormatShort:(BOOL)isSRTMF
{
    return isSRTMF ? OALocalizedString(@"foot") : OALocalizedString(@"m");
}

+ (NSString *)getSRTMFormatLong:(BOOL)isSRTMF
{
    return isSRTMF ? OALocalizedString(@"shared_string_feet") : OALocalizedString(@"shared_string_meters");
}

+ (NSString *)getSRTMFormatItem:(OAResourceItem *)item longFormat:(BOOL)longFormat
{
    if (![self.class isSRTMResourceItem:item])
        return nil;

    BOOL isSRTMF = [self.class isSRTMF:item];
    return longFormat ? [self.class getSRTMFormatLong:isSRTMF] : [self.class getSRTMFormatShort:isSRTMF];
}

+ (NSString *)getSRTMFormatResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource longFormat:(BOOL)longFormat
{
    if (![self.class isSRTMResourceType:resource])
        return nil;

    BOOL isSRTMF = resource->id.endsWith(".srtmf.obf");
    return longFormat ? [self.class getSRTMFormatLong:isSRTMF] : [self.class getSRTMFormatShort:isSRTMF];
}

@end

@interface OAResourceGroupItem ()

@property (nonatomic) NSString *key;
@property (nonatomic, weak) OAWorldRegion *region;

@end

@implementation OAResourceGroupItem
{
    NSMutableDictionary<NSNumber *, NSArray<OAResourceItem *> *> *_individualDownloadItems;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _individualDownloadItems = [NSMutableDictionary new];
    }
    return self;
}

+ (instancetype)withParent:(OAWorldRegion *)parentRegion
{
    OAResourceGroupItem *resourceGroupItem = [[OAResourceGroupItem alloc] init];
    if (resourceGroupItem)
    {
        resourceGroupItem.key = parentRegion.regionId;
        resourceGroupItem.region = parentRegion;
    }
    return resourceGroupItem;
}

- (BOOL)isEmpty
{
    return _individualDownloadItems.count == 0;
}

- (BOOL)hasItems:(OsmAndResourceType)key
{
    return ![self isEmpty] && [self.getTypes containsObject:@((int)key)];
}

- (NSArray<NSNumber *> *)getTypes
{
    return _individualDownloadItems.allKeys;
}

- (NSArray<OAResourceItem *> *)getItems:(OsmAndResourceType)key
{
    return _individualDownloadItems[[OAResourceType toValue:key]];
}

- (void)addItem:(OAResourceItem *)item key:(OsmAndResourceType)key
{
    _individualDownloadItems[[OAResourceType toValue:key]] = [self hasItems:key] ? [[self getItems:key] arrayByAddingObject:item] : @[item];
}

- (void)addItems:(NSArray<OAResourceItem *> *)items key:(OsmAndResourceType)key
{
    _individualDownloadItems[[OAResourceType toValue:key]] = [self hasItems:key] ? [[self getItems:key] arrayByAddingObjectsFromArray:items] : items;
}

- (void)removeItem:(OsmAndResourceType)key subregion:(OAWorldRegion *)subregion
{
    NSMutableArray<OAResourceItem *> *items = [[self getItems:key] mutableCopy];
    NSMutableArray<OAResourceItem *> *itemsToRemove = [NSMutableArray new];
    for (OAResourceItem *item in items)
    {
        if (item.worldRegion == subregion)
            [itemsToRemove addObject:item];
    }
    if (itemsToRemove.count > 0)
    {
        [items removeObjectsInArray:itemsToRemove];
        _individualDownloadItems[[OAResourceType toValue:key]] = [NSArray arrayWithArray:items];
    }
}

- (void)sort
{
    if (![self isEmpty])
    {
        for (NSNumber *key in [self getTypes])
        {
            NSMutableArray<OAResourceItem *> *individualDownloadItems = [[self getItems:[OAResourceType toResourceType:key isGroup:YES]] mutableCopy];
            [individualDownloadItems sortUsingComparator:^NSComparisonResult(OAResourceItem *resource1, OAResourceItem *resource2) {
                return [resource1.title localizedCompare:resource2.title];
            }];
            _individualDownloadItems[key] = [NSArray arrayWithArray:individualDownloadItems];
        }
    }
}

@end

@implementation OAResourceItem

- (BOOL) isEqual:(id)object
{
    if (self.resourceId == nullptr || ((OAResourceItem *)object).resourceId == nullptr)
        return NO;

    return self.resourceId.compare(((OAResourceItem *)object).resourceId) == 0;
}

- (void) updateSize
{
    // override
}

- (NSString *)getDate
{
    if (self.date)
    {
        NSDateFormatter *currentLocaleFormat = [[NSDateFormatter alloc] init];
        currentLocaleFormat.locale = [NSLocale currentLocale];
        currentLocaleFormat.dateStyle = NSDateFormatterMediumStyle;
        return [currentLocaleFormat stringFromDate:self.date];
    }
    return nil;
}

- (BOOL)isInstalled
{
    return [OsmAndApp instance].resourcesManager->isResourceInstalled(_resourceId);
}

- (BOOL)isFree
{
    return NO;
}

@end

@implementation OARepositoryResourceItem

- (BOOL)isFree
{
    return _resource && _resource->free;
}

@end

@interface OAMultipleResourceItem ()

@property (nonatomic) NSArray<OAResourceItem *> *items;

@end

@implementation OAMultipleResourceItem

- (instancetype)initWithType:(OsmAndResourceType)resourceType items:(NSArray<OAResourceItem *> *)items
{
    self = [super init];
    if (self)
    {
        self.resourceType = resourceType;
        NSMutableArray<OAResourceItem *> *resourceItems = [NSMutableArray new];
        for (OAResourceItem *item in items)
        {
            NSString *key = @"";
            if ([item isKindOfClass:OARepositoryResourceItem.class])
                key = ((OARepositoryResourceItem *) item).resource->id.toNSString();
            else if ([item isKindOfClass:OALocalResourceItem.class])
                key = ((OALocalResourceItem *) item).resource->id.toNSString();

            item.downloadTask = [[[OsmAndApp instance].downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:key]] firstObject];

            [resourceItems addObject:item];
            if ([item isKindOfClass:OALocalResourceItem.class])
            {
                self.size += ((OALocalResourceItem *) item).resource->size;
                self.sizePkg += [OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId)->packageSize;
            }
            else if ([item isKindOfClass:OARepositoryResourceItem.class])
            {
                OARepositoryResourceItem *repositoryItem = (OARepositoryResourceItem *) item;
                self.size += repositoryItem.resource->size;
                self.sizePkg += repositoryItem.resource->packageSize;
            }
        }
        self.items = [NSArray arrayWithArray:resourceItems];
    }
    return self;
}

- (BOOL) allDownloaded
{
    if (self.resourceType == OsmAndResourceType::SrtmMapRegion)
    {
        NSMutableArray *srtmItems = [NSMutableArray array];
        NSMutableArray *srtmFeetItems = [NSMutableArray array];
        
        for (OAResourceItem *item in _items)
        {
            if ([OAResourceType isSRTMF:item])
                [srtmFeetItems addObject:item];
            else
                [srtmItems addObject:item];
        }
        BOOL isSrtmItemsDownloaded = [self allItemsDownloaded:srtmItems];
        BOOL isSrtmFeetItemsDownloaded = [self allItemsDownloaded:srtmFeetItems];
        
        return isSrtmItemsDownloaded || isSrtmFeetItemsDownloaded;
    }
    else
    {
        return [self allItemsDownloaded:_items];
    }
}

- (BOOL) allItemsDownloaded:(NSArray<OAResourceItem *> *)items
{
    NSInteger downloadedCount = 0;
    for (OAResourceItem *item in items)
    {
        if ([OsmAndApp instance].resourcesManager->isResourceInstalled(item.resourceId))
            downloadedCount++;
    }
    return downloadedCount == items.count;
}

- (OAResourceItem *) getActiveItem:(BOOL)useDefautValue
{
    if (_items && _items.count > 0)
    {
        for (OAResourceItem *item in _items)
        {
            if (item.downloadTask != nil)
                return item;
        }
        if (useDefautValue)
            return _items[0];
    }
    return nil;
}

- (NSString *) getResourceId
{
    if (_items && _items.count > 0)
    {
        OAResourceItem *firstItem = _items[0];
        NSString *resourceId = firstItem.resourceId.toNSString();
        return [resourceId stringByReplacingOccurrencesOfString:@"srtmf" withString:@"srtm"];
    }
    return nil;
}

@end

@implementation OALocalResourceItem

- (BOOL)isInstalled
{
    return YES;
}

@end

@implementation OAOutdatedResourceItem
@end

@implementation OAMapSourceResourceItem
@end

@implementation OASqliteDbResourceItem

- (void) updateSize
{
    self.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil] fileSize];
}

@end

@implementation OAOnlineTilesResourceItem
@end

@implementation OAMapStyleResourceItem
@end

@implementation OACustomResourceItem

- (NSString *) getTargetFilePath
{
    if (self.downloadContent && ![self.downloadContent[@"sql"] boolValue])
        return self.getBasePathByExtension;

    NSString *fileName = self.title;
    if (self.subfolder && self.subfolder.length > 0)
    {
        fileName = [self.subfolder stringByAppendingPathComponent:fileName];
    }
    return [self.getBasePathByExtension stringByAppendingPathComponent:fileName];
}

- (NSString *) getBasePathByExtension
{
    NSString *titleWithoutExt = self.title;
    if ([titleWithoutExt.pathExtension isEqualToString:@"gz"] ||
        ([titleWithoutExt.pathExtension isEqualToString:@"zip"] && ![self.title hasSuffix:BINARY_MAP_INDEX_EXT_ZIP]))
    {
        titleWithoutExt = [titleWithoutExt stringByDeletingPathExtension];
    }
    if ([titleWithoutExt hasSuffix:SQLITE_EXT])
    {
        BOOL isSqlSource = YES;
        if (self.downloadContent)
            isSqlSource = [self.downloadContent[@"sql"] boolValue];

        if (isSqlSource)
            return [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:MAP_CREATOR_DIR];
        else
            return [OsmAndApp.instance.cachePath stringByAppendingPathComponent:self.downloadContent[@"name"]];
    }
    else if ([titleWithoutExt.lowercaseString hasSuffix:GPX_FILE_EXT])
        return OsmAndApp.instance.gpxPath;
    else if ([titleWithoutExt hasSuffix:BINARY_MAP_INDEX_EXT_ZIP])
        return self.hidden ? OsmAndApp.instance.hiddenMapsPath : OsmAndApp.instance.documentsPath;
    return OsmAndApp.instance.documentsPath;
}

- (NSString *) getVisibleName
{
    return [OAJsonHelper getLocalizedResFromMap:_names defValue:@""];
}

- (NSString *) getSubName
{
    NSString *subName = [self getFirstSubName];

    NSString *secondSubName = [self getSecondSubName];
    if (secondSubName)
        subName = subName == nil ? secondSubName : [NSString stringWithFormat:@"%@ • %@", subName, secondSubName];
    return subName;
}

- (NSString *) getFirstSubName
{
    return [OAJsonHelper getLocalizedResFromMap:_firstSubNames defValue:nil];
}

- (NSString *) getSecondSubName
{
    return [OAJsonHelper getLocalizedResFromMap:_secondSubNames defValue:nil];
}

- (BOOL) isInstalled
{
    NSString *pathForUnzippedResource = self.getTargetFilePath;
    if ([self.getTargetFilePath hasSuffix:@".zip"] || [self.getTargetFilePath hasSuffix:@".gz"])
        pathForUnzippedResource = pathForUnzippedResource.stringByDeletingPathExtension;
    return [NSFileManager.defaultManager fileExistsAtPath:pathForUnzippedResource];
}

@end

@implementation OAResourcesUIHelper

+ (NSString *)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource> &)resource
                     inRegion:(OAWorldRegion *)region
               withRegionName:(BOOL)includeRegionName
             withResourceType:(BOOL)includeResourceType
{
    if (region == [OsmAndApp instance].worldRegion)
    {
        if (resource->id == QLatin1String(kWorldBasemapKey))
        {
            if (includeRegionName)
                return OALocalizedString(@"res_wmap");
            else
                return OALocalizedString(@"res_dmap");
        }
        else if (resource->id == QLatin1String(kWorldSeamarksKey) || resource->id == QLatin1String(kWorldSeamarksOldKey))
        {
            if (includeRegionName)
                return OALocalizedString(@"res_wsea_map");
            else
                return OALocalizedString(@"res_wsea_map");
        }

        // By default, world region has only predefined set of resources
        return nil;
    }
    else if ([region.regionId isEqualToString:OsmAnd::WorldRegions::NauticalRegionId.toNSString()])
    {
        if (resource->id == QLatin1String(kWorldSeamarksKey) || resource->id == QLatin1String(kWorldSeamarksOldKey))
            return OALocalizedString(@"res_wsea_map");

        auto name = resource->id;
        name = name.remove(QStringLiteral(".depth.obf")).replace('_', ' ');
        return name.toNSString().capitalizedString;
    }
    else if ([region.regionId isEqualToString:OsmAnd::WorldRegions::TravelRegionId.toNSString()])
    {
        auto name = resource->id;
        name = name.remove(QStringLiteral(".travel.obf")).replace('_', ' ');
        return name.toNSString().capitalizedString;
    }

    return [OAResourcesUIHelper titleOfResourceType:resource->type inRegion:region withRegionName:includeRegionName withResourceType:includeResourceType];
}

+ (NSString *)titleOfResourceType:(OsmAndResourceType)type
                         inRegion:(OAWorldRegion *)region
                   withRegionName:(BOOL)includeRegionName
                 withResourceType:(BOOL)includeResourceType
{
    NSString *nameStr;
    switch (type)
    {
        case OsmAndResourceType::MapRegion:
        case OsmAndResourceType::RoadMapRegion:
        case OsmAndResourceType::SrtmMapRegion:
        case OsmAndResourceType::WikiMapRegion:
        case OsmAndResourceType::WeatherForecast:
        case OsmAndResourceType::HeightmapRegionLegacy:
        case OsmAndResourceType::GeoTiffRegion:
            if ([region.subregions count] > 0)
            {
                if (!includeRegionName || region == nil)
                    nameStr = OALocalizedString(@"res_mapsres");
                else
                    nameStr =  OALocalizedString(@"%@", region.name);
            }
            else
            {
                if (!includeRegionName || region == nil)
                    nameStr =  OALocalizedString(@"res_mapsres");
                else
                    nameStr =  OALocalizedString(@"%@", region.name);
            }
            break;

        default:
            nameStr = nil;
    }

    if (!nameStr)
        return nil;

    if (includeResourceType)
        nameStr = [nameStr stringByAppendingString:[NSString stringWithFormat:@" - %@", [OAResourceType resourceTypeLocalized:type]]];

    return nameStr;
}

+ (BOOL) isSpaceEnoughToDownloadAndUnpackOf:(OAResourceItem *)item_
{
    if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
    {
        OARepositoryResourceItem* item = (OARepositoryResourceItem*)item_;

        return [self.class isSpaceEnoughToDownloadAndUnpackResource:item.resource];
    }
    else if ([item_ isKindOfClass:[OALocalResourceItem class]])
    {
        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto resource = _app.resourcesManager->getResourceInRepository(item_.resourceId);

        return [self.class isSpaceEnoughToDownloadAndUnpackResource:resource];
    }

    return NO;
}

+ (BOOL) isSpaceEnoughToDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    uint64_t spaceNeeded = resource->packageSize + resource->size;
    return (_app.freeSpaceAvailableOnDevice >= spaceNeeded);
}

+ (BOOL) verifySpaceAvailableToDownloadAndUnpackOf:(OAResourceItem*)item_ asUpdate:(BOOL)isUpdate
{
    if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
    {
        OARepositoryResourceItem* item = (OARepositoryResourceItem*)item_;
        uint64_t spaceNeeded = item.resource->packageSize + item.resource->size;
        NSString *resourceName = [self.class titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];
        return [self.class verifySpaceAvailableDownloadAndUnpackResource:spaceNeeded withResourceName:resourceName asUpdate:isUpdate];
    }
    else if ([item_ isKindOfClass:[OALocalResourceItem class]])
    {
        OALocalResourceItem* item = (OALocalResourceItem*)item_;
        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto resource = _app.resourcesManager->getResourceInRepository(item.resourceId);
        uint64_t spaceNeeded = resource->packageSize + resource->size;
        NSString *resourceName = [self.class titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];
        return [self.class verifySpaceAvailableDownloadAndUnpackResource:spaceNeeded withResourceName:resourceName asUpdate:isUpdate];
    }
    return NO;
}

+ (BOOL) verifySpaceAvailableDownloadAndUnpackResource:(uint64_t)spaceNeeded withResourceName:(NSString*)resourceName asUpdate:(BOOL)isUpdate
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    BOOL isEnoughSpace = (_app.freeSpaceAvailableOnDevice >= spaceNeeded);

    if (!isEnoughSpace)
        [self showNotEnoughSpaceAlertFor:resourceName withSize:spaceNeeded asUpdate:isUpdate];

    return isEnoughSpace;
}

+ (void) showNotEnoughSpaceAlertFor:(NSString*)resourceName
                           withSize:(unsigned long long)size
                           asUpdate:(BOOL)isUpdate
{
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];

    NSMutableString* text;
    if (isUpdate)
    {
        text = [OALocalizedString(@"res_update_no_space") mutableCopy];
        [text appendString:@" "];
        [text appendString:resourceName];
        [text appendString:@"."];
        [text appendString:@" "];
        [text appendString:stringifiedSize];
        [text appendString:@" "];
        [text appendString:OALocalizedString(@"res_no_space_free")];
    }
    else
    {
        text = [OALocalizedString(@"res_install_no_space") mutableCopy];
        [text appendString:@" "];
        [text appendString:resourceName];
        [text appendString:@"."];
        [text appendString:@" "];
        [text appendString:stringifiedSize];
        [text appendString:@" "];
        [text appendString:OALocalizedString(@"res_no_space_free")];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (BOOL) checkIfDownloadAvailable
{
    NSInteger tasksCount = [OsmAndApp instance].downloadsManager.keysOfDownloadTasks.count;
    return ([OAIAPHelper freeMapsAvailable] > 0 && tasksCount < [OAIAPHelper freeMapsAvailable]);
}

+ (BOOL) checkIfDownloadAvailable:(OAWorldRegion *)region
{
    NSInteger tasksCount = [OsmAndApp instance].downloadsManager.keysOfDownloadTasks.count;
    const auto res = OsmAndApp.instance.resourcesManager->getResourceInRepository(QString::fromNSString(region.regionId));
    bool free = res && res->free;

    if (region.regionId == nil || [region isInPurchasedArea] || free || ([OAIAPHelper freeMapsAvailable] > 0 && tasksCount < [OAIAPHelper freeMapsAvailable]))
        return YES;

    return NO;
}

+ (void)startBackgroundDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource  resourceName:(NSString *)name
{
    [self startBackgroundDownloadOf:resource->url.toNSURL() resourceId:resource->id.toNSString() resourceName:name];
}

+ (void)startBackgroundDownloadOf:(const std::shared_ptr<const IncrementalUpdate>&)resource
{
    [self startBackgroundDownloadOf:resource->url.toNSURL() resourceId:resource->resId.toNSString() resourceName:resource->fileName.toNSString()];
}

+ (void)startBackgroundDownloadOf:(NSURL *)resourceUrl resourceId:(NSString *)resourceId resourceName:(NSString *)name
{
    // Create download tasks
    NSString* ver = OAAppVersion.getVersion;
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [resourceUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    NSLog(@"%@", url);

    id<OADownloadTask> task = [[OsmAndApp instance].downloadsManager downloadTaskWithRequest:request
                                                                                      andKey:[@"resource:" stringByAppendingString:resourceId]
                                                                                     andName:name
                                                                                   andHidden:NO];

    if ([[OsmAndApp instance].downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
        [task resume];
}

+ (OAWorldRegion*) findRegionOrAnySubregionOf:(OAWorldRegion*)region
                         thatContainsResource:(const QString&)resourceId
{
    const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);
    const auto acceptedExtension = QString::fromNSString(region.acceptedExtension);

    if (!acceptedExtension.isEmpty())
    {
        if (resourceId.endsWith(acceptedExtension))
            return region;
        return nil;
    }
    else if (resourceId.startsWith(downloadsIdPrefix))
    {
        return region;
    }

    for (OAWorldRegion* subregion in region.subregions)
    {
        OAWorldRegion* match = [self.class findRegionOrAnySubregionOf:subregion thatContainsResource:resourceId];
        if (match)
            return match;
    }

    return nil;
}

+ (NSArray<NSString *> *) getInstalledResourcePathsByTypes:(QSet<OsmAndResourceType>)resourceTypes
includeHidden:(BOOL)includeHidden
{
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    OsmAndAppInstance app = [OsmAndApp instance];
    for (const auto& localResource : app.resourcesManager->getLocalResources())
    {
        if (localResource->origin != OsmAnd::ResourcesManager::ResourceOrigin::Installed)
            continue;
        if (!includeHidden && app.resourcesManager->isLocalResourceHidden(localResource))
            continue;

        const auto& installedResource = std::static_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);
        // Skip mini basemap since it's builtin and not installed in ios
        if (resourceTypes.contains(installedResource->type) && installedResource->id != QString::fromNSString(kWorldMiniBasemapKey.lowercaseString))
            [items addObject:installedResource->localPath.toNSString()];
    }
    return items;
}

+ (NSArray<OAResourceItem *> *) findIndexItemsAt:(NSArray<NSString *> *)names
                                            type:(OsmAndResourceType)type
                               includeDownloaded:(BOOL)includeDownloaded
                                           limit:(NSInteger)limit
{
    NSMutableArray<OAResourceItem *>* res = [NSMutableArray new];
    OAWorldRegion *worldRegion = OsmAndApp.instance.worldRegion;

    for (NSString *name in names)
    {
        OAWorldRegion *downloadRegion = [worldRegion getRegionDataByDownloadName:name];

        if (downloadRegion && (includeDownloaded || ![OAResourcesUIHelper isIndexItemDownloaded:type downloadRegion:downloadRegion res:res]))
            [self.class addIndexItem:type downloadRegion:downloadRegion res:res];

        if (limit != -1 && res.count == limit)
            break;
    }
    return res;
}

+ (NSArray<OAResourceItem *> *) findIndexItemsAt:(CLLocationCoordinate2D)coordinate
                                            type:(OsmAndResourceType)type
                               includeDownloaded:(BOOL)includeDownloaded
                                           limit:(NSInteger)limit
                             skipIfOneDownloaded:(BOOL)skipIfOneDownloaded
{
    NSMutableArray<OAResourceItem *> *res = [NSMutableArray array];
    OAWorldRegion *worldRegion = [[OsmAndApp instance].worldRegion findAtLat:coordinate.latitude lon:coordinate.longitude];
    if (!worldRegion)
        return res;

    NSArray<OAWorldRegion *> *downloadRegions = [[OsmAndApp instance].worldRegion queryAtLat:coordinate.latitude lon:coordinate.longitude];

    for (OAWorldRegion *downloadRegion in downloadRegions)
    {
        if ([worldRegion.regionId hasPrefix:downloadRegion.regionId] || [downloadRegion.regionId hasPrefix:worldRegion.regionId])
        {
            BOOL itemDownloaded = [self.class isIndexItemDownloaded:type downloadRegion:downloadRegion res:res];

            if (skipIfOneDownloaded && itemDownloaded)
                return [NSArray array];

            if (includeDownloaded || !itemDownloaded)
                [self.class addIndexItem:type downloadRegion:downloadRegion res:res];

            if (limit != -1 && res.count == limit)
                break;
        }
    }
    return res;
}

+ (BOOL) isIndexItemDownloaded:(OsmAndResourceType)type downloadRegion:(OAWorldRegion *)downloadRegion res:(NSMutableArray<OAResourceItem *>*)res
{
    NSArray<NSString *> *otherIndexItems = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:downloadRegion];
    for (NSString *resourceId in otherIndexItems)
    {
        const auto resource = [OsmAndApp instance].resourcesManager->getResource(QString::fromNSString(resourceId));
        if (resource && resource->type == type && resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed)
            return YES;
    }
    return downloadRegion.superregion != nil && [self.class isIndexItemDownloaded:type downloadRegion:downloadRegion.superregion res:res];
}

+ (BOOL) addIndexItem:(OsmAndResourceType)type downloadRegion:(OAWorldRegion *)downloadRegion res:(NSMutableArray<OAResourceItem *>*)res
{
    NSArray<OAResourceItem *> *otherIndexItems = [OAResourcesUIHelper requestMapDownloadInfo:@[downloadRegion] resourceTypes:@[[OAResourceType toValue:type]] isGroup:NO];

    for (OAResourceItem *indexItem in otherIndexItems)
    {
        if (![res containsObject:indexItem])
        {
            [res addObject:indexItem];
            return YES;
        }
    }
    return downloadRegion.superregion != nil && [self.class addIndexItem:type downloadRegion:downloadRegion.superregion res:res];
}

+ (NSArray<OAResourceItem *> *)requestMapDownloadInfo:(NSArray<OAWorldRegion *> *)subregions
                                        resourceTypes:(NSArray<NSNumber *> *)resourceTypes
                                              isGroup:(BOOL)isGroup
{
    NSMutableArray<OAResourceItem *> *resources = [NSMutableArray new];
    for (NSNumber *resourceType in resourceTypes)
    {
        OsmAndResourceType type = [OAResourceType toResourceType:resourceType isGroup:isGroup];
        if (type != [OAResourceType unknownType])
            [resources addObjectsFromArray:[OAResourcesUIHelper requestMapDownloadInfo:kCLLocationCoordinate2DInvalid resourceType:type subregions:subregions checkForMissed:YES]];
    }
    return [NSArray arrayWithArray:resources];
}

+ (void)requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate
                  resourceType:(OsmAndResourceType)resourceType
                    onComplete:(void (^)(NSArray<OAResourceItem *>*))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OAResourceItem *> * res = [OAResourcesUIHelper requestMapDownloadInfo:coordinate resourceType:resourceType subregions:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (onComplete)
                onComplete(res);
        });
    });
}

+ (NSArray<OAResourceItem *> *)requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate
                                         resourceType:(OsmAndResourceType)resourceType
                                           subregions:(NSArray<OAWorldRegion *> *)subregions
{
    return [self requestMapDownloadInfo:coordinate resourceType:resourceType subregions:subregions checkForMissed:NO];
}

+ (NSArray<OAResourceItem *> *)requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate
                                         resourceType:(OsmAndResourceType)resourceType
                                           subregions:(NSArray<OAWorldRegion *> *)subregions
                                       checkForMissed:(BOOL)checkForMissed
{
    NSMutableArray<OAResourceItem *> *res = [NSMutableArray new];
    NSArray *sortedSelectedRegions;
    OsmAndAppInstance app = [OsmAndApp instance];

    NSMutableArray<OAWorldRegion *> *mapRegions = subregions ? [subregions mutableCopy] : [NSMutableArray new];
    if (CLLocationCoordinate2DIsValid(coordinate))
    {
        mapRegions = [[app.worldRegion queryAtLat:coordinate.latitude lon:coordinate.longitude] mutableCopy];
        if (mapRegions.count > 0) {
            [mapRegions.copy enumerateObjectsUsingBlock:^(OAWorldRegion *_Nonnull region, NSUInteger idx, BOOL *_Nonnull stop) {
                if (![region contain:coordinate.latitude lon:coordinate.longitude])
                    [mapRegions removeObject:region];
            }];
        }
    }

    if (mapRegions.count > 0)
    {
        sortedSelectedRegions = [mapRegions sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *first = @([(OAWorldRegion *) a getArea]);
            NSNumber *second = @([(OAWorldRegion *) b getArea]);
            return [first compare:second];
        }];

        for (OAWorldRegion *region in sortedSelectedRegions)
        {
            BOOL found = NO;
            NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
            if (ids.count > 0)
            {
                for (NSString *resourceId in ids)
                {
                    const auto& resource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                    // Speacial case for Saudi Arabia Rahal map
                    if (!resource)
                    {
                        const auto installedResource = app.resourcesManager->getResource(QString::fromNSString(resourceId));
                        if (installedResource && installedResource->type == resourceType)
                        {
                            OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
                            item.resourceId = installedResource->id;
                            item.resourceType = installedResource->type;
                            item.title = [self.class titleOfResource:installedResource
                                                            inRegion:region
                                                      withRegionName:YES
                                                    withResourceType:NO];
                            item.worldRegion = region;

                            const auto localResource = app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
                            if (localResource)
                            {
                                item.resource = localResource;
                                item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];

                                found = YES;
                                [res addObject:item];
                            }
                            continue;
                        }
                    }
                    else if (resource->type == resourceType)
                    {
                        if (app.resourcesManager->isResourceInstalled(resource->id))
                        {
                            OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
                            item.resourceId = resource->id;
                            item.resourceType = resource->type;
                            item.title = [self.class titleOfResource:resource
                                                            inRegion:region
                                                      withRegionName:YES
                                                    withResourceType:NO];
                            item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                            item.size = resource->size;
                            item.worldRegion = region;

                            const auto localResource = app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
                            item.resource = localResource;
                            item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];

                            found = YES;
                            [res addObject:item];
                        }
                        else
                        {
                            OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
                            item.resourceId = resource->id;
                            item.resourceType = resource->type;
                            item.title = [self.class titleOfResource:resource
                                                            inRegion:region
                                                      withRegionName:YES
                                                    withResourceType:NO];
                            item.resource = resource;
                            item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                            item.size = resource->size;
                            item.sizePkg = resource->packageSize;
                            item.worldRegion = region;
                            item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

                            found = YES;
                            [res addObject:item];
                        }
                    }
                }
            }
            
            if (!found && checkForMissed)
                return nil;
        }
    }
    return [NSArray arrayWithArray:res];
}

+ (NSArray<OARepositoryResourceItem *> *) getMapsForType:(OsmAnd::ResourcesManager::ResourceType)type latLon:(CLLocationCoordinate2D)latLon
{
    NSMutableArray<OARepositoryResourceItem *> *availableItems = [NSMutableArray array];
    NSArray<OAResourceItem *> * res = [OAResourcesUIHelper requestMapDownloadInfo:latLon resourceType:type subregions:nil];
    if (res.count > 0)
    {
        for (OAResourceItem * item in res)
        {
            if ([item isKindOfClass:OARepositoryResourceItem.class])
            {
                OARepositoryResourceItem *resource = (OARepositoryResourceItem*)item;
                [availableItems addObject:resource];
            }
        }
    }
    return [NSArray arrayWithArray:availableItems];
}

+ (void) getMapsForType:(OsmAnd::ResourcesManager::ResourceType)type latLon:(CLLocationCoordinate2D)latLon onComplete:(void (^)(NSArray<OARepositoryResourceItem *> *))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OARepositoryResourceItem *> *res = [OAResourcesUIHelper getMapsForType:type latLon:latLon];
        dispatch_async(dispatch_get_main_queue(), ^{
           if (onComplete)
               onComplete(res);
        });
    });
}

+ (NSArray<OAResourceItem *> *) getMapsForType:(OsmAnd::ResourcesManager::ResourceType)type names:(NSArray<NSString *> *)names limit:(NSInteger)limit
{
    return [OAResourcesUIHelper findIndexItemsAt:names type:type includeDownloaded:NO limit:limit];
}

+ (CLLocationCoordinate2D) getMapLocation
{
    CLLocation *loc = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
    return loc.coordinate;
}

+ (NSString *) getCountryName:(OAResourceItem *)item
{
    NSString *countryName;

    OAWorldRegion *worldRegion = [OsmAndApp instance].worldRegion;
    OAWorldRegion *region = item.worldRegion;

    if (region.superregion)
    {
        while (region.superregion != worldRegion && region.superregion != nil)
            region = region.superregion;

        if ([region.regionId isEqualToString:OsmAnd::WorldRegions::RussiaRegionId.toNSString()])
            countryName = region.name;
        else if (item.worldRegion.superregion.superregion != worldRegion)
            countryName = item.worldRegion.superregion.name;
    }

    return countryName;
}

+ (BOOL) checkIfDownloadEnabled:(OAWorldRegion *)region
{
    BOOL isAvailable = [self.class checkIfDownloadAvailable:region];
    if (!isAvailable)
    {
        OAWorldRegion * globalRegion = [region getPrimarySuperregion];
        OAProduct* product = [globalRegion getProduct];
        if (!product)
            product = OAIAPHelper.sharedInstance.allWorld;
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:product navController:[OARootViewController instance].navigationController];
        return NO;
    }
    return isAvailable;
}

+ (BOOL) checkIfUpdateEnabled:(OAWorldRegion *)region
{
    if (region.regionId == nil || [region isInPurchasedArea])
    {
        return YES;
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_updates_exp") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
        return NO;
    }
}

+ (BOOL) isInOutdatedResourcesList:(NSString *)resourceId
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    const auto outdatedResources = _app.resourcesManager->getOutdatedInstalledResources();
    for (const auto& outdatedResource : outdatedResources)
    {
        NSString *outdatedResourceId = outdatedResource->id.toNSString();
        if ([outdatedResourceId isEqualToString:resourceId])
        {
            return YES;
        }
    }
    return NO;
}

+ (void) startDownloadOfCustomItem:(OACustomResourceItem *)item
                     onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                     onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    if (item.downloadUrl)
    {
        NSString *name = [item getVisibleName];
        if (!name)
        {
            name = item.title;
            if (item.subfolder && item.subfolder.length > 0)
                name = [item.subfolder stringByAppendingPathComponent:name];
        }

        if ([item.downloadUrl hasPrefix:@"@"])
        {
            NSString *relPath = [item.downloadUrl substringFromIndex:1];
            NSString *pluginPath = [OAPluginsHelper getAbsoulutePluginPathByRegion:item.worldRegion];
            if (pluginPath.length > 0 && relPath.length > 0)
            {
                NSString *srcFilePath = [pluginPath stringByAppendingPathComponent:relPath];
                BOOL failed = [OAResourcesInstaller installCustomResource:srcFilePath resourceId:srcFilePath.lastPathComponent fileName:name hidden:item.hidden];
                if (!failed)
                    [OsmAndApp.instance.localResourcesChangedObservable notifyEvent];
            }
        }
        else
        {
            // Create download task
            NSURL *url = [NSURL URLWithString:item.downloadUrl];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];

            NSLog(@"%@", url);

            OsmAndAppInstance app = [OsmAndApp instance];
            id<OADownloadTask> task = [app.downloadsManager downloadTaskWithRequest:request
                                                                             andKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]
                                                                            andName:name
                                                                          andHidden:item.hidden];
            
            task.resourceItem = item;
            task.creationTime = [NSDate now];
            
            if (onTaskCreated)
                onTaskCreated(task);

            // Resume task only if it's other resource download tasks are not running
            if ([app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
            {
                [task resume];
                if (onTaskResumed)
                    onTaskResumed(task);
            }
        }
    }
    else if (item.downloadContent)
    {
        OATileSource *tileSource = [OATileSource tileSourceWithParameters:item.downloadContent];
        if (tileSource.isSql)
        {
            NSString *path = item.getTargetFilePath;
            if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:tileSource.toSqlParams])
                [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
        }
        else
        {
            OsmAndAppInstance app = OsmAndApp.instance;
            const auto result = tileSource.toOnlineTileSource;
            OsmAnd::OnlineTileSources::installTileSource(result, QString::fromNSString(app.cachePath));
            app.resourcesManager->installTilesResource(result);
        }
        [OsmAndApp.instance.localResourcesChangedObservable notifyEvent];
    }
}

+ (NSString *)messageResourceStartDownload:(NSString *)resourceName stringifiedSize:(NSString *)stringifiedSize isOutdated:(BOOL)isOutdated
{
    NSMutableString *message;
    if (AFNetworkReachabilityManager.sharedManager.isReachableViaWWAN)
    {
        message = !isOutdated ? [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_cell_q"), resourceName, stringifiedSize] mutableCopy] : [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        if (isOutdated)
        {
            [message appendString:resourceName];
            [message appendString:@"."];
            [message appendString:@" "];
            [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
            [message appendString:@" "];
        }
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = !isOutdated ? [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_wifi_q"),
                                                            resourceName,
                                                            stringifiedSize] mutableCopy] : [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        if (isOutdated)
        {
            [message appendString:resourceName];
            [message appendString:@"."];
            [message appendString:@" "];
            [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
            [message appendString:@" "];
        }
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    return [NSString stringWithString:message];
}

+ (void)offerDownloadAndInstallOf:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
{
    [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed completionHandler:nil silent:NO];
}

+ (void)offerDownloadAndInstallOf:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed completionHandler:(void(^)(UIAlertController *))completionHandler silent:(BOOL)silent
{
    if (item.disabled || (item.resourceType == OsmAndResourceType::MapRegion && ![self.class checkIfDownloadEnabled:item.worldRegion]))
        return;

    BOOL isWeatherForecast = item.resourceType == OsmAndResourceType::WeatherForecast;
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:isWeatherForecast ? item.sizePkg : item.resource->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    NSString *resourceName;
    if (isWeatherForecast)
    {
        resourceName = [self.class titleOfResourceType:item.resourceType
                                              inRegion:item.worldRegion
                                        withRegionName:YES
                                      withResourceType:YES];
    }
    else
    {
        resourceName = [self.class titleOfResource:item.resource
                                          inRegion:item.worldRegion
                                    withRegionName:YES
                                  withResourceType:YES];
    }

    uint64_t spaceNeeded;
    if (isWeatherForecast)
        spaceNeeded = item.sizePkg * 5;
    else
        spaceNeeded = item.resource->packageSize + item.resource->size;

    if (![self.class verifySpaceAvailableDownloadAndUnpackResource:spaceNeeded withResourceName:resourceName asUpdate:YES])
        return;
    
    if (!AFNetworkReachabilityManager.sharedManager.isReachable)
    {
        if (!silent)
        	[self showNoInternetAlert];
    }
    else if (AFNetworkReachabilityManager.sharedManager.isReachableViaWiFi)
    {
        [self.class startDownloadOfItem:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
    }
    else if (!silent)
    {
        NSString *message = [self messageResourceStartDownload:resourceName stringifiedSize:stringifiedSize isOutdated:NO];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_install") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.class startDownloadOfItem:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
        }]];
        
        if (completionHandler)
            completionHandler(alert);
        else
            [self presentAlert:alert];
    }
}

+ (void)presentAlert:(UIAlertController *)alert
{
    auto rootController = OARootViewController.instance;
    [rootController canPresentAlertController:alert completion:^(BOOL canPresent) {
        if (canPresent)
            [rootController presentViewController:alert animated:YES completion:nil];
    }];
}

+ (void)offerMultipleDownloadAndInstallOf:(OAMultipleResourceItem *)multipleItem
                            selectedItems:(NSArray<OAResourceItem *> *)selectedItems
                            onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                            onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    NSMutableArray<OAResourceItem *> *items = [selectedItems mutableCopy];
    for (OAResourceItem *item in selectedItems)
    {
        if (![multipleItem.items containsObject:item] || item.disabled || (item.resourceType == OsmAndResourceType::MapRegion && ![self.class checkIfDownloadEnabled:item.worldRegion]))
            [items removeObject:item];
    }
    if (items.count == 0)
        return;

    uint64_t totalSpaceNeeded = 0;
    uint64_t downloadSpaceNeeded = 0;
    if (items.count == multipleItem.items.count)
    {
        totalSpaceNeeded = multipleItem.sizePkg + multipleItem.size;
        downloadSpaceNeeded = multipleItem.sizePkg;
    }
    else
    {
        for (OAResourceItem *item in items)
        {
            if ([item isKindOfClass:OALocalResourceItem.class])
            {
                const auto repositoryResource = [OsmAndApp instance].resourcesManager->getResourceInRepository(((OALocalResourceItem *) item).resourceId);
                totalSpaceNeeded += repositoryResource->packageSize + repositoryResource->size;
                downloadSpaceNeeded += repositoryResource->packageSize;
            }
            else if ([item isKindOfClass:OARepositoryResourceItem.class])
            {
                OARepositoryResourceItem *repositoryItem = (OARepositoryResourceItem *) item;
                totalSpaceNeeded += repositoryItem.sizePkg + repositoryItem.size;
                downloadSpaceNeeded += repositoryItem.sizePkg;
            }
        }
    }

    NSString *resourceName = [self.class titleOfResourceType:multipleItem.resourceType inRegion:multipleItem.worldRegion withRegionName:YES withResourceType:YES];

    if (![self.class verifySpaceAvailableDownloadAndUnpackResource:totalSpaceNeeded withResourceName:resourceName asUpdate:YES])
        return;
    
    if (!AFNetworkReachabilityManager.sharedManager.isReachable)
    {
        [self showNoInternetAlert];
    }
    else if (AFNetworkReachabilityManager.sharedManager.isReachableViaWiFi)
    {
        [self.class startDownloadOfItems:items onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
    }
    else
    {
        NSString *stringifiedSize = [NSByteCountFormatter stringFromByteCount:downloadSpaceNeeded countStyle:NSByteCountFormatterCountStyleFile];
        NSString *message = [self messageResourceStartDownload:resourceName stringifiedSize:stringifiedSize isOutdated:NO];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_install") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.class startDownloadOfItems:items onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
        }]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
    }
}

+ (void)offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item
                   onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                   onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto resourceInRepository = app.resourcesManager->getResourceInRepository(item.resourceId);
    BOOL isFree = resourceInRepository && resourceInRepository->free;
    if (!isFree && ![self.class checkIfUpdateEnabled:item.worldRegion])
        return;

    NSString* resourceName = [self.class titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];

    uint64_t spaceNeeded = resourceInRepository->packageSize + resourceInRepository->size;
    if (![self.class verifySpaceAvailableDownloadAndUnpackResource:spaceNeeded withResourceName:resourceName asUpdate:YES])
        return;

    if (!AFNetworkReachabilityManager.sharedManager.isReachable)
    {
        [self showNoInternetAlert];
    }
    else if (AFNetworkReachabilityManager.sharedManager.isReachableViaWiFi)
    {
        [self.class startDownloadOf:resourceInRepository resourceName:resourceName resourceItem:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
    }
    else
    {
        NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:resourceInRepository->packageSize countStyle:NSByteCountFormatterCountStyleFile];
        NSString* message = [self.class messageResourceStartDownload:resourceName stringifiedSize:stringifiedSize isOutdated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_update") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.class startDownloadOf:resourceInRepository resourceName:resourceName resourceItem:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
        }]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
    }
}

+ (void)showNoInternetAlert
{
    NSString *message = OALocalizedString(@"alert_inet_needed");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [self presentAlert:alert];
}

+ (void)startDownloadOfItem:(OARepositoryResourceItem *)item
              onTaskCreated:(OADownloadTaskCallback)onTaskCreated
              onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    if (item.resourceType == OsmAndResourceType::WeatherForecast)
    {
        if (![[OAPluginsHelper getPlugin:OAWeatherPlugin.class] isEnabled] || ![OAIAPHelper isOsmAndProAvailable])
            return;

        NSString *regionId = [OAWeatherHelper checkAndGetRegionId:item.worldRegion];

        AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
        if (!networkManager.isReachable)
            return;
        else if (!networkManager.isReachableViaWiFi && [OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId] == EOAWeatherAutoUpdateOverWIFIOnly)
            return;
        [[OAWeatherHelper sharedInstance] preparingForDownloadForecastByRegion:item.worldRegion regionId:regionId];

        NSString *ver = OAAppVersion.getVersion;
        // https://osmand.net/download?&weather=yes&file=Weather_Angola_africa.tifsqlite.zip
        NSString *downloadsIdPrefix = [item.worldRegion.downloadsIdPrefix stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[item.worldRegion.downloadsIdPrefix substringToIndex:1] capitalizedString]];
        NSString *pureUrlString = [[NSString alloc] initWithFormat:@"https://osmand.net/download?&weather=yes&file=Weather_%@%@", downloadsIdPrefix, @"tifsqlite.zip"];
        NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver]
                            stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", pureUrlString, params];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        NSLog(@"%@", url);
        NSString* name = [self.class titleOfResourceType:item.resourceType
                                                inRegion:item.worldRegion
                                          withRegionName:YES
                                        withResourceType:YES];
        OsmAndAppInstance app = [OsmAndApp instance];
        id<OADownloadTask> task;
        if (!item.downloadTask)
            item.downloadTask = task = [app.downloadsManager downloadTaskWithRequest:request
                                                                              andKey:[@"resource:" stringByAppendingString:[NSString stringWithFormat:@"%@%@", [item.worldRegion.downloadsIdPrefix lowerCase], @"tifsqlite"]] 
                                                                             andName:name
                                                                           andHidden:item.hidden];
        else
            task = item.downloadTask;

        if (onTaskCreated)
            onTaskCreated(task);

        // Resume task only if it's other resource download tasks are not running
        if ([app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
        {
            [task resume];
            if (onTaskResumed)
                onTaskResumed(task);
        }
    }
    else
    {
        // Create download tasks
        NSString *ver = OAAppVersion.getVersion;
        NSURL *pureUrl = item.resource->url.toNSURL();
        NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        NSLog(@"%@", url);

        NSString* name = [self.class titleOfResource:item.resource
                                            inRegion:item.worldRegion
                                      withRegionName:YES
                                    withResourceType:YES];

        OsmAndAppInstance app = [OsmAndApp instance];
        id<OADownloadTask> task;
        if (!item.downloadTask)
            item.downloadTask = task = [app.downloadsManager downloadTaskWithRequest:request andKey:[@"resource:" stringByAppendingString:item.resource->id.toNSString()] andName:name andHidden:item.hidden];
        else
            task = item.downloadTask;
        
        item.downloadTask.resourceItem = item;
        item.downloadTask.creationTime = [NSDate now];

        if (onTaskCreated)
            onTaskCreated(task);

        // Resume task only if it's other resource download tasks are not running
        if ([app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
        {
            [task resume];
            if (onTaskResumed)
                onTaskResumed(task);
        }
    }
}

+ (void)startDownloadOfItems:(NSArray<OAResourceItem *> *)items onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    NSMutableArray<OAResourceItem *> *mutableItems = [items mutableCopy];
    while (mutableItems.count > 0)
    {
        OAResourceItem *item = mutableItems.firstObject;

        const auto resource = [OsmAndApp instance].resourcesManager->getResourceInRepository(item.resourceId);
        OARepositoryResourceItem *repositoryItem = [[OARepositoryResourceItem alloc] init];
        repositoryItem.resourceId = resource->id;
        repositoryItem.resourceType = resource->type;
        repositoryItem.title = [OAResourcesUIHelper titleOfResource:resource inRegion:item.worldRegion withRegionName:YES withResourceType:NO];
        repositoryItem.resource = resource;
        repositoryItem.downloadTask = item.downloadTask;
        repositoryItem.size = resource->size;
        repositoryItem.sizePkg = resource->packageSize;
        repositoryItem.worldRegion = item.worldRegion;
        repositoryItem.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

        [self.class startDownloadOfItem:repositoryItem onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
        [mutableItems removeObject:item];
    }
}

+ (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
            resourceName:(NSString *)name
            resourceItem:(OAResourceItem *)resourceItem
           onTaskCreated:(OADownloadTaskCallback)onTaskCreated
           onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    // Create download tasks
    NSString *ver = OAAppVersion.getVersion;
    NSURL *pureUrl = resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];

    NSLog(@"%@", url);

    OsmAndAppInstance app = [OsmAndApp instance];
    id<OADownloadTask> task = [app.downloadsManager downloadTaskWithRequest:request
                                                                     andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]
                                                                    andName:name
                                                                  andHidden:NO];
    task.resourceItem = resourceItem;
    task.creationTime = [NSDate now];

    if (onTaskCreated)
        onTaskCreated(task);

    // Resume task only if it's other resource download tasks are not running
    if ([app.downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
    {
        [task resume];
        if (onTaskResumed)
            onTaskResumed(task);
    }
}

+ (void) offerCancelDownloadOf:(OAResourceItem *)item_ onTaskStop:(OADownloadTaskCallback)onTaskStop
{
    [OAResourcesUIHelper offerCancelDownloadOf:item_ onTaskStop:onTaskStop completionHandler:nil];
}

+ (void) offerCancelDownloadOf:(OAResourceItem *)item_ onTaskStop:(OADownloadTaskCallback)onTaskStop completionHandler:(void(^)(UIAlertController *))completionHandler
{
    BOOL isUpdate = NO;
    NSString *resourceName;

    if ([item_ isKindOfClass:OAMultipleResourceItem.class] || item_.resourceType == OsmAndResourceType::WeatherForecast)
    {
        resourceName = [self.class titleOfResourceType:item_.resourceType inRegion:item_.worldRegion withRegionName:YES withResourceType:YES];
    }
    else if ([item_ isKindOfClass:[OALocalResourceItem class]])
    {
        OALocalResourceItem* item = (OALocalResourceItem*)item_;
        isUpdate = [item isKindOfClass:[OAOutdatedResourceItem class]];
        resourceName = [self.class titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];
    }
    else if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
    {
        OARepositoryResourceItem* item = (OARepositoryResourceItem*)item_;
        resourceName = [self.class titleOfResource:item.resource inRegion:item.worldRegion withRegionName:YES withResourceType:YES];
    }
    else if ([item_ isKindOfClass:[OACustomResourceItem class]])
    {
        OACustomResourceItem* item = (OACustomResourceItem*)item_;
        resourceName = [item getVisibleName];
    }

    if (!resourceName)
        return;

    NSMutableString* message;
    if (isUpdate)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_upd_q"), resourceName] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_inst_q"), resourceName] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([item_ isKindOfClass:OAMultipleResourceItem.class])
        {
            for (OAResourceItem *item in ((OAMultipleResourceItem *) item_).items)
            {
                [self.class cancelDownloadOf:item onTaskStop:onTaskStop];
            }
        }
        else
        {
            [self.class cancelDownloadOf:item_ onTaskStop:onTaskStop];
        }
    }]];

    if (completionHandler)
        completionHandler(alert);
    else
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

+ (void) offerCancelDownloadOf:(OAResourceItem *)item_
{
    [self.class offerCancelDownloadOf:item_ onTaskStop:nil];
}

+ (void) cancelDownloadOf:(OAResourceItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop
{
    if (item.resourceType == OsmAndResourceType::WeatherForecast)
    {
        UIView *view = [UIApplication sharedApplication].mainWindow;
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:view];
        [view addSubview:progressHUD];
        [progressHUD showAnimated:YES whileExecutingBlock:^{
            NSString *regionId = [OAWeatherHelper checkAndGetRegionId:item.worldRegion];
            if ([[OAWeatherHelper sharedInstance] isUndefinedDownloadStateFor:item.worldRegion])
                [[OAWeatherHelper sharedInstance] removeLocalForecast:regionId region: item.worldRegion refreshMap:NO];
            else if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
                [[OAWeatherHelper sharedInstance] calculateCacheSize:item.worldRegion onComplete:nil];
        } completionBlock:^{
            if (onTaskStop)
                onTaskStop(item.downloadTask);

            [item.downloadTask stop];
            [progressHUD removeFromSuperview];
        }];
    }
    else
    {
        if (onTaskStop)
            onTaskStop(item.downloadTask);

        [item.downloadTask stop];
    }
}

+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item
                viewController:(UIViewController *)viewController
                   progressHUD:(MBProgressHUD *)progressHUD
           executeAfterSuccess:(dispatch_block_t)block
{
    NSString *title;
    if ([item isKindOfClass:[OASqliteDbResourceItem class]])
    {
        title = ((OASqliteDbResourceItem *) item).title;
    }
    else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
    {
        title = ((OAOnlineTilesResourceItem *) item).title;
    }
    else if (item.resourceType == OsmAndResourceType::WeatherForecast)
    {
        title = [self.class titleOfResourceType:item.resourceType
                                       inRegion:item.worldRegion
                                 withRegionName:YES
                               withResourceType:YES];
    }
    else
    {
        title = [self.class titleOfResource:item.resource
                                   inRegion:item.worldRegion
                             withRegionName:YES
                           withResourceType:YES];
    }

    NSString* message = [NSString stringWithFormat:OALocalizedString(@"res_confirmation_delete"), title];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.class deleteResourcesOf:@[item] progressHUD:progressHUD executeAfterSuccess:block];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [alert setPreferredAction:cancelAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item
                viewController:(UIViewController *)viewController
                   progressHUD:(MBProgressHUD *)progressHUD
{
    [self offerDeleteResourceOf:item viewController:viewController progressHUD:progressHUD executeAfterSuccess:nil];
}

+ (void)deleteResourcesOf:(NSArray<OALocalResourceItem *> *)items progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    dispatch_block_t proc = ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        for (OALocalResourceItem *item in items)
        {
            if (item.resourceType == OsmAndResourceType::WeatherForecast)
            {
                NSString *regionId = [OAWeatherHelper checkAndGetRegionId:item.worldRegion];
                [[OAWeatherHelper sharedInstance] removeLocalForecast:regionId region:item.worldRegion refreshMap:item == items.lastObject];
            }
            else if ([item isKindOfClass:[OASqliteDbResourceItem class]])
            {
                OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *) item;
                [[OAMapCreatorHelper sharedInstance] removeFile:sqliteItem.fileName];
            }
            else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
            {
                OAOnlineTilesResourceItem *tilesItem = (OAOnlineTilesResourceItem *) item;
                [[NSFileManager defaultManager] removeItemAtPath:tilesItem.path error:nil];
                app.resourcesManager->uninstallTilesResource(QString::fromNSString(item.title));
                if ([tilesItem.title isEqualToString:@"OsmAnd (online tiles)"])
                    app.resourcesManager->installBuiltInTileSources();

                [app.localResourcesChangedObservable notifyEvent];
            }
            else
            {
                const auto success = item.resourceId.isEmpty() || app.resourcesManager->uninstallResource(item.resourceId);
                if (!success)
                {
                    OALog(@"Failed to uninstall resource %@ from %@",
                            item.resourceId.toNSString(),
                            item.resource != nullptr ? item.resource->localPath.toNSString() : @"?");
                }
                else
                {
                    if (item.resourceType == OsmAndResourceType::HeightmapRegionLegacy || item.resourceType == OsmAndResourceType::GeoTiffRegion)
                        [app.data.terrainResourcesChangeObservable notifyEvent];
                }

                if (item.resourceType == OsmAndResourceType::MapRegion)
                    [app.data.mapLayerChangeObservable notifyEvent];
            }
        }

        if (block)
            block();
    };

    if (progressHUD)
    {
        [[UIApplication sharedApplication].mainWindow addSubview:progressHUD];
        [progressHUD showAnimated:YES whileExecutingBlock:^{
            proc();
        }];
    }
    else
    {
        proc();
    }
}

+ (void) deleteResourceOf:(OALocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD
{
    [self.class deleteResourcesOf:@[item] progressHUD:progressHUD executeAfterSuccess:nil];
}

+ (void) offerClearCacheOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController executeAfterSuccess:(dispatch_block_t)block
{
    NSString* message;
    NSString *title;

    if ([item isKindOfClass:[OASqliteDbResourceItem class]])
        title = ((OASqliteDbResourceItem *)item).title;
    else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
        title = ((OAOnlineTilesResourceItem *)item).title;

    message = [NSString stringWithFormat:OALocalizedString(@"res_confirmation_clear_cache"), title];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_clear") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.class clearCacheOf:item executeAfterSuccess:block];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil];
    [alert addAction: cancelAction];
    [alert addAction: okAction];
    [alert setPreferredAction:cancelAction];
    [viewController presentViewController:alert animated: YES completion: nil];
}

+ (void) clearTilesOf:(OAResourceItem *)resource area:(OsmAnd::AreaI)area zoom:(float)zoom onComplete:(void (^)(void))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        const auto topLeft = OsmAnd::Utilities::convert31ToLatLon(area.topLeft);
        const auto bottomRight = OsmAnd::Utilities::convert31ToLatLon(area.bottomRight);

        int x1 = OsmAnd::Utilities::getTileNumberX(zoom, topLeft.longitude);
        int x2 = OsmAnd::Utilities::getTileNumberX(zoom, bottomRight.longitude);
        int y1 = OsmAnd::Utilities::getTileNumberY(zoom, topLeft.latitude);
        int y2 = OsmAnd::Utilities::getTileNumberY(zoom, bottomRight.latitude);
        OsmAnd::AreaI tileArea;
        tileArea.topLeft = OsmAnd::PointI(x1, y1);
        tileArea.bottomRight = OsmAnd::PointI(x2, y2);

        int left = (int) floor(tileArea.left());
        int top = (int) floor(tileArea.top());
        int width = (int) (ceil(tileArea.right()) - left);
        int height = (int) (ceil(tileArea.bottom()) - top);

        if ([resource isKindOfClass:OASqliteDbResourceItem.class])
        {
            OASqliteDbResourceItem *item = (OASqliteDbResourceItem *) resource;
            OASQLiteTileSource *sqliteTileSource = [[OASQLiteTileSource alloc] initWithFilePath:item.path];
            [sqliteTileSource deleteImages:tileArea zoom:(int)zoom];
        }
        else if ([resource isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *) resource;
            NSString *downloadPath = item.path;

            if (!downloadPath)
                return;

            for (int i = 0; i < width; i++)
            {
                for (int j = 0; j < height; j++)
                {
                    NSString *tilePath = [NSString stringWithFormat:@"%@/%@/%@/%@.tile", downloadPath, @((int) zoom).stringValue, @(i + left).stringValue, @(j + top).stringValue];
                    [NSFileManager.defaultManager removeItemAtPath:tilePath error:nil];
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            onComplete();
        });
    });
}

+ (void) clearCacheOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block
{
     if ([item isKindOfClass:[OASqliteDbResourceItem class]])
     {
         OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *)item;
         OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
         if ([ts supportsTileDownload])
         {
             [ts deleteCache:block];
         }
     }
     if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
     {
         OAOnlineTilesResourceItem *sqliteItem = (OAOnlineTilesResourceItem *)item;
         NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sqliteItem.path error:NULL];
         for (NSString *elem in dirs)
         {
             if (![elem isEqual:(@".metainfo")])
             {
                 [[NSFileManager defaultManager] removeItemAtPath:[sqliteItem.path stringByAppendingPathComponent:elem] error:NULL];
             }
         }
         if (block)
             block();
     }
}

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView
{
    CGFloat radius = MIN(progressView.frame.size.width, progressView.frame.size.height)/2;
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat tickWidth = radius * .3;
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, tickWidth * 2)];
    [path addLineToPoint:CGPointMake(tickWidth * 3, tickWidth * 2)];
    [path addLineToPoint:CGPointMake(tickWidth * 3, tickWidth)];
    [path addLineToPoint:CGPointMake(tickWidth, tickWidth)];
    [path addLineToPoint:CGPointMake(tickWidth, 0)];
    [path closePath];

    [path applyTransform:CGAffineTransformMakeRotation(-M_PI_4)];
    [path applyTransform:CGAffineTransformMakeTranslation(radius * .46, 1.02 * radius)];

    return path;
}

+ (NSArray<OAResourceItem *> *) getSortedRasterMapSources:(BOOL)includeOffline
{
    // Collect all needed resources
    NSMutableArray<OAResourceItem *> *mapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    OsmAndAppInstance app = OsmAndApp.instance;

    const auto localResources = app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAndResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
        else if (localResource->type == OsmAndResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);
    }

    // Process online tile sources resources
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();

        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            OAOnlineTilesResourceItem* item = [[OAOnlineTilesResourceItem alloc] init];

            NSString *caption = onlineTileSource->name.toNSString();

            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.res = resource;
            item.onlineTileSource = onlineTileSource;
            item.path = [app.cachePath stringByAppendingPathComponent:item.mapSource.name];

            [mapSources addObject:item];
        }
    }


    [mapSources sortUsingComparator:^NSComparisonResult(OAOnlineTilesResourceItem* obj1, OAOnlineTilesResourceItem* obj2) {
        NSString *caption1 = obj1.onlineTileSource->name.toNSString();
        NSString *caption2 = obj2.onlineTileSource->name.toNSString();
        return [caption2 compare:caption1];
    }];

    NSMutableArray<OAResourceItem *> *sqlitedbArr = [NSMutableArray array];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files.allKeys)
    {
        NSString *path = [OAMapCreatorHelper sharedInstance].files[fileName];
        BOOL isOnline = [OASQLiteTileSource isOnlineTileSource:path];
        if (includeOffline || isOnline)
        {
            NSString *title = [OASQLiteTileSource getTitleOf:path];
            OASqliteDbResourceItem* item = [[OASqliteDbResourceItem alloc] init];
            item.mapSource = [[OAMapSource alloc] initWithResource:fileName andVariant:@"" name:title type:@"sqlitedb"];
            item.path = path;
            item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
            item.isOnline = isOnline;

            [sqlitedbArr addObject:item];
        }
    }

    [sqlitedbArr sortUsingComparator:^NSComparisonResult(OASqliteDbResourceItem *obj1, OASqliteDbResourceItem *obj2) {
        return [obj1.mapSource.resourceId caseInsensitiveCompare:obj2.mapSource.resourceId];
    }];

    [mapSources addObjectsFromArray:sqlitedbArr];

    return [NSArray arrayWithArray:mapSources];
}

+ (NSDictionary<OAMapSource *, OAResourceItem *> *) getOnlineRasterMapSourcesBySource
{
    NSArray<OAResourceItem *> *items = [self getSortedRasterMapSources:NO];
    NSMutableDictionary<OAMapSource *, OAResourceItem *> *res = [NSMutableDictionary new];
    for (OAResourceItem *i in items)
    {
        if ([i isKindOfClass:OAMapSourceResourceItem.class])
            [res setObject:i forKey:((OAMapSourceResourceItem *)i).mapSource];
    }
    return [NSDictionary dictionaryWithDictionary:res];
}

+ (NSArray<OAMapStyleResourceItem *> *) getExternalMapStyles
{
    NSMutableArray<OAMapStyleResourceItem *> *res = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto localResources = app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAndResourceType::MapStyle && localResource->origin != OsmAnd::ResourcesManager::ResourceOrigin::Builtin)
            mapStylesResources.push_back(localResource);
    }

    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;

    // Process map styles
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;

        NSString* resourceId = resource->id.toNSString();

        OAMapStyleResourceItem* item = [[OAMapStyleResourceItem alloc] init];
        item.mapSource = [app.data lastMapSourceByResourceId:resourceId];
        if (item.mapSource == nil)
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:mode.variantKey];

        NSString *caption = mapStyle->title.toNSString();

        item.mapSource.name = caption;
        item.resourceType = OsmAndResourceType::MapStyle;
        item.resource = resource;
        item.mapStyle = mapStyle;

        [res addObject:item];
    }

    [res sortUsingComparator:^NSComparisonResult(OAMapStyleResourceItem* obj1, OAMapStyleResourceItem* obj2) {
        if (obj1.sortIndex < obj2.sortIndex)
            return NSOrderedAscending;
        if (obj1.sortIndex > obj2.sortIndex)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return res;
}

+ (QVector<std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource>>) getExternalMapFilesAt:(OsmAnd::PointI)point routeData:(BOOL)routeData
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& localResources = app.resourcesManager->getLocalResources();
    QVector<std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource>> externalMaps;
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(1, point);
    auto dataTypes = OsmAnd::ObfDataTypesMask();
    dataTypes.set(OsmAnd::ObfDataType::Map);
    if (routeData)
        dataTypes.set(OsmAnd::ObfDataType::Routing);
    for (const auto& res : localResources)
    {
        if (res->type == OsmAnd::ResourcesManager::ResourceType::MapRegion && !app.resourcesManager->getResourceInRepository(res->id))
        {
            const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(res->metadata);
            BOOL accept = obfMetadata != nullptr;
            if (accept)
            {
                accept = accept && !obfMetadata->obfFile->obfInfo->isBasemap;
                accept = accept && !obfMetadata->obfFile->obfInfo->isBasemapWithCoastlines;
                accept = accept && !obfMetadata->obfFile->filePath.toLower().contains(QStringLiteral("/world_"));
            }
            if (accept && obfMetadata->obfFile->obfInfo->containsDataFor(&bbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, dataTypes))
                externalMaps.append(res);
        }
    }
    return externalMaps;
}

+ (NSArray<OAResourceItem *> *)getMapRegionResourcesToDownloadForRegions:(NSArray<OAWorldRegion *> *)regions
{
    if (regions.count == 0)
        return @[];
    NSMutableArray<OAResourceItem *> *resources = [NSMutableArray array];
    for (OAWorldRegion *region in regions)
    {
        NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
        if (ids.count > 0)
        {
            for (NSString *resourceId in ids)
            {
                const auto& resource = OsmAndApp.instance.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                {
                    BOOL installed = OsmAndApp.instance.resourcesManager->isResourceInstalled(resource->id);
                    if (!installed)
                    {
                        OARepositoryResourceItem *item = [[OARepositoryResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                                 inRegion:region
                                                           withRegionName:YES
                                                         withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                        item.size = resource->size;
                        item.sizePkg = resource->packageSize;
                        item.worldRegion = region;
                        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
                        [resources addObject:item];
                    }
                }
            }
        }
    }
    return [resources copy];
}

+ (NSArray<OAResourceItem *> *)getMapRegionResourcesToUpdateForRegions:(NSArray<OAWorldRegion *> *)regions
{
    if (regions.count == 0)
        return @[];
    
    NSMutableArray<OAResourceItem *> *resources = [NSMutableArray array];
    const auto& localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    if (!localResources.isEmpty())
    {
        for (OAWorldRegion *region in regions)
        {
            for (const auto& resource : localResources)
            {
                if (resource && resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed && resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                {
                    if ([region.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)]
                        && !resource->id.isNull() && [resource->id.toLower().toNSString() hasPrefix:region.downloadsIdPrefix])
                    {
                        OAOutdatedResourceItem *item = [[OAOutdatedResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                                 inRegion:region
                                                           withRegionName:YES
                                                         withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];;
                        item.worldRegion = region;
                        item.resourceType = resource->type;
                        
                        const auto resourceInRepository = OsmAndApp.instance.resourcesManager->getResourceInRepository(item.resourceId);
                        item.size = resourceInRepository->size;
                        item.sizePkg = resourceInRepository->packageSize;
                        item.date = [NSDate dateWithTimeIntervalSince1970:(resourceInRepository->timestamp / 1000)];
                        [resources addObject:item];
                    }
                }
            }
        }
    }
    return [resources copy];
}

+ (NSString *)formatPointString:(CLLocation *)location {
    return [NSString stringWithFormat:@"points=%f,%f",location.coordinate.latitude, location.coordinate.longitude];
}

+ (void)onlineCalculateRequestWithRouteCalculationResult:(OARouteCalculationResult *)routeCalculationResult
                                              completion:(LocationArrayCallback)completion
{
    NSLog(@"onlineCalculateRequestStartPoint start");
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSString *routeUrlString = @"https://maptile.osmand.net/routing/route";
    
    NSMutableString *pointsString = [NSMutableString string];
    
    for (CLLocation *l in routeCalculationResult.missingMapsPoints) {
        [pointsString appendString:[NSString stringWithFormat:@"&%@", [self formatPointString:l]]];
    }
    
    NSString *routeMode = @"car";
    GeneralRouterProfile profile = routeCalculationResult.missingMapsRoutingContext->config->router->getProfile();
    if (profile == GeneralRouterProfile::BICYCLE || profile == GeneralRouterProfile::PEDESTRIAN)
    {
        routeMode = @"bicycle";
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@?routeMode=%@%@", routeUrlString, routeMode, pointsString];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"onlineCalculateRequestStartPoint finish");
        if (error)
        {
            NSLog(@"Error: %@", error);
            if (completion)
            {
                completion(nil, [NSError errorWithDomain:@"OnlineCalculateRequestErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]);
            }
        }
        else
        {
            if ([response isKindOfClass:[NSHTTPURLResponse class]])
            {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200)
                {
                    if (data)
                    {
                        @try
                        {
                            NSLog(@"Response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                            NSArray *features = json[@"features"];
                            NSMutableArray *locationArray = [NSMutableArray array];
                            for (NSDictionary *feature in features)
                            {
                                NSDictionary *geometry = feature[@"geometry"];
                                NSString *geometryType = geometry[@"type"];
                                if ([geometryType isEqualToString:@"LineString"])
                                {
                                    NSArray *coordinates = geometry[@"coordinates"];
                                    for (NSArray *array in coordinates)
                                    {
                                        if (array.count >= 2)
                                        {
                                            double latitude = [array[1] doubleValue];
                                            double longitude = [array[0] doubleValue];
                                            [locationArray addObject:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
                                        }
                                    }
                                }
                            }
                            NSLog(@"Coordinates array: %@", locationArray);
                            if (completion)
                            {
                                completion([locationArray copy], nil);
                            }
                        }
                        @catch (NSException *e)
                        {
                            NSLog(@"NSException: %@", e.reason);
                            if (completion)
                            {
                                completion(nil, [NSError errorWithDomain:@"OnlineCalculateRequestErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: e.reason}]);
                            }
                        }
                    } else {
                        NSLog(@"Error: No data received");
                        if (completion)
                        {
                            completion(nil, [NSError errorWithDomain:@"OnlineCalculateRequestErrorDomain" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Error: No data received"}]);
                        }
                    }
                } else {
                    NSLog(@"Error: Unexpected HTTP status code: %ld", (long)httpResponse.statusCode);
                    if (completion)
                    {
                        completion(nil, [NSError errorWithDomain:@"OnlineCalculateRequestErrorDomain" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Error: Unexpected HTTP status code"}]);
                    }
                }
            } else {
                NSLog(@"Error: Unexpected response type");
                if (completion)
                {
                    completion(nil, [NSError errorWithDomain:@"OnlineCalculateRequestErrorDomain" code:5 userInfo:@{NSLocalizedDescriptionKey: @"Error: Unexpected response type"}]);
                }
            }
        }
    }];
    
    [task resume];
    [session finishTasksAndInvalidate];
}

@end
