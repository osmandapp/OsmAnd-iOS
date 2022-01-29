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

@end

@implementation OATrackMenuTabSegments
{
    OARouteLineChartHelper *_routeLineChartHelper;

    BOOL _hasTranslated;
    CGPoint _lastTranslation;
    double _highlightDrawX;
}

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
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    NSDictionary<NSString *, NSDictionary *> *segments = self.trackMenuDelegate ? [self.trackMenuDelegate updateSegmentsData] : [NSDictionary dictionary];
    if (!_routeLineChartHelper)
        _routeLineChartHelper = self.trackMenuDelegate ? [self.trackMenuDelegate getLineChartHelper] : nil;

    for (NSInteger index = 0; index < segments.count; index++)
    {
        NSDictionary *segmentDict = segments[[NSString stringWithFormat:@"segment_%li", index]];
        OAGpxTrkSeg *segment = segmentDict[@"segment"];
        OAGPXTrackAnalysis *analysis = segmentDict[@"analysis"];
        __block EOARouteStatisticsMode mode = EOARouteStatisticsModeAltitudeSpeed;

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
            [_routeLineChartHelper changeChartMode:mode
                                             chart:cell.lineChartView
                                          analysis:analysis
                                          modeCell:nil];
        }

        for (UIGestureRecognizer *recognizer in cell.lineChartView.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
            {
                [recognizer addTarget:self action:@selector(onBarChartScrolled:)];
                recognizer.delegate = self;
            }

            [recognizer addTarget:self action:@selector(onChartGesture:)];
        }

        NSString *segmentTitle = nil;
        if (self.trackMenuDelegate)
            segmentTitle = [self.trackMenuDelegate getTrackSegmentTitle:segment];
        if (!segmentTitle)
            segmentTitle = [NSString stringWithFormat:OALocalizedString(@"segnet_num"), index];

        OAGPXTableCellData *segmentCellData = index != 0 ? [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"segment_%li", index],
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: segmentTitle,
                kCellToggle: @NO
        }] : nil;

        CLLocationCoordinate2D startChartPoint = self.trackMenuDelegate && [self.trackMenuDelegate openedFromMap]
                ? [self.trackMenuDelegate getPinLocation] : kCLLocationCoordinate2DInvalid;

        OAGPXTableCellData *chartCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"chart_%li", index],
                kCellType: [OALineChartCell getCellIdentifier],
                kTableValues: @{
                        @"cell_value": cell,
                        @"segment_value": segment,
                        @"points_value": _routeLineChartHelper
                                ? [_routeLineChartHelper generateTrackChartPoints:cell.lineChartView
                                                                       startPoint:startChartPoint
                                                                         segment:segment]
                                : [[OATrackChartPoints alloc] init],
                        @"additional_actions": ^() {
                            if (_routeLineChartHelper)
                            {
                                [_routeLineChartHelper refreshHighlightOnMap:NO
                                                               lineChartView:cell.lineChartView
                                                            trackChartPoints:chartCellData.values[@"points_value"]
                                                                    segment:segment];
                            }
                            if (self.trackMenuDelegate)
                                [self.trackMenuDelegate updateChartHighlightValue:cell.lineChartView segment:segment];
                        }
                }
        }];
        chartCellData.updateData = ^() {
            if (_routeLineChartHelper)
            {
                [_routeLineChartHelper changeChartMode:mode
                                                 chart:cell.lineChartView
                                              analysis:analysis
                                              modeCell:nil];
            }
        };

        OAGPXTableCellData *statisticsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"statistics_%li", index],
                kCellType: [OAQuadItemsWithTitleDescIconCell getCellIdentifier],
                kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment mode:mode],
                kCellToggle: @((mode == EOARouteStatisticsModeAltitudeSpeed && analysis.timeSpan > 0)
                        || mode != EOARouteStatisticsModeAltitudeSpeed)
        }];
        statisticsCellData.updateData = ^() {
            [statisticsCellData setData:@{
                    kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment mode:mode],
                    kCellToggle: @((mode == EOARouteStatisticsModeAltitudeSpeed && analysis.timeSpan > 0)
                            || mode != EOARouteStatisticsModeAltitudeSpeed)
            }];
        };

        OAGPXTableCellData *tabsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"tabs_%li", index],
                kCellType: [OASegmentTableViewCell getCellIdentifier]
        }];
        tabsCellData.updateData = ^() {
            NSInteger selectedIndex = [tabsCellData.values[@"selected_index_int_value"] integerValue];
            if (selectedIndex != NSNotFound)
            {
                if (selectedIndex == 0)
                {
                    mode = EOARouteStatisticsModeAltitudeSpeed;
                }
                else if (tabsCellData.values.count > selectedIndex)
                {
                    NSString *value = tabsCellData.values[[NSString stringWithFormat:@"tab_%li_string_value", selectedIndex]];
                    mode = [value isEqualToString:OALocalizedString(@"map_widget_altitude")]
                            ? EOARouteStatisticsModeAltitudeSlope
                            : [value isEqualToString:OALocalizedString(@"gpx_speed")]
                                    ? EOARouteStatisticsModeSpeed
                                    : EOARouteStatisticsModeAltitudeSpeed;
                }

                if (chartCellData.updateData)
                    chartCellData.updateData();

                if (statisticsCellData.updateData)
                    statisticsCellData.updateData();
            }
        };

        OAGPXTableCellData *buttonsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"buttons_%li", index],
                kCellType: [OARadiusCellEx getCellIdentifier],
                kTableValues: @{
                        @"left_title_string_value": OALocalizedString(@"analyze_on_map"),
                        @"right_title_string_value": OALocalizedString(@"shared_string_options"),
                        @"right_icon_string_value": @"ic_custom_overflow_menu",
                        @"left_on_button_pressed":  ^() {
                            if (self.trackMenuDelegate)
                                [self.trackMenuDelegate openAnalysis:analysis withMode:mode];
                        },
                        @"right_on_button_pressed": ^() {
                            if (self.trackMenuDelegate)
                                [self.trackMenuDelegate openEditSegmentScreen:segment
                                                                     analysis:analysis];
                        }
                },
                kCellToggle: @(!segment.generalSegment)
        }];

        NSMutableArray<OAGPXTableCellData *> *segmentCells = [NSMutableArray array];
        if (segmentCellData != nil)
            [segmentCells addObject:segmentCellData];
        [segmentCells addObject:tabsCellData];

        LineChartData *lineData = cell.lineChartView.lineData;
        NSInteger entryCount = lineData ? lineData.entryCount : 0;
        if (entryCount > 0)
            [segmentCells addObject:chartCellData];

        [segmentCells addObject:statisticsCellData];
        [segmentCells addObject:buttonsCellData];

        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        values[@"tab_0_string_value"] = OALocalizedString(@"shared_string_overview");
        if (analysis.hasElevationData)
            values[@"tab_1_string_value"] = OALocalizedString(@"map_widget_altitude");
        if (analysis.isSpeedSpecified)
            values[analysis.hasElevationData ? @"tab_2_string_value" : @"tab_1_string_value"] = OALocalizedString(@"gpx_speed");
        values[@"row_to_update_int_value"] = @([segmentCells indexOfObject:statisticsCellData]);
        values[@"selected_index_int_value"] = @0;
        [tabsCellData setData:@{ kTableValues: values }];

        OAGPXTableSectionData *segmentSectionData = [OAGPXTableSectionData withData:@{ kSectionCells: segmentCells }];
        [tableSections addObject:segmentSectionData];
        [segmentSectionData setData:@{
                kSectionHeaderHeight: tableSections.firstObject == segmentSectionData ? @0.001 : @36.
        }];
        segmentSectionData.updateData = ^() {
            if ([segmentSectionData.values[@"delete_section_bool_value"] boolValue])
            {
                NSMutableArray<OAGPXTableSectionData *> *newTableData = [self.tableData.sections mutableCopy];
                [newTableData removeObject:segmentSectionData];
                [self.tableData setData:@{ kTableSections: newTableData }];
            }
            else
            {
                for (OAGPXTableCellData *cellData in segmentSectionData.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
        };

        cell.lineChartView.tag =
                [tableSections indexOfObject:segmentSectionData] << 10 | [segmentCells indexOfObject:chartCellData];
    }

    self.tableData = [OAGPXTableData withData: @{ kTableSections: tableSections }];
    self.tableData.updateData = ^() {
        for (OAGPXTableSectionData *sectionData in tableSections)
        {
            if (sectionData.updateData)
                sectionData.updateData();
        }
    };
}

