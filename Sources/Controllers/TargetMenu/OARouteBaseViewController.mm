//
//  OARouteBaseViewController.m
//  OsmAnd
//
//  Created by Paul on 28.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"
#import "OAGPXDocument.h"
#import "OAGPXUIHelper.h"
#import "OAMapLayers.h"
#import "OARouteStatisticsHelper.h"
#import "OAMapRendererView.h"
#import "OARouteStatisticsModeCell.h"
#import "OATransportRoutingHelper.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDatabase.h"
#import "GeneratedAssetSymbols.h"
#import <DGCharts/DGCharts-Swift.h>
#import "OsmAnd_Maps-Swift.h"

@implementation OARouteLineChartHelper
{
    OAGPXDocument *_gpxDoc;
    OABaseVectorLinesLayer *_layer;
}

- (instancetype)initWithGpxDoc:(OAGPXDocument *)gpxDoc layer:(OABaseVectorLinesLayer *)layer
{
    self = [super init];
    if (self)
    {
        _gpxDoc = gpxDoc;
        _layer = layer;
    }
    return self;
}

- (void)changeChartTypes:(NSArray<NSNumber *> *)types
                  chart:(ElevationChart *)chart
               analysis:(OAGPXTrackAnalysis *)analysis
               modeCell:(OARouteStatisticsModeCell *)statsModeCell
{
//    ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) chart.rightYAxisRenderer;
    
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:_gpxDoc.path]];
    BOOL calcWithoutGaps = !gpx.joinSegments && (_gpxDoc.tracks.count > 0 && _gpxDoc.tracks.firstObject.generalTrack);
    if (types.count == 2)
    {
        if (types.lastObject.integerValue == GPXDataSetTypeSpeed && ![analysis isSpeedSpecified])
        {
            [self changeChartTypes:@[@(GPXDataSetTypeAltitude)]
                             chart:chart
                          analysis:analysis
                          modeCell:statsModeCell];
        }
        else
        {
            if (statsModeCell)
            {
                [statsModeCell.modeButton setTitle:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_slash"),
                                                    [OAGPXDataSetType getTitle:types.firstObject.integerValue],
                                                    [OAGPXDataSetType getTitle:types.lastObject.integerValue]]
                                          forState:UIControlStateNormal];
            }
            [GpxUIHelper refreshLineChartWithChartView:chart
                                              analysis:analysis
                                   useGesturesAndScale:YES
                                             firstType:(GPXDataSetType) types.firstObject.integerValue
                                            secondType:(GPXDataSetType) types.lastObject.integerValue
                                       calcWithoutGaps:calcWithoutGaps];
//            renderer.renderingMode = YAxisCombinedRenderingModeBothValues;
        }
    }
    else
    {
        if (statsModeCell)
        {
            [statsModeCell.modeButton setTitle:[OAGPXDataSetType getTitle:types.firstObject.integerValue]
                                      forState:UIControlStateNormal];
        }
        [GpxUIHelper refreshLineChartWithChartView:chart
                                          analysis:analysis
                               useGesturesAndScale:YES
                                         firstType:(GPXDataSetType) types.firstObject.integerValue
                                      useRightAxis:YES
                                   calcWithoutGaps:calcWithoutGaps];
//        renderer.renderingMode = types.lastObject.integerValue == GPXDataSetTypeAltitude
//            ? YAxisCombinedRenderingModeSecondaryValueOnly
//            : YAxisCombinedRenderingModePrimaryValueOnly;
    }
    [chart notifyDataSetChanged];
}

- (void)refreshHighlightOnMap:(BOOL)forceFit
                    chartView:(ElevationChart *)chartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                     analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment = [self getTrackSegment:chartView analysis:analysis];
    [self refreshHighlightOnMap:forceFit
                      chartView:chartView
               trackChartPoints:trackChartPoints
                        segment:segment];
}

