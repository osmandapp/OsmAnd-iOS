//
//  OAResourcesUISwiftHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAResourcesUISwiftHelper.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadsManager.h"
#import "OsmAndAppImpl.h"
#import "OAWorldRegion.h"
#import "OADownloadTask.h"
#import "OAManageResourcesViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OsmAndApp.h"
#import "OADownloadTask.h"
#import "Localization.h"

@implementation OAResourceSwiftItem

- (instancetype) initWithItem:(id)objcResourceItem
{
    self = [super init];
    if (self)
    {
        self.objcResourceItem = objcResourceItem;
    }
    return self;
}

- (NSString *) title
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return res.title;
}

- (NSString *) type
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OAResourceType resourceTypeLocalized:res.resourceType];
}

- (EOAOAResourceSwiftItemType) resourceType
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    switch (res.resourceType)
    {
        case OsmAndResourceType::Unknown:
            return EOAOAResourceSwiftItemTypeUnknown;
        case OsmAndResourceType::MapRegion:
            return EOAOAResourceSwiftItemTypeMapRegion;
        case OsmAndResourceType::RoadMapRegion:
            return EOAOAResourceSwiftItemTypeRoadMapRegion;
        case OsmAndResourceType::SrtmMapRegion:
            return EOAOAResourceSwiftItemTypeSrtmMapRegion;
        case OsmAndResourceType::DepthContourRegion:
            return EOAOAResourceSwiftItemTypeDepthContourRegion;
        case OsmAndResourceType::DepthMapRegion:
            return EOAOAResourceSwiftItemTypeDepthMapRegion;
        case OsmAndResourceType::WikiMapRegion:
            return EOAOAResourceSwiftItemTypeWikiMapRegion;
        case OsmAndResourceType::HillshadeRegion:
            return EOAOAResourceSwiftItemTypeHillshadeRegion;
        case OsmAndResourceType::SlopeRegion:
            return EOAOAResourceSwiftItemTypeSlopeRegion;
        case OsmAndResourceType::HeightmapRegionLegacy:
            return EOAOAResourceSwiftItemTypeHeightmapRegionLegacy;
        case OsmAndResourceType::GeoTiffRegion:
            return EOAOAResourceSwiftItemTypeGeoTiffRegion;
        case OsmAndResourceType::LiveUpdateRegion:
            return EOAOAResourceSwiftItemTypeLiveUpdateRegion;
        case OsmAndResourceType::VoicePack:
            return EOAOAResourceSwiftItemTypeVoicePack;
        case OsmAndResourceType::MapStyle:
            return EOAOAResourceSwiftItemTypeMapStyle;
        case OsmAndResourceType::MapStylesPresets:
            return EOAOAResourceSwiftItemTypeMapStylesPresets;
        case OsmAndResourceType::OnlineTileSources:
            return EOAOAResourceSwiftItemTypeOnlineTileSources;
        case OsmAndResourceType::GpxFile:
            return EOAOAResourceSwiftItemTypeGpxFile;
        case OsmAndResourceType::SqliteFile:
            return EOAOAResourceSwiftItemTypeSqliteFile;
        case OsmAndResourceType::WeatherForecast:
            return EOAOAResourceSwiftItemTypeWeatherForecast;
        case OsmAndResourceType::Travel:
            return EOAOAResourceSwiftItemTypeTravel;
        default:
            return EOAOAResourceSwiftItemTypeUnknown;
    }
}

- (long long) sizePkg
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return res.sizePkg;
}

- (NSString *) formatedSize
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OAResourcesUISwiftHelper formatSize:res.size addZero:NO];
}

- (NSString *) formatedSizePkg
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OAResourcesUISwiftHelper formatSize:res.sizePkg addZero:NO];
}

- (UIImage *) icon
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OAResourceType getIcon:res.resourceType templated:YES];
}

- (NSString *) iconName
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OAResourceType getIconName:res.resourceType];
}

- (BOOL) isInstalled
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [OsmAndApp instance].resourcesManager->isResourceInstalled(res.resourceId);
}

- (NSString *) resourceId
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return res.resourceId.toNSString();
}

- (id<OADownloadTask>) downloadTask
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return res.downloadTask;
}

- (void) refreshDownloadTask
{
    OARepositoryResourceItem *res = (OARepositoryResourceItem *)self.objcResourceItem;
    res.downloadTask = [self getDownloadTaskFor:[self resourceId]];
}

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (BOOL) isOutdatedItem
{
    return [self.objcResourceItem isKindOfClass:OAOutdatedResourceItem.class];
}

@end


@implementation OAMultipleResourceSwiftItem

- (NSArray<OAResourceSwiftItem *> *) items
{
    NSMutableArray<OAResourceSwiftItem *> *items = [NSMutableArray array];
    OAMultipleResourceItem *res = (OAMultipleResourceItem *)self.objcResourceItem;
    for (OAResourceItem *item in res.items)
    {
        [items addObject:[[OAResourceSwiftItem alloc] initWithItem:item]];
    }
    return items;
}

