//
//  OAResourcesUIHelper.m
//  OsmAnd
//
//  Created by Alexey on 03.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAResourcesUIHelper.h"
#import <Reachability.h>
#import <UIAlertView+Blocks.h>
#import <MBProgressHUD.h>

#import "OAAutoObserverProxy.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OAPluginPopupViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAManageResourcesViewController.h"
#import "OATerrainLayer.h"
#import "OARootViewController.h"
#import "OASQLiteTileSource.h"
#import "OAChoosePlanHelper.h"
#import "OADownloadDescriptionInfo.h"
#import "OAJsonHelper.h"
#import "OATileSource.h"
#import "OAIndexConstants.h"
#import "OAResourcesInstaller.h"
#import "OAPlugin.h"
#import "OAWorldRegion.h"

#include "Localization.h"
#include <OsmAndCore/WorldRegions.h>

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/ObfsCollection.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
typedef OsmAnd::IncrementalChangesManager::IncrementalUpdate IncrementalUpdate;

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

@end

@implementation OARepositoryResourceItem
@end

@implementation OALocalResourceItem
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
            return [OsmAndApp.instance.dataPath stringByAppendingPathComponent:MAP_CREATOR_DIR];
        else
            return [OsmAndApp.instance.cachePath stringByAppendingPathComponent:self.downloadContent[@"name"]];
    }
    else if ([titleWithoutExt.lowercaseString hasSuffix:GPX_FILE_EXT])
        return OsmAndApp.instance.gpxPath;
    else if ([titleWithoutExt hasSuffix:BINARY_MAP_INDEX_EXT_ZIP])
        return OsmAndApp.instance.documentsPath;
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

+ (NSString *) resourceTypeLocalized:(OsmAnd::ResourcesManager::ResourceType)type
{
    switch (type)
    {
        case OsmAnd::ResourcesManager::ResourceType::MapRegion:
        case OsmAnd::ResourcesManager::ResourceType::DepthContourRegion:
            return OALocalizedString(@"map_settings_map");
        case OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion:
            return OALocalizedString(@"res_srtm");
        case OsmAnd::ResourcesManager::ResourceType::WikiMapRegion:
            return OALocalizedString(@"res_wiki");
        case OsmAnd::ResourcesManager::ResourceType::RoadMapRegion:
            return OALocalizedString(@"res_roads");
        case OsmAnd::ResourcesManager::ResourceType::HillshadeRegion:
            return OALocalizedString(@"res_hillshade");
        case OsmAnd::ResourcesManager::ResourceType::SlopeRegion:
            return OALocalizedString(@"res_slope");
        case OsmAnd::ResourcesManager::ResourceType::SqliteFile:
            return OALocalizedString(@"online_map");
            
        default:
            return OALocalizedString(@"res_unknown");
    }
}

+ (NSString *) iconNameByresourceType:(OsmAnd::ResourcesManager::ResourceType)type
{
    switch (type)
    {
        case OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion:
            return @"ic_custom_contour_lines";
        case OsmAnd::ResourcesManager::ResourceType::WikiMapRegion:
            return @"ic_custom_wikipedia";
        case OsmAnd::ResourcesManager::ResourceType::HillshadeRegion:
            return @"ic_custom_hillshade";
        case OsmAnd::ResourcesManager::ResourceType::SlopeRegion:
            return @"ic_action_slope";
        default:
            return @"ic_custom_show_on_map";
    }
}