- (void)refreshHighlightOnMap:(BOOL)forceFit
                    chartView:(ElevationChart *)chartView
             trackChartPoints:(OATrackChartPoints *)trackChartPoints
                      segment:(OATrkSegment *)segment
{
    if (!_gpxDoc)
        return;

    NSArray<ChartHighlight *> *highlights = chartView.highlighted;
    CLLocationCoordinate2D location = kCLLocationCoordinate2DInvalid;
    [_layer showCurrentStatisticsLocation:trackChartPoints];

    double minimumVisibleXValue = chartView.lowestVisibleX;
    double maximumVisibleXValue = chartView.highestVisibleX;

    double highlightPosition = -1;

    if (highlights.count > 0)
    {
        ChartHighlight *highlight = highlights.firstObject;
        if (minimumVisibleXValue != 0 && maximumVisibleXValue != 0)
        {
            if (highlight.x < minimumVisibleXValue && highlight.x != chartView.chartXMin)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = minimumVisibleXValue + difference;
                [chartView highlightValueWithX:minimumVisibleXValue + difference dataSetIndex:0 dataIndex:-1];
            }
            else if (highlight.x > maximumVisibleXValue)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = maximumVisibleXValue - difference;
                [chartView highlightValueWithX:maximumVisibleXValue - difference dataSetIndex:0 dataIndex:-1];
            }
            else
            {
                highlightPosition = highlight.x;
            }
        }
        else
        {
            highlightPosition = highlight.x;
        }
        location = [self getLocationAtPos:highlightPosition
                            lineChartView:chartView
                                  segment:segment];
        if (CLLocationCoordinate2DIsValid(location))
            trackChartPoints.highlightedPoint = location;
    }

    trackChartPoints.axisPointsInvalidated = forceFit;
    trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints lineChartView:chartView segment:segment];

    [_layer showCurrentStatisticsLocation:trackChartPoints];
    [self fitTrackOnMap:location
               forceFit:forceFit
          lineChartView:chartView
                segment:segment];
}

- (OATrackChartPoints *)generateTrackChartPoints:(ElevationChart *)chartView
                                        analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment = [self getTrackSegment:chartView analysis:analysis];
    return [self generateTrackChartPoints:chartView startPoint:kCLLocationCoordinate2DInvalid segment:segment];
}

- (OATrackChartPoints *)generateTrackChartPoints:(ElevationChart *)chartView
                                      startPoint:(CLLocationCoordinate2D)startPoint
                                        segment:(OATrkSegment *)segment
{
    OATrackChartPoints *trackChartPoints = [[OATrackChartPoints alloc] init];
    trackChartPoints.segmentColor = -1;
    trackChartPoints.gpx = _gpxDoc;
    trackChartPoints.axisPointsInvalidated = YES;
    trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints lineChartView:chartView segment:segment];
    if (CLLocationCoordinate2DIsValid(startPoint))
        trackChartPoints.highlightedPoint = startPoint;

    return trackChartPoints;
}

