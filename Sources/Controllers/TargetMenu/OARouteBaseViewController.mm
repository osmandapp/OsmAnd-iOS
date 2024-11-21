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
#import "OANativeUtilities.h"
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
    OASGpxFile *_gpxDoc;
    OABaseVectorLinesLayer *_layer;
    OATrackChartPoints *_trackChartPoints;
    double _chartHighlightPos;
    NSArray<CLLocation *> *_xAxisPoints;
}

- (instancetype)initWithGpxDoc:(OASGpxFile *)gpxDoc layer:(OABaseVectorLinesLayer *)layer
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
               analysis:(OASGpxTrackAnalysis *)analysis
               modeCell:(OARouteStatisticsModeCell *)statsModeCell
{
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:_gpxDoc.path]];
    BOOL withoutGaps = YES;
    if ([_gpxDoc isShowCurrentTrack])
    {
        withoutGaps = !gpx.joinSegments
        && (_gpxDoc.tracks.count == 0 || [_gpxDoc.tracks.firstObject isGeneralTrack]);
    }
    else
    {
        withoutGaps = _gpxDoc.tracks.count > 0 && [_gpxDoc.tracks.firstObject isGeneralTrack] && gpx.joinSegments;
    }
    GPXDataSetType secondType = GPXDataSetTypeNone;
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
            secondType = (GPXDataSetType) types.lastObject.integerValue;
        }
    }
    else
    {
        if (statsModeCell)
        {
            [statsModeCell.modeButton setTitle:[OAGPXDataSetType getTitle:types.firstObject.integerValue]
                                      forState:UIControlStateNormal];
        }
    }
    [GpxUIHelper refreshLineChartWithChartView:chart
                                      analysis:analysis
                                     firstType:(GPXDataSetType) types.firstObject.integerValue
                                    secondType:secondType
                                      axisType:GPXDataSetAxisTypeDistance
                               calcWithoutGaps:withoutGaps];
}

- (CLLocation *)getLocationAtPos:(LineChartView *)chart
                             pos:(float)pos
                        analysis:(OASGpxTrackAnalysis *)analysis
                         segment:(OASTrkSegment *)segment
{
    OASGpxDataItem *gpx = [OAGPXDatabase.sharedDb getGPXItem:_gpxDoc.path];
    return [GpxUtils getLocationAtPos:chart
                              gpxFile:_gpxDoc
                              segment:segment
                                  pos:pos
                         joinSegments:gpx.joinSegments];
}

+ (OASTrkSegment *)getTrackSegment:(OASGpxTrackAnalysis *)analysis
                           gpxItem:(OASGpxFile *)gpxItem
{
    if (analysis && gpxItem)
    {
        OASWptPt *locStart = analysis.locationStart;
        OASWptPt *locEnd = analysis.locationEnd;
        for (OASTrack *track in gpxItem.tracks)
        {
            for (OASTrkSegment *segment in track.segments)
            {
                NSArray<OASWptPt *> *points = segment.points;
                NSInteger size = points.count;
                OASWptPt *firstPoint = points.firstObject;
                OASWptPt *lastPoint = points.lastObject;
                if (size > 0
                    && firstPoint.lat == locStart.lat && firstPoint.lon == locStart.lon
                    && lastPoint.lat == locEnd.lat && lastPoint.lon == locEnd.lon)
                    return segment;
            }
        }
    }
    return nil;
}

+ (OASGpxTrackAnalysis *)getAnalysisFor:(OASTrkSegment *)segment
{
    OASGpxTrackAnalysis *analysis = [[OASGpxTrackAnalysis alloc] init];
    auto splitSegments = [ArraySplitSegmentConverter toKotlinArrayFrom:@[[[OASSplitSegment alloc] initWithSegment:segment]]];
    [analysis prepareInformationFileTimeStamp:0 pointsAnalyser:nil splitSegments:splitSegments];
    return analysis;
}

