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

@interface OAResourcesBaseViewController : OACompoundViewController<OADownloadProgressViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarMaps;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPlugins;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPurchases;
@property (nonatomic, assign) BOOL dataInvalidated;

@property OADownloadProgressView* downloadView;

@property (readonly) NSComparator resourceItemsComparator;
@property (strong, nonatomic) OAWorldRegion* region;

+ (BOOL) isDataInvalidated;
+ (void) setDataInvalidated;

- (void) updateTableLayout;
- (void) updateContent;
- (void) refreshContent:(BOOL)update;
- (void) refreshDownloadingContent:(NSString *)downloadTaskKey;

- (void) onItemClicked:(id)senderItem;

- (void) offerDownloadAndInstallOf:(OARepositoryResourceItem *)item;
- (void) offerDownloadAndUpdateOf:(OAOutdatedResourceItem *)item;

- (void) startDownloadOfItem:(OARepositoryResourceItem*)item;
- (void) startDownloadOf:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository>&)resource resourceName:(NSString *)name;

- (void) offerCancelDownloadOf:(OAResourceItem *)item;

- (void) offerDeleteResourceOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block;
- (void) offerDeleteResourceOf:(OALocalResourceItem *)item;

- (void) offerClearCacheOf:(OALocalResourceItem *)item executeAfterSuccess:(dispatch_block_t)block;

- (void) showDetailsOf:(OALocalResourceItem *)item;
- (void) showDetailsOfCustomItem:(OACustomResourceItem *)item;

- (UITableView *) getTableView;

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId;

@end
