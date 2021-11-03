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

#import <OsmAndCore/Utilities.h>

@interface OATrackMenuTabPoints ()

@property (nonatomic) OAGPXTableData *tableData;

@end

@implementation OATrackMenuTabPoints
{
    NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *_waypointGroups;
}

- (BOOL)hasWaypoints
{
    return _waypointGroups.allKeys.count > 0;
}

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_gpx_points");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_waypoint"];
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudPointsTab;
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];
    OsmAndAppInstance app = [OsmAndApp instance];

    _waypointGroups = self.trackMenuDelegate ? [self.trackMenuDelegate updateWaypointsData] : [NSDictionary dictionary];

    if (_waypointGroups.allKeys.count > 0)
    {
        for (NSString *groupName in _waypointGroups.keyEnumerator)
        {
            __block BOOL isHidden = self.trackMenuDelegate
                    ? ![self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:groupName]
                            ? @"" : groupName] : NO;
            __block UIImage *leftIcon = [UIImage templateImageNamed:
                    isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"];
            __block UIColor *tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                    : self.trackMenuDelegate
                            ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:groupName])
                            : [OADefaultFavorite getDefaultColor];
            OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                    kCellKey: [NSString stringWithFormat:@"group_%@", groupName],
                    kCellType: [OASelectionCollapsableCell getCellIdentifier],
                    kCellTitle: groupName,
                    kCellLeftIcon: leftIcon,
                    kCellRightIconName: @"ic_custom_arrow_up",
                    kCellToggle: @YES,
                    kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                    kCellButtonPressed: ^() {
                        if (self.trackMenuDelegate)
                            [self.trackMenuDelegate openWaypointsGroupOptionsScreen:groupName];
                    }
            }];

            __block NSString *currentGroupName = groupName;
            __block BOOL updated = NO;

            [groupCellData setData:@{
                    kTableUpdateData: ^() {
                        NSDictionary *newGroupData = self.trackMenuDelegate
                                ? [self.trackMenuDelegate updateGroupName:currentGroupName
                                                             oldGroupName:groupCellData.title]
                                : [NSDictionary dictionary];
                        if ([newGroupData.allKeys containsObject:@"current_group_name"])
                            currentGroupName = newGroupData[@"current_group_name"];
                        if ([newGroupData.allKeys containsObject:@"updated"])
                            updated = [newGroupData[@"updated"] boolValue];

                        isHidden = self.trackMenuDelegate
                                ? ![self.trackMenuDelegate isWaypointsGroupVisible:[self.trackMenuDelegate isDefaultGroup:currentGroupName]
                                        ? @"" : currentGroupName] : NO;
                        leftIcon = [UIImage templateImageNamed:
                                isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"];
                        tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                                : self.trackMenuDelegate
                                        ? UIColorFromRGB([self.trackMenuDelegate getWaypointsGroupColor:currentGroupName])
                                        : [OADefaultFavorite getDefaultColor];
                        [groupCellData setData:@{
                                kCellKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
                                kCellTitle: currentGroupName,
                                kCellLeftIcon: leftIcon,
                                kCellRightIconName: groupCellData.toggle ? @"ic_custom_arrow_up" : @"ic_custom_arrow_right",
                                kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                                kCellButtonPressed: ^() {
                                    if (self.trackMenuDelegate)
                                        [self.trackMenuDelegate openWaypointsGroupOptionsScreen:currentGroupName];
                                }
                        }];
                    }
            }];

            NSArray<OAGPXTableCellData *> *(^generateDataForWaypointCells)(void) = ^{
                NSMutableArray<OAGPXTableCellData *> *waypointsCells = [NSMutableArray array];
                if (groupCellData.toggle)
                {
                    NSArray<OAGpxWptItem *> *waypoints = _waypointGroups[currentGroupName];

                    for (OAGpxWptItem *waypoint in waypoints) {
                        NSInteger waypointIndex = [waypoints indexOfObject:waypoint];
                        __block OAGpxWptItem *currentWaypoint = waypoint;
                        void (^newWaypoint)(void) = ^{
                            if (updated)
                            {
                                currentWaypoint = _waypointGroups[currentGroupName][waypointIndex];
                                updated = NO;
                            }
                        };
                        newWaypoint();

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
                                kCellTitle: currentWaypoint.point.name,
                                kCellDesc: worldRegion != nil
                                        ? (worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName)
                                        : @"",
                                kCellLeftIcon: [currentWaypoint getCompositeIcon],
                                kCellButtonPressed: ^{
                                    if (self.trackMenuDelegate)
                                        [self.trackMenuDelegate openWptOnMap:currentWaypoint];
                                }
                        }];

                        [waypointCellData setData:@{
                                kTableUpdateData: ^() {
                                    newWaypoint();
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
                                            kTableValues: @{
                                                    @"string_value_distance": currentWaypoint.distance
                                                            ? currentWaypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                                                    @"float_value_direction": @(currentWaypoint.direction)
                                            },
                                            kCellTitle: currentWaypoint.point.name,
                                            kCellLeftIcon: [currentWaypoint getCompositeIcon]
                                    }];
                                }
                        }];
                        [waypointsCells addObject:waypointCellData];
                    }
                }
                return waypointsCells;
            };

            OAGPXTableSectionData *waypointsSection = [OAGPXTableSectionData withData:@{
                    kSectionCells: [@[groupCellData] arrayByAddingObjectsFromArray:generateDataForWaypointCells()],
            }];
            [tableSections addObject:waypointsSection];

            [waypointsSection setData:@{
                    kTableUpdateData: ^() {
                        if (groupCellData.updateData)
                            groupCellData.updateData();
                        NSInteger sectionIndex = [_waypointGroups.allKeys indexOfObject:currentGroupName];

                        BOOL isDuplicate = [waypointsSection.values[@"is_duplicate_bool_value"] boolValue];
                        if (!isDuplicate && sectionIndex != NSNotFound)
                        {
                            if (updated || (self.trackMenuDelegate && waypointsSection.cells.count
                                            != [self.trackMenuDelegate getWaypointsCount:currentGroupName] + 1)
                                    || !groupCellData.toggle)
                            {
                                [waypointsSection setData:@{
                                        kSectionCells: [@[groupCellData] arrayByAddingObjectsFromArray:generateDataForWaypointCells()]
                                }];
                            }
                            else
                            {
                                for (OAGPXTableCellData *cellData in waypointsSection.cells)
                                {
                                    if (groupCellData != cellData && cellData.updateData)
                                        cellData.updateData();
                                }
                            }
                        }

                        if (isDuplicate || (waypointsSection.cells.count == 1 && self.trackMenuDelegate
                                && [self.trackMenuDelegate getWaypointsCount:currentGroupName] == 0)
                                || sectionIndex == NSNotFound)
                        {
                            NSMutableArray<OAGPXTableSectionData *> *newTableData = [self.tableData.sections mutableCopy];
                            [newTableData removeObject:waypointsSection];
                            [self.tableData setData:@{ kTableSections: newTableData }];
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
                        if (![sectionData.header isEqualToString:OALocalizedString(@"actions")])
                            [sectionsData addObject:sectionData];
                    }
                    if (self.trackMenuDelegate)
                        [self.trackMenuDelegate openDeleteWaypointsScreen:sectionsData
                                                           waypointGroups:_waypointGroups];
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
                _waypointGroups = self.trackMenuDelegate ? [self.trackMenuDelegate updateWaypointsData] : [NSDictionary dictionary];

                for (OAGPXTableSectionData *sectionData in tableSections)
                {
                    if (sectionData.updateData)
                        sectionData.updateData();
                }
            }
    }];
}

@end
