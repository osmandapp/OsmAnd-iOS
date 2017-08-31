//
//  OARouteTargetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@interface OARouteTargetViewController : OATargetMenuViewController

@property (nonatomic, readonly) BOOL target;

- (instancetype)initWithTarget:(BOOL)target;

@end
