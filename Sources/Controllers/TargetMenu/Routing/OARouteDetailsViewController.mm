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
#import "OALineChartCell.h"
#import "OARouteInfoCell.h"
#import "OAGPXDocument.h"
#import "OAGPXUIHelper.h"
#import "OAMapLayers.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARouteStatistics.h"
#import "OARouteInfoAltitudeCell.h"
#import "OAMapRendererView.h"
#import "OARouteInfoLegendItemView.h"
#import "OARouteInfoLegendCell.h"
#import "OARouteStatisticsModeCell.h"
#import "OAFilledButtonCell.h"
#import "OASaveGpxToTripsActivity.h"
#import "OAOsmAndFormatter.h"
#import "OAEmissionHelper.h"
#import "OASegmentTableViewCell.h"
#import "OARouteDirectionInfo.h"
#import "OALanesDrawable.h"
#import "OATurnDrawable.h"
#import "OATurnDrawable+cpp.h"
#import <Charts/Charts-Swift.h>
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#define kStatsSection 0
#define kAdditionalRouteDetailsOffset 184.0

#define VIEWPORT_FULL_SCALE 0.6f
#define VIEWPORT_MINIMIZED_SCALE 0.2f

typedef NS_ENUM(NSInteger, EOAOARouteDetailsViewControllerMode)
{
    EOAOARouteDetailsViewControllerModeInstructions = 0,
    EOAOARouteDetailsViewControllerModeAnalysis
};

@implementation OACumulativeInfo

+ (OACumulativeInfo *) getRouteDirectionCumulativeInfo:(NSInteger)position routeDirections:(NSArray<OARouteDirectionInfo *> *)routeDirections
{
    OACumulativeInfo *cumulativeInfo = [[OACumulativeInfo alloc] init];
    if (position >= routeDirections.count)
        return cumulativeInfo;
    
    for (int i = 0; i < position; i++)
    {
        OARouteDirectionInfo *routeDirectionInfo = routeDirections[i];
        cumulativeInfo.time += [routeDirectionInfo getExpectedTime];
        cumulativeInfo.distance += routeDirectionInfo.distance;
    }
    return cumulativeInfo;
}

+ (NSString *) getTimeDescription:(OARouteDirectionInfo *)model
{
    long timeInSeconds = [model getExpectedTime];
    return [OAOsmAndFormatter getFormattedDuration:timeInSeconds];
}

@end


@interface OARouteDetailsViewController () <OAStateChangedListener, ChartViewDelegate, OAStatisticsSelectionDelegate, OAEmissionHelperListener>

@end

@implementation OARouteDetailsViewController
{
    NSDictionary *_data;
    NSMutableDictionary *_instructionsTabData;
    NSMutableDictionary *_analysisTabData;
    
    EOAOARouteDetailsViewControllerMode _selectedTab;
    NSMutableSet<NSNumber *> *_expandedSections;
    
    NSArray<NSNumber *> *_types;
    
    BOOL _hasTranslated;
    double _highlightDrawX;
    
    CGPoint _lastTranslation;
    
    CGFloat _cachedYViewPort;
    OAMapRendererView *_mapView;
    NSString *_emission;
}

- (void)registerCells
{
    [self.tableView registerNib:[UINib nibWithNibName:[OAFilledButtonCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OAFilledButtonCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OASegmentTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OASegmentTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[RouteInfoListItemCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[RouteInfoListItemCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OALineChartCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OALineChartCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OARouteStatisticsModeCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OARouteStatisticsModeCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OARouteInfoAltitudeCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OARouteInfoAltitudeCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OARouteInfoCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OARouteInfoCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OARouteInfoLegendCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OARouteInfoLegendCell reuseIdentifier]];
}

- (UITableViewCell *) getAnalyzeButtonCell
{
    OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell reuseIdentifier]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.button setTitle:OALocalizedString(@"gpx_analyze") forState:UIControlStateNormal];
    [cell.button addTarget:self action:@selector(openRouteDetailsGraph) forControlEvents:UIControlEventTouchUpInside];
    cell.button.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
    [cell.button setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorPrimary] forState:UIControlStateNormal];
    return cell;
}

