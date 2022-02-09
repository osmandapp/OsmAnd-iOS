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

@class OARoutingHelper;
@class LineChartView;
@class OAGPXDocument;
@class OATrackChartPoints;
@class OAGPXTrackAnalysis;
@class OARouteStatisticsModeCell;
@class OATrkSegment;

typedef void(^OARouteLineChartCenterMapOnBBox)(OABBox rect);
typedef void(^OARouteLineChartAdjustViewPort)();

@interface OARouteLineChartHelper : NSObject

@property (nonatomic) BOOL isLandscape;
@property (nonatomic) CGRect screenBBox;

- (instancetype)initWithGpxDoc:(OAGPXDocument *)gpxDoc
               centerMapOnBBox:(OARouteLineChartCenterMapOnBBox)centerMapOnBBox
                adjustViewPort:(OARouteLineChartAdjustViewPort)adjustViewPort;

- (void)changeChartMode:(EOARouteStatisticsMode)mode
                  chart:(LineChartView *)chart
               analysis:(OAGPXTrackAnalysis *)analysis
               modeCell:(OARouteStatisticsModeCell *)statsModeCell;

- (void)refreshHighlightOnMap:(BOOL)forceFit
                lineChartView:(LineChartView *)lineChartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                     analysis:(OAGPXTrackAnalysis *)analysis;

- (void)refreshHighlightOnMap:(BOOL)forceFit
                lineChartView:(LineChartView *)lineChartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                     segment:(OATrkSegment *)segment;

- (OATrackChartPoints *)generateTrackChartPoints:(LineChartView *)lineChartView
                                        analysis:(OAGPXTrackAnalysis *)analysis;

- (OATrackChartPoints *)generateTrackChartPoints:(LineChartView *)lineChartView
                                      startPoint:(CLLocationCoordinate2D)startPoint
                                        segment:(OATrkSegment *)segment;

@end

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;
@property (nonatomic, readonly) OARouteLineChartHelper *routeLineChartHelper;

@property (nonatomic) OAGPXDocument *gpx;
@property (nonatomic) LineChartView *statisticsChart;
@property (nonatomic) OATrackChartPoints *trackChartPoints;
@property (nonatomic) OAGPXTrackAnalysis *analysis;

- (instancetype) initWithGpxData:(NSDictionary *)data;

- (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) adjustViewPort:(BOOL)landscape;

- (double) getRoundedDouble:(double)toRound;

@end

