//
//  OARouteDetailsViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteDetailsViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAStateChangedListener.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"
#import "OALineChartCell.h"
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
#import "OAStatisticsSelectionBottomSheetViewController.h"

#import <Charts/Charts-Swift.h>

#include <OsmAndCore/Utilities.h>

#define kStatsSection 0
#define kMapMargin 20.0

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

#define VIEWPORT_FULL_SCALE 0.6f
#define VIEWPORT_MINIMIZED_SCALE 0.2f

@interface OARouteDetailsViewController () <OAStateChangedListener, OARouteInformationListener, ChartViewDelegate, OAStatisticsSelectionDelegate, UIGestureRecognizerDelegate>

@end

@implementation OARouteDetailsViewController
{
    NSDictionary *_data;
    OARoutingHelper *_routingHelper;
    
    OAGPXTrackAnalysis *_analysis;
    OAGPXDocument *_gpx;
    OATrackChartPoints *_trackChartPoints;
    
    NSMutableSet<NSNumber *> *_expandedSections;
    
    EOARouteStatisticsMode _currentMode;
    
    LineChartView *_statisticsChart;
    BOOL _hasTranslated;
    double _highlightDrawX;
    
    CGPoint _lastTranslation;
    
    CGFloat _cachedYViewPort;
    OAMapRendererView *_mapView;
}

- (void)populateMainGraphSection:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OALineChartCell" owner:self options:nil];
    OALineChartCell *routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];
    routeStatsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    routeStatsCell.lineChartView.delegate = self;
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.lineChartView analysis:_analysis useGesturesAndScale:YES];
    
    BOOL hasSlope = routeStatsCell.lineChartView.lineData.dataSetCount > 1;
    
    _statisticsChart = routeStatsCell.lineChartView;
    for (UIGestureRecognizer *recognizer in _statisticsChart.gestureRecognizers)
    {
        if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
        {
            [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
        }
        [recognizer addTarget:self action:@selector(onChartGesture:)];
    }
    
    if (hasSlope)
    {
        nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteStatisticsModeCell" owner:self options:nil];
        OARouteStatisticsModeCell *modeCell = (OARouteStatisticsModeCell *)[nib objectAtIndex:0];
        modeCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [modeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"map_widget_altitude"), OALocalizedString(@"gpx_slope")] forState:UIControlStateNormal];
        [modeCell.modeButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [modeCell.iconButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        modeCell.rightLabel.text = OALocalizedString(@"shared_string_distance");
        modeCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        
        [dataArr setObject:@[modeCell, routeStatsCell] forKey:@(section++)];
    }
    else
    {
        [dataArr setObject:@[routeStatsCell] forKey:@(section++)];
    }
}

- (void)populateElevationSection:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoAltitudeCell" owner:self options:nil];
    OARouteInfoAltitudeCell *altCell = (OARouteInfoAltitudeCell *)[nib objectAtIndex:0];
    altCell.avgAltitudeTitle.text = OALocalizedString(@"gpx_avg_altitude");
    altCell.altRangeTitle.text = OALocalizedString(@"gpx_alt_range");
    altCell.ascentTitle.text = OALocalizedString(@"gpx_ascent");
    altCell.descentTitle.text = OALocalizedString(@"gpx_descent");
    
    OsmAndAppInstance app = [OsmAndApp instance];
    altCell.avgAltitudeValue.text = [app getFormattedAlt:_analysis.avgElevation];
    altCell.altRangeValue.text = [NSString stringWithFormat:@"%@ - %@", [app getFormattedAlt:_analysis.minElevation], [app getFormattedAlt:_analysis.maxElevation]];
    altCell.ascentValue.text = [app getFormattedAlt:_analysis.diffElevationUp];
    altCell.descentValue.text = [app getFormattedAlt:_analysis.diffElevationDown];
    
    [dataArr setObject:@[altCell] forKey:@(section++)];
}

