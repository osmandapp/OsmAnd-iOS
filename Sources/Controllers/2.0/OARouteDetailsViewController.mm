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
#import "OAFilledButtonCell.h"
#import "OASaveGpxToTripsActivity.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"

#import <Charts/Charts-Swift.h>

#include <OsmAndCore/Utilities.h>

#define kStatsSection 0
#define kAdditionalRouteDetailsOffset 184.0

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

#define VIEWPORT_FULL_SCALE 0.6f
#define VIEWPORT_MINIMIZED_SCALE 0.2f

@interface OARouteDetailsViewController () <OAStateChangedListener, ChartViewDelegate, OAStatisticsSelectionDelegate>

@end

@implementation OARouteDetailsViewController
{
    NSDictionary *_data;
    
    NSMutableSet<NSNumber *> *_expandedSections;
    
    EOARouteStatisticsMode _currentMode;
    
    BOOL _hasTranslated;
    double _highlightDrawX;
    
    CGPoint _lastTranslation;
    
    CGFloat _cachedYViewPort;
    OAMapRendererView *_mapView;
}

- (UITableViewCell *) getAnalyzeButtonCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
    OAFilledButtonCell* cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
    
    if (cell)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.button setTitle:OALocalizedString(@"gpx_analyze") forState:UIControlStateNormal];
        [cell.button addTarget:self action:@selector(openRouteDetailsGraph) forControlEvents:UIControlEventTouchUpInside];
        cell.button.backgroundColor = UIColorFromRGB(color_primary_purple);
        [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    return cell;
}

- (void)populateMainGraphSection:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALineChartCell getCellIdentifier] owner:self options:nil];
    OALineChartCell *routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];
    routeStatsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    routeStatsCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
    routeStatsCell.lineChartView.delegate = self;
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.lineChartView analysis:self.analysis useGesturesAndScale:YES];
    
    BOOL hasSlope = routeStatsCell.lineChartView.lineData.dataSetCount > 1;
    
    self.statisticsChart = routeStatsCell.lineChartView;
    UITableViewCell *analyzeBtnCell = [self getAnalyzeButtonCell];
    for (UIGestureRecognizer *recognizer in self.statisticsChart.gestureRecognizers)
    {
        if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
        {
            [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
        }
        [recognizer addTarget:self action:@selector(onChartGesture:)];
    }
    
    if (hasSlope)
    {
        nib = [[NSBundle mainBundle] loadNibNamed:[OARouteStatisticsModeCell getCellIdentifier] owner:self options:nil];
        OARouteStatisticsModeCell *modeCell = (OARouteStatisticsModeCell *)[nib objectAtIndex:0];
        modeCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [modeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"map_widget_altitude"), OALocalizedString(@"gpx_slope")] forState:UIControlStateNormal];
        [modeCell.modeButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [modeCell.iconButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        modeCell.rightLabel.text = OALocalizedString(@"shared_string_distance");
        modeCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        
        [dataArr setObject:@[modeCell, routeStatsCell, analyzeBtnCell] forKey:@(section++)];
    }
    else
    {
        [dataArr setObject:@[routeStatsCell, analyzeBtnCell] forKey:@(section++)];
    }
}

- (void)populateElevationSection:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARouteInfoAltitudeCell getCellIdentifier] owner:self options:nil];
    OARouteInfoAltitudeCell *altCell = (OARouteInfoAltitudeCell *)[nib objectAtIndex:0];
    altCell.avgAltitudeTitle.text = OALocalizedString(@"gpx_avg_altitude");
    altCell.altRangeTitle.text = OALocalizedString(@"gpx_alt_range");
    altCell.ascentTitle.text = OALocalizedString(@"gpx_ascent");
    altCell.descentTitle.text = OALocalizedString(@"gpx_descent");
    
    OsmAndAppInstance app = [OsmAndApp instance];
    altCell.avgAltitudeValue.text = [app getFormattedAlt:self.analysis.avgElevation];
    altCell.altRangeValue.text = [NSString stringWithFormat:@"%@ - %@", [app getFormattedAlt:self.analysis.minElevation], [app getFormattedAlt:self.analysis.maxElevation]];
    altCell.ascentValue.text = [app getFormattedAlt:self.analysis.diffElevationUp];
    altCell.descentValue.text = [app getFormattedAlt:self.analysis.diffElevationDown];
    
    [dataArr setObject:@[altCell] forKey:@(section++)];
}

