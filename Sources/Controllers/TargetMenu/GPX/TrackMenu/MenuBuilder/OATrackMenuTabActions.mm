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
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabActions

@dynamic tableData, isGeneratedData;

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
    OAGPXTableCellData *showOnMapCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"control_show_on_map",
            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"map_settings_show")
    }];
    showOnMapCellData.onSwitch = ^(BOOL toggle) {
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate changeTrackVisible];
    };
    showOnMapCellData.isOn = ^() { return self.trackMenuDelegate ? [self.trackMenuDelegate isTrackVisible] : NO; };

    OAGPXTableCellData *appearanceCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"control_appearance",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_appearance",
            kCellTitle: OALocalizedString(@"map_settings_appearance")
    }];
    appearanceCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openAppearance];
    };

    OAGPXTableCellData *navigationCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"control_navigation",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_navigation",
            kCellTitle: OALocalizedString(@"routing_settings")
    }];
    navigationCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openNavigation];
    };

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[showOnMapCellData, appearanceCellData, navigationCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *analyzeCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"analyze",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_graph",
            kCellTitle: OALocalizedString(@"analyze_on_map")
    }];
    analyzeCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openAnalysis:EOARouteStatisticsModeAltitudeSlope];
    };

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[analyzeCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *shareCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"share",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_export",
            kCellTitle: OALocalizedString(@"ctx_mnu_share")
    }];
    shareCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openExport];
    };

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[shareCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *editCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"edit",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_trip_edit",
            kCellTitle: OALocalizedString(@"edit_track")
    }];
    editCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate editSegment];
    };

    OAGPXTableCellData *duplicateCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"edit_create_duplicate",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_copy",
            kCellTitle: OALocalizedString(@"duplicate_track")
    }];
    duplicateCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openDuplicateTrack];
    };

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[editCellData, duplicateCellData],
            kSectionHeaderHeight: @19.
    }]];

    NSMutableArray<OAGPXTableCellData *> *changeCells = [NSMutableArray array];

    OAGPXTableCellData *renameCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"change_rename",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_edit",
            kCellTitle: OALocalizedString(@"gpx_rename_q")
    }];
    renameCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate showAlertRenameTrack];
    };

    [changeCells addObject:renameCellData];

    OAGPXTableCellData *moveCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"change_move",
            kCellType: [OATitleDescriptionIconRoundCell getCellIdentifier],
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"",
            kCellRightIconName: @"ic_custom_folder_move",
            kCellTitle: OALocalizedString(@"plan_route_change_folder")
    }];
    moveCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openMoveTrack];
    };
    moveCellData.updateData = ^() {
        [moveCellData setData:@{ kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"" }];
    };

    [changeCells addObject:moveCellData];

    OAGPXTableSectionData *changeSectionData = [OAGPXTableSectionData withData:@{
            kTableDataKey: @"change_section",
            kSectionCells: changeCells
    }];
    [changeSectionData setData:@{ kSectionHeaderHeight: @19. }];
    changeSectionData.updateData = ^() {
        for (OAGPXTableCellData *cellData in changeSectionData.cells)
        {
            if (cellData.updateData)
                cellData.updateData();
        }
    };

    [tableSections addObject:changeSectionData];

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"delete",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont boldSystemFontOfSize:17] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellTitle: OALocalizedString(@"shared_string_delete"),
            kCellTintColor: @color_primary_red
    }];
    deleteCellData.onButtonPressed = ^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate showAlertDeleteTrack];
    };

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[deleteCellData],
            kSectionHeaderHeight: @19.
    }]];

    self.tableData = [OAGPXTableData withData: @{ kTableSections: tableSections }];
    self.tableData.updateData = ^() {
        for (OAGPXTableSectionData *sectionData in tableSections)
        {
            if (sectionData.updateData)
                sectionData.updateData();
        }
    };

    self.isGeneratedData = YES;
}

@end
