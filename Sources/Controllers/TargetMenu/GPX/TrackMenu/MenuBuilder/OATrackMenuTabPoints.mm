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

@end

@implementation OATrackMenuTabPoints

- (BOOL)hasWaypoints
{
    NSMutableArray<NSString *> *waypointSortedGroupNames = self.trackMenuDelegate
            ? [[self.trackMenuDelegate getWaypointSortedGroups] mutableCopy] : [NSMutableArray array];
    [waypointSortedGroupNames removeObject:OALocalizedString(@"route_points")];
    return waypointSortedGroupNames.count > 0;
}

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_gpx_points");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_folder_points"];
}

- (QuadRect *)updateQR:(QuadRect *)q p:(OAGpxWpt *)p defLat:(CGFloat)defLat defLon:(CGFloat)defLon
{
    if (q.left == defLon && q.top == defLat &&
            q.right == defLon && q.bottom == defLat)
    {
        return [[QuadRect alloc] initWithLeft:p.position.longitude
                                          top:p.position.latitude
                                        right:p.position.longitude
                                       bottom:p.position.latitude];
    }
    else
    {
        return [[QuadRect alloc] initWithLeft:MIN(q.left, p.position.longitude)
                                          top:MAX(q.top, p.position.latitude)
                                        right:MAX(q.right, p.position.longitude)
                                       bottom:MIN(q.bottom, p.position.latitude)];
    }
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudPointsTab;
}

