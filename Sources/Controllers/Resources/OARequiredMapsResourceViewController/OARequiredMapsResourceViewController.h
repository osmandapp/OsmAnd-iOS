//
//  OARequiredMapsResourceViewController.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 02.04.2024.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

// #import <OsmAndCore/ResourcesManager.h>
#import "OABaseButtonsViewController.h"
// #import "OAResourcesUIHelper.h"

//@protocol OADownloadMultipleResourceDelegate
//
//@required
//
//- (void)downloadResources:(OAMultipleResourceItem *)item selectedItems:(NSArray<OAResourceItem *> *)selectedItems;
//- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceItem *> *)itemsToCheck;
//- (void)clearMultipleResources;
//- (void)onDetailsSelected:(OALocalResourceItem *)item;
//
//@end

@class OAWorldRegion;

NS_ASSUME_NONNULL_BEGIN

@interface OARequiredMapsResourceViewController : OABaseNavbarViewController

- (instancetype)initWithWorldRegion:(NSArray<OAWorldRegion *> *)missingMaps
                       mapsToUpdate:(NSArray<OAWorldRegion *> *)mapsToUpdate;

//@property(weak, nonatomic) id <OADownloadMultipleResourceDelegate> delegate;
//
//- (instancetype)initWithResource:(OAMultipleResourceItem *)resource;

@end
NS_ASSUME_NONNULL_END