+ (OsmAnd::ResourcesManager::ResourceType) resourceTypeByScopeId:(NSString *)scopeId
{
    if ([scopeId isEqualToString:@"map"])
        return OsmAnd::ResourcesManager::ResourceType::MapRegion;
    else if ([scopeId isEqualToString:@"voice"])
        return OsmAnd::ResourcesManager::ResourceType::VoicePack;
//    else if ([scopeId isEqualToString:@"fonts"])
//        return OsmAnd::ResourcesManager::ResourceType::Unknown;
    else if ([scopeId isEqualToString:@"road_map"])
        return OsmAnd::ResourcesManager::ResourceType::RoadMapRegion;
    else if ([scopeId isEqualToString:@"srtm_map"])
        return OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion;
    else if ([scopeId isEqualToString:@"depth"])
        return OsmAnd::ResourcesManager::ResourceType::DepthContourRegion;
    else if ([scopeId isEqualToString:@"hillshade"])
        return OsmAnd::ResourcesManager::ResourceType::HillshadeRegion;
    else if ([scopeId isEqualToString:@"slope"])
        return OsmAnd::ResourcesManager::ResourceType::SlopeRegion;
    else if ([scopeId isEqualToString:@"wikimap"])
        return OsmAnd::ResourcesManager::ResourceType::WikiMapRegion;
//    else if ([scopeId isEqualToString:@"wikivoyage"])
//        return OsmAnd::ResourcesManager::ResourceType::MapRegion;
//    else if ([scopeId isEqualToString:@"travel"])
//        return OsmAnd::ResourcesManager::ResourceType::MapRegion;
    else if ([scopeId isEqualToString:@"live_updates"])
        return OsmAnd::ResourcesManager::ResourceType::LiveUpdateRegion;
    else if ([scopeId isEqualToString:@"gpx"])
        return OsmAnd::ResourcesManager::ResourceType::GpxFile;
    else if ([scopeId isEqualToString:@"sqlite"])
        return OsmAnd::ResourcesManager::ResourceType::SqliteFile;
    
    //TODO: add another types from ResourcesManager.h
    //HeightmapRegion,
    //MapStyle,
    //MapStylesPresets,
    //OnlineTileSources,
    
    return OsmAnd::ResourcesManager::ResourceType::Unknown;
}

+ (NSString *) iconNameByResourseType:(OsmAnd::ResourcesManager::ResourceType)type
{
    if (type == OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion)
        return @"ic_custom_contour_lines";
    else if (type == OsmAnd::ResourcesManager::ResourceType::DepthContourRegion)
        return @"ic_custom_contour_lines";
    else if (type == OsmAnd::ResourcesManager::ResourceType::WikiMapRegion)
        return @"ic_custom_wikipedia";
    else if (type == OsmAnd::ResourcesManager::ResourceType::HillshadeRegion)
        return @"ic_custom_hillshade";
    else if (type == OsmAnd::ResourcesManager::ResourceType::SlopeRegion)
        return @"ic_action_slope";
    else if (type == OsmAnd::ResourcesManager::ResourceType::LiveUpdateRegion)
        return @"ic_custom_upload"; //ic_custom_online
    else if (type == OsmAnd::ResourcesManager::ResourceType::VoicePack)
        return @"ic_custom_sound";
    else if (type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
        return @"ic_custom_map_style";
    else if (type == OsmAnd::ResourcesManager::ResourceType::MapStylesPresets)
        return @"ic_custom_options";
    else if (type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources)
        return @"ic_custom_map_online";
    else if (type == OsmAnd::ResourcesManager::ResourceType::GpxFile)
        return @"ic_custom_route";
    else if (type == OsmAnd::ResourcesManager::ResourceType::SqliteFile)
        return @"ic_custom_overlay_map";
    else
        return @"ic_custom_map";
}

+ (NSString *) titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource> &)resource
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
        name = name.remove(QStringLiteral("_osmand_ext")).remove(QStringLiteral(".depth.obf")).mid(6).replace('_', ' ');
        return [[NSString alloc] initWithFormat:@"%@ %@", OALocalizedString(@"download_depth_countours"), [OAUtilities capitalizeFirstLetterAndLowercase:name.toNSString()]];
    }
    NSString *nameStr;
    switch (resource->type)
    {
        case OsmAndResourceType::MapRegion:
        //case OsmAndResourceType::RoadMapRegion:
        case OsmAndResourceType::SrtmMapRegion:
        case OsmAndResourceType::WikiMapRegion:
        case OsmAndResourceType::HillshadeRegion:
        case OsmAndResourceType::SlopeRegion:
            
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
        nameStr = [nameStr stringByAppendingString:[NSString stringWithFormat:@" - %@", [self.class resourceTypeLocalized:resource->type]]];
    
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

+ (BOOL) verifySpaceAvailableToDownloadAndUnpackOf:(OAResourceItem*)item_
                                          asUpdate:(BOOL)isUpdate
{
    if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
    {
        OARepositoryResourceItem* item = (OARepositoryResourceItem*)item_;

        return [self.class verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                                  withResourceName:[self.class titleOfResource:item.resource
                                                                                               inRegion:item.worldRegion
                                                                                         withRegionName:YES
                                                                                       withResourceType:YES]
                                                          asUpdate:isUpdate];
    }
    else if ([item_ isKindOfClass:[OALocalResourceItem class]])
    {
        OALocalResourceItem* item = (OALocalResourceItem*)item_;

        OsmAndAppInstance _app = [OsmAndApp instance];
        const auto resource = _app.resourcesManager->getResourceInRepository(item.resourceId);

        return [self.class verifySpaceAvailableDownloadAndUnpackResource:resource
                                                  withResourceName:[self.class titleOfResource:item.resource
                                                                                               inRegion:item.worldRegion
                                                                                         withRegionName:YES
                                                                                       withResourceType:YES]
                                                          asUpdate:isUpdate];
    }
    
    return NO;
}

+ (BOOL) verifySpaceAvailableDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
                                      withResourceName:(NSString *)resourceName
                                              asUpdate:(BOOL)isUpdate
{
    OsmAndAppInstance _app = [OsmAndApp instance];
    uint64_t spaceNeeded = resource->packageSize + resource->size;
    BOOL isEnoughSpace = (_app.freeSpaceAvailableOnDevice >= spaceNeeded);

    if (!isEnoughSpace)
    {
        [self showNotEnoughSpaceAlertFor:resourceName
                                withSize:spaceNeeded
                                asUpdate:isUpdate];
    }
    
    return isEnoughSpace;
}

+ (void) showNotEnoughSpaceAlertFor:(NSString*)resourceName
                           withSize:(unsigned long long)size
                           asUpdate:(BOOL)isUpdate
{
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:size
                                                               countStyle:NSByteCountFormatterCountStyleFile];

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
    
    if (region.regionId == nil || [region isInPurchasedArea] || ([OAIAPHelper freeMapsAvailable] > 0 && tasksCount < [OAIAPHelper freeMapsAvailable]))
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
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [resourceUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);
    
    id<OADownloadTask> task = [[OsmAndApp instance].downloadsManager downloadTaskWithRequest:request
                                                                                      andKey:[@"resource:" stringByAppendingString:resourceId]
                                                                                     andName:name];
    
    if ([[OsmAndApp instance].downloadsManager firstActiveDownloadTasksWithKeyPrefix:@"resource:"] == nil)
        [task resume];
}

