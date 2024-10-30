//
//  OARouteBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OACommonTypes.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"

#define kMapMargin 20.0

@class OARoutingHelper, OATrackChartPoints, OASGpxTrackAnalysis, OARouteStatisticsModeCell, OASTrkSegment, OASGpxFile, OABaseVectorLinesLayer, ElevationChart, OASTrackItem;

@protocol OARouteLineChartHelperDelegate

- (void)centerMapOnBBox:(const OABBox)rect;
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

- (void)refreshHighlightOnMap:(BOOL)forceFit
                    chartView:(ElevationChart *)chartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                     analysis:(OASGpxTrackAnalysis *)analysis;

- (void)refreshHighlightOnMap:(BOOL)forceFit
                    chartView:(ElevationChart *)chartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                      segment:(OASTrkSegment *)segment;

- (OATrackChartPoints *)generateTrackChartPoints:(ElevationChart *)chartView
                                        analysis:(OASGpxTrackAnalysis *)analysis;

- (OATrackChartPoints *)generateTrackChartPoints:(ElevationChart *)chartView
                                      startPoint:(CLLocationCoordinate2D)startPoint
                                        segment:(OASTrkSegment *)segment;

@end

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;
@property (nonatomic, readonly) OARouteLineChartHelper *routeLineChartHelper;

@property (nonatomic) OASGpxFile *gpx;
@property (nonatomic) OASTrackItem *trackItem;
@property (nonatomic) ElevationChart *statisticsChart;
@property (nonatomic) OATrackChartPoints *trackChartPoints;
@property (nonatomic) OASGpxTrackAnalysis *analysis;

- (instancetype) initWithGpxData:(NSDictionary *)data;

+ (NSAttributedString *) getFormattedElevationString:(OASGpxTrackAnalysis *)analysis;
+ (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) adjustViewPort:(BOOL)landscape;

- (double) getRoundedDouble:(double)toRound;

@end