- (void)populateStatistics:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    const auto& originalRoute = self.routingHelper.getRoute.getOriginalRoute;
    if (!originalRoute.empty())
    {
        NSArray<OARouteStatistics *> *routeInfo = [OARouteStatisticsHelper calculateRouteStatistic:originalRoute];
        
        for (OARouteStatistics *stat in routeInfo)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARouteInfoCell getCellIdentifier] owner:self options:nil];
            OARouteInfoCell *cell = (OARouteInfoCell *)[nib objectAtIndex:0];
            cell.detailsButton.tag = section;
            [cell.detailsButton addTarget:self action:@selector(detailsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.titleView.text = [OAUtilities getLocalizedRouteInfoProperty:stat.name];
            [cell.detailsButton setTitle:OALocalizedString(@"rendering_category_details") forState:UIControlStateNormal];
            cell.barChartView.delegate = self;
            [GpxUIHelper refreshBarChartWithChartView:cell.barChartView statistics:stat analysis:self.analysis nightMode:[OAAppSettings sharedManager].nightMode];
            
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
            
            nib = [[NSBundle mainBundle] loadNibNamed:[OARouteInfoLegendCell getCellIdentifier] owner:self options:nil];
            OARouteInfoLegendCell *legend = (OARouteInfoLegendCell *)[nib objectAtIndex:0];
            
            for (NSString *key in stat.partition)
            {
                OARouteSegmentAttribute *segment = stat.partition[key];
                NSString *title = [stat.name isEqualToString:@"routeInfo_steepness"] && ![segment.getUserPropertyName isEqualToString:kUndefinedAttr] ? segment.getUserPropertyName : OALocalizedString([NSString stringWithFormat:@"rendering_attr_%@_name", segment.getUserPropertyName]);
                OARouteInfoLegendItemView *item = [[OARouteInfoLegendItemView alloc] initWithTitle:title color:UIColorFromARGB(segment.color) distance:[[OsmAndApp instance] getFormattedDistance:segment.distance]];
                [legend.legendStackView addArrangedSubview:item];
            }
            [dataArr setObject:@[cell, legend] forKey:@(section++)];
        }
    }
}

- (void) generateData
{
    if (!self.gpx || !self.analysis)
    {
        self.gpx = [OAGPXUIHelper makeGpxFromRoute:self.routingHelper.getRoute];
        self.analysis = [self.gpx getAnalysis:0];
    }
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

- (BOOL) needsMapRuler
{
    return YES;
}

- (NSAttributedString *)getAttributedTypeStr
{
    return [self getFormattedDistTimeString];
}

- (NSAttributedString *) getAdditionalInfoStr
{
    OsmAndAppInstance app = [OsmAndApp instance];
    UIFont *textFont = [UIFont systemFontOfSize:13.0];
    NSDictionary *attrs = @{NSFontAttributeName: textFont, NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)};
    if (self.analysis)
    {
        NSMutableAttributedString *res = [NSMutableAttributedString new];
        
        NSTextAttachment *arrowUpAttachment = [[NSTextAttachment alloc] init];
        arrowUpAttachment.image = [[UIImage imageNamed:@"ic_small_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        arrowUpAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 20.)/2.f, 20., 20.);
        
        NSTextAttachment *arrowDownAttachment = [[NSTextAttachment alloc] init];
        arrowDownAttachment.image = [[UIImage imageNamed:@"ic_small_arrow_down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        arrowDownAttachment.bounds = CGRectMake(0., roundf(textFont.capHeight - 20.)/2.f, 20., 20.);
        
        [res appendAttributedString:[NSAttributedString attributedStringWithAttachment:arrowUpAttachment]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:[app getFormattedAlt:self.analysis.maxElevation] attributes:attrs]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:@"    "]];
        
        [res appendAttributedString:[NSAttributedString attributedStringWithAttachment:arrowDownAttachment]];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:[app getFormattedAlt:self.analysis.minElevation] attributes:attrs]];
        
        [res addAttributes:attrs range:NSMakeRange(0, res.length)];
        
        return res;
    }
    
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
}

