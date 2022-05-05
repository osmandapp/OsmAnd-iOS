//
//  OATrackMenuTabSegments.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabSegments.h"
#import "OARootViewController.h"
#import "OARouteBaseViewController.h"
#import "OAIconTitleValueCell.h"
#import "OALineChartCell.h"
#import "OAQuadItemsWithTitleDescIconCell.h"
#import "OASegmentTableViewCell.h"
#import "OARadiusCellEx.h"
#import "Localization.h"
#import "OAMapLayers.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXTrackAnalysis.h"

#import <Charts/Charts-Swift.h>
#import "OsmAnd_Maps-Swift.h"
#import "OARouteStatisticsHelper.h"

@interface OATrackMenuTabSegments () <UIGestureRecognizerDelegate, ChartViewDelegate>

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabSegments
{
    OARouteLineChartHelper *_routeLineChartHelper;

    BOOL _hasTranslated;
    CGPoint _lastTranslation;
    double _highlightDrawX;
}

@dynamic tableData, isGeneratedData;

- (void)commonInit
{
    _lastTranslation = CGPointZero;
}

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_gpx_track");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_trip"];
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudSegmentsTab;
}

- (void)generateData
{
    self.tableData = [OAGPXTableData withData: @{ kTableKey: @"table_tab_segments" }];

    NSArray<OATrkSegment *> *segments = @[];
    if (self.trackMenuDelegate)
    {
        segments = [self.trackMenuDelegate getSegments];

        if (!_routeLineChartHelper)
            _routeLineChartHelper = [self.trackMenuDelegate getLineChartHelper];
    }

    OATrkSegment *generalSegment = self.trackMenuDelegate ? [self.trackMenuDelegate getGeneralSegment] : nil;
    OAGPXTrackAnalysis *generalAnalysis = self.trackMenuDelegate ? [self.trackMenuDelegate getGeneralAnalysis] : nil;
    if (generalSegment && generalAnalysis)
    {
        [self generateSegmentSectionData:generalSegment
                                analysis:generalAnalysis
                                   index:0];
    }

    for (NSInteger index = 0; index < segments.count; index++)
    {
        OAGPXTrackAnalysis *analysis = [OAGPXTrackAnalysis segment:0 seg:segments[index]];
        [self generateSegmentSectionData:segments[index]
                                analysis:analysis
                                   index:generalSegment ? index + 1 : index];
    }

    self.isGeneratedData = YES;
}

