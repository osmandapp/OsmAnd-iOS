//
//  OATrackMenuTabSegments.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabSegments.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAValueTableViewCell.h"
#import "OAQuadItemsWithTitleDescIconCell.h"
#import "OASegmentTableViewCell.h"
#import "OARadiusCellEx.h"
#import "Localization.h"
#import "OAMapLayers.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDocumentPrimitives.h"
#import <DGCharts/DGCharts-Swift.h>
#import "OsmAnd_Maps-Swift.h"
#import "OARouteStatisticsHelper.h"

@interface OATrackMenuTabSegments () <UIGestureRecognizerDelegate, ChartViewDelegate>

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabSegments
{
    TrackChartHelper *_trackChartHelper;

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

    NSArray<OASTrkSegment *> *segments = @[];
    if (self.trackMenuDelegate)
    {
        segments = [self.trackMenuDelegate getSegments];
        if (!_trackChartHelper)
            _trackChartHelper = [self.trackMenuDelegate getLineChartHelper];
    }

    OASTrkSegment *generalSegment = self.trackMenuDelegate ? [self.trackMenuDelegate getGeneralSegment] : nil;
    if (generalSegment)
    {
        [self generateSegmentSectionData:generalSegment
                                analysis:[TrackChartHelper getAnalysisFor:generalSegment]
                                   index:0];
    }

    for (NSInteger index = 0; index < segments.count; index++)
    {        
        OASGpxTrackAnalysis *analysis = [TrackChartHelper getAnalysisFor:segments[index]];
        if (analysis)
        {
            [self generateSegmentSectionData:segments[index]
                                    analysis:analysis
                                       index:generalSegment ? index + 1 : index];
        }
    }

    self.isGeneratedData = YES;
}

- (void)generateSegmentSectionData:(OASTrkSegment *)segment
                          analysis:(OASGpxTrackAnalysis *)analysis
                             index:(NSInteger)index
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:ElevationChartCell.reuseIdentifier owner:self options:nil];
    ElevationChartCell *cell = (ElevationChartCell *) nib[0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.chartView.delegate = self;
    cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);

    [GpxUIHelper setupElevationChartWithChartView:cell.chartView];

    if (_trackChartHelper)
    {
        [_trackChartHelper changeChartTypes:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]
                                          chart:cell.chartView
                                       analysis:analysis
                                  statsModeCell:nil];
    }

    OAGPXTableSectionData *segmentSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: [NSString stringWithFormat:@"section_%p", (__bridge void *) segment],
            kTableValues: @{
                    @"segment_value": segment,
                    @"analysis_value": analysis,
                    @"mode_value": @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]
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
        segmentTitle = [NSString stringWithFormat:OALocalizedString(@"segments_count"), index];

    OAGPXTableCellData *segmentCellData = index != 0 ? [OAGPXTableCellData withData:@{
            kTableKey: [NSString stringWithFormat:@"segment_%p", (__bridge void *) segment],
            kCellType: [OAValueTableViewCell getCellIdentifier],
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

    LineChartData *lineData = cell.chartView.lineData;
    NSInteger entryCount = lineData ? lineData.entryCount : 0;

    OAGPXTableCellData *chartCellData;
    if (entryCount > 0)
    {
        for (UIGestureRecognizer *recognizer in cell.chartView.gestureRecognizers)
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
                kCellType: ElevationChartCell.reuseIdentifier
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
            kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment types:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]],
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
        values[@"tab_1_string_value"] = OALocalizedString(@"altitude");
    if (analysis.isSpeedSpecified)
        values[analysis.hasElevationData ? @"tab_2_string_value" : @"tab_1_string_value"] = OALocalizedString(@"shared_string_speed");
    values[@"row_to_update_int_value"] = @([segmentSectionData.subjects indexOfObject:statisticsCellData]);
    values[@"selected_index_int_value"] = @0;
    [tabsCellData setData:@{ kTableValues: values }];

    if (cell && chartCellData)
        cell.chartView.tag = [self.tableData.subjects indexOfObject:segmentSectionData] << 10 | [segmentSectionData.subjects indexOfObject:chartCellData];
}

