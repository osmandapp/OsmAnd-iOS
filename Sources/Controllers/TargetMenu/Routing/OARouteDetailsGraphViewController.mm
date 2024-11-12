//
//  OARouteDetailsGraphViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteDetailsGraphViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OASizes.h"
#import "OAStateChangedListener.h"
#import "OARoutingHelper.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "OAGPXUIHelper.h"
#import "OAMapLayers.h"
#import "OARouteLayer.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OARouteStatistics.h"
#import "OATargetPointsHelper.h"
#import "OAMapRendererView.h"
#import "OARouteInfoLegendItemView.h"
#import "OARouteStatisticsModeCell.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"
#import "OAGPXDatabase.h"
#import "GeneratedAssetSymbols.h"
#import <DGCharts/DGCharts-Swift.h>

#include <OsmAndCore/Utilities.h>

#define kGraphOffset 200.0

@interface OARouteDetailsGraphViewController () <OAStateChangedListener, ChartViewDelegate, OAStatisticsSelectionDelegate>

@end

@implementation OARouteDetailsGraphViewController
{
    NSArray *_data;

    NSArray<NSNumber *> *_types;
    
    BOOL _hasTranslated;
    double _highlightDrawX;
    
    CGPoint _lastTranslation;
    
    CGFloat _cachedYViewPort;
    OAMapRendererView *_mapView;
    OATrackMenuViewControllerState *_trackMenuControlState;
}

- (instancetype)initWithGpxData:(NSDictionary *)data
          trackMenuControlState:(OATargetMenuViewControllerState *)trackMenuControlState
{
    self = [super initWithGpxData:data];
    if (self)
    {
        if (data)
        {
            _trackMenuControlState = trackMenuControlState;
        }
    }
    return self;
}

- (NSArray *) getMainGraphSectionData
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:ElevationChartCell.reuseIdentifier owner:self options:nil];
    ElevationChartCell *routeStatsCell = (ElevationChartCell *)[nib objectAtIndex:0];
    routeStatsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    routeStatsCell.chartView.delegate = self;

    [GpxUIHelper setupElevationChartWithChartView:routeStatsCell.chartView
                                        topOffset:20
                                     bottomOffset:4
                              useGesturesAndScale:YES];
    OASGpxDataItem *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.gpx.path]];
    BOOL calcWithoutGaps = !gpx.joinSegments && (self.gpx.tracks.count > 0 && self.gpx.tracks.firstObject.generalTrack);
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.chartView
                                      analysis:self.analysis
                                     firstType:GPXDataSetTypeAltitude
                                    secondType:GPXDataSetTypeSlope
                                      axisType:GPXDataSetAxisTypeDistance
                               calcWithoutGaps:calcWithoutGaps];

    self.statisticsChart = routeStatsCell.chartView;
    for (UIGestureRecognizer *recognizer in self.statisticsChart.gestureRecognizers)
    {
        if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
        {
            [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
        }
        [recognizer addTarget:self action:@selector(onChartGesture:)];
    }

    BOOL hasSlope = routeStatsCell.chartView.lineData.dataSetCount > 1;
    if (hasSlope)
    {
        nib = [[NSBundle mainBundle] loadNibNamed:[OARouteStatisticsModeCell getCellIdentifier] owner:self options:nil];
        OARouteStatisticsModeCell *modeCell = (OARouteStatisticsModeCell *)[nib objectAtIndex:0];
        modeCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [modeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"altitude"), OALocalizedString(@"shared_string_slope")] forState:UIControlStateNormal];
        [modeCell.modeButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [modeCell.iconButton addTarget:self action:@selector(onStatsModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        modeCell.rightLabel.text = OALocalizedString(@"shared_string_distance");
        modeCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        
        return @[modeCell, routeStatsCell];
    }
    else
    {
        return @[routeStatsCell];
    }
}

- (void) generateData
{
    if (!self.gpx || !self.analysis)
    {
        self.gpx = [OAGPXUIHelper makeGpxFromRoute:self.routingHelper.getRoute];
        self.analysis = [self.gpx getAnalysisFileTimestamp:0];
    }
    _types = _trackMenuControlState ? _trackMenuControlState.routeStatistics : @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSlope)];
    _lastTranslation = CGPointZero;
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _cachedYViewPort = _mapView.viewportYScale;
    
    _data = [self getMainGraphSectionData];
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (BOOL)hideButtons
{
    return YES;
}

- (NSAttributedString *)getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (NSString *)getTypeStr
{
    return nil;
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscape && !OAUtilities.isIPad;
}