+ (OAWorldRegion*) findRegionOrAnySubregionOf:(OAWorldRegion*)region
                         thatContainsResource:(const QString&)resourceId
{
    const auto& downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);

    if (resourceId.startsWith(downloadsIdPrefix))
        return region;

    for (OAWorldRegion* subregion in region.subregions)
    {
        OAWorldRegion* match = [self.class findRegionOrAnySubregionOf:subregion thatContainsResource:resourceId];
        if (match)
            return match;
    }

    return nil;
}

+ (NSArray<NSString *> *) getInstalledResourcePathsByTypes:(QSet<OsmAnd::ResourcesManager::ResourceType>)resourceTypes
{
    NSMutableArray<NSString *> *items = [NSMutableArray new];
    OsmAndAppInstance app = [OsmAndApp instance];
    for (const auto& localResource : app.resourcesManager->getLocalResources())
    {
        if (localResource->origin != OsmAnd::ResourcesManager::ResourceOrigin::Installed)
            continue;
        const auto& installedResource = std::static_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);
        if (resourceTypes.contains(installedResource->type))
        {
            [items addObject:installedResource->localPath.toNSString()];
        }
    }
    return items;
}

+ (NSArray<OAResourceItem *> *) findIndexItemsAt:(NSArray<NSString *> *)names type:(OsmAnd::ResourcesManager::ResourceType)type includeDownloaded:(BOOL)includeDownloaded limit:(NSInteger)limit
{
    NSMutableArray<OAResourceItem *>* res = [NSMutableArray new];
    OAWorldRegion *worldRegion = OsmAndApp.instance.worldRegion;
    
    for (NSString *name in names)
    {
        OAWorldRegion *downloadRegion = [worldRegion getRegionDataByDownloadName:name];
        
        if (downloadRegion && (includeDownloaded || ![OAResourcesUIHelper isIndexItemDownloaded:type downloadRegion:downloadRegion res:res]))
        {
            [self addIndexItem:type downloadRegion:downloadRegion res:res];
        }
        
        if (limit != -1 && res.count == limit)
            break;
    }
    return res;
}

