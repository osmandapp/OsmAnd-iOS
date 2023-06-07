//
//  OADownloadMultipleResourceViewController.h
//  OsmAnd
//
//  Created by Skalii on 15.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <OsmAndCore/ResourcesManager.h>
#import "OABaseButtonsViewController.h"
#import "OAResourcesUIHelper.h"

@protocol OADownloadMultipleResourceDelegate

@required

- (void)downloadResources:(OAMultipleResourceItem *)item selectedItems:(NSArray<OAResourceItem *> *)selectedItems;
- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceItem *> *)itemsToCheck;
- (void)clearMultipleResources;
- (void)onDetailsSelected:(OALocalResourceItem *)item;

@end

@interface OADownloadMultipleResourceViewController : OABaseButtonsViewController

@property(weak, nonatomic) id <OADownloadMultipleResourceDelegate> delegate;

- (instancetype)initWithResource:(OAMultipleResourceItem *)resource;

@end