- (void)generateSegmentSectionData:(OATrkSegment *)segment
                          analysis:(OAGPXTrackAnalysis *)analysis
                             index:(NSInteger)index
{
    if (!segment)
        return;

    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALineChartCell getCellIdentifier] owner:self options:nil];
    OALineChartCell *cell = (OALineChartCell *) nib[0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.lineChartView.delegate = self;
    cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);

    [GpxUIHelper setupGPXChartWithChartView:cell.lineChartView
                               yLabelsCount:4
                                  topOffset:20
                               bottomOffset:4
                        useGesturesAndScale:YES
    ];

    if (_routeLineChartHelper)
    {
        [_routeLineChartHelper changeChartMode:EOARouteStatisticsModeAltitudeSpeed
                                         chart:cell.lineChartView
                                      analysis:analysis
                                      modeCell:nil];
    }

    CLLocationCoordinate2D startChartPoint = self.trackMenuDelegate && [self.trackMenuDelegate openedFromMap]
            ? [self.trackMenuDelegate getPinLocation] : kCLLocationCoordinate2DInvalid;

    OAGPXTableSectionData *segmentSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: [NSString stringWithFormat:@"section_%p", (__bridge void *) segment],
            kTableValues: @{
                    @"segment_value": segment,
                    @"analysis_value": analysis,
                    @"mode_value": @(EOARouteStatisticsModeAltitudeSpeed),
                    @"points_value": _routeLineChartHelper
                            ? [_routeLineChartHelper generateTrackChartPoints:cell.lineChartView
                                                                   startPoint:startChartPoint
                                                                      segment:segment]
                            : [[OATrackChartPoints alloc] init]
            }
    }];
    if (cell)
        segmentSectionData.values[@"cell_value"] = cell;
    [self.tableData.subjects addObject:segmentSectionData];
    [segmentSectionData setData:@{ kSectionHeaderHeight: self.tableData.subjects.firstObject == segmentSectionData ? @0.001 : @36. }];

    NSString *segmentTitle = nil;
    if (self.trackMenuDelegate)
        segmentTitle = [self.trackMenuDelegate getTrackSegmentTitle:segment];
    if (!segmentTitle)
        segmentTitle = [NSString stringWithFormat:OALocalizedString(@"segnet_num"), index];

    OAGPXTableCellData *segmentCellData = index != 0 ? [OAGPXTableCellData withData:@{
            kTableKey: [NSString stringWithFormat:@"segment_%p", (__bridge void *) segment],
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: segmentTitle,
            kCellToggle: @NO
    }] : nil;

    if (segmentCellData)
        [segmentSectionData.subjects addObject:segmentCellData];

    OAGPXTableCellData *tabsCellData = [OAGPXTableCellData withData:@{
            kTableKey: [NSString stringWithFormat:@"tabs_%p", (__bridge void *) segment],
            kCellType: [OASegmentTableViewCell getCellIdentifier]
    }];
    [segmentSectionData.subjects addObject:tabsCellData];

    LineChartData *lineData = cell.lineChartView.lineData;
    NSInteger entryCount = lineData ? lineData.entryCount : 0;

    OAGPXTableCellData *chartCellData;
    if (entryCount > 0)
    {
        for (UIGestureRecognizer *recognizer in cell.lineChartView.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
            {
                [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
                recognizer.delegate = self;
            }

            [recognizer addTarget:self action:@selector(onChartGesture:)];
        }

        chartCellData = [OAGPXTableCellData withData:@{
                kTableKey: [NSString stringWithFormat:@"chart_%p", (__bridge void *) segment],
                kCellType: [OALineChartCell getCellIdentifier]
        }];
    }
    else
    {
        cell = nil;
    }

    if (chartCellData)
        [segmentSectionData.subjects addObject:chartCellData];

    OAGPXTableCellData *statisticsCellData = [OAGPXTableCellData withData:@{
            kTableKey: [NSString stringWithFormat:@"statistics_%p", (__bridge void *) segment],
            kCellType: [OAQuadItemsWithTitleDescIconCell getCellIdentifier],
            kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment mode:EOARouteStatisticsModeAltitudeSpeed],
            kCellToggle: @(analysis.timeSpan > 0)
    }];
    [segmentSectionData.subjects addObject:statisticsCellData];

    OAGPXTableCellData *buttonsCellData = [OAGPXTableCellData withData:@{
            kTableKey: [NSString stringWithFormat:@"segment_buttons_%p", (__bridge void *) segment],
            kCellType: [OARadiusCellEx getCellIdentifier],
            kTableValues: @{
                    @"left_title_string_value": OALocalizedString(@"analyze_on_map"),
                    @"right_title_string_value": OALocalizedString(@"shared_string_options"),
                    @"right_icon_string_value": @"ic_custom_overflow_menu"
            },
            kCellToggle: @(!segment.generalSegment)
    }];
    [segmentSectionData.subjects addObject:buttonsCellData];

    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    values[@"tab_0_string_value"] = OALocalizedString(@"shared_string_overview");
    if (analysis.hasElevationData)
        values[@"tab_1_string_value"] = OALocalizedString(@"map_widget_altitude");
    if (analysis.isSpeedSpecified)
        values[analysis.hasElevationData ? @"tab_2_string_value" : @"tab_1_string_value"] = OALocalizedString(@"gpx_speed");
    values[@"row_to_update_int_value"] = @([segmentSectionData.subjects indexOfObject:statisticsCellData]);
    values[@"selected_index_int_value"] = @0;
    [tabsCellData setData:@{ kTableValues: values }];

    if (cell && chartCellData)
        cell.lineChartView.tag = [self.tableData.subjects indexOfObject:segmentSectionData] << 10 | [segmentSectionData.subjects indexOfObject:chartCellData];
}

