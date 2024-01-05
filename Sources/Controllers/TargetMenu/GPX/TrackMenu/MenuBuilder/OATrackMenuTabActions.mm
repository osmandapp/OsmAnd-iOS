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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OATrackMenuTabActions ()

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabActions

@dynamic tableData, isGeneratedData;

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_actions");
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
    self.tableData = [OAGPXTableData withData: @{ kTableKey: @"table_tab_actions" }];

    OAGPXTableSectionData *controlSectionData = [OAGPXTableSectionData withData:@{ kSectionHeaderHeight: @19. }];
    [self.tableData.subjects addObject:controlSectionData];

    OAGPXTableCellData *showOnMapCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"control_show_on_map",
            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"shared_string_show_on_map")
    }];
    [controlSectionData.subjects addObject:showOnMapCellData];

    OAGPXTableCellData *appearanceCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"control_appearance",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_appearance",
            kCellTitle: OALocalizedString(@"shared_string_appearance")
    }];
    [controlSectionData.subjects addObject:appearanceCellData];

    OAGPXTableCellData *navigationCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"control_navigation",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_navigation",
            kCellTitle: OALocalizedString(@"routing_settings")
    }];
    [controlSectionData.subjects addObject:navigationCellData];

    OAGPXTableSectionData *analyzeSectionData = [OAGPXTableSectionData withData:@{ kSectionHeaderHeight: @19. }];
    [self.tableData.subjects addObject:analyzeSectionData];

    OAGPXTableCellData *analyzeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"analyze",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_graph",
            kCellTitle: OALocalizedString(@"analyze_on_map")
    }];
    [analyzeSectionData.subjects addObject:analyzeCellData];

    OAGPXTableSectionData *shareSectionData = [OAGPXTableSectionData withData:@{ kSectionHeaderHeight: @19. }];
    [self.tableData.subjects addObject:shareSectionData];

    OAGPXTableCellData *shareCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"share",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_export",
            kCellTitle: OALocalizedString(@"shared_string_share")
    }];
    [shareSectionData.subjects addObject:shareCellData];
    
    OAGPXTableCellData *uploadToOSMCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"upload_to_openstreetmap",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_upload_to_openstreetmap",
            kCellTitle: OALocalizedString(@"upload_to_openstreetmap")
    }];
    [shareSectionData.subjects addObject:uploadToOSMCellData];

    OAGPXTableSectionData *editSectionData = [OAGPXTableSectionData withData:@{ kSectionHeaderHeight: @19. }];
    [self.tableData.subjects addObject:editSectionData];

    OAGPXTableCellData *editCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"edit",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_trip_edit",
            kCellTitle: OALocalizedString(@"edit_track")
    }];
    [editSectionData.subjects addObject:editCellData];

    OAGPXTableCellData *duplicateCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"edit_create_duplicate",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_copy",
            kCellTitle: OALocalizedString(@"duplicate_track")
    }];
    [editSectionData.subjects addObject:duplicateCellData];

    OAGPXTableSectionData *changeSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_change",
            kSectionHeaderHeight: @19.
    }];
    [self.tableData.subjects addObject:changeSectionData];

    OAGPXTableCellData *renameCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"change_rename",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_edit",
            kCellTitle: OALocalizedString(@"rename_track")
    }];
    [changeSectionData.subjects addObject:renameCellData];

    OAGPXTableCellData *moveCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"change_move",
            kCellType: [OATitleDescriptionIconRoundCell getCellIdentifier],
            kCellDesc: [self generateDirName],
            kCellRightIconName: @"ic_custom_folder_move",
            kCellTitle: OALocalizedString(@"change_folder")
    }];
    [changeSectionData.subjects addObject:moveCellData];

    OAGPXTableSectionData *deleteSectionData = [OAGPXTableSectionData withData:@{ kSectionHeaderHeight: @19. }];
    [self.tableData.subjects addObject:deleteSectionData];

    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"delete",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont scaledBoldSystemFontOfSize:17] },
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellTitle: OALocalizedString(@"shared_string_delete"),
            kCellTintColor: [UIColor colorNamed:ACColorNameButtonBgColorDisruptive]
    }];
    [deleteSectionData.subjects addObject:deleteCellData];

    self.isGeneratedData = YES;
}

- (NSString *)generateDirName
{
    return self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"";
}

#pragma mark - Cell action methods

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"control_show_on_map"] && self.trackMenuDelegate)
        [self.trackMenuDelegate changeTrackVisible];
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"control_show_on_map"] && self.trackMenuDelegate)
        return [self.trackMenuDelegate isTrackVisible];

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"change_move"] && self.trackMenuDelegate)
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

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData sourceView:(UIView *)sourceView
{
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
    else if ([tableData.key isEqualToString:@"upload_to_openstreetmap"] && self.trackMenuDelegate)
        [self.trackMenuDelegate openUploadGpxToOSM];
}

@end