- (void)populateStatistics:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    const auto& originalRoute = _routingHelper.getRoute.getOriginalRoute;
    if (!originalRoute.empty())
    {
        NSArray<OARouteStatistics *> *routeInfo = [OARouteStatisticsHelper calculateRouteStatistic:originalRoute];
        
        for (OARouteStatistics *stat in routeInfo)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoCell" owner:self options:nil];
            OARouteInfoCell *cell = (OARouteInfoCell *)[nib objectAtIndex:0];
            cell.detailsButton.tag = section;
            [cell.detailsButton addTarget:self action:@selector(detailsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.titleView.text = [OAUtilities getLocalizedRouteInfoProperty:stat.name];
            [cell.detailsButton setTitle:OALocalizedString(@"rendering_category_details") forState:UIControlStateNormal];
            cell.barChartView.delegate = self;
            [GpxUIHelper refreshBarChartWithChartView:cell.barChartView statistics:stat analysis:_analysis nightMode:[OAAppSettings sharedManager].nightMode];
            
            for (UIGestureRecognizer *recognizer in cell.barChartView.gestureRecognizers)
            {
                if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
                {
                    [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
                }
                [recognizer addTarget:self action:@selector(onChartGesture:)];
            }
            [cell.barChartView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBarChartTapped:)]];
            
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
            
            nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoLegendCell" owner:self options:nil];
            OARouteInfoLegendCell *legend = (OARouteInfoLegendCell *)[nib objectAtIndex:0];
            
            for (NSString *key in stat.partition)
            {
                OARouteSegmentAttribute *segment = stat.partition[key];
                NSString *title = [stat.name isEqualToString:@"routeInfo_steepness"] && ![segment.getUserPropertyName isEqualToString:UNDEFINED_ATTR] ? segment.getUserPropertyName : OALocalizedString([NSString stringWithFormat:@"rendering_attr_%@_name", segment.getUserPropertyName]);
                OARouteInfoLegendItemView *item = [[OARouteInfoLegendItemView alloc] initWithTitle:title color:UIColorFromARGB(segment.color) distance:[[OsmAndApp instance] getFormattedDistance:segment.distance]];
                [legend.legendStackView addArrangedSubview:item];
            }
            [dataArr setObject:@[cell, legend] forKey:@(section++)];
        }
    }
}

- (void) generateData
{
    _gpx = [OAGPXUIHelper makeGpxFromRoute:_routingHelper.getRoute];
    _analysis = [_gpx getAnalysis:0];
    _expandedSections = [NSMutableSet new];
    _currentMode = EOARouteStatisticsModeBoth;
    _lastTranslation = CGPointZero;
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _cachedYViewPort = _mapView.viewportYScale;
    
    NSMutableDictionary *dataArr = [NSMutableDictionary new];
    NSInteger section = 0;
    
    [self populateMainGraphSection:dataArr section:section];
    
    [self populateElevationSection:dataArr section:section];

    [self populateStatistics:dataArr section:section];
    
    _data = [NSDictionary dictionaryWithDictionary:dataArr];
}

