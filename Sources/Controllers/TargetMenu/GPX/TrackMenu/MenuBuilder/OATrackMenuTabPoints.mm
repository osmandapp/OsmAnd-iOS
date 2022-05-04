//
//  OATrackMenuTabPoints.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabPoints.h"
#import "OASelectionCollapsableCell.h"
#import "OAPointWithRegionTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OADefaultFavorite.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "QuadRect.h"

#import <OsmAndCore/Utilities.h>

@interface OATrackMenuTabPoints ()

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabPoints

@dynamic tableData, isGeneratedData;

- (BOOL)hasWaypoints
{
    if (!self.trackMenuDelegate)
        return NO;

    NSArray<NSString *> *waypointSortedGroupNames = [self.trackMenuDelegate getWaypointSortedGroups];
    return waypointSortedGroupNames.count > ([waypointSortedGroupNames containsObject:OALocalizedString(@"route_points")] ? 1 : 0);
}

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_gpx_points");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_folder_points"];
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudPointsTab;
}

- (QuadRect *)updateQR:(QuadRect *)q1 q2:(QuadRect *)q2 defLat:(CGFloat)defLat defLon:(CGFloat)defLon
{
    BOOL hasQ1 = q1 && q1.left != defLon && q1.top != defLat && q1.right != defLon && q1.bottom != defLat;
    return [[QuadRect alloc] initWithLeft:hasQ1 ? MIN(q1.left, q2.left) : q2.left
                                      top:hasQ1 ? MAX(q1.top, q2.top) : q2.top
                                    right:hasQ1 ? MAX(q1.right, q2.right) : q2.right
                                   bottom:hasQ1 ? MIN(q1.bottom, q2.bottom) : q2.bottom];
}

