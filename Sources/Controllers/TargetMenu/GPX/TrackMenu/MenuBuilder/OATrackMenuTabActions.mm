//
//  OATrackMenuTabActions.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabActions.h"
#import "OATitleSwitchRoundCell.h"
#import "OATitleIconRoundCell.h"
#import "OATitleDescriptionIconRoundCell.h"
#import "Localization.h"
#import "OAColors.h"

@interface OATrackMenuTabActions ()

@property (nonatomic) OAGPXTableData *tableData;

@end

@implementation OATrackMenuTabActions

@dynamic tableData;

- (NSString *)getTabTitle
{
    return OALocalizedString(@"actions");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_overflow_menu"];
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudActionsTab;
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"control_show_on_map",
                            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
                            kCellTitle: OALocalizedString(@"map_settings_show"),
                            kCellOnSwitch: ^(BOOL toggle) {
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate changeTrackVisible];
                            },
                            kCellIsOn: ^() {
                                return self.trackMenuDelegate && [self.trackMenuDelegate isTrackVisible];
                            }
                    }],
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"control_appearance",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_appearance",
                            kCellTitle: OALocalizedString(@"map_settings_appearance"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openAppearance];
                            }
                    }],
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"control_navigation",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_navigation",
                            kCellTitle: OALocalizedString(@"routing_settings"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openNavigation];
                            }
                    }]
            ],
            kSectionHeaderHeight: @20.
    }]];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"analyze",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_appearance",
                            kCellTitle: OALocalizedString(@"analyze_on_map"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openAnalysis:EOARouteStatisticsModeAltitudeSlope];
                            }
                    }]
            ],
            kSectionHeaderHeight: @20.
    }]];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"share",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_export",
                            kCellTitle: OALocalizedString(@"ctx_mnu_share"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openExport];
                            }
                    }]
            ],
            kSectionHeaderHeight: @20.
    }]];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"edit",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_trip_edit",
                            kCellTitle: OALocalizedString(@"edit_track"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate editSegment];
                            }
                    }],
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"edit_create_duplicate",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_copy",
                            kCellTitle: OALocalizedString(@"duplicate_track"),
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate openDuplicateTrack];
                            }
                    }]
            ],
            kSectionHeaderHeight: @20.
    }]];

    NSMutableArray<OAGPXTableCellData *> *changeCells = [NSMutableArray array];

    [changeCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"change_rename",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_edit",
            kCellTitle: OALocalizedString(@"gpx_rename_q"),
            kCellButtonPressed: ^{
                if (self.trackMenuDelegate)
                    [self.trackMenuDelegate showAlertRenameTrack];
            }
    }]];

    OAGPXTableCellData *moveCellData = [OAGPXTableCellData withData:@{
            kCellKey: @"change_move",
            kCellType: [OATitleDescriptionIconRoundCell getCellIdentifier],
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"",
            kCellRightIconName: @"ic_custom_folder_move",
            kCellTitle: OALocalizedString(@"plan_route_change_folder"),
            kCellButtonPressed: ^{
                if (self.trackMenuDelegate)
                    [self.trackMenuDelegate openMoveTrack];
            }
    }];
    [moveCellData setData:@{
            kTableUpdateData: ^() {
                [moveCellData setData:@{kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"" }];
            }
    }];
    [changeCells addObject:moveCellData];

    OAGPXTableSectionData *changeSection = [OAGPXTableSectionData withData:@{ kSectionCells: changeCells }];
    [changeSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in changeSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            },
            kSectionHeaderHeight: @20.
    }];
    [tableSections addObject:changeSection];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"delete",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_remove_outlined",
                            kCellTitle: OALocalizedString(@"shared_string_delete"),
                            kCellTintColor: @color_primary_red,
                            kCellButtonPressed: ^{
                                if (self.trackMenuDelegate)
                                    [self.trackMenuDelegate showAlertDeleteTrack];
                            }
                    }]
            ],
            kSectionHeaderHeight: @20.
    }]];

    self.tableData = [OAGPXTableData withData: @{ kTableSections: tableSections }];
    [self.tableData setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableSectionData *sectionData in tableSections)
                {
                    if (sectionData.updateData)
                        sectionData.updateData();
                }
            }
    }];
}

@end