- (void) restoreMapViewPort
{
    if (_mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        _mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (_mapView.viewportYScale != _cachedYViewPort)
        _mapView.viewportYScale = _cachedYViewPort;
}

- (void) adjustViewPort:(BOOL)landscape
{
    if (!self.delegate)
        return;
    
    if (!landscape)
    {
        if (self.delegate.isInFullMode && _mapView.viewportYScale != VIEWPORT_FULL_SCALE)
            _mapView.viewportYScale = VIEWPORT_FULL_SCALE;
        else if (!self.delegate.isInFullScreenMode && !self.delegate.isInFullMode && _mapView.viewportYScale != VIEWPORT_MINIMIZED_SCALE)
            _mapView.viewportYScale = VIEWPORT_MINIMIZED_SCALE;
        
        if (_mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
            _mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    }
    else
    {
        if (_mapView.viewportYScale != _cachedYViewPort)
            _mapView.viewportYScale = _cachedYViewPort;
        
        if (_mapView.viewportXScale != VIEWPORT_SHIFTED_SCALE)
            _mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
    }
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (NSAttributedString *)getAttributedTypeStr
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

- (NSAttributedString *) getAdditionalInfoStr
{
    OsmAndAppInstance app = [OsmAndApp instance];
    UIFont *textFont = [UIFont systemFontOfSize:13.0];
    NSDictionary *attrs = @{NSFontAttributeName: textFont, NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)};
    if (_analysis)
    {
        NSMutableAttributedString *res = [NSMutableAttributedString new];
        
        NSTextAttachment *arrowUpAttachment = [[NSTextAttachment alloc] init];
        arrowUpAttachment.image = [[UIImage imageNamed:@"ic_small_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        arrowUpAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 20.)/2.f, 20., 20.);
        
        NSTextAttachment *arrowDownAttachment = [[NSTextAttachment alloc] init];
        arrowDownAttachment.image = [[UIImage imageNamed:@"ic_small_arrow_down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        arrowDownAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 20.)/2.f, 20., 20.);
        
        [res appendAttributedString:[NSAttributedString attributedStringWithAttachment:arrowUpAttachment]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:[app getFormattedAlt:_analysis.maxElevation] attributes:attrs]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:@"    "]];
        
        [res appendAttributedString:[NSAttributedString attributedStringWithAttachment:arrowDownAttachment]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:[app getFormattedAlt:_analysis.minElevation] attributes:attrs]];
        
        [res addAttributes:attrs range:NSMakeRange(0, res.length)];
        
        return res;
    }
    
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
    [self setupRouteInfo];
    
    [self generateData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
    [_tableView setScrollEnabled:NO];
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 125.;
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
    
    if (self.delegate)
        [self.delegate requestFullMode];
    
    [self centerMapOnRoute];
}

- (void)centerMapOnBBox:(const OABBox &)routeBBox
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL landscape = [self isLandscapeIPadAware];
    [mapPanel displayAreaOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right) zoom:0 bottomInset:!landscape && self.delegate ? self.delegate.getVisibleHeight + kMapMargin : 0 leftInset:landscape ? self.contentView.frame.size.width + kMapMargin : 0];
}

- (void) centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    OABBox routeBBox;
    routeBBox.top = DBL_MAX;
    routeBBox.bottom = DBL_MAX;
    routeBBox.left = DBL_MAX;
    routeBBox.right = DBL_MAX;
    if ([_routingHelper isRouteCalculated] && !error)
    {
        routeBBox = [_routingHelper getBBox];
        if ([_routingHelper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
        {
            [self centerMapOnBBox:routeBBox];
        }
    }
}

- (void) setupRouteInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate)
            [self.delegate contentChanged];
    });
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

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin;
    CGRect leftBtnFrame = _cancelButton.frame;
    CGRect rightBtnFrame = _startButton.frame;

    if (_startButton.isDirectionRTL)
    {
        rightBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        rightBtnFrame.size.width = w / 2 - 8;
        
        leftBtnFrame.origin.x = CGRectGetMaxX(rightBtnFrame) + 16.;
        leftBtnFrame.size.width = rightBtnFrame.size.width;
        
        _cancelButton.frame = leftBtnFrame;
        _startButton.frame = rightBtnFrame;
    }
    else
    {
        leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        leftBtnFrame.size.width = w / 2 - 8;
        _cancelButton.frame = leftBtnFrame;
        
        rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
        rightBtnFrame.size.width = leftBtnFrame.size.width;
        _startButton.frame = rightBtnFrame;
    }
    
    _cancelButton.layer.cornerRadius = 9.;
    [self setupButtonAppearance:_startButton iconName:@"ic_custom_navigation_arrow.png" color:UIColor.whiteColor];
}

- (void) setupButtonAppearance:(UIButton *) button iconName:(NSString *)iconName color:(UIColor *)color
{
    button.layer.cornerRadius = 9.;
    [button setImage:[[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setTintColor:color];
}

- (void)refreshContent
{
    [self generateData];
    [self.tableView reloadData];
}

- (UIView *) getTopView
{
    return self.navBar;
}

- (UIView *) getMiddleView
{
    return self.contentView;
}

- (UIView *)getBottomView
{
    return self.bottomToolBarView;
}

- (CGFloat)getToolBarHeight
{
    return twoButtonsBottmomSheetHeight;
}

- (CGFloat)getNavBarHeight
{
    return defaultNavBarHeight;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL) needsLayoutOnModeChange
{
    return NO;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (BOOL) isLandscapeIPadAware
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (void)onMenuDismissed
{
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
    [self restoreMapViewPort];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"gpx_route");
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.startButton setTitle:OALocalizedString(@"gpx_start") forState:UIControlStateNormal];
}

- (CGFloat)contentHeight
{
    return _tableView.contentSize.height;
}

- (void)onSectionPressed:(NSIndexPath *)indexPath {
    NSArray *sectionData = _data[@(indexPath.section)];
    OARouteInfoCell *cell = sectionData[indexPath.row];
    [cell onDetailsPressed];
    if ([_expandedSections containsObject:@(indexPath.section)])
    {
        [_expandedSections removeObject:@(indexPath.section)];
        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [_expandedSections addObject:@(indexPath.section)];
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
    }
    [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    [self.delegate contentHeightChanged:_tableView.contentSize.height];
}

- (void) detailsButtonPressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:button.tag];
        [self onSectionPressed:indexPath];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
        if (self.delegate)
            [self.delegate contentChanged];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self adjustViewPort:[self isLandscapeIPadAware]];
    }];
}

- (void) onBarChartTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        ChartHighlight *h = [_statisticsChart getHighlightByTouchPoint:CGPointMake([recognizer locationInView:_statisticsChart].x, 0.)];
        _statisticsChart.lastHighlighted = h;
        [_statisticsChart highlightValue:h callDelegate:YES];
    }
}

