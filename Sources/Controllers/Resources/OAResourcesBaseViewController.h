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

#include <OsmAndCore/ResourcesManager.h>

#define public(name) OAResourcesBaseViewController__##name

#define ResourceItem public(ResourceItem)
@interface ResourceItem : NSObject
@property NSString* title;
@property QString resourceId;
@property id<OADownloadTask> __weak downloadTask;
@property OAWorldRegion* worldRegion;
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

@interface OAResourcesBaseViewController : UIViewController

@property BOOL dataInvalidated;

- (void)updateContent;
- (void)refreshContent;

- (NSString*)titleOfResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::Resource>&)resource
                    inRegion:(OAWorldRegion*)region
              withRegionName:(BOOL)includeRegionName;

- (void)onItemClicked:(id)senderItem;
- (void)offerDownloadAndInstallOf:(RepositoryResourceItem*)item;
- (void)offerDownloadAndUpdateOf:(OutdatedResourceItem*)item;
- (void)offerCancelDownloadOf:(ResourceItem*)item;
- (void)offerDeleteResourceOf:(LocalResourceItem*)item;
- (void)showDetailsOf:(LocalResourceItem*)item;

- (id<OADownloadTask>)getDownloadTaskFor:(NSString*)resourceId;

@property(readonly) NSComparator resourceItemsComparator;

+ (OAWorldRegion*)findRegionOrAnySubregionOf:(OAWorldRegion*)region
                        thatContainsResource:(const QString&)resourceId;

@end
