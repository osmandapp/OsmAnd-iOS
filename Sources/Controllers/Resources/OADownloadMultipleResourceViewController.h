//
//  OADownloadMultipleResourceViewController.h
//  OsmAnd
//
//  Created by Skalii on 15.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAResourceSwiftItem, OAMultipleResourceSwiftItem;

@protocol OADownloadMultipleResourceDelegate

@required

- (void)downloadResources:(OAMultipleResourceSwiftItem *)item selectedItems:(NSArray<OAResourceSwiftItem *> *)selectedItems;
- (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceSwiftItem *> *)itemsToCheck;
- (void)clearMultipleResources;
- (void)onDetailsSelected:(OAResourceSwiftItem *)item;

@end

@interface OADownloadMultipleResourceViewController : OABaseButtonsViewController

@property(weak, nonatomic) id <OADownloadMultipleResourceDelegate> delegate;

- (instancetype)initWithSwiftResource:(OAMultipleResourceSwiftItem *)swiftResource;

@end
