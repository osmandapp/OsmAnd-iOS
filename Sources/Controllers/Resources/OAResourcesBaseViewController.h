//
//  OAResourcesBaseViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OsmAndApp.h"
#import "OAWorldRegion.h"
#import "OADownloadProgressView.h"
#import "OASuperViewController.h"

#include <OsmAndCore/ResourcesManager.h>

#define public(name) OAResourcesBaseViewController__##name

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
@end

@interface OAResourcesBaseViewController : OASuperViewController<OADownloadProgressViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarMaps;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPlugins;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPurchases;

@property OADownloadProgressView* downloadView;

@property BOOL dataInvalidated;

+ (NSString *)resourceTypeLocalized:(OsmAnd::ResourcesManager::ResourceType)type;

- (void)updateTableLayout;
- (void)updateContent;
- (void)refreshContent:(BOOL)update;
- (void)refreshDownloadingContent:(NSString *)downloadTaskKey;

+ (NSString*)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                    inRegion:(OAWorldRegion*)region
              withRegionName:(BOOL)includeRegionName;

- (void)onItemClicked:(id)senderItem;

- (BOOL)isSpaceEnoughToDownloadAndUnpackOf:(ResourceItem*)item;
- (BOOL)isSpaceEnoughToDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource;
- (BOOL)verifySpaceAvailableToDownloadAndUnpackOf:(ResourceItem*)item
                                         asUpdate:(BOOL)isUpdate;
- (BOOL)verifySpaceAvailableDownloadAndUnpackResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
                                     withResourceName:(NSString*)resourceName
                                             asUpdate:(BOOL)isUpdate;
- (void)showNotEnoughSpaceAlertFor:(NSString*)resourceName
                          withSize:(unsigned long long)size
                          asUpdate:(BOOL)isUpdate;

- (void)offerDownloadAndInstallOf:(RepositoryResourceItem*)item;
- (void)offerDownloadAndUpdateOf:(OutdatedResourceItem*)item;
- (void)startDownloadOfItem:(RepositoryResourceItem*)item;
- (void)startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name
;
+ (void)startBackgroundDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource  resourceName:(NSString *)name;

- (void)offerCancelDownloadOf:(ResourceItem*)item;
- (void)cancelDownloadOf:(ResourceItem*)item;

- (void)offerDeleteResourceOf:(LocalResourceItem*)item executeAfterSuccess:(dispatch_block_t)block;
- (void)offerDeleteResourceOf:(LocalResourceItem*)item;
- (void)deleteResourceOf:(LocalResourceItem*)item executeAfterSuccess:(dispatch_block_t)block;
- (void)deleteResourceOf:(LocalResourceItem*)item;

- (void)showDetailsOf:(LocalResourceItem*)item;

- (UITableView *)getTableView;

- (id<OADownloadTask>)getDownloadTaskFor:(NSString*)resourceId;

@property(readonly) NSComparator resourceItemsComparator;
@property (strong, nonatomic) OAWorldRegion* region;

+ (OAWorldRegion*)findRegionOrAnySubregionOf:(OAWorldRegion*)region
                        thatContainsResource:(const QString&)resourceId;
+ (NSString *)getCountryName:(ResourceItem *)item;

@end
