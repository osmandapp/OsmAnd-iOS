//
//  OARouteBaseViewController.h
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OACommonTypes.h"

@class OARoutingHelper;
@class LineChartView;
@class OAGPXDocument;
@class OATrackChartPoints;
@class OAGPXTrackAnalysis;

@interface OARouteBaseViewController : OATargetMenuViewController

@property (nonatomic, readonly) OARoutingHelper *routingHelper;

@property (nonatomic) OAGPXDocument *gpx;
@property (nonatomic) LineChartView *statisticsChart;
@property (nonatomic) OATrackChartPoints *trackChartPoints;
@property (nonatomic) OAGPXTrackAnalysis *analysis;

- (NSAttributedString *) getFormattedDistTimeString;

- (void) setupRouteInfo;

- (BOOL) isLandscapeIPadAware;

- (void) refreshHighlightOnMap:(BOOL)forceFit;
- (void) adjustViewPort:(BOOL)landscape;

@end