- (void)updateDistanceAndDirection:(OAGPXTableCellData *)cellData waypoint:(OAGpxWptItem *)waypoint
{
    OsmAndAppInstance app = [OsmAndApp instance];
    CLLocation *newLocation = app.locationServices.lastKnownLocation;
    if (newLocation)
    {
        CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
                (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                        ? newLocation.course : newHeading;

        OsmAnd::LatLon latLon(waypoint.point.position.latitude, waypoint.point.position.longitude);
        const auto &wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        CLLocation *location = [[CLLocation alloc] initWithLatitude:OsmAnd::Utilities::get31LatitudeY(wptPosition31.y)
                                                          longitude:OsmAnd::Utilities::get31LongitudeX(wptPosition31.x)];

        waypoint.distanceMeters = OsmAnd::Utilities::distance(
                newLocation.coordinate.longitude,
                newLocation.coordinate.latitude,
                location.coordinate.longitude,
                location.coordinate.latitude
        );
        waypoint.distance = [OAOsmAndFormatter getFormattedDistance:waypoint.distanceMeters];
        CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:location];
        waypoint.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

        QuadRect *pointRect = [cellData.values.allKeys containsObject:@"quad_rect_value_point_area"]
                ? cellData.values[@"quad_rect_value_point_area"]
                : [[QuadRect alloc] initWithLeft:waypoint.point.position.longitude
                                             top:waypoint.point.position.latitude
                                           right:waypoint.point.position.longitude
                                          bottom:waypoint.point.position.latitude];

        cellData.values[@"quad_rect_value_point_area"] = pointRect;
        cellData.values[@"string_value_distance"] = waypoint.distance ? waypoint.distance : [OAOsmAndFormatter getFormattedDistance:0];
        cellData.values[@"float_value_direction"] = @(waypoint.direction);
    }
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    if (self.trackMenuDelegate)
    {
        for (NSString *groupName in [self.trackMenuDelegate getWaypointSortedGroups])
        {
            NSMutableArray<OAGPXTableCellData *> *cells = [NSMutableArray array];
            OAGPXTableSectionData *waypointsSectionData = [OAGPXTableSectionData withData:@{
                    kTableKey: [NSString stringWithFormat:@"section_waypoints_group_%@", groupName],
                    kTableSubjects: cells,
                    kTableValues: @{
                            @"is_hidden": @(self.trackMenuDelegate
                                    ? ![self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:groupName]
                                            ? @"" : groupName]
                                    : NO),
                            @"regenerate_waypoints": @(NO)
                    }
            }];
            waypointsSectionData.values[@"tint_color"] = [waypointsSectionData.values[@"is_hidden"] boolValue]
                    ? UIColorFromRGB(color_footer_icon_gray)
                    : self.trackMenuDelegate
                            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:groupName])
                            : [OADefaultFavorite getDefaultColor];

            OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                    kTableKey: [NSString stringWithFormat:@"cell_waypoints_group_%@", groupName],
                    kCellType: [OASelectionCollapsableCell getCellIdentifier],
                    kCellTitle: groupName,
                    kCellLeftIcon: [UIImage templateImageNamed:[waypointsSectionData.values[@"is_hidden"] boolValue]
                            ? @"ic_custom_folder_hidden" : @"ic_custom_folder"],
                    kCellRightIconName: @"ic_custom_arrow_up",
                    kCellToggle: @YES,
                    kCellTintColor: @([OAUtilities colorToNumber:waypointsSectionData.values[@"tint_color"]]),
                    kTableValues: @{ @"is_rte": @(self.trackMenuDelegate && [self.trackMenuDelegate isRteGroup:groupName]) }
            }];
            [cells addObject:groupCellData];

            if (self.trackMenuDelegate)
            {
                [cells addObjectsFromArray:[self generateDataForWaypointCells:[self.trackMenuDelegate getWaypointsData][groupName]
                                                                        isRte:[groupCellData.values[@"is_rte"] boolValue]]];
            }

            [self updatePointsQuadRect:waypointsSectionData];
            [tableSections addObject:waypointsSectionData];

            [waypointsSectionData setData:@{
                    kSectionHeaderHeight: tableSections.firstObject == waypointsSectionData ? @0.001 : @14.
            }];
        }
    }

    BOOL hasWaypoints = [self hasWaypoints];
    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"delete_waypoints",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"delete_waypoints"),
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellToggle: @(hasWaypoints),
            kCellTintColor: hasWaypoints ? @color_primary_purple : @unselected_tab_icon,
    }];

    OAGPXTableCellData *addWaypointCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"add_waypoint",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"add_waypoint"),
            kCellRightIconName: @"ic_custom_add_gpx_waypoint",
            kCellToggle: @YES,
            kCellTintColor: @color_primary_purple
    }];

    OAGPXTableSectionData *actionsSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"actions_section",
            kTableSubjects: @[addWaypointCellData, deleteCellData],
            kSectionHeader: OALocalizedString(@"actions"),
            kSectionHeaderHeight: @56.
    }];
    [tableSections addObject:actionsSectionData];

    self.tableData = [OAGPXTableData withData:@{
            kTableKey: @"table_tab_points",
            kTableSubjects: tableSections
    }];

    self.isGeneratedData = YES;
}