+ (BOOL) isIndexItemDownloaded:(OsmAnd::ResourcesManager::ResourceType)type downloadRegion:(OAWorldRegion *)downloadRegion res:(NSMutableArray<OAResourceItem *>*)res
{
    CLLocationCoordinate2D regionCenter = CLLocationCoordinate2DMake((downloadRegion.bboxTopLeft.latitude + downloadRegion.bboxBottomRight.latitude) / 2, (downloadRegion.bboxTopLeft.longitude + downloadRegion.bboxBottomRight.longitude) / 2);
    NSArray<OAResourceItem *> *otherIndexItems = [self requestMapDownloadInfo:regionCenter resourceType:type];
    
    for (OAResourceItem *indexItem in otherIndexItems)
    {
        auto resource = OsmAndApp.instance.resourcesManager->getResource(indexItem.resourceId);
        BOOL isInstalled = resource && resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed;
        
        if (indexItem.resourceType == type && isInstalled)
        {
            return YES;
        }
    }
    return downloadRegion.superregion != nil && [self addIndexItem:type downloadRegion:downloadRegion.superregion res:res];
}

+ (BOOL) addIndexItem:(OsmAnd::ResourcesManager::ResourceType)type downloadRegion:(OAWorldRegion *)downloadRegion res:(NSMutableArray<OAResourceItem *>*)res
{
    CLLocationCoordinate2D regionCenter = CLLocationCoordinate2DMake((downloadRegion.bboxTopLeft.latitude + downloadRegion.bboxBottomRight.latitude) / 2, (downloadRegion.bboxTopLeft.longitude + downloadRegion.bboxBottomRight.longitude) / 2);
    NSArray<OAResourceItem *> *otherIndexItems = [self requestMapDownloadInfo:regionCenter resourceType:type];
    
    for (OAResourceItem *indexItem in otherIndexItems)
    {
        if (indexItem.resourceType == type && ![res containsObject:indexItem])
        {
            [res addObject:indexItem];
            return YES;
        }
    }
    return downloadRegion.superregion != nil && [self addIndexItem:type downloadRegion:downloadRegion.superregion res:res];
}

+ (NSArray<OAResourceItem *> *) requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate resourceType:(OsmAnd::ResourcesManager::ResourceType)resourceType
{
    NSMutableArray<OAResourceItem *>* res;
    res = [NSMutableArray new];
 
    NSArray *sortedSelectedRegions;
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray<OAWorldRegion *> *mapRegions = [[app.worldRegion queryAtLat:coordinate.latitude lon:coordinate.longitude] mutableCopy];
    NSArray<OAWorldRegion *> *copy = [NSArray arrayWithArray:mapRegions];
    if (mapRegions.count > 0)
    {
        [copy enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![region contain:coordinate.latitude lon:coordinate.longitude])
                [mapRegions removeObject:region];
        }];
    }
    
    if (mapRegions.count > 0)
    {
        sortedSelectedRegions = [mapRegions sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *first = [NSNumber numberWithDouble:[(OAWorldRegion *)a getArea]];
            NSNumber *second = [NSNumber numberWithDouble:[(OAWorldRegion *)b getArea]];
            return [first compare:second];
        }];
        
        for (OAWorldRegion *region in sortedSelectedRegions)
        {
            NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
            if (ids.count > 0)
            {
                for (NSString *resourceId in ids)
                {
                    const auto& resource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                    if (resource && resource->type == resourceType)
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
                            item.resource = app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
                            item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                            item.size = resource->size;
                            item.worldRegion = region;
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
                            [res addObject:item];
                        }
                    }
                }
            }
        }
    }
    return [NSArray arrayWithArray:res];
}

+ (void) requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate resourceType:(OsmAnd::ResourcesManager::ResourceType)resourceType onComplete:(void (^)(NSArray<OAResourceItem *>*))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OAResourceItem *> * res = [OAResourcesUIHelper requestMapDownloadInfo:coordinate resourceType:resourceType];
        dispatch_async(dispatch_get_main_queue(), ^{
           if (onComplete)
               onComplete(res);
        });
    });
}