- (BOOL)allDownloaded
{
    OAMultipleResourceItem *res = (OAMultipleResourceItem *)self.objcResourceItem;
    return [res allDownloaded];
}

- (OAResourceSwiftItem *) getActiveItem:(BOOL)useDefautValue
{
    OAMultipleResourceItem *res = (OAMultipleResourceItem *)self.objcResourceItem;
    OAResourceItem *activeItem = [res getActiveItem:useDefautValue];
    return [[OAResourceSwiftItem alloc] initWithItem:activeItem];
}

- (NSString *) getResourceId
{
    OAMultipleResourceItem *res = (OAMultipleResourceItem *)self.objcResourceItem;
    return [res getResourceId];
}

@end


@implementation OAResourcesUISwiftHelper

+ (OAWorldRegion *) worldRegionByScopeId:(NSString *)regionId
{
    OsmAndAppInstance app = OsmAndApp.instance;
    return [app.worldRegion getSubregion:regionId];
}

+ (NSNumber *) resourceTypeByScopeId:(NSString *)scopeId
{
    OsmAndResourceType cppType = [OAResourceType resourceTypeByScopeId:scopeId];
    return [OAResourceType toValue:cppType];
}

+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegionId:(NSString *)regionId resourceTypeNames:(NSArray<NSString *> *)resourceTypeNames
{
    OAWorldRegion *region = [self worldRegionByScopeId:regionId];
    
    NSMutableArray<NSNumber *> *types = [NSMutableArray array];
    for (NSString *name in resourceTypeNames)
    {
        NSNumber *type = [self resourceTypeByScopeId:name];
        [types addObject:type];
    }
    
    return [self getResourcesInRepositoryIdsByRegion:region resourceTypes:types];
}

+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegion:(OAWorldRegion *)region resourceTypes:(NSArray<NSNumber *> *)resourceTypes
{
    NSMutableArray<OAResourceSwiftItem *> *swiftResources = [NSMutableArray array];
    
    OsmAndAppInstance app = OsmAndApp.instance;
    NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
    
    for (NSString *resourceId in ids)
    {
        const auto& cppResource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
        
        for (NSNumber *type in resourceTypes)
        {
            OsmAndResourceType cppType = [OAResourceType toResourceType:type isGroup:NO];
            if (cppResource->type == cppType)
            {
                OAResourceItem *objcResource = [self resourceItemByResource:cppResource region:region];
                [swiftResources addObject:[[OAResourceSwiftItem alloc] initWithItem:objcResource]];
                break;
            }
        }
    }

    return swiftResources;
}

+ (OAResourceSwiftItem *) getResourceFromDownloadTask:(id<OADownloadTask>)downloadTask
{
    if (downloadTask && downloadTask.resourceItem)
        return [[OAResourceSwiftItem alloc] initWithItem:downloadTask.resourceItem];
    return nil;
}

+ (OAResourceItem *) resourceItemByResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> &)resource region:(OAWorldRegion *)region
{
    OsmAndAppInstance app = OsmAndApp.instance;
    
    if (app.resourcesManager->isResourceInstalled(resource->id))
    {
        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:region
                                           withRegionName:YES
                                         withResourceType:NO];
        item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
        item.size = resource->size;
        item.worldRegion = region;

        const auto localResource = app.resourcesManager->getLocalResource(resource->id);
        item.resource = localResource;
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResource->localPath.toNSString() error:NULL] fileModificationDate];

        return item;
    }
    else
    {
        OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:region
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
        item.size = resource->size;
        item.sizePkg = resource->packageSize;
        item.worldRegion = region;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

        return item;
    }
}

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView
{
    return [OAResourcesUIHelper tickPath:progressView];
}

+ (void)offerDownloadAndInstallOf:(OAResourceSwiftItem *)item
                    onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                    onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    OARepositoryResourceItem *res = (OARepositoryResourceItem *)item.objcResourceItem;
    [OAResourcesUIHelper offerDownloadAndInstallOf:res onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
}

+ (void)offerDownloadAndInstallOf:(OAResourceSwiftItem *)item
                    onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                    onTaskResumed:(OADownloadTaskCallback)onTaskResumed
                completionHandler:(void(^)(UIAlertController *))completionHandler
{
    OARepositoryResourceItem *res = (OARepositoryResourceItem *)item.objcResourceItem;
    [OAResourcesUIHelper offerDownloadAndInstallOf:res onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed completionHandler:completionHandler silent:NO];
}

+ (void)offerDownloadAndUpdateOf:(OAResourceSwiftItem *)item
                   onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                   onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    if ([item isOutdatedItem])
    {
        OAOutdatedResourceItem *res = (OAOutdatedResourceItem *)item.objcResourceItem;
        [OAResourcesUIHelper offerDownloadAndUpdateOf:res onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
    }
}

