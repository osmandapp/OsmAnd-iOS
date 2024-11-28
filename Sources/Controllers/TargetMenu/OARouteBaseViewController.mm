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

@interface OARouteBaseViewController () <OARouteInformationListener, ChartHelperDelegate>

@end

@implementation OARouteBaseViewController
{
    OABaseVectorLinesLayer *_layer;
}

- (instancetype) initWithGpxData:(NSDictionary *)data
{
    self = [super init];
    if (self && data)
    {
        _gpx = data[@"gpx"];
        _trackItem = data[@"trackItem"];
        _analysis = data[@"analysis"];
        _segment = data[@"segment"];
        OAMapLayers *layers = [OARootViewController instance].mapPanel.mapViewController.mapLayers;
        _layer = [data[@"route"] boolValue] ? layers.routeMapLayer : layers.gpxMapLayer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
    _trackChartHelper = [[TrackChartHelper alloc] initWithGpxDoc:_gpx];
    _trackChartHelper.delegate = self;
    _trackChartHelper.isLandscape = [self isLandscapeIPadAware];
    _trackChartHelper.screenBBox = [self getScreenBBox];
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
        _trackChartHelper.isLandscape = [self isLandscapeIPadAware];
        _trackChartHelper.screenBBox = [self getScreenBBox];
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

- (BOOL) isLandscapeIPadAware
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (void)centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    if ([_routingHelper isRouteCalculated] && !error && ![_routingHelper isPublicTransportMode])
    {
        OASKQuadRect *rect = [GpxUtils getRectFrom:[_routingHelper getBBox]];
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
            [self centerMapOnBBox:[GpxUtils getRectFrom:[transportHelper getBBox]]];
    }
    else
    {
        [self centerMapOnBBox:[_gpx getRect]];
    }
}

#pragma mark - ChartHelperDelegate

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

- (void) adjustViewPort:(BOOL)landscape
{
    // override
}

- (void)showCurrentHighlitedLocation:(TrackChartPoints *)trackChartPoints
{
    [_layer showCurrentHighlitedLocation:trackChartPoints];
}

- (void)showCurrentStatisticsLocation:(TrackChartPoints *)trackChartPoints
{
    [_layer showCurrentStatisticsLocation:trackChartPoints];
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
