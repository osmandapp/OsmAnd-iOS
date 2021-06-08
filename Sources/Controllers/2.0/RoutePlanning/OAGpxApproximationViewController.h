//
//  OAGpxApproximationViewController.h
//  OsmAnd
//
//  Created by Skalii on 31.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@protocol OAGpxApproximationBottomSheetDelegate <NSObject>

@required

- (void)onCancelGpxApproximation;
- (void)onApplyGpxApproximation;

@end

@class OAGpxRtePt, OAApplicationMode;

@interface OAGpxApproximationViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OAGpxApproximationBottomSheetDelegate> delegate;

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxRtePt *> *> *)routePoints;

@end
