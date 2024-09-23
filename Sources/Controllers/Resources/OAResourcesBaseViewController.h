//
//  OAResourcesBaseViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OADownloadProgressView.h"
#import "OACompoundViewController.h"
#import "OAResourcesUIHelper.h"

@interface OAResourcesBaseViewController : OACompoundViewController<OADownloadProgressViewDelegate>

@property (nonatomic, assign) BOOL dataInvalidated;

@property (readonly) NSComparator resourceItemsComparator;
@property (strong, nonatomic) OAWorldRegion* region;

+ (BOOL) isDataInvalidated;
+ (void) setDataInvalidated;

- (void) updateTableLayout;
- (void) updateContent;
- (void) refreshContent:(BOOL)update;
- (void) updateDisplayItem:(OAResourceItem *)item;

- (void) onItemClicked:(id)senderItem;

- (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item;
- (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item;

- (void) showDownloadViewForTask:(id<OADownloadTask>)task;

- (void) startDownloadOfItem:(OARepositoryResourceItem*)item;
- (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource
            resourceName:(NSString *)name;

- (void) offerCancelDownloadOf:(OAResourceItem *)item;

- (void) offerDeleteResourceOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)onComplete;
- (void) offerDeleteResourceOf:(OALocalResourceItem *)item;
- (void) offerSilentDeleteResourcesOf:(NSArray<OALocalResourceItem *> *)items;

- (void) offerClearCacheOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block;

- (void) showDetailsOf:(OALocalResourceItem *)item;
- (void) showDetailsOfCustomItem:(OACustomResourceItem *)item;

- (UITableView *) getTableView;

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId;

@end