- (void)refreshChart:(LineChartView *)chart
       fitTrackOnMap:(BOOL)fitTrackOnMap
            forceFit:(BOOL)forceFit
    recalculateXAxis:(BOOL)recalculateXAxis
            analysis:(OASGpxTrackAnalysis *)analysis
             segment:(OASTrkSegment *)segment
{
    if (!_gpxDoc)
        return;
    
    NSArray<ChartHighlight *> *highlights = chart.highlighted;
    CLLocation *location;
    
    OATrackChartPoints *trackChartPoints = _trackChartPoints;
    if (!trackChartPoints)
    {
        trackChartPoints = [[OATrackChartPoints alloc] init];
        OASInt *segmentColor = segment != nil
            ? [segment getColorDefColor:0]
            : [[OASInt alloc] initWithInt:0];
        [trackChartPoints setSegmentColor:segmentColor.integerValue];
        [trackChartPoints setGpx:_gpxDoc];
        trackChartPoints.start = analysis.locationStart.position;
        trackChartPoints.end = analysis.locationEnd.position;
        _trackChartPoints = trackChartPoints;
    }
    
    double minimumVisibleXValue = chart.lowestVisibleX;
    double maximumVisibleXValue = chart.highestVisibleX;
    
    if (highlights && highlights.count > 0)
    {
        if (minimumVisibleXValue != 0 && maximumVisibleXValue != 0)
        {
            if (highlights[0].x < minimumVisibleXValue)
            {
                float difference = (maximumVisibleXValue - minimumVisibleXValue) * .1;
                _chartHighlightPos = minimumVisibleXValue + difference;
                [chart highlightValueWithX:minimumVisibleXValue + difference
                              dataSetIndex:0
                                 dataIndex:-1];
            }
            else if (highlights[0].x > maximumVisibleXValue)
            {
                float difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1f;
                _chartHighlightPos = maximumVisibleXValue - difference;
                [chart highlightValueWithX:maximumVisibleXValue - difference
                              dataSetIndex:0
                                 dataIndex:-1];
            }
            else
            {
                _chartHighlightPos = highlights[0].x;
            }
        }
        else
        {
            _chartHighlightPos = highlights[0].x;
        }

        location = [self getLocationAtPos:chart
                                      pos:_chartHighlightPos
                                 analysis:analysis
                                  segment:segment];
        if (location)
            [trackChartPoints setHighlightedPoint:location.coordinate];
        [_layer showCurrentHighlitedLocation:trackChartPoints];
    }
    else
    {
        _chartHighlightPos = -1;
    }

    CLLocationCoordinate2D start = [segment isGeneralSegment] ? CLLocationCoordinate2DMake(0, 0) : analysis.locationStart.position;
    CLLocationCoordinate2D end = [segment isGeneralSegment] ? CLLocationCoordinate2DMake(0, 0) : analysis.locationEnd.position;
    if (recalculateXAxis
        || ![OAMapUtils areLatLonEqual:trackChartPoints.start l2:start]
        || ![OAMapUtils areLatLonEqual:trackChartPoints.end l2:end])
    {
        trackChartPoints.start = start;
        trackChartPoints.end = end;

        [trackChartPoints setXAxisPoints:[self getXAxisPoints:chart
                                                     analysis:analysis
                                                      segment:segment]];
        [_layer showCurrentStatisticsLocation:trackChartPoints];
        if (location)
            [[OARootViewController instance].mapPanel refreshMap];
    }

    if (location && fitTrackOnMap)
    {
        [self fitTrackOnMap:chart
                   location:location.coordinate
                   forceFit:forceFit
                   analysis:analysis
                    segment:segment];
    }
}

- (NSArray<CLLocation *> *)getXAxisPoints:(LineChartView *)chart
                                 analysis:(OASGpxTrackAnalysis *)analysis
                                  segment:(OASTrkSegment *)segment
{
    NSArray<NSNumber *> *entries = chart.xAxis.entries;
    LineChartData *lineData = chart.lineData;
    double maxXValue = lineData ? lineData.xMax : -1;
    if (entries.count >= 2 && lineData)
    {
        double interval = [entries[1] doubleValue] - [entries[0] doubleValue];
        if (interval > 0)
        {
            NSMutableArray<CLLocation *> *xAxisPoints = [NSMutableArray array];
            float currentPointEntry = interval;
            while (currentPointEntry < maxXValue)
            {
                CLLocation *location = [self getLocationAtPos:chart
                                                          pos:currentPointEntry
                                                     analysis:analysis
                                                      segment:segment];
                if (location)
                    [xAxisPoints addObject:location];
                currentPointEntry += interval;
            }
            _xAxisPoints = xAxisPoints;
        }
    }
    return _xAxisPoints;
}

