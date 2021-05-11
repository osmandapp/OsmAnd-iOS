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
#import "OASizes.h"
#import "OAColors.h"
#import "OAStateChangedListener.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"
#import "OARouteInfoCell.h"
#import "OsmAndApp.h"
#import "OAGPXDocument.h"
#import "OAGPXUIHelper.h"
#import "OAMapLayers.h"
#import "OARouteLayer.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OARouteStatistics.h"
#import "OARouteInfoAltitudeCell.h"
#import "OATargetPointsHelper.h"
#import "OAMapRendererView.h"
#import "OARouteInfoLegendItemView.h"
#import "OARouteInfoLegendCell.h"
#import "OARouteStatisticsModeCell.h"
#import "OAFilledButtonCell.h"
#import "OATransportRoutingHelper.h"

#import <Charts/Charts-Swift.h>

@interface OARouteBaseViewController () <OARouteInformationListener>

@end

@implementation OARouteBaseViewController

- (instancetype) initWithGpxData:(NSDictionary *)data
{
    self = [super init];
    
    if (self) {
        if (data)
        {
            _gpx = data[@"gpx"];
            _analysis = data[@"analysis"];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
}

- (void)onMenuShown
{
    [self centerMapOnRoute];
}

- (BOOL) needsAdditionalBottomMargin
{
    return NO;
}

- (NSAttributedString *) getFormattedDistTimeString
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    NSDictionary *numericAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    NSDictionary *alphabeticAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSString *dist = [app getFormattedDistance:[_routingHelper getLeftDistance]];
    NSAttributedString *distance = [self formatDistance:dist numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];
    NSAttributedString *time = [self getFormattedTimeInterval:[_routingHelper getLeftTime] numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];

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

- (NSAttributedString *) formatDistance:(NSString *)dist numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
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

- (NSAttributedString *) getFormattedTimeInterval:(NSTimeInterval)timeInterval numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableAttributedString *time = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    
    if (hours > 0)
    {
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", hours] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_hour") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes > 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", minutes] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_min_short") attributes:alphabeticAttributes];
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

- (NSString *)getTimeAfter:(NSTimeInterval)timeInterval
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
        {
            [self centerMapOnBBox:routeBBox];
        }
    }
    else if (_routingHelper.isPublicTransportMode)
    {
        OATransportRoutingHelper *transportHelper = OATransportRoutingHelper.sharedInstance;
        if (!transportHelper.isRouteBeingCalculated && transportHelper.getRoutes.size() > 0 && transportHelper.currentRoute != -1)
        {
            [self centerMapOnBBox:transportHelper.getBBox];
        }
    }
}

- (void)centerMapOnBBox:(const OABBox)routeBBox
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL landscape = [self isLandscapeIPadAware];
    [mapPanel displayAreaOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right) zoom:0 bottomInset:!landscape && self.delegate ? self.delegate.getVisibleHeight + kMapMargin : 0 leftInset:landscape ? self.contentView.frame.size.width + kMapMargin : 0];
}

- (BOOL) isLandscapeIPadAware
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (void) refreshHighlightOnMap:(BOOL)forceFit
{
    if (!self.gpx)
        return;
    
    NSArray<ChartHighlight *> *highlights = _statisticsChart.highlighted;
    OsmAnd::LatLon location;
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    
    OATrackChartPoints *trackChartPoints = self.trackChartPoints;
    if (!trackChartPoints)
    {
        trackChartPoints = [[OATrackChartPoints alloc] init];
        trackChartPoints.segmentColor = -1;
        trackChartPoints.gpx = self.gpx;
        trackChartPoints.axisPointsInvalidated = YES;
        trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints];
        [mapVC.mapLayers.routeMapLayer showCurrentStatisticsLocation:trackChartPoints];
        self.trackChartPoints = trackChartPoints;
    }
    
    double minimumVisibleXValue = _statisticsChart.lowestVisibleX;
    double maximumVisibleXValue = _statisticsChart.highestVisibleX;
    
    double highlightPosition = -1;
    
    if (highlights.count > 0)
    {
        ChartHighlight *highlight = highlights.firstObject;
        if (minimumVisibleXValue != 0 && maximumVisibleXValue != 0)
        {
            if (highlight.x < minimumVisibleXValue && highlight.x != _statisticsChart.chartXMin)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = minimumVisibleXValue + difference;
            }
            else if (highlight.x > maximumVisibleXValue)
            {
                double difference = (maximumVisibleXValue - minimumVisibleXValue) * 0.1;
                highlightPosition = maximumVisibleXValue - difference;
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
        location = [self getLocationAtPos:highlightPosition];
        if (location.latitude != 0 && location.longitude != 0)
        {
            trackChartPoints.highlightedPoint = location;
        }
    }
    
    trackChartPoints.axisPointsInvalidated = forceFit;
    trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints];
    
    [mapVC.mapLayers.routeMapLayer showCurrentStatisticsLocation:trackChartPoints];
    [self fitTrackOnMap:location forceFit:forceFit];
}