- (CGFloat) additionalContentOffset
{
    return !OAUtilities.isLandscape || OAUtilities.isIPad ? kGraphOffset + OAUtilities.getBottomMargin : 0.0;
}

- (BOOL)hasInfoView
{
    return NO;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupRouteInfo];
    
    [self generateData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView setScrollEnabled:NO];
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 125.;

    [self.routeLineChartHelper refreshChart:self.statisticsChart
                              fitTrackOnMap:YES
                                   forceFit:NO
                           recalculateXAxis:YES];
    [self updateRouteStatisticsGraph];
}

- (BOOL)isLandscapeIPadAware
{
    return [self isLandscape];
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


- (CGFloat)getNavBarHeight
{
    return defaultNavBarHeight;
}

- (BOOL) needsMapRuler
{
    return YES;
}

- (BOOL) hasTopToolbar
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
    return NO;
}

- (BOOL)supportFullMenu
{
    return NO;
}

- (void)onMenuShown
{
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"gpx_analyze");
}

- (CGFloat)contentHeight
{
    return _tableView.contentSize.height;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
        if (self.delegate)
            [self.delegate contentChanged];
    } completion:nil];
}

- (void) onStatsModeButtonPressed:(id)sender
{
    OAStatisticsSelectionBottomSheetViewController *statsModeBottomSheet = [[OAStatisticsSelectionBottomSheetViewController alloc] initWithTypes:_types analysis:self.analysis];
    statsModeBottomSheet.delegate = self;
    [statsModeBottomSheet show];
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
              ([recognizer isKindOfClass:UITapGestureRecognizer.class]
               && (((UITapGestureRecognizer *) recognizer).nsuiNumberOfTapsRequired == 2)))
             && recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self.routeLineChartHelper refreshChart:self.statisticsChart
                                  fitTrackOnMap:YES
                                       forceFit:NO
                               recalculateXAxis:YES];
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

- (void)chartTranslated:(ChartViewBase *)chartView dX:(CGFloat)dX dY:(CGFloat)dY
{
    _hasTranslated = true;
    if (_highlightDrawX != -1)
    {
        ChartHighlight *h = [self.statisticsChart getHighlightByTouchPoint:CGPointMake(_highlightDrawX, 0.)];
        if (h)
        {
            [self.statisticsChart highlightValue:h callDelegate:YES];
            [self.routeLineChartHelper refreshChart:self.statisticsChart
                                      fitTrackOnMap:YES
                                           forceFit:NO
                                   recalculateXAxis:NO];
        }
    }
}

- (IBAction)buttonDonePressed:(id)sender
{
    [self cancelPressed];
}

- (void)cancelPressed
{
    if (_trackMenuControlState)
    {
        if (_trackMenuControlState.openedFromTracksList && !_trackMenuControlState.openedFromTrackMenu && _trackMenuControlState.navControllerHistory)
        {
            [[OARootViewController instance].mapPanel targetHideMenu:0.3 backButtonClicked:YES onComplete:^{
                [[OARootViewController instance].navigationController setViewControllers:_trackMenuControlState.navControllerHistory animated:YES];
            }];
        }
        else
        {
            _trackMenuControlState.openedFromTrackMenu = NO;
            __weak __typeof(self) weakSelf = self;
            [[OARootViewController instance].mapPanel targetHideMenu:0.3 backButtonClicked:YES onComplete:^{
                
                if (weakSelf.trackItem)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:weakSelf.trackItem
                                                                       trackHudMode:EOATrackMenuHudMode
                                                                              state:_trackMenuControlState];
                }
                else
                {
                    NSLog(@"trackItem is empty");
                }
            }];
        }
    }
    else
    {
        [[OARootViewController instance].mapPanel openTargetViewWithRouteDetails:self.gpx analysis:self.analysis];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    [self.routeLineChartHelper refreshChart:self.statisticsChart
                              fitTrackOnMap:YES
                                   forceFit:NO
                           recalculateXAxis:NO];
}

#pragma mark - OAStatisticsSelectionDelegate

- (void)onTypesSelected:(NSArray<NSNumber *> *)types
{
    _types = types;
    [self updateRouteStatisticsGraph];
}

- (void) updateRouteStatisticsGraph
{
    if (_data.count > 1)
    {
        OARouteStatisticsModeCell *statsModeCell = _data[0];
        ElevationChartCell *graphCell = _data[1];

        [self.routeLineChartHelper changeChartTypes:_types
                                              chart:graphCell.chartView
                                           analysis:self.analysis
                                           modeCell:statsModeCell];
    }
}


@end