- (void)fitTrackOnMap:(LineChartView *)lineChartView
             location:(CLLocationCoordinate2D)location
             forceFit:(BOOL)forceFit
             analysis:(OASGpxTrackAnalysis *)analysis
              segment:(OASTrkSegment *)segment
{
    OASKQuadRect *rect = [self getRect:lineChartView
                              startPos:lineChartView.lowestVisibleX
                                endPos:lineChartView.highestVisibleX
                              analysis:analysis
                               segment:segment];
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

- (OASKQuadRect *)getRect:(LineChartView *)chart
                 startPos:(float)startPos
                   endPos:(float)endPos
                 analysis:(OASGpxTrackAnalysis *)analysis
                  segment:(OASTrkSegment *)segment
{
    double left = 0, right = 0;
    double top = 0, bottom = 0;
    LineChartData *lineData = chart.lineData;
    NSArray<id<ChartDataSetProtocol>> *ds = lineData ? lineData.dataSets : [NSArray array];
    if (ds.count > 0 && _gpxDoc && segment)
    {
        id <ChartDataSetProtocol> dataSet = ds.firstObject;
        GPXDataSetAxisType axisType = [GpxUIHelper getDataSetAxisTypeWithDataSet:dataSet];
        if (axisType == GPXDataSetAxisTypeTime || axisType == GPXDataSetAxisTypeTimeOfDay)
        {
            float startTime = startPos * 1000;
            float endTime = endPos * 1000;
            for (OASWptPt *p in segment.points)
            {
                if (p.time - analysis.startTime >= startTime && p.time - analysis.startTime <= endTime)
                {
                    if (left == 0 && right == 0)
                    {
                        left = [p getLongitude];
                        right = [p getLongitude];
                        top = [p getLatitude];
                        bottom = [p getLatitude];
                    }
                    else
                    {
                        left = min(left, [p getLongitude]);
                        right = max(right, [p getLongitude]);
                        top = max(top, [p getLatitude]);
                        bottom = min(bottom, [p getLatitude]);
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
                OASWptPt *currentPoint = segment.points[i];
                if (i != 0)
                {
                    OASWptPt *previousPoint = segment.points[i - 1];
                    if (currentPoint.distance < previousPoint.distance)
                        previousSplitDistance += previousPoint.distance;
                }
                if (previousSplitDistance + currentPoint.distance >= startDistance
                    && previousSplitDistance + currentPoint.distance <= endDistance)
                {
                    if (left == 0 && right == 0)
                    {
                        left = [currentPoint getLongitude];
                        right = [currentPoint getLongitude];
                        top = [currentPoint getLatitude];
                        bottom = [currentPoint getLatitude];
                    }
                    else
                    {
                        left = min(left, [currentPoint getLongitude]);
                        right = max(right, [currentPoint getLongitude]);
                        top = max(top, [currentPoint getLatitude]);
                        bottom = min(bottom, [currentPoint getLatitude]);
                    }
                }
            }
        }
    }
    return [[OASKQuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
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
            _trackItem = data[@"trackItem"];
            _analysis = data[@"analysis"];
            _segment = data[@"segment"];
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

+ (NSAttributedString *) getFormattedElevationString:(OASGpxTrackAnalysis *)analysis
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

- (void)centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    if ([_routingHelper isRouteCalculated] && !error && ![_routingHelper isPublicTransportMode])
    {
        OASKQuadRect *rect = [OARoutingHelper getRect:[_routingHelper getBBox]];
        if ([_routingHelper isRoutePlanningMode] && rect.left != DBL_MAX)
            [self centerMapOnBBox:rect];
        else
            [self centerMapOnBBox:[_gpx getRect]];
    }
    else if ([_routingHelper isPublicTransportMode])
    {
        OATransportRoutingHelper *transportHelper = [OATransportRoutingHelper sharedInstance];
        if (![transportHelper isRouteBeingCalculated]
            && [transportHelper getRoutes].size() > 0
            && transportHelper.currentRoute != -1)
            [self centerMapOnBBox:[OARoutingHelper getRect:[transportHelper getBBox]]];
    }
    else
    {
        [self centerMapOnBBox:[_gpx getRect]];
    }
}

- (void)centerMapOnBBox:(OASKQuadRect *)routeBBox
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