- (NSArray<CLLocation *> *) getXAxisPoints:(OATrackChartPoints *)points
{
    if (!points.axisPointsInvalidated)
        return points.xAxisPoints;
    
    NSMutableArray<CLLocation *> *result = [NSMutableArray new];
    NSArray<NSNumber *> *entries = _statisticsChart.xAxis.entries;
    LineChartData *lineData = _statisticsChart.lineData;
    double maxXValue = lineData ? lineData.xMax : -1;
    if (entries.count >= 2 && lineData)
    {
        double interval = entries[1].doubleValue - entries[0].doubleValue;
        if (interval > 0)
        {
            double currentPointEntry = interval;
            while (currentPointEntry < maxXValue)
            {
                OsmAnd::LatLon location = [self getLocationAtPos:currentPointEntry];
                [result addObject:[[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude]];
                currentPointEntry += interval;
            }
        }
    }
    return result;
}

- (void) changeChartMode:(EOARouteStatisticsMode)mode chart:(LineChartView *)chart modeCell:(OARouteStatisticsModeCell *)statsModeCell
{
    switch (mode) {
        case EOARouteStatisticsModeBoth:
        {
            [statsModeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"map_widget_altitude"), OALocalizedString(@"gpx_slope")] forState:UIControlStateNormal];
            for (id<IChartDataSet> data in chart.lineData.dataSets)
            {
                data.visible = YES;
            }
            chart.leftAxis.enabled = YES;
            chart.leftAxis.drawLabelsEnabled = NO;
            chart.leftAxis.drawGridLinesEnabled = NO;
            chart.rightAxis.enabled = YES;
            ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) chart.rightYAxisRenderer;
            renderer.renderingMode = YAxisCombinedRenderingModeBothValues;
            break;
        }
        case EOARouteStatisticsModeAltitude:
        {
            [statsModeCell.modeButton setTitle:OALocalizedString(@"map_widget_altitude") forState:UIControlStateNormal];
            chart.lineData.dataSets[0].visible = YES;
            chart.lineData.dataSets[1].visible = NO;
            chart.leftAxis.enabled = YES;
            chart.leftAxis.drawLabelsEnabled = YES;
            chart.leftAxis.drawGridLinesEnabled = YES;
            chart.rightAxis.enabled = NO;
            break;
        }
        case EOARouteStatisticsModeSlope:
        {
            [statsModeCell.modeButton setTitle:OALocalizedString(@"gpx_slope") forState:UIControlStateNormal];
            chart.lineData.dataSets[0].visible = NO;
            chart.lineData.dataSets[1].visible = YES;
            chart.leftAxis.enabled = NO;
            chart.leftAxis.drawLabelsEnabled = NO;
            chart.leftAxis.drawGridLinesEnabled = NO;
            chart.rightAxis.enabled = YES;
            ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) chart.rightYAxisRenderer;
            renderer.renderingMode = YAxisCombinedRenderingModePrimaryValueOnly;
            break;
        }
        default:
            break;
    }
    [chart notifyDataSetChanged];
}

- (OsmAnd::LatLon) getLocationAtPos:(double) position
{
    OsmAnd::LatLon latLon;
    LineChartData *data = _statisticsChart.lineData;
    NSArray<id<IChartDataSet>> *dataSets = data ? data.dataSets : [NSArray new];
    if (dataSets.count > 0 && self.gpx)
    {
        OAGpxTrk *track = self.gpx.tracks.firstObject;
        if (!track)
            return latLon;
        
        OAGpxTrkSeg *segment = track.segments.firstObject;
        if (!segment)
            return latLon;
        id<IChartDataSet> dataSet = dataSets.firstObject;
//        OrderedLineDataSet dataSet = (OrderedLineDataSet) ds.get(0);
//        if (gpxItem.chartAxisType == GPXDataSetAxisType.TIME ||
//                gpxItem.chartAxisType == GPXDataSetAxisType.TIMEOFDAY) {
//            float time = pos * 1000;
//            WptPt previousPoint = null;
//            for (WptPt currentPoint : segment.points) {
//                long totalTime = currentPoint.time - gpxItem.analysis.startTime;
//                if (totalTime >= time) {
//                    if (previousPoint != null) {
//                        double percent = 1 - (totalTime - time) / (currentPoint.time - previousPoint.time);
//                        double dLat = (currentPoint.lat - previousPoint.lat) * percent;
//                        double dLon = (currentPoint.lon - previousPoint.lon) * percent;
//                        latLon = new LatLon(previousPoint.lat + dLat, previousPoint.lon + dLon);
//                    } else {
//                        latLon = new LatLon(currentPoint.lat, currentPoint.lon);
//                    }
//                    break;
//                }
//                previousPoint = currentPoint;
//            }
//        } else {
        double distance = position * [dataSet getDivX];
        double previousSplitDistance = 0;
        OAGpxTrkPt *previousPoint = nil;
        for (int i = 0; i < segment.points.count; i++)
        {
            OAGpxTrkPt *currentPoint = segment.points[i];
            if (previousPoint != nil)
            {
                if (currentPoint.distance < previousPoint.distance)
                {
                    previousSplitDistance += previousPoint.distance;
                }
            }
            double totalDistance = previousSplitDistance + currentPoint.distance;
            if (totalDistance >= distance)
            {
                if (previousPoint != nil)
                {
                    double percent = 1 - (totalDistance - distance) / (currentPoint.distance - previousPoint.distance);
                    double dLat = (currentPoint.getLatitude - previousPoint.getLatitude) * percent;
                    double dLon = (currentPoint.getLongitude - previousPoint.getLongitude) * percent;
                    latLon = OsmAnd::LatLon(previousPoint.getLatitude + dLat, previousPoint.getLongitude + dLon);
                }
                else
                {
                    latLon = OsmAnd::LatLon(currentPoint.getLongitude, currentPoint.getLongitude);
                }
                break;
            }
            previousPoint = currentPoint;
        }
    }
    return latLon;
}