- (OASegmentTableViewCell *) getTabSelectorView
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
    OASegmentTableViewCell *cell = (OASegmentTableViewCell *) nib[0];
    UIFont *font = [UIFont scaledSystemFontOfSize:14. weight:UIFontWeightSemibold];
    [cell.segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary], NSFontAttributeName : font} forState:UIControlStateSelected];
    [cell.segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary], NSFontAttributeName : font} forState:UIControlStateNormal];
    [cell.segmentControl setTitle:OALocalizedString(@"shared_string_instructions") forSegmentAtIndex:0];
    [cell.segmentControl setTitle:OALocalizedString(@"shared_string_analysis") forSegmentAtIndex:1];
    [cell.segmentControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [cell.segmentControl setSelectedSegmentIndex:_selectedTab == EOAOARouteDetailsViewControllerModeInstructions ? 0 : 1];
    cell.hideTopSectionSeparator = YES;
    return cell;
}

- (void) populateInstructionsTabCells:(NSInteger &)section
{
    _instructionsTabData = [NSMutableDictionary dictionary];
    NSMutableArray<UITableViewCell *> *cells = [NSMutableArray array];
    
    NSArray<OARouteDirectionInfo *> *routeDirections = [self.routingHelper getRouteDirections];
    for (NSInteger i = 0; i < routeDirections.count; i++)
    {
        OARouteDirectionInfo *routeDirectionInfo = routeDirections[i];
        UITableViewCell *cell = [self getRouteDirectionCell:i model:routeDirectionInfo directionsInfo:routeDirections];
        [cells addObject:cell];
    }

    [_instructionsTabData setObject:cells forKey:@(section++)];
}