- (NSArray<OAGPXTableCellData *> *)generateDataForWaypointCells:(NSArray<OAGpxWptItem *> *)waypoints
                                                          isRte:(BOOL)isRte
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray<OAGPXTableCellData *> *waypointsCells = [NSMutableArray array];
    for (OAGpxWptItem *waypoint in waypoints)
    {
        CLLocationCoordinate2D gpxLocation = self.trackMenuDelegate
                ? [self.trackMenuDelegate getCenterGpxLocation] : kCLLocationCoordinate2DInvalid;
        OAWorldRegion *worldRegion = gpxLocation.latitude != DBL_MAX
                ? [app.worldRegion findAtLat:gpxLocation.latitude lon:gpxLocation.longitude] : nil;

        NSString *name = !isRte
                ? waypoint.point.name
                : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
                        [waypoints indexOfObject:waypoint] + 1];
        OAGPXTableCellData *waypointCellData = [OAGPXTableCellData withData:@{
                kTableKey: [NSString stringWithFormat:@"waypoint_%@", name],
                kCellType: [OAPointWithRegionTableViewCell getCellIdentifier],
                kCellTitle: name,
                kCellDesc: worldRegion != nil
                        ? (worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName)
                        : @"",
                kCellLeftIcon: !isRte ? [waypoint getCompositeIcon]
                        : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                    color:UIColorFromRGB(color_footer_icon_gray)],
                kTableValues: @{
                        @"waypoint": waypoint,
                        @"quad_rect_value_point_area": [[QuadRect alloc] initWithLeft:waypoint.point.position.longitude
                                                                                  top:waypoint.point.position.latitude
                                                                                right:waypoint.point.position.longitude
                                                                               bottom:waypoint.point.position.latitude]
                }
        }];
        [waypointsCells addObject:waypointCellData];
    }
    return waypointsCells;
}

