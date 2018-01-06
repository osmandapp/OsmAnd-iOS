//
//  OARouteTargetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OARTargetPoint;

@interface OARouteTargetViewController : OATargetInfoViewController

@property (nonatomic, readonly) OARTargetPoint *targetPoint;

- (instancetype) initWithTargetPoint:(OARTargetPoint *)targetPoint;

@end
