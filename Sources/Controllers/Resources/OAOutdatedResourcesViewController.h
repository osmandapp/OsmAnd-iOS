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

- (void)setupWithRegion:(OAWorldRegion*)region
       andOutdatedItems:(NSArray*)items;

@end