- (void)runAdditionalActions
{
    if (self.tableData.subjects.count > 0)
    {
        OAGPXTableSectionData *sectionData = self.tableData.subjects.firstObject;
        OALineChartCell *cell = ((OALineChartCell *) sectionData.values[@"cell_value"]);
        if (cell)
        {
            if (_routeLineChartHelper)
            {
                [_routeLineChartHelper refreshHighlightOnMap:NO
                                               lineChartView:cell.lineChartView
                                            trackChartPoints:sectionData.values[@"points_value"]
                                                     segment:sectionData.values[@"segment_value"]];
            }
            if (self.trackMenuDelegate)
            {
                [self.trackMenuDelegate updateChartHighlightValue:cell.lineChartView
                                                          segment:sectionData.values[@"segment_value"]];
            }
        }
    }
}

- (NSDictionary<NSString *, NSDictionary *> *)getStatisticsDataForAnalysis:(OAGPXTrackAnalysis *)analysis
                                                                   segment:(OATrkSegment *)segment
                                                                      mode:(EOARouteStatisticsMode)mode
{
    NSMutableDictionary *titles = [NSMutableDictionary dictionary];
    NSMutableDictionary *icons = [NSMutableDictionary dictionary];
    NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];

    OATrack *track = self.trackMenuDelegate ? [self.trackMenuDelegate getTrack:segment] : nil;
    BOOL joinSegments = self.trackMenuDelegate && [self.trackMenuDelegate isJoinSegments];
    switch (mode)
    {
        case EOARouteStatisticsModeAltitudeSpeed:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"shared_string_distance");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"shared_string_time_span");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"shared_string_start_time");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"shared_string_end_time");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_distance";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_time_interval";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_time_start";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_time_end";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistance];

            descriptions[@"top_right_description_string_value"] = [OAOsmAndFormatter getFormattedTimeInterval:
                    !joinSegments && track && track.generalTrack
                            ? analysis.timeSpanWithoutGaps : analysis.timeSpan shortFormat:YES];

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm, MM-dd-yy"];
            descriptions[@"bottom_left_description_string_value"] =
                    [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:analysis.startTime]];
            descriptions[@"bottom_right_description_string_value"] =
                    [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:analysis.endTime]];

            break;
        }
        case EOARouteStatisticsModeAltitudeSlope:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"gpx_avg_altitude");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"gpx_alt_range");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"gpx_ascent");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"gpx_descent");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_altitude_average";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_altitude_range";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_ascent";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_descent";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.avgElevation];
            descriptions[@"top_right_description_string_value"] = [NSString stringWithFormat:@"%@ - %@",
                    [OAOsmAndFormatter getFormattedAlt:analysis.minElevation],
                    [OAOsmAndFormatter getFormattedAlt:analysis.maxElevation]];
            descriptions[@"bottom_left_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationUp];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationDown];

            break;
        }
        case EOARouteStatisticsModeSpeed:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"gpx_average_speed");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"gpx_max_speed");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"shared_string_time_moving");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"distance_moving");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_speed";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_max_speed";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_time_start";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_time_end";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedSpeed:analysis.avgSpeed];
            descriptions[@"top_right_description_string_value"] = [OAOsmAndFormatter getFormattedSpeed:analysis.maxSpeed];

            descriptions[@"bottom_left_description_string_value"] = [OAOsmAndFormatter getFormattedTimeInterval:
                            !joinSegments && track && track.generalTrack ? analysis.timeSpanWithoutGaps : analysis.timeMoving
                                                                                                    shortFormat:YES];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistanceMoving];

            break;
        }
        default:
            return @{ };
    }

    return @{
            @"titles": titles,
            @"icons": icons,
            @"descriptions": descriptions
    };
}

- (void)syncVisibleCharts:(LineChartView *)chartView
{
    for (OAGPXTableSectionData *sectionData in self.tableData.subjects)
    {
        OALineChartCell *cell = sectionData.values[@"cell_value"];
        if (cell)
        {
            [cell.lineChartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix
                                                               chart:cell.lineChartView
                                                          invalidate:YES];
        }
    }
}