- (void)runAdditionalActions
{
    if (self.tableData.sections.count > 0)
    {
        OAGPXTableSectionData *segmentsSectionData = self.tableData.sections.firstObject;
        for (OAGPXTableCellData *segmentCellData in segmentsSectionData.cells)
        {
            if ([segmentCellData.type isEqualToString:[OALineChartCell getCellIdentifier]]
                && [segmentCellData.values.allKeys containsObject:@"additional_actions"])
            {
                void (^runAdditionalActions)() = segmentCellData.values[@"additional_actions"];
                runAdditionalActions();
            }
        }
    }
}

- (NSDictionary<NSString *, NSDictionary *> *)getStatisticsDataForAnalysis:(OAGPXTrackAnalysis *)analysis
                                                                   segment:(OAGpxTrkSeg *)segment
                                                                      mode:(EOARouteStatisticsMode)mode
{
    NSMutableDictionary *titles = [NSMutableDictionary dictionary];
    NSMutableDictionary *icons = [NSMutableDictionary dictionary];
    NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];

    OAGpxTrk *track = self.trackMenuDelegate ? [self.trackMenuDelegate getTrack:segment] : nil;
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
                            !joinSegments && track && track.generalTrack ? analysis.timeSpanWithoutGaps : analysis.timeSpan
                                                                                                    shortFormat:YES];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistance];

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
    for (OAGPXTableSectionData *sectionData in self.tableData.sections)
    {
        for (OAGPXTableCellData *cellData in sectionData.cells)
        {
            if ([cellData.type isEqualToString:[OALineChartCell getCellIdentifier]])
            {
                OALineChartCell *chartCell = cellData.values[@"cell_value"];
                if (chartCell)
                    [chartCell.lineChartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix
                                                                            chart:chartCell.lineChartView
                                                                       invalidate:YES];
            }
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
    OAGPXTableCellData *cellData = self.tableData.sections[indexPath.section].cells[indexPath.row];

    if (_routeLineChartHelper)
    {
        OAGpxTrkSeg *segment = cellData.values[@"segment_value"];
        [_routeLineChartHelper refreshHighlightOnMap:NO
                                       lineChartView:(LineChartView *) chartView
                                    trackChartPoints:cellData.values[@"points_value"]
                                             segment:segment];
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
            OAGPXTableCellData *cellData = self.tableData.sections[indexPath.section].cells[indexPath.row];

            if (_routeLineChartHelper)
            {
                OAGpxTrkSeg *segment = cellData.values[@"segment_value"];
                [_routeLineChartHelper refreshHighlightOnMap:YES
                                               lineChartView:lineChartView
                                            trackChartPoints:cellData.values[@"points_value"]
                                                    segment:segment];
            }
        }
    }
}

@end