+ (NSArray<OARepositoryResourceItem *> *) getMapsForType:(OsmAnd::ResourcesManager::ResourceType)type latLon:(CLLocationCoordinate2D)latLon
{
    NSMutableArray<OARepositoryResourceItem *> *availableItems = [NSMutableArray array];
    NSArray<OAResourceItem *> * res = [OAResourcesUIHelper requestMapDownloadInfo:latLon resourceType:type];
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
        while (region.superregion != worldRegion)
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

+ (void) startDownloadOfCustomItem:(OACustomResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    if (item.downloadUrl)
    {
        NSString* name = item.title;
        if (item.subfolder && item.subfolder.length > 0)
            name = [item.subfolder stringByAppendingPathComponent:name];
        
        if ([item.downloadUrl hasPrefix:@"@"])
        {
            NSString *relPath = [item.downloadUrl substringFromIndex:1];
            NSString *pluginPath = [OAPlugin getAbsoulutePluginPathByRegion:item.worldRegion];
            if (pluginPath.length > 0 && relPath.length > 0)
            {
                NSString *srcFilePath = [pluginPath stringByAppendingPathComponent:relPath];
                BOOL failed = [OAResourcesInstaller installCustomResource:srcFilePath nsResourceId:srcFilePath.lastPathComponent.lowerCase fileName:name];
                if (!failed)
                    [OsmAndApp.instance.localResourcesChangedObservable notifyEvent];
            }
        }
        else
        {
            // Create download task
            NSURL* url = [NSURL URLWithString:item.downloadUrl];
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            
            NSLog(@"%@", url);
            
            OsmAndAppInstance app = [OsmAndApp instance];
            id<OADownloadTask> task = [app.downloadsManager downloadTaskWithRequest:request
                                                                             andKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]
                                                                            andName:name];
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

+ (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed completionHandler:nil];
}

+ (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed completionHandler:(void(^)(UIAlertController *))completionHandler
{
    if (item.disabled || (item.resourceType == OsmAndResourceType::MapRegion && ![self.class checkIfDownloadEnabled:item.worldRegion]))
        return;

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:item.resource->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    
    NSString* resourceName = [self.class titleOfResource:item.resource
                                                inRegion:item.worldRegion
                                          withRegionName:YES
                                        withResourceType:YES];
    
    if (![self.class verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                                  withResourceName:resourceName
                                                          asUpdate:YES])
        return;

    NSMutableString* message;
    NetworkStatus status = [Reachability reachabilityForInternetConnection].currentReachabilityStatus;
    
    if (status == NotReachable)
    {
        message = [OALocalizedString(@"alert_inet_needed") mutableCopy];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        if (status == ReachableViaWWAN)
        {
            message = [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_cell_q"),
                                        resourceName,
                                        stringifiedSize] mutableCopy];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"incur_high_charges")];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"proceed_q")];
            
        }
        else if (status == ReachableViaWiFi)
        {
            message = [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_wifi_q"),
                        resourceName,
                        stringifiedSize] mutableCopy];
            [message appendString:@" "];
            [message appendString:OALocalizedString(@"proceed_q")];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_install") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.class startDownloadOfItem:item onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
        }]];
        
        if (completionHandler)
            completionHandler(alert);
        else
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
}

+ (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    if (![self.class checkIfUpdateEnabled:item.worldRegion])
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto resourceInRepository = app.resourcesManager->getResourceInRepository(item.resourceId);

    NSString* resourceName = [self.class titleOfResource:item.resource
                                                inRegion:item.worldRegion
                                          withRegionName:YES
                                        withResourceType:YES];
    
    if (![self.class verifySpaceAvailableDownloadAndUnpackResource:resourceInRepository
                                                  withResourceName:resourceName
                                                          asUpdate:YES])
    {
        return;
    }

    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:resourceInRepository->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];

    NSMutableString* message;
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        [message appendString:resourceName];
        [message appendString:@"."];
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_cell"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = [OALocalizedString(@"res_upd_avail_q") mutableCopy];
        [message appendString:@" "];
        [message appendString:resourceName];
        [message appendString:@"."];
        [message appendString:@" "];
        [message appendString:[NSString stringWithFormat:OALocalizedString(@"prch_nau_q2_wifi"), stringifiedSize]];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_update") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.class startDownloadOf:resourceInRepository resourceName:resourceName onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
    }]];
    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (void) startDownloadOfItem:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    // Create download tasks
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSURL* pureUrl = item.resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);
    
    NSString* name = [self.class titleOfResource:item.resource
                                        inRegion:item.worldRegion
                                  withRegionName:YES
                                withResourceType:YES];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    id<OADownloadTask> task = [app.downloadsManager downloadTaskWithRequest:request
                                                                     andKey:[@"resource:" stringByAppendingString:item.resource->id.toNSString()]
                                                                    andName:name];
    
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