- (double)getRoundedDouble:(double)toRound
{
    return floorf(toRound * 100 + 0.5) / 100;
}

#pragma - mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer.view isKindOfClass:[UITableView class]])
        return NO;

    return YES;
}

#pragma - mark ChartViewDelegate

- (void)chartValueNothingSelected:(ChartViewBase *)chartView
{
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
}

- (void)chartValueSelected:(ChartViewBase *)chartView
                     entry:(ChartDataEntry *)entry
                 highlight:(ChartHighlight *)highlight
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chartView.tag & 0x3FF inSection:chartView.tag >> 10];
    OAGPXTableSectionData *sectionData = self.tableData.subjects[indexPath.section];

    if (_routeLineChartHelper)
    {
        [_routeLineChartHelper refreshHighlightOnMap:NO
                                       lineChartView:(LineChartView *) chartView
                                    trackChartPoints:sectionData.values[@"points_value"]
                                             segment:sectionData.values[@"segment_value"]];
    }
}

- (void)chartScaled:(ChartViewBase *)chartView scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY
{
    [self syncVisibleCharts:(LineChartView *) chartView];
}

- (void)chartTranslated:(ChartViewBase *)chartView dX:(CGFloat)dX dY:(CGFloat)dY
{
    LineChartView *lineChartView = (LineChartView *) chartView;
    _hasTranslated = YES;
    if (_highlightDrawX != -1)
    {
        ChartHighlight *h = [lineChartView getHighlightByTouchPoint:CGPointMake(_highlightDrawX, 0.)];
        if (h != nil)
            [lineChartView highlightValue:h callDelegate:true];
    }
}

#pragma - mark Selectors

- (void)onBarChartScrolled:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.view && [recognizer.view isKindOfClass:LineChartView.class])
    {
        LineChartView *lineChartView = (LineChartView *) recognizer.view;
        if (recognizer.state == UIGestureRecognizerStateChanged)
        {
            if (lineChartView.lowestVisibleX > 0.1
                    && [self getRoundedDouble:lineChartView.highestVisibleX]
                    != [self getRoundedDouble:lineChartView.chartXMax])
            {
                _lastTranslation = [recognizer translationInView:lineChartView];
                return;
            }

            ChartHighlight *lastHighlighted = lineChartView.lastHighlighted;
            CGPoint touchPoint = [recognizer locationInView:lineChartView];
            CGPoint translation = [recognizer translationInView:lineChartView];
            ChartHighlight *h = [lineChartView getHighlightByTouchPoint:CGPointMake(lineChartView.isFullyZoomedOut
                    ? touchPoint.x : _highlightDrawX + (_lastTranslation.x - translation.x), 0.)];

            if (h != lastHighlighted)
            {
                lineChartView.lastHighlighted = h;
                [lineChartView highlightValue:h callDelegate:YES];
            }
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded)
        {
            _lastTranslation = CGPointZero;
            if (lineChartView.highlighted.count > 0)
                _highlightDrawX = lineChartView.highlighted.firstObject.drawX;
        }
    }
}

- (void)onChartGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.view && [recognizer.view isKindOfClass:LineChartView.class])
    {
        LineChartView *lineChartView = (LineChartView *) recognizer.view;
        if (recognizer.state == UIGestureRecognizerStateBegan)
        {
            _hasTranslated = NO;
            if (lineChartView.highlighted.count > 0)
                _highlightDrawX = lineChartView.highlighted.firstObject.drawX;
            else
                _highlightDrawX = -1;
        }
        else if (([recognizer isKindOfClass:UIPinchGestureRecognizer.class]
                || ([recognizer isKindOfClass:UITapGestureRecognizer.class]
                        && (((UITapGestureRecognizer *) recognizer).nsuiNumberOfTapsRequired == 2)))
                && recognizer.state == UIGestureRecognizerStateEnded)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lineChartView.tag & 0x3FF
                                                        inSection:lineChartView.tag >> 10];
            OAGPXTableSectionData *sectionData = self.tableData.subjects[indexPath.section];

            if (_routeLineChartHelper)
            {
                [_routeLineChartHelper refreshHighlightOnMap:YES
                                               lineChartView:lineChartView
                                            trackChartPoints:sectionData.values[@"points_value"]
                                                    segment:sectionData.values[@"segment_value"]];
            }
        }
    }
}