- (void) onBarChartScrolled:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (_statisticsChart.lowestVisibleX > 0.1 && _statisticsChart.highestVisibleX != _statisticsChart.chartXMax)
        {
            _lastTranslation = [recognizer translationInView:_statisticsChart];
            return;
        }
        
        ChartHighlight *lastHighlighted = _statisticsChart.lastHighlighted;
        CGPoint touchPoint = [recognizer locationInView:_statisticsChart];
        CGPoint translation = [recognizer translationInView:_statisticsChart];
        ChartHighlight *h = [_statisticsChart getHighlightByTouchPoint:CGPointMake(_statisticsChart.isFullyZoomedOut ? touchPoint.x : _highlightDrawX + (_lastTranslation.x - translation.x), 0.)];
        
        if (h != lastHighlighted)
        {
            _statisticsChart.lastHighlighted = h;
            [_statisticsChart highlightValue:h callDelegate:YES];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastTranslation = CGPointZero;
        if (_statisticsChart.highlighted.count > 0)
            _highlightDrawX = _statisticsChart.highlighted.firstObject.drawX;
    }
}

- (void) onChartGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        _hasTranslated = NO;
        if (_statisticsChart.highlighted.count > 0)
            _highlightDrawX = _statisticsChart.highlighted.firstObject.drawX;
        else
            _highlightDrawX = -1;
    }
    else if (([recognizer isKindOfClass:UIPinchGestureRecognizer.class] ||
              ([recognizer isKindOfClass:UITapGestureRecognizer.class] && (((UITapGestureRecognizer *) recognizer).nsuiNumberOfTapsRequired == 2)))
             && recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self refreshHighlightOnMap:YES];
    }
}

- (void) onStatsModeButtonPressed:(id)sender
{
    OAStatisticsSelectionBottomSheetViewController *statsModeBottomSheet = [[OAStatisticsSelectionBottomSheetViewController alloc] initWithMode:_currentMode];
    statsModeBottomSheet.delegate = self;
    [statsModeBottomSheet show];
}

- (void) cancelPressed
{
    [[OARootViewController instance].mapPanel showRouteInfo];
}

- (IBAction)buttonGoPressed:(id)sender
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel hideContextMenu];
    [mapPanel startNavigation];
}

- (IBAction)buttonDonePressed:(id)sender
{
    [self cancelPressed];
}

- (IBAction)cancelPressed:(id)sender
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel hideContextMenu];
    [mapPanel stopNavigation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section > 1)
    {
        return ((NSArray *)_data[@(section)]).count - ([_expandedSections containsObject:@(section)] ? 0 : 1);
    }
    return ((NSArray *)_data[@(section)]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.001 : 16.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 1 && indexPath.row == 0)
        [self onSectionPressed:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self refreshContent];
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

#pragma - mark ChartViewDelegate

- (void)chartValueNothingSelected:(ChartViewBase *)chartView
{
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
    
    for (NSArray *cellArray in _data.allValues)
    {
        for (UITableViewCell *cell in cellArray)
        {
            if ([cell isKindOfClass:OARouteInfoCell.class])
            {
                OARouteInfoCell *routeCell = (OARouteInfoCell *) cell;
                [routeCell.barChartView highlightValue:nil];
            }
        }
    }
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    for (NSArray *cellArray in _data.allValues)
    {
        for (UITableViewCell *cell in cellArray)
        {
            if ([cell isKindOfClass:OARouteInfoCell.class])
            {
                OARouteInfoCell *routeCell = (OARouteInfoCell *) cell;
                
                ChartHighlight *bh = [routeCell.barChartView.highlighter getHighlightWithX:1. y:highlight.xPx];
                [bh setDrawWithX:highlight.xPx y:highlight.xPx];
                [routeCell.barChartView highlightValue:bh];
            }
        }
    }
    [self refreshHighlightOnMap:NO];
}

- (void)chartScaled:(ChartViewBase *)chartView scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY
{
    [self syncVisibleCharts:chartView];
}

- (void)chartTranslated:(ChartViewBase *)chartView dX:(CGFloat)dX dY:(CGFloat)dY
{
    [self syncVisibleCharts:chartView];
    _hasTranslated = true;
    if (_highlightDrawX != -1)
    {
        ChartHighlight *h = [_statisticsChart getHighlightByTouchPoint:CGPointMake(_highlightDrawX, 0.)];
        if (h != nil)
            [_statisticsChart highlightValue:h callDelegate:true];
    }
}

