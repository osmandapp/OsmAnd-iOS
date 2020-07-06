//
//  OAResourcesUIHelper.h
//  OsmAnd
//
//  Created by Alexey on 03.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OAWorldRegion.h"
#import <FFCircularProgressView.h>
#import "FFCircularProgressView+isSpinning.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/IncrementalChangesManager.h>

#define public(name) OAResourcesUIHelper__##name

#define ResourceItem public(ResourceItem)

@interface ResourceItem : NSObject
@property NSString* title;
@property QString resourceId;
@property OsmAnd::ResourcesManager::ResourceType resourceType;
@property uint64_t size;
@property uint64_t sizePkg;
@property id<OADownloadTask> __weak downloadTask;
@property OAWorldRegion* worldRegion;
@property BOOL disabled;

- (void) updateSize;

@end

#define RepositoryResourceItem public(RepositoryResourceItem)
@interface RepositoryResourceItem : ResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resource;
@end

#define LocalResourceItem public(LocalResourceItem)
@interface LocalResourceItem : ResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> resource;
@end

#define OutdatedResourceItem public(OutdatedResourceItem)
@interface OutdatedResourceItem : LocalResourceItem
@end

#define SqliteDbResourceItem public(SqliteDbResourceItem)
@interface SqliteDbResourceItem : LocalResourceItem
@property NSString* path;
@property NSString* fileName;
@property NSString* optionalLabel;
@end

#define OnlineTilesResourceItem public(OnlineTilesResourceItem)
@interface OnlineTilesResourceItem : LocalResourceItem
@property NSString* path;
@end

typedef void (^OADownloadTaskCallback)(id<OADownloadTask> task);

@class MBProgressHUD;

@interface OAResourcesUIHelper : NSObject

+ (NSString *) resourceTypeLocalized:(OsmAnd::ResourcesManager::ResourceType)type;

+ (NSString *) titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                      inRegion:(OAWorldRegion*)region
                withRegionName:(BOOL)includeRegionName
              withResourceType:(BOOL)includeResourceType;

+ (BOOL) isSpaceEnoughToDownloadAndUnpackOf:(ResourceItem*)item;
+ (BOOL) isSpaceEnoughToDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource;
+ (BOOL) verifySpaceAvailableToDownloadAndUnpackOf:(ResourceItem*)item
                                          asUpdate:(BOOL)isUpdate;
+ (BOOL) verifySpaceAvailableDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
                                      withResourceName:(NSString*)resourceName
                                              asUpdate:(BOOL)isUpdate;
+ (void) showNotEnoughSpaceAlertFor:(NSString*)resourceName
                           withSize:(unsigned long long)size
                           asUpdate:(BOOL)isUpdate;

+ (void) startBackgroundDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource  resourceName:(NSString *)name;
+ (void) startBackgroundDownloadOf:(const std::shared_ptr<const OsmAnd::IncrementalChangesManager::IncrementalUpdate>&)resource;
+ (void) startBackgroundDownloadOf:(NSURL *)resourceUrl resourceId:(NSString *)resourceId resourceName:(NSString *)name;

+ (void) offerDownloadAndInstallOf:(RepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
+ (void) offerDownloadAndUpdateOf:(OutdatedResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void) startDownloadOfItem:(RepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
+ (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void) offerCancelDownloadOf:(ResourceItem *)item_ onTaskStop:(OADownloadTaskCallback)onTaskStop;
+ (void) offerCancelDownloadOf:(ResourceItem *)item_;
+ (void) cancelDownloadOf:(ResourceItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop;

+ (void) offerDeleteResourceOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block;
+ (void) offerDeleteResourceOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD;
+ (void) deleteResourceOf:(LocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block;
+ (void) deleteResourceOf:(LocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD;

+ (void) offerClearCacheOf:(LocalResourceItem *)item viewController:(UIViewController *)viewController executeAfterSuccess:(dispatch_block_t)block;
+ (void) clearCacheOf:(LocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block;

+ (OAWorldRegion *) findRegionOrAnySubregionOf:(OAWorldRegion*)region
                          thatContainsResource:(const QString&)resourceId;
+ (NSString *) getCountryName:(ResourceItem *)item;
+ (BOOL) checkIfDownloadAvailable:(OAWorldRegion *)region;
+ (void) requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate resourceType:(OsmAnd::ResourcesManager::ResourceType)resourceType onComplete:(void (^)(NSArray<ResourceItem *>*))onComplete;

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView;

@end
