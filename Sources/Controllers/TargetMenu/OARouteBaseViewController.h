//
//  OARouteBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

#define kMapMargin 20.0

@class OARoutingHelper, OASGpxTrackAnalysis, OARouteStatisticsModeCell, OASGpxFile, OABaseVectorLinesLayer, LineChartView, ElevationChart, OASTrackItem, OASKQuadRect;

@protocol OARouteLineChartHelperDelegate

- (void)centerMapOnBBox:(OASKQuadRect *)rect;
- (void)adjustViewPort:(BOOL)landscape;

@end

@interface OARouteLineChartHelper : NSObject

@property (nonatomic) BOOL isLandscape;
@property (nonatomic) CGRect screenBBox;

- (instancetype)initWithGpxDoc:(OASGpxFile *)gpxDoc layer:(OABaseVectorLinesLayer *)layer;

@property (nonatomic, weak) id<OARouteLineChartHelperDelegate> delegate;

- (void)changeChartTypes:(NSArray<NSNumber *> *)types
                  chart:(ElevationChart *)chart
               analysis:(OASGpxTrackAnalysis *)analysis
               modeCell:(OARouteStatisticsModeCell *)statsModeCell;

- (void)refreshChart:(LineChartView *)chart
       fitTrackOnMap:(BOOL)fitTrackOnMap
            forceFit:(BOOL)forceFit
    recalculateXAxis:(BOOL)recalculateXAxis;

@end

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;
@property (nonatomic, readonly) OARouteLineChartHelper *routeLineChartHelper;

@property (nonatomic) OASGpxFile *gpx;
@property (nonatomic) OASTrackItem *trackItem;
@property (nonatomic) ElevationChart *statisticsChart;
@property (nonatomic) OASGpxTrackAnalysis *analysis;

- (instancetype) initWithGpxData:(NSDictionary *)data;

+ (NSAttributedString *) getFormattedElevationString:(OASGpxTrackAnalysis *)analysis;
+ (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) adjustViewPort:(BOOL)landscape;

- (double) getRoundedDouble:(double)toRound;

@end

