//
//  OARouteBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

#define kMapMargin 20.0

@class OARoutingHelper, OASGpxTrackAnalysis, OARouteStatisticsModeCell, OASGpxFile, OASTrkSegment, OABaseVectorLinesLayer, LineChartView, ElevationChart, TrackChartHelper, OASTrackItem, OASKQuadRect;

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;
@property (nonatomic, readonly) TrackChartHelper *trackChartHelper;

@property (nonatomic) OASGpxFile *gpx;
@property (nonatomic) OASTrackItem *trackItem;
@property (nonatomic) ElevationChart *statisticsChart;
@property (nonatomic) OASGpxTrackAnalysis *analysis;
@property (nonatomic) OASTrkSegment *segment;

- (instancetype) initWithGpxData:(NSDictionary *)data;

+ (NSAttributedString *) getFormattedElevationString:(OASGpxTrackAnalysis *)analysis;
+ (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) adjustViewPort:(BOOL)landscape;

- (double) getRoundedDouble:(double)toRound;

@end