- (UITableViewCell *) getRouteDirectionCell:(NSInteger)directionInfoIndex model:(OARouteDirectionInfo *)model directionsInfo:(NSArray<OARouteDirectionInfo *> *)directionsInfo
{
    RouteInfoListItemCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[RouteInfoListItemCell reuseIdentifier]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    OATurnDrawable *turnDrawable = [[OATurnDrawable alloc] initWithMini:NO themeColor:EOATurnDrawableThemeColorSystem];
    const auto turnType = model.turnType;
    [turnDrawable setTurnType:turnType];
    turnDrawable.textColor = [UIColor colorNamed:ACColorNameWidgetValueColor];
    
    CGFloat size = MAX(turnDrawable.pathForTurn.bounds.origin.x + turnDrawable.pathForTurn.bounds.size.width,
                       turnDrawable.pathForTurn.bounds.origin.y + turnDrawable.pathForTurn.bounds.size.height);
    turnDrawable.frame = CGRectMake(0, 0, size, size);
    [turnDrawable setClr:[UIColor colorNamed:ACColorNameTextColorPrimary]];
    [turnDrawable setNeedsDisplay];
    [cell setLeftTurnIconDrawable:turnDrawable];
    [cell setLeftImageViewWithImage:turnDrawable.toUIImage];
    
    vector<int> lanes = model.turnType->getLanes();
    if (lanes.size() > 0)
    {
        OALanesDrawable *_lanesDrawable = [[OALanesDrawable alloc] initWithScaleCoefficient:1];
        [_lanesDrawable setLanes:lanes];
        [_lanesDrawable updateBounds];
        _lanesDrawable.frame = CGRectMake(0, 0, _lanesDrawable.width, _lanesDrawable.height);
        [_lanesDrawable setNeedsDisplay];
        [cell setBottomLanesImageWithImage:_lanesDrawable.toUIImage];
    }
    else
    {
        [cell setBottomLanesImageWithImage:nil];
    }
    
    NSString *segmentDescription = [model getDescriptionRoutePart];
    [cell setBottomLabelWithText:segmentDescription];
    
    if (model.distance > 0)
    {
        BOOL shouldRoundUp = ![[OAAppSettings sharedManager].preciseDistanceNumbers get];
        NSString *segmentDistanceLabelText = [OAOsmAndFormatter getFormattedDistance:model.distance roundUp:shouldRoundUp];
        [cell setTopLeftLabelWithText:segmentDistanceLabelText];
        [cell setTopLeftLabelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
        
        OACumulativeInfo *cumulativeInfo = [OACumulativeInfo getRouteDirectionCumulativeInfo:directionInfoIndex + 1 routeDirections:directionsInfo];
        NSString *distance = [OAOsmAndFormatter getFormattedDistance:cumulativeInfo.distance roundUp:shouldRoundUp];
        NSString *time = [OAOsmAndFormatter getFormattedTimeInterval:cumulativeInfo.time shortFormat:YES];
        [cell setTopRightLabelWithText:[NSString stringWithFormat:@"%@ • %@", distance, time]];
    }
    else
    {
        if (!segmentDescription || segmentDescription.length == 0)
        {
            BOOL isLastCell = directionInfoIndex == (directionsInfo.count - 1);
            segmentDescription = OALocalizedString(isLastCell ? @"arrived_at_destination" : @"arrived_at_intermediate_point");
            [cell setTopLeftLabelWithText:segmentDescription];
            [cell setTopLeftLabelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
            [cell setTopRightLabelWithText:@""];
        }
        [cell setBottomLabelWithText:@""];
    }
    
    return cell;
}

- (void) populateAnalysisTabCells:(NSInteger &)section
{
    _analysisTabData = [NSMutableDictionary dictionary];
    [self populateMainGraphSection:_analysisTabData section:section];
    [self populateElevationSection:_analysisTabData section:section];
    [self populateStatistics:_analysisTabData section:section];
}

- (void)populateMainGraphSection:(NSMutableDictionary *)dataArr section:(NSInteger &)section 
{
    OALineChartCell *routeStatsCell = [self.tableView dequeueReusableCellWithIdentifier:[OALineChartCell reuseIdentifier]];
    routeStatsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    routeStatsCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
    routeStatsCell.lineChartView.delegate = self;

    [GpxUIHelper setupGPXChartWithChartView:routeStatsCell.lineChartView
                               yLabelsCount:4
                                  topOffset:20
                               bottomOffset:4
                        useGesturesAndScale:YES
    ];

    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:self.gpx.path]];
    BOOL calcWithoutGaps = !gpx.joinSegments && (self.gpx.tracks.count > 0 && self.gpx.tracks.firstObject.generalTrack);
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.lineChartView
                                      analysis:self.analysis
                           useGesturesAndScale:YES
                                     firstType:GPXDataSetTypeAltitude
                                    secondType:GPXDataSetTypeSlope
                               calcWithoutGaps:calcWithoutGaps];
    
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
        OARouteStatisticsModeCell *modeCell = [self.tableView dequeueReusableCellWithIdentifier:[OARouteStatisticsModeCell reuseIdentifier]];
        modeCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [modeCell.modeButton setTitle:[NSString stringWithFormat:@"%@/%@", OALocalizedString(@"altitude"), OALocalizedString(@"shared_string_slope")] forState:UIControlStateNormal];
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
    OARouteInfoAltitudeCell *altCell = [self.tableView dequeueReusableCellWithIdentifier:[OARouteInfoAltitudeCell reuseIdentifier]];
    altCell.avgAltitudeTitle.text = OALocalizedString(@"average_altitude");
    altCell.altRangeTitle.text = OALocalizedString(@"altitude_range");
    altCell.ascentTitle.text = OALocalizedString(@"gpx_ascent");
    altCell.descentTitle.text = OALocalizedString(@"gpx_descent");
    
    altCell.avgAltitudeValue.text = [OAOsmAndFormatter getFormattedAlt:self.analysis.avgElevation];
    altCell.altRangeValue.text = [NSString stringWithFormat:@"%@ - %@", [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation], [OAOsmAndFormatter getFormattedAlt:self.analysis.maxElevation]];
    altCell.ascentValue.text = [OAOsmAndFormatter getFormattedAlt:self.analysis.diffElevationUp];
    altCell.descentValue.text = [OAOsmAndFormatter getFormattedAlt:self.analysis.diffElevationDown];
    
    [dataArr setObject:@[altCell] forKey:@(section++)];
}