- (void)runAdditionalActions
{
    if (self.tableData.subjects.count > 0)
    {
        OAGPXTableSectionData *sectionData = self.tableData.subjects.firstObject;
        ElevationChartCell *cell = ((ElevationChartCell *) sectionData.values[@"cell_value"]);
        if (cell)
        {
            OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            OASTrkSegment *segment = sectionData.values[@"segment_value"];
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate updateChartHighlightValue:cell.chartView segment:segment];
            if (analysis && segment && _trackChartHelper)
            {
                [_trackChartHelper refreshChart:cell.chartView
                                           fitTrack:YES
                                           forceFit:YES
                                   recalculateXAxis:YES
                                           analysis:analysis
                                            segment:segment];
            }
        }
    }
}

- (NSDictionary<NSString *, NSDictionary *> *)getStatisticsDataForAnalysis:(OASGpxTrackAnalysis *)analysis
                                                                   segment:(OASTrkSegment *)segment
                                                                     types:(NSArray<NSNumber *> *)types
{
    NSMutableDictionary *titles = [NSMutableDictionary dictionary];
    NSMutableDictionary *icons = [NSMutableDictionary dictionary];
    NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];

    OASTrack *track = self.trackMenuDelegate ? [self.trackMenuDelegate getTrack:segment] : nil;
    BOOL joinSegments = self.trackMenuDelegate && [self.trackMenuDelegate isJoinSegments];
    if (types.count == 2)
    {
        if (types.firstObject.integerValue == GPXDataSetTypeAltitude && types.lastObject.integerValue == GPXDataSetTypeSpeed)
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
                                                                   ? analysis.timeSpanWithoutGaps / 1000 : analysis.timeSpan / 1000 shortFormat:YES];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm, MM-dd-yy"];
            descriptions[@"bottom_left_description_string_value"] =
            [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[self convertToSeconds:analysis.startTime]]];
            descriptions[@"bottom_right_description_string_value"] =
            [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[self convertToSeconds:analysis.endTime]]];
        }
        if (types.firstObject.integerValue == GPXDataSetTypeAltitude && types.lastObject.integerValue == GPXDataSetTypeSlope)
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"average_altitude");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"altitude_range");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"altitude_ascent");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"altitude_descent");
            
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
        }
    }
    else
    {
        if (types.firstObject.integerValue == GPXDataSetTypeSpeed)
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"map_widget_average_speed");
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
                            !joinSegments && track && track.generalTrack ? analysis.timeSpanWithoutGaps / 1000 : analysis.timeMoving / 1000
                                                                                                    shortFormat:YES];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistanceMoving];
        }
        else
        {
            return @{ };
        }
    }
    return @{
            @"titles": titles,
            @"icons": icons,
            @"descriptions": descriptions
    };
}

- (float)convertToSeconds:(float)timestamp
{
    return timestamp > 10000000000 ? timestamp / 1000 : timestamp;
}

