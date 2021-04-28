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

@class OADownloadDescriptionInfo;

@interface OAResourceItem : NSObject
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

@interface OARepositoryResourceItem : OAResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> resource;
@end

@interface OALocalResourceItem : OAResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource> resource;
@end

@interface OAOutdatedResourceItem : OALocalResourceItem
@end

@interface OAMapSourceResourceItem : OALocalResourceItem
@property OAMapSource* mapSource;
@end

@interface OASqliteDbResourceItem : OAMapSourceResourceItem
@property NSString* path;
@property NSString* fileName;
@property BOOL isOnline;
@end

@interface OAOnlineTilesResourceItem : OAMapSourceResourceItem
@property NSString* path;
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> res;
@end

@interface OAMapStyleResourceItem : OAMapSourceResourceItem
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@property int sortIndex;
@end

@interface OACustomResourceItem : OAResourceItem
@property NSString *subfolder;
@property NSString *downloadUrl;

@property NSDictionary<NSString *, NSString *> *names;
@property NSDictionary<NSString *, NSString *> *firstSubNames;
@property NSDictionary<NSString *, NSString *> *secondSubNames;

@property OADownloadDescriptionInfo *descriptionInfo;

- (NSString *) getSubName;
- (NSString *) getTargetFilePath;

- (BOOL) isInstalled;

@end

typedef void (^OADownloadTaskCallback)(id<OADownloadTask> task);

@class MBProgressHUD;

@interface OAResourcesUIHelper : NSObject

+ (NSString *) resourceTypeLocalized:(OsmAnd::ResourcesManager::ResourceType)type;

+ (NSString *) titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                      inRegion:(OAWorldRegion*)region
                withRegionName:(BOOL)includeRegionName
              withResourceType:(BOOL)includeResourceType;

+ (BOOL) isSpaceEnoughToDownloadAndUnpackOf:(OAResourceItem*)item;
+ (BOOL) isSpaceEnoughToDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource;
+ (BOOL) verifySpaceAvailableToDownloadAndUnpackOf:(OAResourceItem*)item
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

+ (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
+ (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void) startDownloadOfItem:(OARepositoryResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
+ (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;
+ (void) startDownloadOfCustomItem:(OACustomResourceItem *)item onTaskCreated:(OADownloadTaskCallback)onTaskCreated onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void) offerCancelDownloadOf:(OAResourceItem *)item_ onTaskStop:(OADownloadTaskCallback)onTaskStop;
+ (void) offerCancelDownloadOf:(OAResourceItem *)item_;
+ (void) cancelDownloadOf:(OAResourceItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop;

+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block;
+ (void) offerDeleteResourceOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController progressHUD:(MBProgressHUD *)progressHUD;
+ (void) deleteResourceOf:(OALocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD executeAfterSuccess:(dispatch_block_t)block;
+ (void) deleteResourceOf:(OALocalResourceItem *)item progressHUD:(MBProgressHUD *)progressHUD;

+ (void) offerClearCacheOf:(OALocalResourceItem *)item viewController:(UIViewController *)viewController executeAfterSuccess:(dispatch_block_t)block;
+ (void) clearCacheOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block;

+ (OAWorldRegion *) findRegionOrAnySubregionOf:(OAWorldRegion*)region
                          thatContainsResource:(const QString&)resourceId;
+ (NSString *) getCountryName:(OAResourceItem *)item;
+ (BOOL) checkIfDownloadAvailable;
+ (BOOL) checkIfDownloadAvailable:(OAWorldRegion *)region;
+ (void) requestMapDownloadInfo:(CLLocationCoordinate2D)coordinate resourceType:(OsmAnd::ResourcesManager::ResourceType)resourceType onComplete:(void (^)(NSArray<OAResourceItem *>*))onComplete;
+ (void) clearTilesOf:(OAResourceItem *)resource area:(OsmAnd::AreaI)area zoom:(float)zoom onComplete:(void (^)(void))onComplete;

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView;

+ (NSArray<OAResourceItem *> *) getSortedRasterMapSources:(BOOL)includeOffline;
+ (NSDictionary<OAMapSource *, OAResourceItem *> *) getOnlineRasterMapSourcesBySource;

+ (NSArray<OAMapStyleResourceItem *> *) getExternalMapStyles;

+ (NSArray<NSString *> *) getInstalledResourcePathsByTypes:(QSet<OsmAnd::ResourcesManager::ResourceType>)resourceTypes;

@end
