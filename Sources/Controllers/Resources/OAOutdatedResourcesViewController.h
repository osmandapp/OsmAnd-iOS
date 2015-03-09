//
//  OAOutdatedResourcesViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAResourcesBaseViewController.h"

@interface OAOutdatedResourcesViewController : OAResourcesBaseViewController

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarMaps;
@property (weak, nonatomic) IBOutlet UIButton *btnToolbarPurchases;

@property (nonatomic, assign) BOOL openFromSplash;

- (void)setupWithRegion:(OAWorldRegion*)region
       andOutdatedItems:(NSArray*)items;

@end
