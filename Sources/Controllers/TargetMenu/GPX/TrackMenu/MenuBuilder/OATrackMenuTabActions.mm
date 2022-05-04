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
            kTableKey: @"control_show_on_map",
            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"map_settings_show")
    }];

    OAGPXTableCellData *appearanceCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"control_appearance",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_appearance",
            kCellTitle: OALocalizedString(@"map_settings_appearance")
    }];

    OAGPXTableCellData *navigationCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"control_navigation",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_navigation",
            kCellTitle: OALocalizedString(@"routing_settings")
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[showOnMapCellData, appearanceCellData, navigationCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *analyzeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"analyze",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_graph",
            kCellTitle: OALocalizedString(@"analyze_on_map")
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[analyzeCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *shareCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"share",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_export",
            kCellTitle: OALocalizedString(@"ctx_mnu_share")
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[shareCellData],
            kSectionHeaderHeight: @19.
    }]];

    OAGPXTableCellData *editCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"edit",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_trip_edit",
            kCellTitle: OALocalizedString(@"edit_track")
    }];

    OAGPXTableCellData *duplicateCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"edit_create_duplicate",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_copy",
            kCellTitle: OALocalizedString(@"duplicate_track")
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[editCellData, duplicateCellData],
            kSectionHeaderHeight: @19.
    }]];

    NSMutableArray<OAGPXTableCellData *> *changeCells = [NSMutableArray array];

    OAGPXTableCellData *renameCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"change_rename",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_edit",
            kCellTitle: OALocalizedString(@"gpx_rename_q")
    }];

    [changeCells addObject:renameCellData];

    OAGPXTableCellData *moveCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"change_move",
            kCellType: [OATitleDescriptionIconRoundCell getCellIdentifier],
            kCellDesc: [self generateDirName],
            kCellRightIconName: @"ic_custom_folder_move",
            kCellTitle: OALocalizedString(@"plan_route_change_folder")
    }];

    [changeCells addObject:moveCellData];

    OAGPXTableSectionData *changeSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_change",
            kTableSubjects: changeCells,
            kSectionHeaderHeight: @19.
    }];
    [tableSections addObject:changeSectionData];

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"delete",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont boldSystemFontOfSize:17] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellTitle: OALocalizedString(@"shared_string_delete"),
            kCellTintColor: @color_primary_red
    }];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[deleteCellData],
            kSectionHeaderHeight: @19.
    }]];

    self.tableData = [OAGPXTableData withData: @{
            kTableKey: @"table_tab_actions",
            kTableSubjects: tableSections
    }];

    self.isGeneratedData = YES;
}

- (NSString *)generateDirName
{
    return self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"";
}

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"control_show_on_map"] && self.trackMenuDelegate)
        [self.trackMenuDelegate changeTrackVisible];
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return NO;

    if ([tableData.key isEqualToString:@"control_show_on_map"] && self.trackMenuDelegate)
        return [self.trackMenuDelegate isTrackVisible];

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    else if ([tableData.key isEqualToString:@"change_move"] && self.trackMenuDelegate)
    {
        [tableData setData:@{ kCellDesc: [self generateDirName] }];
    }
    else if ([tableData.key isEqualToString:@"section_change"] && self.trackMenuDelegate)
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"table_tab_actions"])
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
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"control_appearance"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openAppearance];
    else if ([tableData.key isEqualToString:@"control_navigation"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openNavigation];
    else if ([tableData.key isEqualToString:@"analyze"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openAnalysis:EOARouteStatisticsModeAltitudeSlope];
    else if ([tableData.key isEqualToString:@"share"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openExport];
    else if ([tableData.key isEqualToString:@"edit"] && self.trackMenuDelegate)
        [self.trackMenuDelegate editSegment];
    else if ([tableData.key isEqualToString:@"edit_create_duplicate"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openDuplicateTrack];
    else if ([tableData.key isEqualToString:@"change_rename"] && self.trackMenuDelegate)
        [self.trackMenuDelegate showAlertRenameTrack];
    else if ([tableData.key isEqualToString:@"change_move"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openMoveTrack];
    else if ([tableData.key isEqualToString:@"delete"] && self.trackMenuDelegate)
        [self.trackMenuDelegate showAlertDeleteTrack];
}

@end
