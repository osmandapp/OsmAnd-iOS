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

@end
