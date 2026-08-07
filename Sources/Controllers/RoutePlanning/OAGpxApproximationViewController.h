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

@property (nonatomic, copy, nullable) void (^onApplyConfiguration)(OAApplicationMode *mode, float distanceThreshold);

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints;
- (instancetype)initWithMode:(OAApplicationMode *)mode
                 routePoints:(NSArray<NSArray<OASWptPt *> *> *)routePoints
      shouldCalculateOnApply:(BOOL)shouldCalculateOnApply;

@end
