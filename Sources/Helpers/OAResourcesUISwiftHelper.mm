//
//  OAResourcesUISwiftHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAResourcesUISwiftHelper.h"
#import "OAResourcesUIHelper.h"
#import "OsmAndAppImpl.h"
#import "OAWorldRegion.h"
#import "OAManageResourcesViewController.h"

@implementation OAResourceSwiftItem : NSObject

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
    if (res.resourceType == OsmAndResourceType::Unknown)
        return EOAOAResourceSwiftItemTypeUnknown;
    else if (res.resourceType == OsmAndResourceType::MapRegion)
        return EOAOAResourceSwiftItemTypeMapRegion;
    else if (res.resourceType == OsmAndResourceType::RoadMapRegion)
        return EOAOAResourceSwiftItemTypeRoadMapRegion;
    else if (res.resourceType == OsmAndResourceType::SrtmMapRegion)
        return EOAOAResourceSwiftItemTypeSrtmMapRegion;
    else if (res.resourceType == OsmAndResourceType::DepthContourRegion)
        return EOAOAResourceSwiftItemTypeDepthContourRegion;
    else if (res.resourceType == OsmAndResourceType::DepthMapRegion)
        return EOAOAResourceSwiftItemTypeDepthMapRegion;
    else if (res.resourceType == OsmAndResourceType::WikiMapRegion)
        return EOAOAResourceSwiftItemTypeWikiMapRegion;
    else if (res.resourceType == OsmAndResourceType::HillshadeRegion)
        return EOAOAResourceSwiftItemTypeHillshadeRegion;
    else if (res.resourceType == OsmAndResourceType::SlopeRegion)
        return EOAOAResourceSwiftItemTypeSlopeRegion;
    else if (res.resourceType == OsmAndResourceType::HeightmapRegionLegacy)
        return EOAOAResourceSwiftItemTypeHeightmapRegionLegacy;
    else if (res.resourceType == OsmAndResourceType::GeoTiffRegion)
        return EOAOAResourceSwiftItemTypeGeoTiffRegion;
    else if (res.resourceType == OsmAndResourceType::LiveUpdateRegion)
        return EOAOAResourceSwiftItemTypeLiveUpdateRegion;
    else if (res.resourceType == OsmAndResourceType::VoicePack)
        return EOAOAResourceSwiftItemTypeVoicePack;
    else if (res.resourceType == OsmAndResourceType::MapStyle)
        return EOAOAResourceSwiftItemTypeMapStyle;
    else if (res.resourceType == OsmAndResourceType::MapStylesPresets)
        return EOAOAResourceSwiftItemTypeMapStylesPresets;
    else if (res.resourceType == OsmAndResourceType::OnlineTileSources)
        return EOAOAResourceSwiftItemTypeOnlineTileSources;
    else if (res.resourceType == OsmAndResourceType::GpxFile)
        return EOAOAResourceSwiftItemTypeGpxFile;
    else if (res.resourceType == OsmAndResourceType::SqliteFile)
        return EOAOAResourceSwiftItemTypeSqliteFile;
    else if (res.resourceType == OsmAndResourceType::WeatherForecast)
        return EOAOAResourceSwiftItemTypeWeatherForecast;
    else if (res.resourceType == OsmAndResourceType::Travel)
        return EOAOAResourceSwiftItemTypeTravel;
    
    return EOAOAResourceSwiftItemTypeUnknown;
}

- (NSString *) formatedSize
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [NSByteCountFormatter stringFromByteCount:res.size countStyle:NSByteCountFormatterCountStyleFile];
}

- (NSString *) formatedSizePkg
{
    OAResourceItem *res = (OAResourceItem *)self.objcResourceItem;
    return [NSByteCountFormatter stringFromByteCount:res.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
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
    return [res isInstalled];
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
    [OAResourcesUIHelper offerDownloadAndInstallOf:res onTaskCreated:onTaskCreated onTaskResumed:onTaskResumed completionHandler:completionHandler];
}

+ (void) offerCancelDownloadOf:(OAResourceSwiftItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop completionHandler:(void(^)(UIAlertController *))completionHandler
{
    OAResourceItem *res = (OAResourceItem *)item.objcResourceItem;
    [OAResourcesUIHelper offerCancelDownloadOf:res onTaskStop:onTaskStop completionHandler:completionHandler];
}

@end