- (NSArray<CLLocation *> *)getXAxisPoints:(OATrackChartPoints *)points
                            lineChartView:(ElevationChart *)chartView
                                  segment:(OATrkSegment *)segment
{
    if (!points.axisPointsInvalidated)
        return points.xAxisPoints;

    NSMutableArray<CLLocation *> *result = [NSMutableArray new];
    NSArray<NSNumber *> *entries = chartView.xAxis.entries;
    LineChartData *lineData = chartView.lineData;
    double maxXValue = lineData ? lineData.xMax : -1;
    if (entries.count >= 2 && lineData)
    {
        double interval = entries[1].doubleValue - entries[0].doubleValue;
        if (interval > 0)
        {
            double currentPointEntry = interval;
            while (currentPointEntry < maxXValue)
            {
                CLLocationCoordinate2D location = [self getLocationAtPos:currentPointEntry
                                                           lineChartView:chartView
                                                                 segment:segment];
                if (CLLocationCoordinate2DIsValid(location))
                    [result addObject:[[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude]];

                currentPointEntry += interval;
            }
        }
    }
    return result;
}

+ (OATrkSegment *)getSegmentForAnalysis:(OAGPXDocument *)gpxDoc analysis:(OAGPXTrackAnalysis *)analysis
{
    for (OATrack *track in gpxDoc.tracks)
    {
        for (OATrkSegment *segment in track.segments)
        {
            NSInteger size = segment.points.count;
            if (size > 0 && [segment.points.firstObject isEqual:analysis.locationStart]
                    && [segment.points[size - 1] isEqual:analysis.locationEnd])
                return segment;
        }
    }
    return nil;
}

- (OATrkSegment *)getTrackSegment:(LineChartView *)chart analysis:(OAGPXTrackAnalysis *)analysis
{
    OATrkSegment *segment;
    LineChartData *lineData = chart.lineData;
    NSArray<id <ChartDataSetProtocol>> *ds = lineData ? lineData.dataSets : [NSArray array];

    if (ds && ds.count > 0)
        segment = [self.class getSegmentForAnalysis:_gpxDoc analysis:analysis];

    return segment;
}

- (CLLocationCoordinate2D)getLocationAtPos:(double)position
                             lineChartView:(LineChartView *)lineChartView
                                   segment:(OATrkSegment *)segment
{
    LineChartData *data = lineChartView.lineData;
    NSArray<id<ChartDataSetProtocol>> *dataSets = data ? data.dataSets : nil;

    if (dataSets && dataSets.count > 0 && segment && _gpxDoc)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:_gpxDoc.path]];
        BOOL joinSegments = gpx.joinSegments;
        id<ChartDataSetProtocol> dataSet = dataSets.firstObject;
        if ([GpxUIHelper getDataSetAxisTypeWithDataSet:dataSet] == GPXDataSetAxisTypeTime)
        {
            double time = position * 1000;
            return [OAGPXUIHelper getSegmentPointByTime:segment
                                                gpxFile:_gpxDoc
                                                   time:time
                                        preciseLocation:NO
                                           joinSegments:joinSegments];
        }
        else
        {
            double distance = [dataSet getDivX] * position;
            return [OAGPXUIHelper getSegmentPointByDistance:segment
                                                    gpxFile:_gpxDoc
                                            distanceToPoint:distance
                                            preciseLocation:NO
                                               joinSegments:joinSegments];
        }
    }
    return kCLLocationCoordinate2DInvalid;
}

- (void)fitTrackOnMap:(CLLocationCoordinate2D)location
             forceFit:(BOOL)forceFit
        lineChartView:(LineChartView *)lineChartView
              segment:(OATrkSegment *)segment
{
    OABBox rect = [self getRect:lineChartView segment:segment];
    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    if (rect.left != 0 && rect.right != 0)
    {
        auto point = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.latitude, location.longitude));
        CGPoint mapPoint;
        [mapViewController.mapView convert:&point toScreen:&mapPoint checkOffScreen:YES];

        if (forceFit && self.delegate)
        {
            [self.delegate centerMapOnBBox:rect];
        }
        else if (CLLocationCoordinate2DIsValid(location) && !CGRectContainsPoint(_screenBBox, mapPoint))
        {
            if (!_isLandscape && self.delegate)
                [self.delegate adjustViewPort:self.isLandscape];

            Point31 pos = [OANativeUtilities convertFromPointI:point];
            [mapViewController goToPosition:pos animated:YES];
        }
    }
}

