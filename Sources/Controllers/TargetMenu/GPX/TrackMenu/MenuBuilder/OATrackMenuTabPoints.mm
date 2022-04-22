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
        
        [cellData setData:@{
                kTableValues: @{
                        @"quad_rect_value_point_area": pointRect,
                        @"string_value_distance": waypoint.distance ? waypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                        @"float_value_direction": @(waypoint.direction)
                }
        }];
    }
}

- (void)generateData
{
    __block NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];
    OsmAndAppInstance app = [OsmAndApp instance];

    if (self.trackMenuDelegate)
    {
        for (NSString *groupName in [self.trackMenuDelegate getWaypointSortedGroups])
        {
            __block NSString *currentGroupName = groupName;
            NSMutableArray<OAGPXTableCellData *> *cells = [NSMutableArray array];
            OAGPXTableSectionData *waypointsSectionData = [OAGPXTableSectionData withData:@{
                    kTableDataKey: [NSString stringWithFormat:@"group_%@_section", currentGroupName],
                    kSectionCells: cells
            }];
            BOOL isRte = self.trackMenuDelegate && [self.trackMenuDelegate isRteGroup:currentGroupName];
            __block BOOL regenerateWaypoints = NO;
            __block BOOL isHidden = self.trackMenuDelegate
                    ? ![self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:currentGroupName]
                            ? @"" : currentGroupName] : NO;
            __block UIColor *tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                    : self.trackMenuDelegate
                            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:currentGroupName])
                            : [OADefaultFavorite getDefaultColor];

            OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                    kTableDataKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
                    kCellType: [OASelectionCollapsableCell getCellIdentifier],
                    kCellTitle: currentGroupName,
                    kCellLeftIcon: [UIImage templateImageNamed:
                            isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"],
                    kCellRightIconName: @"ic_custom_arrow_up",
                    kCellToggle: @YES,
                    kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                    kTableValues: @{
                        @"extra_button_pressed_value": ^() {
                            if (self.trackMenuDelegate)
                                [self.trackMenuDelegate openWaypointsGroupOptionsScreen:currentGroupName];
                        }
                   }
            }];
            [cells addObject:groupCellData];

            NSArray<OAGPXTableCellData *> *(^generateDataForWaypointCells)(NSArray<OAGpxWptItem *> *) =
                    ^(NSArray<OAGpxWptItem *> *currentWaypoints) {
                NSMutableArray<OAGPXTableCellData *> *waypointsCells = [NSMutableArray array];
                for (OAGpxWptItem *currentWaypoint in currentWaypoints)
                 {
                     CLLocationCoordinate2D gpxLocation = self.trackMenuDelegate
                             ? [self.trackMenuDelegate getCenterGpxLocation] : kCLLocationCoordinate2DInvalid;
                     OAWorldRegion *worldRegion = gpxLocation.latitude != DBL_MAX
                             ? [app.worldRegion findAtLat:gpxLocation.latitude lon:gpxLocation.longitude] : nil;

                     OAGPXTableCellData *waypointCellData = [OAGPXTableCellData withData:@{
                             kTableDataKey: [NSString stringWithFormat:@"waypoint_%@", currentWaypoint.point.name],
                             kCellType: [OAPointWithRegionTableViewCell getCellIdentifier],
                             kCellTitle: !isRte ? currentWaypoint.point.name
                                     : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
                                             [currentWaypoints indexOfObject:currentWaypoint] + 1],
                             kCellDesc: worldRegion != nil
                                     ? (worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName)
                                     : @"",
                             kCellLeftIcon: !isRte ? [currentWaypoint getCompositeIcon]
                                     : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                                 color:UIColorFromRGB(color_footer_icon_gray)],
                             kTableValues: @{ @"quad_rect_value_point_area": [[QuadRect alloc] initWithLeft:currentWaypoint.point.position.longitude
                                                                                              top:currentWaypoint.point.position.latitude
                                                                                            right:currentWaypoint.point.position.longitude
                                                                                           bottom:currentWaypoint.point.position.latitude]}
                     }];
                     waypointCellData.onButtonPressed = ^{
                         if (self.trackMenuDelegate)
                             [self.trackMenuDelegate openWptOnMap:currentWaypoint];
                     };

                     waypointCellData.updateProperty = ^(id value) {
                         if ([value isKindOfClass:NSString.class])
                         {
                             if ([(NSString *) value isEqualToString:@"update_distance_and_direction"])
                                 [self updateDistanceAndDirection:waypointCellData waypoint:currentWaypoint];
                         }
                     };
                     waypointCellData.updateData = ^() {
                         [waypointCellData setData:@{
                                 kTableDataKey: [NSString stringWithFormat:@"waypoint_%@", currentWaypoint.point.name],
                                 kCellTitle: !isRte
                                         ? currentWaypoint.point.name
                                         : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
                                                 [currentWaypoints indexOfObject:currentWaypoint] + 1],
                                 kCellLeftIcon: !isRte
                                         ? [currentWaypoint getCompositeIcon]
                                         : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                                     color:UIColorFromRGB(color_footer_icon_gray)]
                         }];
                         waypointCellData.onButtonPressed = ^{
                             if (self.trackMenuDelegate)
                                 [self.trackMenuDelegate openWptOnMap:currentWaypoint];
                         };
                     };
                     [waypointsCells addObject:waypointCellData];
                 }
                return waypointsCells;
            };

            if (self.trackMenuDelegate)
                [cells addObjectsFromArray:generateDataForWaypointCells([self.trackMenuDelegate getWaypointsData][currentGroupName])];

            void (^updatePointsQuadRect) (void) = ^{
                QuadRect *pointsRect = nil;
                for (OAGPXTableCellData *cellData in waypointsSectionData.cells)
                {
                    if ([cellData.values.allKeys containsObject:@"quad_rect_value_point_area"])
                        pointsRect = [self updateQR:pointsRect q2:cellData.values[@"quad_rect_value_point_area"] defLat:0. defLon:0.];
                }
                if (pointsRect)
                    [waypointsSectionData setData:@{ kTableValues: @{ @"quad_rect_value_points_area": pointsRect } }];
            };

            updatePointsQuadRect();

            groupCellData.updateData = ^() {
                isHidden = self.trackMenuDelegate
                        ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                                [self.trackMenuDelegate isDefaultGroup:currentGroupName] ? @"" : currentGroupName]
                        : NO;
                tintColor = isHidden
                        ? UIColorFromRGB(color_footer_icon_gray)
                        : self.trackMenuDelegate
                                ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:currentGroupName])
                                : [OADefaultFavorite getDefaultColor];

                [groupCellData setData:@{
                        kTableDataKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
                        kCellTitle: currentGroupName,
                        kCellLeftIcon: [UIImage templateImageNamed:
                                isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"],
                        kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                        kTableValues: @{
                                @"extra_button_pressed_value": ^() {
                                    if (self.trackMenuDelegate)
                                        [self.trackMenuDelegate openWaypointsGroupOptionsScreen:currentGroupName];
                                }
                        }
                }];
            };
            groupCellData.updateProperty = ^(id value) {
                if ([value isKindOfClass:NSDictionary.class])
                {
                    NSDictionary *dataToUpdate = value;

                    if ([dataToUpdate.allKeys containsObject:@"new_group_name"])
                    {
                        currentGroupName = dataToUpdate[@"new_group_name"];

                        [waypointsSectionData setData:@{
                                kTableDataKey: [NSString stringWithFormat:@"group_%@_section", currentGroupName]
                        }];

                        isHidden = self.trackMenuDelegate
                                ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                                        [self.trackMenuDelegate isDefaultGroup:currentGroupName] ? @"" : currentGroupName]
                                : NO;
                    }

                    if ([dataToUpdate.allKeys containsObject:@"new_group_color"])
                        tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray) : dataToUpdate[@"new_group_color"];

                    BOOL hasExist = [dataToUpdate.allKeys containsObject:@"exist_group_name_index"];
                    NSInteger existI = [dataToUpdate[@"exist_group_name_index"] integerValue];
                    regenerateWaypoints = hasExist && existI > 0;
                }
            };

            [tableSections addObject:waypointsSectionData];

            [waypointsSectionData setData:@{
                    kSectionHeaderHeight: tableSections.firstObject == waypointsSectionData ? @0.001 : @14.
            }];
            waypointsSectionData.updateData = ^() {
                for (OAGPXTableCellData *cellData in waypointsSectionData.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }

                if (regenerateWaypoints)
                {
                    updatePointsQuadRect();
                    regenerateWaypoints = NO;
                }
            };
            waypointsSectionData.updateProperty = ^(id value) {
                for (OAGPXTableCellData *cellData in cells)
                {
                    if (cellData.updateProperty)
                        cellData.updateProperty(value);
                }
            };
        }
    }

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"delete_waypoints",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"delete_waypoints"),
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellToggle: @([self hasWaypoints]),
            kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon,
    }];
    deleteCellData.onButtonPressed = ^{
        if (deleteCellData.toggle)
        {
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate stopLocationServices];

            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openDeleteWaypointsScreen:self.tableData];
        }
    };
    deleteCellData.updateData = ^() {
        [deleteCellData setData:@{
                kCellToggle: @([self hasWaypoints]),
                kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon
        }];
    };

    OAGPXTableCellData *addWaypointCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"add_waypoint",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"add_waypoint"),
            kCellRightIconName: @"ic_custom_add_gpx_waypoint",
            kCellToggle: @YES,
            kCellTintColor: @color_primary_purple
    }];
    addWaypointCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openNewWaypointScreen];
    };

    OAGPXTableSectionData *actionsSectionData = [OAGPXTableSectionData withData:@{
            kTableDataKey: @"actions_section",
            kSectionCells: @[addWaypointCellData, deleteCellData],
            kSectionHeader: OALocalizedString(@"actions"),
            kSectionHeaderHeight: @56.
    }];
    actionsSectionData.updateData = ^() {
        for (OAGPXTableCellData *cellData in actionsSectionData.cells)
        {
            if (cellData.updateData)
                cellData.updateData();
        }
    };

    [tableSections addObject:actionsSectionData];

    self.tableData = [OAGPXTableData withData:@{ kTableSections: tableSections }];
    self.tableData.updateData = ^() {
        for (OAGPXTableSectionData *sectionData in tableSections)
        {
            if (sectionData.updateData)
                sectionData.updateData();
        }

        [tableSections sortUsingComparator:^NSComparisonResult(OAGPXTableSectionData *obj1, OAGPXTableSectionData *obj2) {
            if (obj2 == actionsSectionData)
                return NSOrderedAscending;

            NSString *group1 = obj1.cells.firstObject.key;
            NSString *group2 = obj2.cells.firstObject.key;
            return [group1 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedDescending
                    : [group2 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedAscending
                            : [group1 compare:group2];
        }];

        for (OAGPXTableSectionData *sectionData in self.tableData.sections)
        {
            if (sectionData != actionsSectionData)
            {
                [sectionData setData:@{
                        kSectionHeaderHeight: self.tableData.sections.firstObject == sectionData ? @0.001 : @14.
                }];
            }
        }
    };
    self.tableData.updateProperty = ^(id value) {
        if ([value isKindOfClass:NSDictionary.class])
        {
            NSDictionary *dataToUpdate = value;
            if ([dataToUpdate.allKeys containsObject:@"delete_group_name_index"])
            {
                NSInteger deleteSectionI = [dataToUpdate[@"delete_group_name_index"] integerValue];
                if (deleteSectionI != NSNotFound)
                {
                    NSMutableArray *cells = tableSections[deleteSectionI].cells;
                    NSArray<NSNumber *> *waypointsIdxToDelete = dataToUpdate[@"delete_waypoints_idx"];
                    if (cells.count - 1 == waypointsIdxToDelete.count)
                    {
                        [tableSections removeObjectAtIndex:deleteSectionI];
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
                        NSMutableArray *cells = tableSections[existI == newI + 1 ? existI : newI].cells;
                        NSMutableArray *extraCells = tableSections[extraCellsIndex].cells;
                        [extraCells removeObjectAtIndex:0];
                        [cells addObjectsFromArray:extraCells];
                        [tableSections removeObjectAtIndex:extraCellsIndex];
                    }
                    else if ((!hasExist || existI != NSNotFound) && hasNew)
                    {
                        OAGPXTableSectionData *groupSectionData = tableSections[oldI];
                        [tableSections removeObjectAtIndex:oldI];
                        [tableSections insertObject:groupSectionData atIndex:newI];
                    }

                    if (hasNew && existI != NSNotFound)
                    {
                        OAGPXTableSectionData *groupSectionData = tableSections[existI == newI ? existI : newI];
                        if (groupSectionData.updateProperty)
                            groupSectionData.updateProperty(value);
                    }
                    else
                    {
                        OAGPXTableSectionData *groupSectionData = tableSections[oldI];
                        if (groupSectionData.updateProperty)
                            groupSectionData.updateProperty(value);
                    }
                }
            }
        }
    };

    self.isGeneratedData = YES;
}

@end