- (void) setupRouteInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate)
            [self.delegate contentChanged];
    });
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

- (CGFloat)additionalContentOffset
{
    return [self isLandscapeIPadAware] ? 0.0 : kAdditionalRouteDetailsOffset;
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

- (void)onMenuDismissed
{
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
    [self restoreMapViewPort];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"gpx_route");
    [self.doneButton setTitle:OALocalizedString(@"gpx_export") forState:UIControlStateNormal];
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

- (void) openRouteDetailsGraph
{
    [[OARootViewController instance].mapPanel openTargetViewWithRouteDetailsGraph:self.gpx analysis:self.analysis];
}

- (void) onBarChartTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        ChartHighlight *h = [self.statisticsChart getHighlightByTouchPoint:CGPointMake([recognizer locationInView:self.statisticsChart].x, 0.)];
        self.statisticsChart.lastHighlighted = h;
        [self.statisticsChart highlightValue:h callDelegate:YES];
    }
}

- (void) onBarChartScrolled:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (self.statisticsChart.lowestVisibleX > 0.1 && [self getRoundedDouble:self.statisticsChart.highestVisibleX] != [self getRoundedDouble:self.statisticsChart.chartXMax])
        {
            _lastTranslation = [recognizer translationInView:self.statisticsChart];
            return;
        }
        
        ChartHighlight *lastHighlighted = self.statisticsChart.lastHighlighted;
        CGPoint touchPoint = [recognizer locationInView:self.statisticsChart];
        CGPoint translation = [recognizer translationInView:self.statisticsChart];
        ChartHighlight *h = [self.statisticsChart getHighlightByTouchPoint:CGPointMake(self.statisticsChart.isFullyZoomedOut ? touchPoint.x : _highlightDrawX + (_lastTranslation.x - translation.x), 0.)];
        
        if (h != lastHighlighted)
        {
            self.statisticsChart.lastHighlighted = h;
            [self.statisticsChart highlightValue:h callDelegate:YES];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastTranslation = CGPointZero;
        if (self.statisticsChart.highlighted.count > 0)
            _highlightDrawX = self.statisticsChart.highlighted.firstObject.drawX;
    }
}

- (void) onChartGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        _hasTranslated = NO;
        if (self.statisticsChart.highlighted.count > 0)
            _highlightDrawX = self.statisticsChart.highlighted.firstObject.drawX;
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

- (IBAction)buttonCancelPressed:(id)sender
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
    if (!self.gpx)
        return;
    
    OARootViewController *rootVC = [OARootViewController instance];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *title = [NSString stringWithFormat:@"_%@_.gpx", [formatter stringFromDate:[NSDate date]]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:title];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm_EEE"];
    self.gpx.tracks.firstObject.name = [formatter stringFromDate:[NSDate date]];
    [self.gpx saveTo:path];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                      applicationActivities:@[[[OASaveGpxToTripsActivity alloc] init]]];
    
    activityViewController.popoverPresentationController.sourceView = rootVC.view;
    activityViewController.popoverPresentationController.sourceRect = _doneButton.frame;
    
    [rootVC presentViewController:activityViewController
                                     animated:YES
                                   completion:nil];
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
        ChartHighlight *h = [self.statisticsChart getHighlightByTouchPoint:CGPointMake(_highlightDrawX, 0.)];
        if (h != nil)
            [self.statisticsChart highlightValue:h callDelegate:true];
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
        
        [self changeChartMode:_currentMode chart:graphCell.lineChartView modeCell:statsModeCell];
    }
}

@end