- (OABBox)getRect:(LineChartView *)lineChartView
          segment:(OATrkSegment *)segment
{
    OABBox bbox;

    double startPos = lineChartView.lowestVisibleX;
    double endPos = lineChartView.highestVisibleX;
    double left = 0, right = 0;
    double top = 0, bottom = 0;
    LineChartData *data = lineChartView.lineData;
    NSArray<id<ChartDataSetProtocol>> *dataSets = data ? data.dataSets : [NSArray new];
    if (dataSets.count > 0 && segment && _gpxDoc)
    {
        id <ChartDataSetProtocol> dataSet = dataSets.firstObject;

        GPXDataSetAxisType axisType = [GpxUIHelper getDataSetAxisTypeWithDataSet:dataSet];
        if (axisType == GPXDataSetAxisTypeTime || axisType == GPXDataSetAxisTypeTimeOfDay)
        {
            float startTime = startPos * 1000;
            float endTime = endPos * 1000;
            OAGPXTrackAnalysis *analysis = [OAGPXTrackAnalysis segment:0 seg:segment];
            for (OAWptPt *p in segment.points)
            {
                if (p.time - analysis.startTime >= startTime && p.time - analysis.startTime <= endTime)
                {
                    if (left == 0 && right == 0)
                    {
                        left = p.position.longitude;
                        right = p.position.longitude;
                        top = p.position.latitude;
                        bottom = p.position.latitude;
                    }
                    else
                    {
                        left = MIN(left, p.position.longitude);
                        right = MAX(right, p.position.longitude);
                        top = MAX(top, p.position.latitude);
                        bottom = MIN(bottom, p.position.latitude);
                    }
                }
            }
        }
        else
        {
            double startDistance = startPos * [dataSet getDivX];
            double endDistance = endPos * [dataSet getDivX];

            double previousSplitDistance = 0;
            for (NSInteger i = 0; i < segment.points.count; i++)
            {
                OAWptPt *currentPoint = segment.points[i];
                if (i != 0)
                {
                    OAWptPt *previousPoint = segment.points[i - 1];
                    if (currentPoint.distance < previousPoint.distance)
                        previousSplitDistance += previousPoint.distance;
                }
                if (previousSplitDistance + currentPoint.distance >= startDistance
                        && previousSplitDistance + currentPoint.distance <= endDistance)
                {
                    if (left == 0 && right == 0)
                    {
                        left = currentPoint.getLongitude;
                        right = currentPoint.getLongitude;
                        top = currentPoint.getLatitude;
                        bottom = currentPoint.getLatitude;
                    }
                    else
                    {
                        left = min(left, currentPoint.getLongitude);
                        right = max(right, currentPoint.getLongitude);
                        top = max(top, currentPoint.getLatitude);
                        bottom = min(bottom, currentPoint.getLatitude);
                    }
                }
            }
        }
    }

    bbox.top = top;
    bbox.bottom = bottom;
    bbox.left = left;
    bbox.right = right;

    return bbox;
}

@end

@interface OARouteBaseViewController () <OARouteInformationListener, OARouteLineChartHelperDelegate>

@end

@implementation OARouteBaseViewController
{
    OABaseVectorLinesLayer *_layer;
}