- (void)generateData
{
    __block NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];
    OsmAndAppInstance app = [OsmAndApp instance];

    NSArray<NSString *> *waypointSortedGroupNames = self.trackMenuDelegate
            ? [self.trackMenuDelegate getWaypointSortedGroups] : [NSArray array];

    if (waypointSortedGroupNames.count > 0)
    {
        for (NSString *groupName in waypointSortedGroupNames)
        {
            NSMutableArray<OAGPXTableCellData *> *cellsData = [NSMutableArray array];
            OAGPXTableSectionData *waypointsSection = [OAGPXTableSectionData withData:@{ kSectionCells: cellsData }];
            __block NSString *currentGroupName = groupName;
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
                    kCellKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
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
            [cellsData addObject:groupCellData];

            NSArray<OAGPXTableCellData *> *(^generateDataForWaypointCells)(NSArray<OAGpxWptItem *> *) =
                    ^(NSArray<OAGpxWptItem *> *currentWaypoints) {
                NSMutableArray<OAGPXTableCellData *> *waypointsData = [NSMutableArray array];
                for (OAGpxWptItem *currentWaypoint in currentWaypoints)
                 {
                    CLLocationCoordinate2D gpxLocation = self.trackMenuDelegate
                            ? [self.trackMenuDelegate getCenterGpxLocation] : kCLLocationCoordinate2DInvalid;
                    OAWorldRegion *worldRegion = gpxLocation.latitude != DBL_MAX
                            ? [app.worldRegion findAtLat:gpxLocation.latitude lon:gpxLocation.longitude] : nil;

                    OAGPXTableCellData *waypointCellData = [OAGPXTableCellData withData:@{
                            kCellKey: [NSString stringWithFormat:@"waypoint_%@", currentWaypoint.point.name],
                            kCellType: [OAPointWithRegionTableViewCell getCellIdentifier],
                            kTableValues: @{
                                    @"string_value_distance": currentWaypoint.distance
                                            ? currentWaypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                                    @"float_value_direction": @(currentWaypoint.direction)
                            },
                            kCellTitle: !isRte ? currentWaypoint.point.name
                                    : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
                                            [currentWaypoints indexOfObject:currentWaypoint] + 1],
                            kCellDesc: worldRegion != nil
                                    ? (worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName)
                                    : @"",
                            kCellLeftIcon: !isRte ? [currentWaypoint getCompositeIcon]
                                    : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                                color:UIColorFromRGB(color_footer_icon_gray)],
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openWptOnMap:currentWaypoint];
                            }
                    }];
                    [waypointCellData setData:@{
                            kTableUpdateData: ^() {
                                CLLocation *newLocation = app.locationServices.lastKnownLocation;
                                if (newLocation)
                                {
                                    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
                                    CLLocationDirection newDirection =
                                            (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                                                    ? newLocation.course : newHeading;

                                    OsmAnd::LatLon latLon(currentWaypoint.point.position.latitude,
                                            currentWaypoint.point.position.longitude);
                                    const auto &wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
                                    const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
                                    const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);

                                    const auto distance = OsmAnd::Utilities::distance(
                                            newLocation.coordinate.longitude,
                                            newLocation.coordinate.latitude,
                                            wptLon,
                                            wptLat
                                    );

                                    currentWaypoint.distance = [OAOsmAndFormatter getFormattedDistance:distance];
                                    currentWaypoint.distanceMeters = distance;
                                    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[
                                            [CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
                                    currentWaypoint.direction =
                                            OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
                                }

                                [waypointCellData setData:@{
                                        kCellKey: [NSString stringWithFormat:@"waypoint_%@", currentWaypoint.point.name],
                                        kTableValues: @{
                                                @"string_value_distance": currentWaypoint.distance
                                                        ? currentWaypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                                                @"float_value_direction": @(currentWaypoint.direction)
                                        },
                                        kCellTitle: !isRte ? currentWaypoint.point.name
                                                : [NSString stringWithFormat:@"%@ %lu", OALocalizedString(@"gpx_point"),
                                                        [currentWaypoints indexOfObject:currentWaypoint] + 1],
                                        kCellLeftIcon: !isRte ? [currentWaypoint getCompositeIcon]
                                                : [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_location_marker"]
                                                                            color:UIColorFromRGB(color_footer_icon_gray)],
                                        kCellButtonPressed: ^{
                                            if (self.trackMenuDelegate)
                                                [self.trackMenuDelegate openWptOnMap:currentWaypoint];
                                        }
                                }];
                            },
                    }];
                    [waypointsData addObject:waypointCellData];
                }
                return waypointsData;
            };

            __block NSArray<OAGpxWptItem *> *waypoints = [self.trackMenuDelegate getWaypointsData][currentGroupName];
            if (self.trackMenuDelegate)
                [cellsData addObjectsFromArray:generateDataForWaypointCells(waypoints)];

            QuadRect *(^getQuadRectForSelectedGroup)(NSArray<OAGpxWptItem *> *) =
                    ^(NSArray<OAGpxWptItem *> *currentWaypoints) {
                QuadRect *pointsRect = nil;

                if (!currentWaypoints || currentWaypoints.count == 0)
                    return pointsRect;

                OAGpxWpt *p = currentWaypoints.firstObject.point;
                pointsRect = [[QuadRect alloc] initWithLeft:p.position.longitude
                                                        top:p.position.latitude
                                                      right:p.position.longitude
                                                     bottom:p.position.latitude];
                if (currentWaypoints.count > 1)
                {
                    for (OAGpxWptItem *waypoint in waypoints)
                    {
                        pointsRect = [self updateQR:pointsRect p:waypoint.point defLat:0. defLon:0.];
                    }
                }

                return pointsRect;
            };

            [waypointsSection setData:@{
                    kTableValues: @{ @"points_quad_rect_value": getQuadRectForSelectedGroup(waypoints) }
            }];

            [groupCellData setData:@{
                    kTableUpdateData: ^() {
                        if (regenerateWaypoints)
                        {
                            if (self.trackMenuDelegate)
                                waypoints = [self.trackMenuDelegate getWaypointsData][currentGroupName];

                            NSMutableArray *newCellsData = [NSMutableArray array];
                            [newCellsData addObject:groupCellData];
                            [newCellsData addObjectsFromArray:generateDataForWaypointCells(waypoints)];
                            [waypointsSection setData:@{
                                    kSectionCells: newCellsData,
                                    kTableValues: @{ @"points_quad_rect_value": getQuadRectForSelectedGroup(waypoints) }
                            }];
                            regenerateWaypoints = NO;
                        }

                        isHidden = self.trackMenuDelegate ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                                [self.trackMenuDelegate isDefaultGroup:currentGroupName] ? @"" : currentGroupName] : NO;
                        tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                                : self.trackMenuDelegate
                                        ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:currentGroupName])
                                        : [OADefaultFavorite getDefaultColor];

                        [groupCellData setData:@{
                                kCellKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
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
                    },
                    kTableUpdateProperty: ^(id value) {
                        if ([value isKindOfClass:NSDictionary.class])
                        {
                            NSDictionary *dataToUpdate = value;

                            if ([dataToUpdate.allKeys containsObject:@"new_group_name"])
                            {
                                currentGroupName = dataToUpdate[@"new_group_name"];
                                isHidden = self.trackMenuDelegate ? ![self.trackMenuDelegate isWaypointsGroupVisible:
                                        [self.trackMenuDelegate isDefaultGroup:currentGroupName] ? @"" : currentGroupName] : NO;
                            }

                            if ([dataToUpdate.allKeys containsObject:@"new_group_color"])
                                tintColor = isHidden
                                        ? UIColorFromRGB(color_footer_icon_gray) : dataToUpdate[@"new_group_color"];

                            BOOL hasExist = [dataToUpdate.allKeys containsObject:@"exist_group_name_index"];
                            NSInteger existI = [dataToUpdate[@"exist_group_name_index"] integerValue];
                            regenerateWaypoints = (hasExist && existI > 0) || [dataToUpdate[@"regenerate_bool_value"] boolValue];
                        }
                    }
            }];

            [tableSections addObject:waypointsSection];

            [waypointsSection setData:@{
                    kTableUpdateData: ^() {
                        for (OAGPXTableCellData *cellData in waypointsSection.cells)
                        {
                            if (cellData.updateData)
                                cellData.updateData();
                        }
                    },
                    kTableUpdateProperty: ^(id value) {
                        for (OAGPXTableCellData *cellData in waypointsSection.cells)
                        {
                            if (cellData.updateProperty)
                                cellData.updateProperty(value);
                        }
                    },
                    kSectionHeaderHeight: tableSections.firstObject == waypointsSection ? @0.001 : @14.
            }];
        }
    }

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kCellKey: @"delete_waypoints",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"delete_waypoints"),
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellToggle: @([self hasWaypoints]),
            kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon,
    }];
    [deleteCellData setData:@{
            kCellButtonPressed: ^{
                if (deleteCellData.toggle)
                {
                    if (self.trackMenuDelegate)
                        [self.trackMenuDelegate stopLocationServices];

                    NSMutableArray<OAGPXTableSectionData *> *sectionsData = [NSMutableArray array];
                    for (OAGPXTableSectionData *sectionData in self.tableData.sections)
                    {
                        BOOL isAction = [sectionData.header isEqualToString:OALocalizedString(@"actions")];
                        BOOL isRte = [sectionData.cells.firstObject.title isEqualToString:OALocalizedString(@"route_points")];
                        if (!isAction && !isRte)
                            [sectionsData addObject:sectionData];
                    }
                    if (self.trackMenuDelegate)
                        [self.trackMenuDelegate openDeleteWaypointsScreen:sectionsData];
                }
            }
    }];
    [deleteCellData setData:@{
            kTableUpdateData: ^() {
                [deleteCellData setData:@{
                        kCellToggle: @([self hasWaypoints]),
                        kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon
                }];
            }
    }];

    OAGPXTableSectionData *actionsSection = [OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"add_waypoint",
                            kCellType: [OAIconTitleValueCell getCellIdentifier],
                            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                            kCellTitle: OALocalizedString(@"add_waypoint"),
                            kCellRightIconName: @"ic_custom_add_gpx_waypoint",
                            kCellToggle: @YES,
                            kCellTintColor: @color_primary_purple,
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openNewWaypointScreen];
                            }
                    }],
                    deleteCellData
            ],
            kSectionHeader: OALocalizedString(@"actions"),
            kSectionHeaderHeight: @56.
    }];

    [actionsSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in actionsSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];
    [tableSections addObject:actionsSection];

    self.tableData = [OAGPXTableData withData: @{ kTableSections: tableSections }];
    [self.tableData setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableSectionData *sectionData in tableSections)
                {
                    if (sectionData.updateData)
                        sectionData.updateData();
                }

                [self.tableData setData:@{
                        kTableSections: tableSections = [[tableSections sortedArrayUsingComparator:
                                ^NSComparisonResult(OAGPXTableSectionData *obj1, OAGPXTableSectionData *obj2) {
                                    if (obj2 == actionsSection)
                                        return NSOrderedAscending;

                                    NSString *group1 = obj1.cells.firstObject.key;
                                    NSString *group2 = obj2.cells.firstObject.key;
                                    return [group1 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedDescending
                                            : [group2 hasSuffix:OALocalizedString(@"route_points")] ? NSOrderedAscending
                                                    : [group1 compare:group2];
                                }] mutableCopy]
                }];

                for (OAGPXTableSectionData *sectionData in self.tableData.sections)
                {
                    if (sectionData != actionsSection)
                        [sectionData setData:@{
                                kSectionHeaderHeight: self.tableData.sections.firstObject == sectionData ? @0.001 : @14.
                        }];
                }
            },
            kTableUpdateProperty: ^(id value) {
                if ([value isKindOfClass:NSDictionary.class])
                {
                    NSDictionary *dataToUpdate = value;
                    if ([dataToUpdate.allKeys containsObject:@"delete_group_name_index"])
                    {
                        NSInteger deleteSectionI = [dataToUpdate[@"delete_group_name_index"] integerValue];
                        if (deleteSectionI != NSNotFound)
                        {
                            NSMutableArray *cells = [tableSections[deleteSectionI].cells mutableCopy];
                            NSArray<NSNumber *> *waypointsIdxToDelete = dataToUpdate[@"delete_waypoints_idx"];
                            if (cells.count - 1 == waypointsIdxToDelete.count)
                            {
                                [tableSections removeObjectAtIndex:deleteSectionI];
                            }
                            else
                            {
                                NSMutableArray *cellsToDelete = [NSMutableArray array];
                                for (NSNumber *waypointIdToDelete in waypointsIdxToDelete)
                                {
                                    [cellsToDelete addObject:[cells objectAtIndex:waypointIdToDelete.intValue + 1]];
                                }
                                [cells removeObjectsInArray:cellsToDelete];
                                [tableSections[deleteSectionI] setData:@{ kSectionCells: cells }];
                            }
                            [self.tableData setData:@{ kTableSections: tableSections }];

                            for (OAGPXTableSectionData *section in tableSections)
                            {
                                OAGPXTableCellData *groupCell = section.cells.firstObject;
                                if (groupCell.updateProperty)
                                    groupCell.updateProperty(@{ @"regenerate_bool_value": @YES });
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
                                NSMutableArray *cells = [tableSections[existI == newI + 1 ? existI : newI].cells mutableCopy];
                                NSMutableArray *extraCells = [tableSections[existI == newI + 1 ? oldI : newI == existI
                                        ? oldI : existI].cells mutableCopy];
                                [extraCells removeObjectAtIndex:0];
                                [cells addObjectsFromArray:extraCells];
                                [tableSections[existI == newI + 1 ? existI : newI] setData:@{ kSectionCells: cells }];
                                [tableSections removeObjectAtIndex:existI == newI + 1 ? oldI : newI == existI ? oldI : existI];
                                [self.tableData setData:@{ kTableSections: tableSections }];
                            }
                            else if ((!hasExist || existI != NSNotFound) && hasNew)
                            {
                                OAGPXTableSectionData *groupSection = tableSections[oldI];
                                [tableSections removeObjectAtIndex:oldI];
                                [tableSections insertObject:groupSection atIndex:newI];
                                [self.tableData setData:@{ kTableSections: tableSections }];
                            }

                            if (hasNew && existI != NSNotFound)
                            {
                                OAGPXTableSectionData *groupSection = tableSections[existI == newI ? existI : newI];
                                if (groupSection.updateProperty)
                                    groupSection.updateProperty(value);
                            }
                            else
                            {
                                OAGPXTableSectionData *groupSection = tableSections[oldI];
                                if (groupSection.updateProperty)
                                    groupSection.updateProperty(value);
                            }
                        }
                    }
                }
            }
    }];
}

@end