+ (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    // Create download tasks
    NSString* ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSURL* pureUrl = resource->url.toNSURL();
    NSString *params = [[NSString stringWithFormat:@"&event=2&osmandver=OsmAndIOs+%@", ver] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@", [pureUrl absoluteString], params];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"%@", url);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    id<OADownloadTask> task = [app.downloadsManager downloadTaskWithRequest:request
                                                                     andKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]
                                                                    andName:name];

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
    std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
    if ([item_ isKindOfClass:[OALocalResourceItem class]])
    {
        OALocalResourceItem* item = (OALocalResourceItem*)item_;

        resource = item.resource;
        isUpdate = [item isKindOfClass:[OAOutdatedResourceItem class]];
    }
    else if ([item_ isKindOfClass:[OARepositoryResourceItem class]])
    {
        OARepositoryResourceItem* item = (OARepositoryResourceItem*)item_;

        resource = item.resource;
    }
    if (!resource)
        return;

    NSMutableString* message;
    if (isUpdate)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_upd_q"),
                    [self.class titleOfResource:resource
                                       inRegion:item_.worldRegion
                                 withRegionName:YES
                               withResourceType:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }
    else
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_cancel_inst_q"),
                    [self.class titleOfResource:resource
                                       inRegion:item_.worldRegion
                                 withRegionName:YES
                               withResourceType:YES]] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"data_will_be_lost")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.class cancelDownloadOf:item_ onTaskStop:onTaskStop];
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
    if (onTaskStop)
        onTaskStop(item.downloadTask);
    
    [item.downloadTask stop];
}

+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    NSString *title;
    if ([item isKindOfClass:[OASqliteDbResourceItem class]])
        title = ((OASqliteDbResourceItem *)item).title;
    else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
        title = ((OAOnlineTilesResourceItem *)item).title;
    else
        title = [self.class titleOfResource:item.resource
                                   inRegion:item.worldRegion
                             withRegionName:YES
                           withResourceType:YES];
    
    NSString* message = [NSString stringWithFormat:OALocalizedString(@"res_confirmation_delete"), title];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.class deleteResourceOf:item progressHUD:progressHUD executeAfterSuccess:block];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [alert setPreferredAction:cancelAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD
{
    [self offerDeleteResourceOf:item viewController:viewController progressHUD:progressHUD executeAfterSuccess:nil];
}

+ (void) deleteResourceOf:(OALocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    dispatch_block_t proc = ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        if ([item isKindOfClass:[OASqliteDbResourceItem class]])
        {
            OASqliteDbResourceItem *sqliteItem = (OASqliteDbResourceItem *)item;
            [[OAMapCreatorHelper sharedInstance] removeFile:sqliteItem.fileName];
            if (block)
                block();
        }
        else if ([item isKindOfClass:[OAOnlineTilesResourceItem class]])
        {
            OAOnlineTilesResourceItem *tilesItem = (OAOnlineTilesResourceItem *)item;
            [[NSFileManager defaultManager] removeItemAtPath:tilesItem.path error:nil];
            app.resourcesManager->uninstallTilesResource(QString::fromNSString(item.title));
            if ([tilesItem.title isEqualToString:@"OsmAnd (online tiles)"])
                app.resourcesManager->installOsmAndOnlineTileSource();

            [app.localResourcesChangedObservable notifyEvent];
            if (block)
                block();
        }
        else
        {
            if (item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion)
            {
                NSString *filename = [app.resourcesManager->getLocalResource(item.resourceId)->localPath.toNSString() lastPathComponent];
                if (app.data.terrainType == EOATerrainTypeHillshade)
                    [[OATerrainLayer sharedInstanceHillshade] removeFromDB:filename];
                else if (app.data.terrainType == EOATerrainTypeSlope)
                    [[OATerrainLayer sharedInstanceSlope] removeFromDB:filename];
            }
            
            const auto success = item.resourceId.isEmpty() || app.resourcesManager->uninstallResource(item.resourceId);
            if (!success)
            {
                OALog(@"Failed to uninstall resource %@ from %@",
                      item.resourceId.toNSString(),
                      item.resource != nullptr ? item.resource->localPath.toNSString() : @"?");
            }
            else
            {
                if (item.resourceType == OsmAndResourceType::HillshadeRegion || item.resourceType == OsmAndResourceType::SlopeRegion)
                    [app.data.terrainResourcesChangeObservable notifyEvent];
                
                if (block)
                    block();
            }
        }
    };
    
    if (progressHUD)
    {
        [[[[UIApplication sharedApplication] windows] lastObject] addSubview:progressHUD];
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
    [self.class deleteResourceOf:item progressHUD:progressHUD executeAfterSuccess:nil];
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
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:OALocalizedString(@"poi_clear") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

@end