- (void)populateStatistics:(NSMutableDictionary *)dataArr section:(NSInteger &)section {
    const auto& originalRoute = self.routingHelper.getRoute.getOriginalRoute;
    if (!originalRoute.empty())
    {
        NSArray<OARouteStatistics *> *routeInfo = [OARouteStatisticsHelper calculateRouteStatistic:originalRoute];
        
        for (OARouteStatistics *stat in routeInfo)
        {
            OARouteInfoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARouteInfoCell reuseIdentifier]];
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
            
            OARouteInfoLegendCell *legend = [self.tableView dequeueReusableCellWithIdentifier:[OARouteInfoLegendCell reuseIdentifier]];
            
            for (NSString *key in stat.partition)
            {
                OARouteSegmentAttribute *segment = stat.partition[key];
                NSString *title = [stat.name isEqualToString:@"routeInfo_steepness"] && ![segment.getUserPropertyName isEqualToString:kUndefinedAttr] ? segment.getUserPropertyName : OALocalizedString([NSString stringWithFormat:@"rendering_attr_%@_name", segment.getUserPropertyName]);
                OARouteInfoLegendItemView *item = [[OARouteInfoLegendItemView alloc] initWithTitle:title color:UIColorFromARGB(segment.color) distance:[OAOsmAndFormatter getFormattedDistance:segment.distance]];
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
    _types = @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSlope)];
    _lastTranslation = CGPointZero;
    _mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    _cachedYViewPort = _mapView.viewportYScale;
    
    NSMutableDictionary *dataArr = [NSMutableDictionary new];
    NSInteger section = 0;
    
    // this first cell with tab selector was added as a view to the tableview header to avoid showing the first tableview separator above it.
    self.tableView.tableHeaderView = [self getTabSelectorView];
    
    if (_selectedTab == EOAOARouteDetailsViewControllerModeInstructions)
    {
        if (!_instructionsTabData)
            [self populateInstructionsTabCells:section];
        [dataArr addEntriesFromDictionary:_instructionsTabData];
    }
    else if (_selectedTab == EOAOARouteDetailsViewControllerModeAnalysis)
    {
        if (!_analysisTabData)
            [self populateAnalysisTabCells:section];
        [dataArr addEntriesFromDictionary:_analysisTabData];
    }

    _data = [NSDictionary dictionaryWithDictionary:dataArr];
}

- (void) restoreMapViewPort
{
    [[OARootViewController instance].mapPanel.mapViewController setViewportScaleX:kViewportScale y:_cachedYViewPort];
}

