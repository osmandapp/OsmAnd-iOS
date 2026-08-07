//
//  OAGpxApproximationViewController.h
//  OsmAnd
//
//  Created by Skalii on 31.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAPlanningPopupBaseViewController.h"

@class OASWptPt, OAApplicationMode;

@interface OAGpxApproximationViewController : OAPlanningPopupBaseViewController


- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints;

@end