- (instancetype) initWithGpxData:(NSDictionary *)data
{
    self = [super init];
    
    if (self) {
        if (data)
        {
            _gpx = data[@"gpx"];
            _analysis = data[@"analysis"];
            OAMapLayers *layers = [OARootViewController instance].mapPanel.mapViewController.mapLayers;
            _layer = [data[@"route"] boolValue] ? layers.routeMapLayer : layers.gpxMapLayer;
            
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
    _routeLineChartHelper = [[OARouteLineChartHelper alloc] initWithGpxDoc:_gpx layer:_layer];
    _routeLineChartHelper.delegate = self;
    _routeLineChartHelper.isLandscape = [self isLandscapeIPadAware];
    _routeLineChartHelper.screenBBox = [self getScreenBBox];
}

- (void)onMenuDismissed
{
    [_routingHelper removeListener:self];
    [_layer hideCurrentStatisticsLocation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _routeLineChartHelper.isLandscape = [self isLandscapeIPadAware];
        _routeLineChartHelper.screenBBox = [self getScreenBBox];
    }];
}

- (CGRect)getScreenBBox
{
    BOOL landscape = [self isLandscapeIPadAware];
    CGFloat bottomInset = !landscape && self.delegate ? self.delegate.getVisibleHeight : 0;
    CGFloat topInset = !landscape && !self.navBar.isHidden ? self.navBar.frame.size.height : 0;
    CGFloat leftInset = landscape ? self.contentView.frame.size.width + kMapMargin : 0;
    return CGRectMake(leftInset + kMapMargin, topInset, DeviceScreenWidth - leftInset - kMapMargin * 2, DeviceScreenHeight - topInset - bottomInset);
}

- (void)onMenuShown
{
    [self centerMapOnRoute];
}

- (BOOL) needsAdditionalBottomMargin
{
    return NO;
}

- (BOOL)showTopControls
{
    return YES;
}

+ (NSAttributedString *) getFormattedElevationString:(OAGPXTrackAnalysis *)analysis
{
    UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    NSDictionary *textAttrs = @{ NSFontAttributeName: textFont, NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorSecondary] };
    if (analysis)
    {
        NSMutableAttributedString *res = [NSMutableAttributedString new];

        NSTextAttachment *arrowUpAttachment = [[NSTextAttachment alloc] init];
        arrowUpAttachment.image = [UIImage templateImageNamed:@"ic_small_uphill"];
        arrowUpAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 18.)/2.f, 18., 18.);
        NSMutableAttributedString *uphillIcon = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                 [NSAttributedString attributedStringWithAttachment:arrowUpAttachment]];
        [uphillIcon setColor:[UIColor colorNamed:ACColorNameIconColorDefault] forString:uphillIcon.string];

        NSTextAttachment *arrowDownAttachment = [[NSTextAttachment alloc] init];
        arrowDownAttachment.image = [UIImage templateImageNamed:@"ic_small_downhill"];
        arrowDownAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 18.)/2.f, 18., 18.);
        NSMutableAttributedString *downhilIcon = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                  [NSAttributedString attributedStringWithAttachment:arrowDownAttachment]];
        [downhilIcon setColor:[UIColor colorNamed:ACColorNameIconColorDefault] forString:downhilIcon.string];

        NSTextAttachment *rangeAttachment = [[NSTextAttachment alloc] init];
        rangeAttachment.image = [UIImage templateImageNamed:@"ic_small_altitude_range"];
        rangeAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 18.)/2.f, 18., 18.);
        NSMutableAttributedString *elevationIcon = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                  [NSAttributedString attributedStringWithAttachment:rangeAttachment]];
        [elevationIcon setColor:[UIColor colorNamed:ACColorNameIconColorDefault] forString:elevationIcon.string];

        [res appendAttributedString:uphillIcon];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:
                                     [NSString stringWithFormat:@"  %@", [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationUp]]
                                                                    attributes:textAttrs]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:@"    "]];

        [res appendAttributedString:downhilIcon];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:
                                     [NSString stringWithFormat:@"  %@", [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationDown]]
                                                                    attributes:textAttrs]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:@"    "]];

        [res appendAttributedString:elevationIcon];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:
        [NSString stringWithFormat:@"  %@", [NSString stringWithFormat:@"%@ - %@",
                                            [OAOsmAndFormatter getFormattedAlt:analysis.minElevation],
                                            [OAOsmAndFormatter getFormattedAlt:analysis.maxElevation]]]
                                                                    attributes:textAttrs]];
        return res;
    }
    return nil;
}

+ (NSAttributedString *) getFormattedDistTimeString
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];

    NSDictionary *numericAttributes = @{NSFontAttributeName: [UIFont scaledSystemFontOfSize:20 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]};
    NSDictionary *alphabeticAttributes = @{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3], NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary] };
    NSString *dist = [OAOsmAndFormatter getFormattedDistance:[routingHelper getLeftDistance]];
    NSAttributedString *distance = [self formatDistance:dist numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];
    NSAttributedString *time = [self getFormattedTimeInterval:[routingHelper getLeftTime] numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    NSAttributedString *bullet = [[NSAttributedString alloc] initWithString:@"•" attributes:alphabeticAttributes];
    [str appendAttributedString:distance];
    [str appendAttributedString:space];
    [str appendAttributedString:bullet];
    [str appendAttributedString:space];
    [str appendAttributedString:time];

    return str;
}