- (void)updatePointsQuadRect:(OAGPXTableSectionData *)waypointsSectionData
{
    QuadRect *pointsRect = nil;
    for (OAGPXTableCellData *cellData in waypointsSectionData.subjects)
    {
        if ([cellData.values.allKeys containsObject:@"quad_rect_value_point_area"])
            pointsRect = [self updateQR:pointsRect q2:cellData.values[@"quad_rect_value_point_area"] defLat:0. defLon:0.];
    }
    if (pointsRect)
        waypointsSectionData.values[@"quad_rect_value_points_area"] = pointsRect;
}

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key hasPrefix:@"waypoint_"] && self.trackMenuDelegate && tableData.values[@"waypoint"])
    {
        OAGPXTableSectionData *sectionData;
        for (OAGPXTableSectionData *sData in self.tableData.subjects)
        {
            if ([sData getSubject:tableData.key])
                sectionData = sData;
        }
        if (sectionData)
        {
            OAGpxWptItem *waypoint = tableData.values[@"waypoint"];
            NSString *name = ![sectionData.subjects.firstObject.values[@"is_rte"] boolValue]
                    ? waypoint.point.name
                    : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
               [sectionData.subjects indexOfObject:tableData]];
            [tableData setData:@{
                    kTableKey: [NSString stringWithFormat:@"waypoint_%@", name],
                    kCellTitle: name,
                    kCellLeftIcon: ![sectionData.subjects.firstObject.values[@"is_rte"] boolValue]
                            ? [waypoint getCompositeIcon]
                            : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                        color:UIColorFromRGB(color_footer_icon_gray)]
            }];
        }
    }
    else if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        OAGPXTableCellData *cellData = (OAGPXTableCellData *) tableData;
        OAGPXTableSectionData *sectionData = [self.tableData getSubject:[NSString stringWithFormat:@"section_waypoints_group_%@", cellData.title]];
        if (sectionData)
        {
            sectionData.values[@"is_hidden"] = @(self.trackMenuDelegate
                    ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                            [self.trackMenuDelegate isDefaultGroup:cellData.title] ? @"" : cellData.title]
                    : NO);
            sectionData.values[@"tint_color"] = [sectionData.values[@"is_hidden"] boolValue]
                    ? UIColorFromRGB(color_footer_icon_gray)
                    : self.trackMenuDelegate
                            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:cellData.title])
                            : [OADefaultFavorite getDefaultColor];

            [cellData setData:@{
                    kTableKey: [NSString stringWithFormat:@"cell_waypoints_group_%@", cellData.title],
                    kCellLeftIcon: [UIImage templateImageNamed:[sectionData.values[@"is_hidden"] boolValue]
                            ? @"ic_custom_folder_hidden" : @"ic_custom_folder"],
                    kCellTintColor: @([OAUtilities colorToNumber:sectionData.values[@"tint_color"]])
            }];
            cellData.values[@"is_rte"] = @(self.trackMenuDelegate && [self.trackMenuDelegate isRteGroup:cellData.title]);
        }
    }
    else if ([tableData.key hasPrefix:@"section_waypoints_group_"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }

        if ([sectionData.values[@"regenerate_waypoints"] boolValue])
        {
            [self updatePointsQuadRect:sectionData];
            sectionData.values[@"regenerate_waypoints"] = @(NO);
        }
    }
    else if ([tableData.key hasPrefix:@"delete_waypoints"])
    {
        BOOL hasWaypoints = [self hasWaypoints];
        [tableData setData:@{
                kCellToggle: @(hasWaypoints),
                kCellTintColor: hasWaypoints ? @color_primary_purple : @unselected_tab_icon
        }];
    }
    else if ([tableData.key hasPrefix:@"actions_section"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key hasPrefix:@"table_tab_points"])
    {
        OAGPXTableData *tData = (OAGPXTableData *) tableData;
        for (OAGPXTableSectionData *sectionData in tData.subjects)
        {
            [self updateData:sectionData];
        }

        [tData.subjects sortUsingComparator:^NSComparisonResult(OAGPXTableSectionData *obj1, OAGPXTableSectionData *obj2) {
            if ([obj2.key isEqualToString:@"actions_section"])
                return NSOrderedAscending;

            NSString *group1 = obj1.subjects.firstObject.key;
            NSString *group2 = obj2.subjects.firstObject.key;
            return [group1 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedDescending
                    : [group2 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedAscending
                            : [group1 compare:group2];
        }];

        for (OAGPXTableSectionData *sectionData in tData.subjects)
        {
            if (![sectionData.key isEqualToString:@"actions_section"])
            {
                [sectionData setData:@{
                        kSectionHeaderHeight: self.tableData.subjects.firstObject == sectionData ? @0.001 : @14.
                }];
            }
        }
    }
}

- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key hasPrefix:@"waypoint_"] && self.trackMenuDelegate && tableData.values[@"waypoint"])
    {
        OAGPXTableCellData *cellData = (OAGPXTableCellData *) tableData;
        if ([value isKindOfClass:NSString.class] && [(NSString *) value isEqualToString:@"update_distance_and_direction"])
            [self updateDistanceAndDirection:cellData waypoint:cellData.values[@"waypoint"]];
    }
    else if ([tableData.key hasPrefix:@"cell_waypoints_group_"])
    {
        if ([value isKindOfClass:NSDictionary.class])
        {
            NSDictionary *dataToUpdate = value;
            OAGPXTableCellData *cellData = (OAGPXTableCellData *) tableData;
            OAGPXTableSectionData *sectionData = [self.tableData getSubject:[NSString stringWithFormat:@"section_waypoints_group_%@", cellData.title]];

            if ([dataToUpdate.allKeys containsObject:@"new_group_name"])
            {
                [tableData setData:@{ kCellTitle: dataToUpdate[@"new_group_name"] }];
                [sectionData setData:@{ kTableKey: [NSString stringWithFormat:@"section_waypoints_group_%@", cellData.title] }];

                sectionData.values[@"is_hidden"] = @(self.trackMenuDelegate
                        ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                                [self.trackMenuDelegate isDefaultGroup:cellData.title] ? @"" : cellData.title]
                        : NO);
            }

            if ([dataToUpdate.allKeys containsObject:@"new_group_color"])
            {
                sectionData.values[@"tint_color"] = [sectionData.values[@"is_hidden"] boolValue]
                        ? UIColorFromRGB(color_footer_icon_gray) : dataToUpdate[@"new_group_color"];
            }

            BOOL hasExist = [dataToUpdate.allKeys containsObject:@"exist_group_name_index"];
            NSInteger existI = [dataToUpdate[@"exist_group_name_index"] integerValue];
            sectionData.values[@"regenerate_waypoints"] = @(hasExist && existI > 0);
        }
    }
    else if ([tableData.key hasPrefix:@"section_waypoints_group_"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateProperty:value tableData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"table_tab_points"])
    {
        if ([value isKindOfClass:NSDictionary.class])
        {
            NSDictionary *dataToUpdate = value;
            OAGPXTableData *tData = (OAGPXTableData *) tableData;

            if ([dataToUpdate.allKeys containsObject:@"delete_group_name_index"])
            {
                NSInteger deleteSectionI = [dataToUpdate[@"delete_group_name_index"] integerValue];
                if (deleteSectionI != NSNotFound)
                {
                    NSMutableArray *cells = tData.subjects[deleteSectionI].subjects;
                    NSArray<NSNumber *> *waypointsIdxToDelete = dataToUpdate[@"delete_waypoints_idx"];
                    if (cells.count - 1 == waypointsIdxToDelete.count)
                    {
                        [tData.subjects removeObjectAtIndex:deleteSectionI];
                    }
                    else
                    {
                        for (NSNumber *waypointIdToDelete in waypointsIdxToDelete)
                        {
                            [cells removeObjectAtIndex:waypointIdToDelete.intValue + 1];
                        }
                    }
                }
            }
            else
            {
                BOOL hasExist = [dataToUpdate.allKeys containsObject:@"exist_group_name_index"];
                BOOL hasNew = [dataToUpdate.allKeys containsObject:@"new_group_name_index"];
                NSInteger oldI = [dataToUpdate[@"old_group_name_index"] integerValue];
                NSInteger existI = [dataToUpdate[@"exist_group_name_index"] integerValue];
                NSInteger newI = [dataToUpdate[@"new_group_name_index"] integerValue];
                if (oldI != NSNotFound && newI != NSNotFound)
                {
                    if (hasExist && existI != NSNotFound && hasNew)
                    {
                        NSInteger extraCellsIndex = existI == newI + 1 ? oldI : newI == existI ? oldI : existI;
                        NSMutableArray *cells = tData.subjects[existI == newI + 1 ? existI : newI].subjects;
                        NSMutableArray *extraCells = tData.subjects[extraCellsIndex].subjects;
                        [extraCells removeObjectAtIndex:0];
                        [cells addObjectsFromArray:extraCells];
                        [tData.subjects removeObjectAtIndex:extraCellsIndex];
                    }
                    else if ((!hasExist || existI != NSNotFound) && hasNew)
                    {
                        OAGPXTableSectionData *groupSectionData = tData.subjects[oldI];
                        [tData.subjects removeObjectAtIndex:oldI];
                        [tData.subjects insertObject:groupSectionData atIndex:newI];
                    }

                    if (hasNew && existI != NSNotFound)
                    {
                        OAGPXTableSectionData *groupSectionData = tData.subjects[existI == newI ? existI : newI];
                        [self updateProperty:value tableData:groupSectionData];
                    }
                    else
                    {
                        OAGPXTableSectionData *groupSectionData = tData.subjects[oldI];
                        [self updateProperty:value tableData:groupSectionData];
                    }
                }
            }
        }
    }
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key hasPrefix:@"cell_waypoints_group_"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openWaypointsGroupOptionsScreen:((OAGPXTableCellData *) tableData).title];
    }
    else if ([tableData.key hasPrefix:@"waypoint_"] && self.trackMenuDelegate && tableData.values[@"waypoint"])
    {
        [self.trackMenuDelegate openWptOnMap:tableData.values[@"waypoint"]];
    }
    else if ([tableData.key hasPrefix:@"delete_waypoints"])
    {
        OAGPXTableCellData *cellData = (OAGPXTableCellData *) tableData;
        if (cellData.toggle)
        {
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate stopLocationServices];

            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openDeleteWaypointsScreen:self.tableData];
        }
    }
    else if ([tableData.key hasPrefix:@"add_waypoint"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openNewWaypointScreen];
    }
}

@end
