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
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OARouteStatistics.h"
#import "OARouteInfoAltitudeCell.h"
#import "OATargetPointsHelper.h"
#import "OARouteInfoLegendItemView.h"
#import "OARouteInfoLegendCell.h"

#import <Charts/Charts-Swift.h>

#include <OsmAndCore/Utilities.h>

@interface OARouteDetailsViewController () <OAStateChangedListener, OARouteInformationListener, ChartViewDelegate>

@end

@implementation OARouteDetailsViewController
{
    NSDictionary *_data;
    OARoutingHelper *_routingHelper;
    
    OAGPXTrackAnalysis *_analysis;
    
    NSMutableSet<NSNumber *> *_expandedSections;
}

- (void) generateData
{
    _analysis = _routingHelper.getTrackAnalysis;
    _expandedSections = [NSMutableSet new];
    
    NSMutableDictionary *dataArr = [NSMutableDictionary new];
    NSInteger section = 0;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OALineChartCell" owner:self options:nil];
    OALineChartCell *routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];
    routeStatsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    routeStatsCell.lineChartView.delegate = self;
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.lineChartView analysis:_analysis useGesturesAndScale:YES];
    [dataArr setObject:@[routeStatsCell] forKey:@(section++)];
    
    nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoAltitudeCell" owner:self options:nil];
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
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
            
            nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoLegendCell" owner:self options:nil];
            OARouteInfoLegendCell *legend = (OARouteInfoLegendCell *)[nib objectAtIndex:0];
            
            for (NSString *key in stat.partition)
            {
                OARouteSegmentAttribute *segment = stat.partition[key];
                NSString *title = [stat.name isEqualToString:@"routeInfo_steepness"] ? segment.getUserPropertyName : OALocalizedString([NSString stringWithFormat:@"rendering_attr_%@_name", segment.getUserPropertyName]);
                OARouteInfoLegendItemView *item = [[OARouteInfoLegendItemView alloc] initWithTitle:title color:UIColorFromARGB(segment.color) distance:[[OsmAndApp instance] getFormattedDistance:segment.distance]];
                [legend.legendStackView addArrangedSubview:item];
            }
            [dataArr setObject:@[cell, legend] forKey:@(section++)];
        }
    }
    
    _data = [NSDictionary dictionaryWithDictionary:dataArr];
}



- (BOOL)hasControlButtons
{
    return NO;
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSString *)getTypeStr
{
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
    [self applySafeAreaMargins];
    
    UIColor *eleTint = UIColorFromRGB(color_text_footer);
    _eleUpImageView.image = [_eleUpImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleDownImageView.image = [_eleDownImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleUpImageView.tintColor = eleTint;
    _eleDownImageView.tintColor = eleTint;
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
    
    if (self.delegate)
        [self.delegate requestFullMode];
    
    [self centerMapOnRoute];
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
            [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)];
        }
    }
}

- (void) setupRouteInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        if (![_routingHelper isRouteCalculated])
        {
            NSString *emptyEle = [NSString stringWithFormat:@"0 %@", OALocalizedString(@"units_m")];;
            _routeInfoLabel.text = OALocalizedString(@"no_active_route");
            _elevationLabel.text = emptyEle;
            _descentLabel.text = emptyEle;
        }
        else
        {
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
            
            _routeInfoLabel.attributedText = str;
            OAGPXTrackAnalysis *trackAnalysis = _routingHelper.getTrackAnalysis;
            if (trackAnalysis)
            {
                _elevationLabel.text = [app getFormattedAlt:trackAnalysis.maxElevation];
                _descentLabel.text = [app getFormattedAlt:trackAnalysis.minElevation];
            }
        }
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
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin * 2;
    CGRect leftBtnFrame = _cancelButton.frame;
    leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
    leftBtnFrame.size.width = w / 2 - 8;
    _cancelButton.frame = leftBtnFrame;
    
    CGRect rightBtnFrame = _startButton.frame;
    rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
    rightBtnFrame.size.width = leftBtnFrame.size.width;
    _startButton.frame = rightBtnFrame;
    
    _cancelButton.layer.cornerRadius = 6.;
    [self setupButtonAppearance:_startButton iconName:@"ic_custom_navigation_arrow.png" color:UIColor.whiteColor];
}

- (void) setupButtonAppearance:(UIButton *) button iconName:(NSString *)iconName color:(UIColor *)color
{
    button.layer.cornerRadius = 6.;
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
    return 60.;
}

- (CGFloat)getNavBarHeight
{
    return navBarWithSearchFieldHeight;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
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
    } completion:nil];
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

- (void)chartViewDidEndPanning:(ChartViewBase *)chartView
{
    
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
//    for (NSArray *cellArray in _data.allValues)
//    {
//        for (UITableViewCell *cell in cellArray)
//        {
//            if ([cell isKindOfClass:OARouteInfoCell.class])
//            {
//                OARouteInfoCell *routeCell = (OARouteInfoCell *) cell;
//                [routeCell.barChartView highlightValues:@[highlight]];
//            }
//            else if ([cell isKindOfClass:OALineChartCell.class])
//            {
//                OALineChartCell *chartCell = (OALineChartCell *) cell;
//                [chartCell.lineChartView highlightValues:@[highlight]];
//            }
//        }
//    }
}

- (void)chartScaled:(ChartViewBase *)chartView scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY
{
    [self syncVisibleCharts:chartView];
}

- (void)chartTranslated:(ChartViewBase *)chartView dX:(CGFloat)dX dY:(CGFloat)dY
{
    [self syncVisibleCharts:chartView];
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

@end