- (OABBox) getRect
{
    OABBox bbox;
    
    double startPos = _statisticsChart.lowestVisibleX;
    double endPos = _statisticsChart.highestVisibleX;
    double left = 0, right = 0;
    double top = 0, bottom = 0;
    LineChartData *data = _statisticsChart.lineData;
    NSArray<id<IChartDataSet>> *dataSets = data ? data.dataSets : [NSArray new];
    if (dataSets.count > 0 && self.gpx)
    {
        OAGpxTrk *track = self.gpx.tracks.firstObject;
        if (!track)
            return bbox;
        
        OAGpxTrkSeg *segment = track.segments.firstObject;
        if (!segment)
            return bbox;
        id<IChartDataSet> dataSet = dataSets.firstObject;
        
//        if (gpxItem.chartAxisType == GPXDataSetAxisType.TIME || gpxItem.chartAxisType == GPXDataSetAxisType.TIMEOFDAY) {
//            float startTime = startPos * 1000;
//            float endTime = endPos * 1000;
//            for (WptPt p : segment.points) {
//                if (p.time - gpxItem.analysis.startTime >= startTime && p.time - gpxItem.analysis.startTime <= endTime) {
//                    if (left == 0 && right == 0) {
//                        left = p.getLongitude();
//                        right = p.getLongitude();
//                        top = p.getLatitude();
//                        bottom = p.getLatitude();
//                    } else {
//                        left = Math.min(left, p.getLongitude());
//                        right = Math.max(right, p.getLongitude());
//                        top = Math.max(top, p.getLatitude());
//                        bottom = Math.min(bottom, p.getLatitude());
//                    }
//                }
//            }
//        } else {
        double startDistance = startPos * [dataSet getDivX];
        double endDistance = endPos * [dataSet getDivX];
        double previousSplitDistance = 0;
        for (NSInteger i = 0; i < segment.points.count; i++)
        {
            OAGpxTrkPt *currentPoint = segment.points[i];
            if (i != 0)
            {
                OAGpxTrkPt *previousPoint = segment.points[i - 1];
                if (currentPoint.distance < previousPoint.distance)
                {
                    previousSplitDistance += previousPoint.distance;
                }
            }
            if (previousSplitDistance + currentPoint.distance >= startDistance && previousSplitDistance + currentPoint.distance <= endDistance)
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
    
    bbox.top = top;
    bbox.bottom = bottom;
    bbox.left = left;
    bbox.right = right;
    
    return bbox;
}

- (void) fitTrackOnMap:(OsmAnd::LatLon) location forceFit:(BOOL) forceFit
{
    OABBox rect = [self getRect];
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if (rect.left != 0 && rect.right != 0)
    {
        BOOL landscape = [self isLandscapeIPadAware];
        CGFloat bottomInset = !landscape && self.delegate ? self.delegate.getVisibleHeight : 0;
        CGFloat topInset = !landscape && !self.navBar.isHidden ? self.navBar.frame.size.height : 0;
        CGFloat leftInset = landscape ? self.contentView.frame.size.width + kMapMargin : 0;
        CGRect screenBBox = CGRectMake(leftInset + kMapMargin, topInset, DeviceScreenWidth - leftInset - kMapMargin * 2, DeviceScreenHeight - topInset - bottomInset);
        auto point = OsmAnd::Utilities::convertLatLonTo31(location);
        CGPoint mapPoint;
        [mapVC.mapView convert:&point toScreen:&mapPoint checkOffScreen:YES];
        
        if (forceFit)
        {
            [self centerMapOnBBox:rect];
        }
        else if (location.latitude != 0 && location.longitude != 0 &&
                   !CGRectContainsPoint(screenBBox, mapPoint))
        {
            if (!landscape)
                [self adjustViewPort:landscape];
            
            Point31 pos = [OANativeUtilities convertFromPointI:point];
            [mapVC goToPosition:pos animated:YES];
        }
    }
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