- (void) syncVisibleCharts:(ChartViewBase *)chartView
{
    for (NSArray *cellArray in _data.allValues)
    {
        for (UITableViewCell *cell in cellArray)
        {
            if ([cell isKindOfClass:OARouteInfoCell.class])
            {
                OARouteInfoCell *routeCell = (OARouteInfoCell *) cell;
                [routeCell.barChartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix chart:routeCell.barChartView invalidate:YES];
            }
            else if ([cell isKindOfClass:OALineChartCell.class])
            {
                OALineChartCell *chartCell = (OALineChartCell *) cell;

                [chartCell.lineChartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix chart:chartCell.lineChartView invalidate:YES];
            }
        }
    }
}

- (void) refreshHighlightOnMap:(BOOL)forceFit
{
    if (!_gpx)
        return;
    
    NSArray<ChartHighlight *> *highlights = _statisticsChart.highlighted;
    OsmAnd::LatLon location;
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    
    OATrackChartPoints *trackChartPoints = _trackChartPoints;
    if (!trackChartPoints)
    {
        trackChartPoints = [[OATrackChartPoints alloc] init];
        trackChartPoints.segmentColor = -1;
        trackChartPoints.gpx = _gpx;
        trackChartPoints.axisPointsInvalidated = YES;
        trackChartPoints.xAxisPoints = [self getXAxisPoints:trackChartPoints];
        [mapVC.mapLayers.routeMapLayer showCurrentStatisticsLocation:trackChartPoints];
        _trackChartPoints = trackChartPoints;
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

- (OsmAnd::LatLon) getLocationAtPos:(double) position
{
    OsmAnd::LatLon latLon;
    LineChartData *data = _statisticsChart.lineData;
    NSArray<id<IChartDataSet>> *dataSets = data ? data.dataSets : [NSArray new];
    if (dataSets.count > 0 && _gpx)
    {
        OAGpxTrk *track = _gpx.tracks.firstObject;
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
    if (dataSets.count > 0 && _gpx)
    {
        OAGpxTrk *track = _gpx.tracks.firstObject;
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

#pragma mark - OAStatisticsSelectionDelegate

- (void)onNewModeSelected:(EOARouteStatisticsMode)mode
{
    _currentMode = mode;
    [self updateRouteStatisticsGraph];
}

- (void) updateRouteStatisticsGraph
{
    NSArray *statsSection = _data[@(kStatsSection)];
    if (statsSection.count > 1)
    {
        OARouteStatisticsModeCell *statsModeCell = statsSection[0];
        OALineChartCell *graphCell = statsSection[1];
        
        switch (_currentMode) {
            case EOARouteStatisticsModeBoth:
            {
                [statsModeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"map_widget_altitude"), OALocalizedString(@"gpx_slope")] forState:UIControlStateNormal];
                for (id<IChartDataSet> data in graphCell.lineChartView.lineData.dataSets)
                {
                    data.visible = YES;
                }
                graphCell.lineChartView.leftAxis.enabled = YES;
                graphCell.lineChartView.leftAxis.drawLabelsEnabled = NO;
                graphCell.lineChartView.rightAxis.enabled = YES;
                ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) graphCell.lineChartView.rightYAxisRenderer;
                renderer.renderingMode = YAxisCombinedRenderingModeBothValues;
                break;
            }
            case EOARouteStatisticsModeAltitude:
            {
                [statsModeCell.modeButton setTitle:OALocalizedString(@"map_widget_altitude") forState:UIControlStateNormal];
                graphCell.lineChartView.lineData.dataSets[0].visible = YES;
                graphCell.lineChartView.lineData.dataSets[1].visible = NO;
                graphCell.lineChartView.leftAxis.enabled = YES;
                graphCell.lineChartView.leftAxis.drawLabelsEnabled = YES;
                graphCell.lineChartView.rightAxis.enabled = NO;
                break;
            }
            case EOARouteStatisticsModeSlope:
            {
                [statsModeCell.modeButton setTitle:OALocalizedString(@"gpx_slope") forState:UIControlStateNormal];
                graphCell.lineChartView.lineData.dataSets[0].visible = NO;
                graphCell.lineChartView.lineData.dataSets[1].visible = YES;
                graphCell.lineChartView.leftAxis.enabled = NO;
                graphCell.lineChartView.leftAxis.drawLabelsEnabled = NO;
                graphCell.lineChartView.rightAxis.enabled = YES;
                ChartYAxisCombinedRenderer *renderer = (ChartYAxisCombinedRenderer *) graphCell.lineChartView.rightYAxisRenderer;
                renderer.renderingMode = YAxisCombinedRenderingModePrimaryValueOnly;
                break;
            }
            default:
                break;
        }
        [graphCell.lineChartView notifyDataSetChanged];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

@end