+ (void) offerCancelDownloadOf:(OAResourceSwiftItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop completionHandler:(void(^)(UIAlertController *))completionHandler
{
    OAResourceItem *res = (OAResourceItem *)item.objcResourceItem;
    [OAResourcesUIHelper offerCancelDownloadOf:res onTaskStop:onTaskStop completionHandler:completionHandler];
}

+ (void)offerMultipleDownloadAndInstallOf:(OAMultipleResourceSwiftItem *)multipleItem
                            selectedItems:(NSArray<OAResourceSwiftItem *> *)selectedItems
                            onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                            onTaskResumed:(OADownloadTaskCallback)onTaskResumed
{
    NSMutableArray<OAResourceItem *> *items = [NSMutableArray array];
    for (OAResourceSwiftItem *item in selectedItems)
    {
        [items addObject:item.objcResourceItem];
    }
    [OAResourcesUIHelper offerMultipleDownloadAndInstallOf:multipleItem.objcResourceItem selectedItems:items onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed];
}

+ (void)deleteResourcesOf:(NSArray<OAResourceSwiftItem *> *)items progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    NSMutableArray<OALocalResourceItem *> *itemsToDelete = [NSMutableArray array];
    for (OAResourceSwiftItem *item in items)
    {
        [itemsToDelete addObject:(OALocalResourceItem *)item.objcResourceItem];
    }
    [OAResourcesUIHelper deleteResourcesOf:itemsToDelete progressHUD:progressHUD executeAfterSuccess:block];
}

+ (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceSwiftItem *> *)itemsToCheck
{
    NSMutableArray<OALocalResourceItem *> *itemsToRemove = [NSMutableArray new];
    OAResourceItem *prevItem;
    for (OAResourceSwiftItem *item in itemsToCheck)
    {
        OAResourceItem *itemToCheck = item.objcResourceItem;
        QString srtmMapName = itemToCheck.resourceId.remove(QLatin1String([OAResourceType isSRTMF:itemToCheck] ? ".srtmf.obf" : ".srtm.obf"));
        if (prevItem && prevItem.resourceId.startsWith(srtmMapName))
        {
            BOOL prevItemInstalled = OsmAndApp.instance.resourcesManager->isResourceInstalled(prevItem.resourceId);
            if (prevItemInstalled && prevItem.resourceId.compare(itemToCheck.resourceId) != 0)
            {
                [itemsToRemove addObject:(OALocalResourceItem *) prevItem];
            }
            else
            {
                BOOL itemToCheckInstalled = OsmAndApp.instance.resourcesManager->isResourceInstalled(itemToCheck.resourceId);
                if (itemToCheckInstalled && itemToCheck.resourceId.compare(prevItem.resourceId) != 0)
                    [itemsToRemove addObject:(OALocalResourceItem *) itemToCheck];
            }
        }
        prevItem = itemToCheck;
    }
    [self offerSilentDeleteResourcesOf:itemsToRemove];
}

+ (void)offerSilentDeleteResourcesOf:(NSArray<OALocalResourceItem *> *)items
{
    [OAResourcesUIHelper deleteResourcesOf:items progressHUD:nil executeAfterSuccess:nil];
}

+ (void) onDownldedResourceInstalled
{
    [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
    [OAManageResourcesViewController prepareData];
}

+ (BOOL) isInOutdatedResourcesList:(NSString *)resourceId
{
    return [OAResourcesUIHelper isInOutdatedResourcesList:resourceId];
}

+ (NSString *) formatSize:(long long)bytes addZero:(BOOL)addZero
{
    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    formatter.zeroPadsFractionDigits = addZero;
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    return [formatter stringFromByteCount:bytes];
}

+ (NSString *) formatedDownloadingProgressString:(long long)wholeSizeBytes progress:(float)progress
{
    return [self.class formatedDownloadingProgressString:wholeSizeBytes progress:progress addZero:YES];
}

+ (NSString *) formatedDownloadingProgressString:(long long)wholeSizeBytes progress:(float)progress addZero:(BOOL)addZero
{
    return [self.class formatedDownloadingProgressString:wholeSizeBytes progress:progress addZero:addZero combineViaSlash:NO];
}

+ (NSString *) formatedDownloadingProgressString:(long long)wholeSizeBytes progress:(float)progress addZero:(BOOL)addZero combineViaSlash:(BOOL)combineViaSlash
{
    NSString *wholeFileSize = [self formatSize:wholeSizeBytes addZero:NO];
    long long downloadedPartBytes = ((long long) wholeSizeBytes * progress);
    NSString *downloadedPart = [self formatSize:downloadedPartBytes addZero:addZero];
    return [NSString stringWithFormat:OALocalizedString(combineViaSlash ? @"ltr_or_rtl_combine_via_slash" : @"downloaded_bytes"), downloadedPart, wholeFileSize];
}

@end
