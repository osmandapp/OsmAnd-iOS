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
#import "OAHillshadeLayer.h"
//#import "OASizes.h"
#import "OARootViewController.h"
#import "OASQLiteTileSource.h"
//#import "OATargetMenuViewController.h"

#include "Localization.h"
#include <OsmAndCore/WorldRegions.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
typedef OsmAnd::IncrementalChangesManager::IncrementalUpdate IncrementalUpdate;

@implementation ResourceItem

- (BOOL) isEqual:(id)object
{
    if (self.resourceId == nullptr || ((ResourceItem *)object).resourceId == nullptr)
        return NO;
    
    return self.resourceId.compare(((ResourceItem *)object).resourceId) == 0;
}

- (void) updateSize
{
    // override
}

@end

@implementation RepositoryResourceItem
@end

@implementation LocalResourceItem
@end

@implementation OutdatedResourceItem
@end

@implementation SqliteDbResourceItem

- (void) updateSize
{
    self.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil] fileSize];
}

@end

@implementation OnlineTilesResourceItem
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
            
        default:
            return OALocalizedString(@"res_unknown");
    }
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

+ (BOOL) isSpaceEnoughToDownloadAndUnpackOf:(ResourceItem *)item_
{
    if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

        return [self.class isSpaceEnoughToDownloadAndUnpackResource:item.resource];
    }
    else if ([item_ isKindOfClass:[LocalResourceItem class]])
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

+ (BOOL) verifySpaceAvailableToDownloadAndUnpackOf:(ResourceItem*)item_
                                          asUpdate:(BOOL)isUpdate
{
    if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

        return [self.class verifySpaceAvailableDownloadAndUnpackResource:item.resource
                                                  withResourceName:[self.class titleOfResource:item.resource
                                                                                               inRegion:item.worldRegion
                                                                                         withRegionName:YES
                                                                                       withResourceType:YES]
                                                          asUpdate:isUpdate];
    }
    else if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        LocalResourceItem* item = (LocalResourceItem*)item_;

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

+ (BOOL) checkIfDownloadAvailable:(OAWorldRegion *)region
{
#if defined(OSMAND_IOS_DEV)
    return YES;
#endif
    
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

+ (void) requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate resourceType:(OsmAnd::ResourcesManager::ResourceType)resourceType onComplete:(void (^)(NSArray<ResourceItem *>*))onComplete
{
    NSMutableArray<ResourceItem *>* res;
    res = [NSMutableArray new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
                NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsyRegion:region];
                if (ids.count > 0)
                {
                    for (NSString *resourceId in ids)
                    {
                        const auto resource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                        if (resource->type == resourceType)
                        {
                            if (app.resourcesManager->isResourceInstalled(resource->id))
                            {
                                LocalResourceItem *item = [[LocalResourceItem alloc] init];
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
                                RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
           if (onComplete)
               onComplete(res);
        });
    });
}

+ (NSString *) getCountryName:(ResourceItem *)item
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_free_exp") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return isAvailable;
}

+ (BOOL) checkIfUpdateEnabled:(OAWorldRegion *)region
{
#if defined(OSMAND_IOS_DEV)
    return YES;
#endif
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

+ (void) offerDownloadAndInstallOf:(RepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
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
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN)
    {
        message = [[NSString stringWithFormat:OALocalizedString(@"res_inst_avail_cell_q"),
                                    resourceName,
                                    stringifiedSize] mutableCopy];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"incur_high_charges")];
        [message appendString:@" "];
        [message appendString:OALocalizedString(@"proceed_q")];
        
    }
    else
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
    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (void) offerDownloadAndUpdateOf:(OutdatedResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
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

+ (void) startDownloadOfItem:(RepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed
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

+ (void) offerCancelDownloadOf:(ResourceItem *)item_ onTaskStop:(OADownloadTaskCallback)onTaskStop
{
    BOOL isUpdate = NO;
    std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
    if ([item_ isKindOfClass:[LocalResourceItem class]])
    {
        LocalResourceItem* item = (LocalResourceItem*)item_;

        resource = item.resource;
        isUpdate = [item isKindOfClass:[OutdatedResourceItem class]];
    }
    else if ([item_ isKindOfClass:[RepositoryResourceItem class]])
    {
        RepositoryResourceItem* item = (RepositoryResourceItem*)item_;

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
    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (void) offerCancelDownloadOf:(ResourceItem *)item_
{
    [self.class offerCancelDownloadOf:item_ onTaskStop:nil];
}

+ (void) cancelDownloadOf:(ResourceItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop
{
    if (onTaskStop)
        onTaskStop(item.downloadTask);
    
    [item.downloadTask stop];
}

+ (void) offerDeleteResourceOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    NSString *title;
    if ([item isKindOfClass:[SqliteDbResourceItem class]])
        title = ((SqliteDbResourceItem *)item).title;
    else if ([item isKindOfClass:[OnlineTilesResourceItem class]])
        title = ((OnlineTilesResourceItem *)item).title;
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

+ (void) offerDeleteResourceOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD
{
    [self offerDeleteResourceOf:item viewController:viewController progressHUD:progressHUD executeAfterSuccess:nil];
}

+ (void) deleteResourceOf:(LocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block
{
    dispatch_block_t proc = ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        if ([item isKindOfClass:[SqliteDbResourceItem class]])
        {
            SqliteDbResourceItem *sqliteItem = (SqliteDbResourceItem *)item;
            [[OAMapCreatorHelper sharedInstance] removeFile:sqliteItem.fileName];
            if (block)
                block();
        }
        else if ([item isKindOfClass:[OnlineTilesResourceItem class]])
        {
            OnlineTilesResourceItem *tilesItem = (OnlineTilesResourceItem *)item;
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
            if (item.resourceType == OsmAndResourceType::HillshadeRegion)
            {
                NSString *filename = [app.resourcesManager->getLocalResource(item.resourceId)->localPath.toNSString() lastPathComponent];
                if (app.data.hillshade == EOATerrainTypeHillshade)
                    [[OAHillshadeLayer sharedInstanceHillshade] removeFromDB:filename];
                else if (app.data.hillshade == EOATerrainTypeSlope)
                    [[OAHillshadeLayer sharedInstanceSlope] removeFromDB:filename];
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
                if (item.resourceType == OsmAndResourceType::HillshadeRegion)
                    [app.data.hillshadeResourcesChangeObservable notifyEvent];
                
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

+ (void) deleteResourceOf:(LocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD
{
    [self.class deleteResourceOf:item progressHUD:progressHUD executeAfterSuccess:nil];
}

+ (void) offerClearCacheOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController executeAfterSuccess:(dispatch_block_t)block
{
    NSString* message;
    NSString *title;
    
    if ([item isKindOfClass:[SqliteDbResourceItem class]])
        title = ((SqliteDbResourceItem *)item).title;
    else if ([item isKindOfClass:[OnlineTilesResourceItem class]])
        title = ((OnlineTilesResourceItem *)item).title;
    
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

+ (void) clearCacheOf:(LocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block
{
     if ([item isKindOfClass:[SqliteDbResourceItem class]])
     {
         SqliteDbResourceItem *sqliteItem = (SqliteDbResourceItem *)item;
         OASQLiteTileSource *ts = [[OASQLiteTileSource alloc] initWithFilePath:sqliteItem.path];
         if ([ts supportsTileDownload])
         {
             [ts deleteCache:block];
         }
     }
     if ([item isKindOfClass:[OnlineTilesResourceItem class]])
     {
         OnlineTilesResourceItem *sqliteItem = (OnlineTilesResourceItem *)item;
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

@end
