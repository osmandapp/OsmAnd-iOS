//
//  OAManageResourcesViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAResourcesBaseViewController.h"

@interface OAManageResourcesViewController : OAResourcesBaseViewController

@property (nonatomic, assign) BOOL openFromSplash;
@property (nonatomic, assign) BOOL displayBannerPurchaseAllMaps;

+ (NSArray<NSString *> *) getResourcesInRepositoryIdsByRegion:(OAWorldRegion *)region;
+ (void) prepareData;
+ (BOOL) lackOfResources;

@end
