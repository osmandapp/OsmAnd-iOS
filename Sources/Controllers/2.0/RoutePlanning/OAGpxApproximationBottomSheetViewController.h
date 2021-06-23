//
//  OAGpxApproximationBottomSheetViewController.h
//  OsmAnd
//
//  Created by Skalii on 31.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OAGpxTrkPt, OAApplicationMode, OAGpxRouteApproximation;

@protocol OAGpxApproximationBottomSheetDelegate <NSObject>

@required

- (void)onCancelGpxApproximation;
- (void)onApplyGpxApproximation;
- (void)onGpxApproximationDone:(NSArray<OAGpxRouteApproximation *> *)gpxApproximations pointsList:(NSArray<NSArray<OAGpxTrkPt *> *> *)pointsList mode:(OAApplicationMode *)mode;

@end

@interface OAGpxApproximationBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OAGpxApproximationBottomSheetDelegate> delegate;

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxTrkPt *> *> *)routePoints;

@end
