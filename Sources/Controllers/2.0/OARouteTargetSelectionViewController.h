//
//  OARouteTargetSelectionViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@interface OARouteTargetSelectionViewController : OATargetMenuViewController

@property (nonatomic, readonly) OATargetPointType type;

- (instancetype) initWithTargetPointType:(OATargetPointType)type;

@end