#pragma mark - Cell action methods

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key hasPrefix:@"chart_"])
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"chart_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData && _routeLineChartHelper)
        {
            OALineChartCell *cell = ((OALineChartCell *) sectionData.values[@"cell_value"]);
            if (cell)
            {
                [_routeLineChartHelper changeChartMode:(EOARouteStatisticsMode) [sectionData.values[@"mode_value"] integerValue]
                                                 chart:cell.lineChartView
                                              analysis:sectionData.values[@"analysis_value"]
                                              modeCell:nil];
            }
        }
    }
    else if ([tableData.key hasPrefix:@"statistics_"])
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"statistics_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData)
        {
            EOARouteStatisticsMode mode = (EOARouteStatisticsMode) [sectionData.values[@"mode_value"] integerValue];
            OAGPXTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            [tableData setData:@{
                    kTableValues: [self getStatisticsDataForAnalysis:analysis
                                                             segment:sectionData.values[@"segment_value"]
                                                                mode:mode],
                    kCellToggle: @((mode == EOARouteStatisticsModeAltitudeSpeed && analysis.timeSpan > 0)
                            || mode != EOARouteStatisticsModeAltitudeSpeed)
            }];
        }
    }
    else if ([tableData.key hasPrefix:@"tabs_"])
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"tabs_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData)
        {
            NSInteger selectedIndex = [tableData.values[@"selected_index_int_value"] integerValue];
            if (selectedIndex != NSNotFound)
            {
                EOARouteStatisticsMode mode;
                if (tableData.values.count > selectedIndex && selectedIndex != 0)
                {
                    NSString *value = tableData.values[[NSString stringWithFormat:@"tab_%li_string_value", selectedIndex]];
                    mode = [value isEqualToString:OALocalizedString(@"map_widget_altitude")]
                            ? EOARouteStatisticsModeAltitudeSlope
                            : [value isEqualToString:OALocalizedString(@"gpx_speed")]
                                    ? EOARouteStatisticsModeSpeed
                                    : EOARouteStatisticsModeAltitudeSpeed;
                }
                else
                {
                    mode = EOARouteStatisticsModeAltitudeSpeed;
                }
                sectionData.values[@"mode_value"] = @(mode);

                OAGPXTableCellData *chartData = [sectionData getSubject:[@"chart_" stringByAppendingString:segmentKey]];
                if (chartData)
                    [self updateData:chartData];
                OAGPXTableCellData *statisticsData = [sectionData getSubject:[@"statistics_" stringByAppendingString:segmentKey]];
                if (statisticsData)
                    [self updateData:statisticsData];
            }
        }
    }
    else if ([tableData.key hasPrefix:@"section_"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        if ([tableData.values[@"delete_section_bool_value"] boolValue])
        {
            [self.tableData.subjects removeObject:sectionData];
        }
        else
        {
            for (OAGPXTableCellData *cellData in sectionData.subjects)
            {
                [self updateData:cellData];
            }
        }
    }
    else if ([tableData.key hasPrefix:@"table_tab_segments"])
    {
        OAGPXTableData *tData = (OAGPXTableData *) tableData;
        for (OAGPXTableSectionData *sectionData in tData.subjects)
        {
            [self updateData:sectionData];
        }
    }
}

- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData
{
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key hasPrefix:@"segment_buttons_"] && self.trackMenuDelegate)
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"segment_buttons_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData)
        {
            EOARouteStatisticsMode mode = (EOARouteStatisticsMode) [sectionData.values[@"mode_value"] integerValue];
            OAGPXTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            BOOL isLeftButtonSelected = [tableData.values[@"is_left_button_selected"] boolValue];
            if (isLeftButtonSelected)
                [self.trackMenuDelegate openAnalysis:analysis withMode:mode];
            else
                [self.trackMenuDelegate openEditSegmentScreen:sectionData.values[@"segment_value"] analysis:analysis];
        }
    }
}

@end
