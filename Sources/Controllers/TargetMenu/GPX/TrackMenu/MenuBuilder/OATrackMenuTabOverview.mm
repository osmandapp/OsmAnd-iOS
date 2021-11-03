//
//  OATrackMenuTabOverview.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabOverview.h"
#import "OATextViewSimpleCell.h"
#import "OATextLineViewCell.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"

#define kInfoCreatedOnCell 0

@interface OATrackMenuTabOverview ()

@property (nonatomic) OAGPXTableData *tableData;

@end

@implementation OATrackMenuTabOverview

- (NSString *)getTabTitle
{
    return OALocalizedString(@"shared_string_overview");
}

- (UIImage *)getTabIcon
{
    return [OABaseTrackMenuTabItem getUnselectedIcon:@"ic_custom_overview"];
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    NSString *description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";

    if (description && description.length > 0)
    {
        NSMutableArray<OAGPXTableCellData *> *descriptionCells = [NSMutableArray array];

        NSAttributedString * (^generateDescriptionAttrString) (void) = ^{
            return [OAUtilities createAttributedString:
                            [description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
                                                  font:[UIFont systemFontOfSize:17]
                                                 color:UIColor.blackColor
                                           strokeColor:nil
                                           strokeWidth:0
                                             alignment:NSTextAlignmentNatural];
        };

        NSAttributedString *descriptionAttr = generateDescriptionAttrString();
        OAGPXTableCellData *descriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"description",
                kCellType: [OATextViewSimpleCell getCellIdentifier],
                kTableValues: @{ @"attr_string_value": descriptionAttr }
        }];

        [descriptionCellData setData:@{
                kTableUpdateData: ^() {
                    [descriptionCellData setData:@{ kTableValues: @{ @"attr_string_value": generateDescriptionAttrString() } }];
                }
        }];
        [descriptionCells addObject:descriptionCellData];

        OAGPXTableCellData * (^generateDataForFullDescriptionCell) (void) = ^{
            return [OAGPXTableCellData withData:@{
                    kCellKey: @"full_description",
                    kCellType: [OATextLineViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"read_full_description"),
                    kCellButtonPressed: ^{
                        if (self.trackMenuDelegate)
                            [self.trackMenuDelegate openDescription];
                    }
            }];
        };

        if (description.length > descriptionAttr.length)
            [descriptionCells addObject:generateDataForFullDescriptionCell()];

        OAGPXTableSectionData *descriptionSection = [OAGPXTableSectionData withData:@{
                kSectionCells: descriptionCells,
                kSectionHeader: OALocalizedString(@"description"),
                kSectionHeaderHeight: @56.
        }];
        [descriptionSection setData:@{
                kTableUpdateData: ^() {
                    NSAttributedString *newDescriptionAttr = generateDescriptionAttrString();

                    BOOL hasFullDescription = [descriptionSection.cells.lastObject.key isEqualToString:@"full_description"];
                    if (description.length > newDescriptionAttr.length && !hasFullDescription)
                        [descriptionSection.cells addObject:generateDataForFullDescriptionCell()];
                    else if (description.length <= newDescriptionAttr.length && hasFullDescription)
                        [descriptionSection.cells removeObject:descriptionSection.cells.lastObject];

                    for (OAGPXTableCellData *cellData in descriptionSection.cells)
                    {
                        if (cellData.updateData)
                            cellData.updateData();
                    }
                }
        }];
        [tableSections addObject:descriptionSection];
    }

    NSMutableArray<OAGPXTableCellData *> *infoCells = [NSMutableArray array];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kCellKey: @"size",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_size"),
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @""
    }];

    [sizeCellData setData:@{
            kTableUpdateData: ^() {
                [sizeCellData setData:@{ kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @"" }];
            }
    }];
    [infoCells addObject:sizeCellData];

    NSString * (^generateCreatedOnString) (void) = ^{
        return self.trackMenuDelegate ? [self.trackMenuDelegate getCreatedOn] : @"";
    };
    __block NSString *createdOn = generateCreatedOnString();

    OAGPXTableCellData * (^generateDataForCreatedOnCell) (void) = ^{
        OAGPXTableCellData *createdOnCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"created_on",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"res_created_on"),
                kCellDesc: createdOn
        }];
        [createdOnCellData setData:@{
                kTableUpdateData: ^() {
                    createdOn = generateCreatedOnString();
                    [createdOnCellData setData:@{ kCellDesc: createdOn }];
                }
        }];

        return createdOnCellData;
    };

    if (createdOn.length > 0)
        [infoCells addObject:generateDataForCreatedOnCell()];

    OAGPXTableCellData * (^generateDataForLocationCell) (void) = ^{
        OAGPXTableCellData *locationCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"location",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"sett_arr_loc"),
                kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @""
        }];
        [locationCellData setData:@{
                kTableUpdateData: ^() {
                    [locationCellData setData:@{ kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"" }];
                }
        }];
        return locationCellData;
    };

    if (self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack])
        [infoCells addObject:generateDataForLocationCell()];

    OAGPXTableSectionData *infoSection = [OAGPXTableSectionData withData:@{
            kSectionCells: infoCells,
            kSectionHeader: OALocalizedString(@"shared_string_info"),
            kSectionHeaderHeight: @56.
    }];
    [infoSection setData:@{
            kTableUpdateData: ^() {
                createdOn = generateCreatedOnString();
                BOOL hasCreatedOn = [infoSection containsCell:@"created_on"];
                if (createdOn.length > 0 && !hasCreatedOn)
                    [infoSection.cells insertObject:generateDataForCreatedOnCell() atIndex:kInfoCreatedOnCell];
                else if (createdOn.length == 0 && hasCreatedOn)
                    [infoSection.cells removeObjectAtIndex:kInfoCreatedOnCell];

                BOOL isCurrentTrack = self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack];
                BOOL hasLocation = [infoSection.cells.lastObject.key isEqualToString:@"location"];
                if (!isCurrentTrack && !hasLocation)
                    [infoSection.cells addObject:generateDataForLocationCell()];
                else if (isCurrentTrack && hasLocation)
                    [infoSection.cells removeObject:infoSection.cells.lastObject];

                for (OAGPXTableCellData *cellData in infoSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];

    [tableSections addObject:infoSection];

    self.tableData = [OAGPXTableData withData:@{ kTableSections: tableSections }];
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