- (void)syncVisibleCharts:(LineChartView *)chartView
{
    for (OAGPXTableSectionData *sectionData in self.tableData.subjects)
    {
        ElevationChartCell *cell = sectionData.values[@"cell_value"];
        if (cell)
        {
            [cell.chartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix
                                                           chart:cell.chartView
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
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers.gpxMapLayer hideCurrentStatisticsLocation];
}

- (void)chartValueSelected:(ChartViewBase *)chartView
                     entry:(ChartDataEntry *)entry
                 highlight:(ChartHighlight *)highlight
{
    if (_trackChartHelper && [chartView isKindOfClass:LineChartView.class])
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chartView.tag & 0x3FF inSection:chartView.tag >> 10];
        OAGPXTableSectionData *sectionData = self.tableData.subjects[indexPath.section];
        OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
        OASTrkSegment *segment = sectionData.values[@"segment_value"];
        if (analysis && segment)
        {
            [_trackChartHelper refreshChart:(LineChartView *) chartView
                                       fitTrack:YES
                                       forceFit:NO
                               recalculateXAxis:NO
                                       analysis:analysis
                                        segment:segment];
        }
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
        if (h)
        {
            [lineChartView highlightValue:h callDelegate:YES];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lineChartView.tag & 0x3FF inSection:lineChartView.tag >> 10];
            OAGPXTableSectionData *sectionData = self.tableData.subjects[indexPath.section];
            OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            OASTrkSegment *segment = sectionData.values[@"segment_value"];
            if (analysis && segment)
            {
                [_trackChartHelper refreshChart:lineChartView
                                           fitTrack:YES
                                           forceFit:NO
                                   recalculateXAxis:NO
                                           analysis:analysis
                                            segment:segment];
            }
        }
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
        ElevationChart *lineChartView = (ElevationChart *) recognizer.view;
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
            if (_trackChartHelper)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lineChartView.tag & 0x3FF inSection:lineChartView.tag >> 10];
                OAGPXTableSectionData *sectionData = self.tableData.subjects[indexPath.section];
                OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
                OASTrkSegment *segment = sectionData.values[@"segment_value"];
                if (analysis && segment)
                {
                    [_trackChartHelper refreshChart:lineChartView
                                               fitTrack:YES
                                               forceFit:NO
                                       recalculateXAxis:YES
                                               analysis:analysis
                                                segment:segment];
                }
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
        if (sectionData && _trackChartHelper)
        {
            ElevationChartCell *cell = ((ElevationChartCell *) sectionData.values[@"cell_value"]);
            if (cell)
            {
                [_trackChartHelper changeChartTypes:sectionData.values[@"mode_value"]
                                                  chart:cell.chartView
                                               analysis:sectionData.values[@"analysis_value"]
                                          statsModeCell:nil];
            }
        }
    }
    else if ([tableData.key hasPrefix:@"statistics_"])
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"statistics_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData)
        {
            NSArray<NSNumber *> *types = sectionData.values[@"mode_value"];
            OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            [tableData setData:@{
                    kTableValues: [self getStatisticsDataForAnalysis:analysis
                                                             segment:sectionData.values[@"segment_value"]
                                                               types:types],
                    kCellToggle: @(([types isEqual:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]] && analysis.timeSpan > 0)
                            || ![types isEqual:@[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)]])
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
                NSArray<NSNumber *> *types;
                if (tableData.values.count > selectedIndex && selectedIndex != 0)
                {
                    NSString *value = tableData.values[[NSString stringWithFormat:@"tab_%li_string_value", selectedIndex]];
                    types = [value isEqualToString:OALocalizedString(@"altitude")]
                            ? @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSlope)]
                            : [value isEqualToString:OALocalizedString(@"shared_string_speed")]
                                    ? @[@(GPXDataSetTypeSpeed)]
                                    : @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)];
                }
                else
                {
                    types = @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)];
                }
                sectionData.values[@"mode_value"] = types;

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

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData sourceView:(UIView *)sourceView
{
    if ([tableData.key hasPrefix:@"segment_buttons_"] && self.trackMenuDelegate)
    {
        NSString *segmentKey = [tableData.key stringByReplacingOccurrencesOfString:@"segment_buttons_" withString:@""];
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[@"section_" stringByAppendingString:segmentKey]];
        if (sectionData)
        {
            OASGpxTrackAnalysis *analysis = sectionData.values[@"analysis_value"];
            OASTrkSegment *segment = sectionData.values[@"segment_value"];
            if (analysis && segment)
            {
                if ([tableData.values[@"is_left_button_selected"] boolValue])
                {
                    [self.trackMenuDelegate openAnalysis:analysis
                                                 segment:segment
                                               withTypes:sectionData.values[@"mode_value"]];
                }
                else
                {
                    [self.trackMenuDelegate openEditSegmentScreen:segment
                                                         analysis:analysis];
                }
            }
        }
    }
}

@end