+ (NSAttributedString *) formatDistance:(NSString *)dist numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] init];
    if (dist.length > 0)
    {
        NSArray<NSString *> *components = [[dist trim] componentsSeparatedByString:@" "];
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
        for (NSInteger i = 0; i < components.count; i++)
        {
            NSAttributedString *str = [[NSAttributedString alloc] initWithString:components[i] attributes:i % 2 == 0 ? numericAttributes : alphabeticAttributes];
            [res appendAttributedString:str];
            if (i != components.count - 1)
                [res appendAttributedString:space];
        }
    }
    return res;
}

+ (NSAttributedString *) getFormattedTimeInterval:(NSTimeInterval)timeInterval numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableAttributedString *time = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    
    if (hours > 0)
    {
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", hours] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"int_hour") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes > 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", minutes] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"m") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes == 0 && hours == 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", seconds] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_sec_short") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    
    NSString *eta = [NSString stringWithFormat:@" (%@)", [self getTimeAfter:timeInterval]];
    [time appendAttributedString:[[NSAttributedString alloc] initWithString:eta attributes:alphabeticAttributes]];
    
    return [[NSAttributedString alloc] initWithAttributedString:time];
}

+ (NSString *)getTimeAfter:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger nowHours = [components hour];
    NSInteger nowMinutes = [components minute];
    nowHours = nowMinutes + minutes >= 60 ? nowHours + 1 : nowHours;
    return [NSString stringWithFormat:@"%02ld:%02ld", (nowHours + hours) % 24, (nowMinutes + minutes) % 60];
}

- (double) getRoundedDouble:(double)toRound
{
    return floorf(toRound * 100 + 0.5) / 100;
}

- (void)setupRouteInfo
{
    // override
}

- (void) adjustViewPort:(BOOL)landscape
{
    // override
}

- (void) centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    OABBox routeBBox;
    routeBBox.top = DBL_MAX;
    routeBBox.bottom = DBL_MAX;
    routeBBox.left = DBL_MAX;
    routeBBox.right = DBL_MAX;
    if ([_routingHelper isRouteCalculated] && !error && !_routingHelper.isPublicTransportMode)
    {
        routeBBox = [_routingHelper getBBox];
        if ([_routingHelper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
            [self centerMapOnBBox:routeBBox];
        else
            [self centerMapOnGpx:_gpx];
    }
    else if (_routingHelper.isPublicTransportMode)
    {
        OATransportRoutingHelper *transportHelper = OATransportRoutingHelper.sharedInstance;
        if (!transportHelper.isRouteBeingCalculated && transportHelper.getRoutes.size() > 0 && transportHelper.currentRoute != -1)
            [self centerMapOnBBox:transportHelper.getBBox];
    }
    else
    {
        [self centerMapOnGpx:_gpx];
    }
}

- (void)centerMapOnGpx:(OAGPXDocument *)gpx
{
    if (gpx)
    {
        OABBox routeBBox;
        OAGpxBounds gpxBounds = gpx.bounds;
        routeBBox.top = gpxBounds.topLeft.latitude;
        routeBBox.bottom = gpxBounds.bottomRight.latitude;
        routeBBox.left = gpxBounds.topLeft.longitude;
        routeBBox.right = gpxBounds.bottomRight.longitude;
        [self centerMapOnBBox:routeBBox];
    }
}

- (void)centerMapOnBBox:(const OABBox)routeBBox
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL landscape = [self isLandscapeIPadAware];
    [mapPanel displayAreaOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left)
                   bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)
                          zoom:0
                   bottomInset:!landscape && self.delegate ? self.delegate.getVisibleHeight + kMapMargin : 0
                     leftInset:landscape ? self.contentView.frame.size.width + kMapMargin : 0
                      animated:YES];
}

- (BOOL) isLandscapeIPadAware
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    [self setupRouteInfo];
}

- (void) routeWasUpdated
{
    [self setupRouteInfo];
}

- (void) routeWasCancelled
{
    [self setupRouteInfo];
}

- (void) routeWasFinished
{
    [self setupRouteInfo];
}

@end