- (void) adjustViewPort:(BOOL)landscape
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if (!self.delegate)
        return;
    if (!landscape)
    {
        if (self.delegate.isInFullMode)
            [mapPanel.mapViewController setViewportScaleY:VIEWPORT_FULL_SCALE];
        else if (!self.delegate.isInFullScreenMode && !self.delegate.isInFullMode)
            [mapPanel.mapViewController setViewportScaleY:VIEWPORT_MINIMIZED_SCALE];
        [mapPanel.mapViewController setViewportScaleX:kViewportScale];
    }
    else
    {
        [mapPanel.mapViewController setViewportScaleX:kViewportBottomScale y:_cachedYViewPort];
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

- (BOOL)hideButtons
{
    return YES;
}

- (NSAttributedString *)getAttributedTypeStr
{
    return [self.class getFormattedDistTimeString];
}

- (NSAttributedString *) getAdditionalInfoStr
{
    NSMutableAttributedString *attrDescription =
    [[NSMutableAttributedString alloc] initWithAttributedString:[self.class getFormattedElevationString:self.analysis]];
    if (_emission)
    {
        NSString *emission = [NSString stringWithFormat:@"    |    %@", _emission];
        [attrDescription addString:emission fontWeight:UIFontWeightRegular size:15.];
        [attrDescription setColor:[UIColor colorNamed:ACColorNameTextColorSecondary] forString:emission];
    }
    return attrDescription;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    OAEmissionHelper *emissionHelper = [OAEmissionHelper sharedInstance];
    OAMotorType *motorType = [emissionHelper getMotorTypeForMode:[self.routingHelper getAppMode]];
    if (motorType)
        [emissionHelper getEmission:motorType meters:[self.routingHelper getLeftDistance] listener:self];
    
    [self setupRouteInfo];
    
    _selectedTab = EOAOARouteDetailsViewControllerModeInstructions;
    _expandedSections = [NSMutableSet new];
    [self registerCells];
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
        [self.delegate requestHeaderOnlyMode];
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
    [self setupButtonAppearance:_startButton iconName:@"ic_custom_navigation_arrow.png" color:[UIColor colorNamed:ACColorNameButtonTextColorPrimary]];
}

- (void) setupButtonAppearance:(UIButton *) button iconName:(NSString *)iconName color:(UIColor *)color
{
    button.layer.cornerRadius = 9.;
    [button setImage:[UIImage templateImageNamed:iconName] forState:UIControlStateNormal];
    [button setTintColor:color];
}

- (void)refreshContent
{
    NSInteger contentSectionNumber = 1;
    [self populateInstructionsTabCells:contentSectionNumber];
    [self populateAnalysisTabCells:contentSectionNumber];
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

- (BOOL) showTopViewInFullscreen
{
    return YES;
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

- (BOOL)supportFullMenu
{
    return NO;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (void)onMenuDismissed
{
    [super onMenuDismissed];
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
    [self restoreMapViewPort];
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"layer_route");
    [self.doneButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.startButton setTitle:OALocalizedString(@"shared_string_control_start") forState:UIControlStateNormal];
}

- (CGFloat)contentHeight
{
    return _tableView.contentSize.height;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)onSectionPressed:(NSIndexPath *)indexPath {
    NSArray *sectionData = _data[@(indexPath.section)];
    OARouteInfoCell *cell = sectionData[indexPath.row];
    [cell onDetailsPressed];
    [_tableView performBatchUpdates:^{
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
    } completion:^(BOOL finished) {
        self.tableView.tableHeaderView = [self getTabSelectorView];
        [self.delegate contentHeightChanged:_tableView.contentSize.height];
    }];
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
    [[OARootViewController instance].mapPanel openTargetViewWithRouteDetailsGraph:self.gpx
                                                                         analysis:self.analysis
                                                                 menuControlState:nil];
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
        if (!self.trackChartPoints)
        {
            self.trackChartPoints = [self.routeLineChartHelper generateTrackChartPoints:self.statisticsChart
                                                                               analysis:self.analysis];
        }
        [self.routeLineChartHelper refreshHighlightOnMap:YES
                                           lineChartView:self.statisticsChart
                                        trackChartPoints:self.trackChartPoints
                                                analysis:self.analysis];
    }
}

- (void) onStatsModeButtonPressed:(id)sender
{
    OAStatisticsSelectionBottomSheetViewController *statsModeBottomSheet = [[OAStatisticsSelectionBottomSheetViewController alloc] initWithTypes:_types analysis:self.analysis];
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
    OARootViewController *rootVC = [OARootViewController instance];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *title = [NSString stringWithFormat:@"_%@_.gpx", [formatter stringFromDate:[NSDate date]]];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:title];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm_EEE"];
    OAGPXDocument *doc = [OARoutingHelper.sharedInstance generateGPXFileWithRoute:[formatter stringFromDate:[NSDate date]]];
    if (!doc)
        return;
    
    doc.tracks.firstObject.name = [formatter stringFromDate:[NSDate date]];
    [doc saveTo:path];
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

- (void) segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        _selectedTab = (EOAOARouteDetailsViewControllerMode) segment.selectedSegmentIndex;
        [self generateData];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_selectedTab == EOAOARouteDetailsViewControllerModeAnalysis && section > 1)
    {
        return ((NSArray *)_data[@(section)]).count - ([_expandedSections containsObject:@(section)] ? 0 : 1);
    }
    return ((NSArray *)_data[@(section)]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_selectedTab == EOAOARouteDetailsViewControllerModeInstructions && section == 0)
        return OALocalizedString(@"step_by_step");
    return @" ";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedTab == EOAOARouteDetailsViewControllerModeAnalysis && indexPath.section > 1 && indexPath.row == 0)
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

    if (!self.trackChartPoints)
    {
        self.trackChartPoints = [self.routeLineChartHelper generateTrackChartPoints:self.statisticsChart
                                                                           analysis:self.analysis];
    }
    [self.routeLineChartHelper refreshHighlightOnMap:NO
                                       lineChartView:self.statisticsChart
                                    trackChartPoints:self.trackChartPoints
                                            analysis:self.analysis];
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

- (void)onTypesSelected:(NSArray<NSNumber *> *)types
{
    _types = types;
    [self updateRouteStatisticsGraph];
}

- (void) updateRouteStatisticsGraph
{
    NSArray *statsSection = _data[@(kStatsSection)];
    if (statsSection.count > 1)
    {
        OARouteStatisticsModeCell *statsModeCell = statsSection[0];
        OALineChartCell *graphCell = statsSection[1];

        [self.routeLineChartHelper changeChartTypes:_types
                                              chart:graphCell.lineChartView
                                           analysis:self.analysis
                                           modeCell:statsModeCell];
    }
}

#pragma mark - OAEmissionHelperListener

- (void)onSetupEmission:(NSString *)result
{
    _emission = result;
    [[OARootViewController instance].mapPanel updateTargetDescriptionLabel];
}

@end
