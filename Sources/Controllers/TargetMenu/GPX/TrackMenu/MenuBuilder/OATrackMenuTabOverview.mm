//
//  OATrackMenuTabOverview.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabOverview.h"
#import "OATextViewSimpleCell.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAWikiArticleHelper.h"
#import "OAImageDescTableViewCell.h"

#define kInfoCreatedOnCell 0

@interface OATrackMenuTabOverview ()

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabOverview
{
    NSString *_description;
}

@dynamic tableData, isGeneratedData;

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
    NSString *imageURL = [self.trackMenuDelegate getMetadataImageLink];
    _description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
    NSMutableArray<OAGPXTableCellData *> *descriptionCells = [NSMutableArray array];
    
    if ((!imageURL || imageURL.length == 0) && _description && _description.length > 0)
        imageURL = [self findFirstImageURL:_description];
    if (imageURL)
    {
        OAGPXTableCellData *imageCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"image",
                kCellType: [OAImageDescTableViewCell getCellIdentifier],
                kTableValues: @{ @"img": imageURL }
        }];
        [descriptionCells addObject:imageCellData];
    }

    if (!_description || _description.length == 0)
    {
        OAGPXTableCellData *addDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"add_description",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"add_description"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        [descriptionCells addObject:addDescriptionCellData];
        
        OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
                kTableSubjects: descriptionCells,
                kSectionHeader: OALocalizedString(@"description"),
                kSectionHeaderHeight: @56.
        }];
        [tableSections addObject:descriptionSectionData];
    }
    else
    {
        _description = [OAWikiArticleHelper getFirstParagraph:_description];

        OAGPXTableCellData *descriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"description",
                kCellType: [OATextViewSimpleCell getCellIdentifier],
                kTableValues: @{ @"attr_string_value": [self generateDescriptionAttrString] }
        }];
        [descriptionCells addObject:descriptionCellData];

        OAGPXTableCellData *editDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"edit_description",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"context_menu_edit_descr"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        [descriptionCells addObject:editDescriptionCellData];

        OAGPXTableCellData *readFullDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"read_full_description",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"read_full_description"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        [descriptionCells addObject:readFullDescriptionCellData];

        OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_description",
                kTableSubjects: descriptionCells,
                kSectionHeader: OALocalizedString(@"description"),
                kSectionHeaderHeight: @56.
        }];
        [tableSections addObject:descriptionSectionData];
    }

    NSMutableArray<OAGPXTableCellData *> *infoCells = [NSMutableArray array];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"size",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_size"),
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @""
    }];
    [infoCells addObject:sizeCellData];

    OAGPXTableCellData *createdOnCellData = [self generateCreatedOnCellData];
    if (createdOnCellData.desc && createdOnCellData.desc.length > 0)
        [infoCells addObject:createdOnCellData];

    OAGPXTableCellData *locationCellData = [self generateLocationCellData];
    if (self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack])
        [infoCells addObject:locationCellData];

    OAGPXTableSectionData *infoSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_info",
            kTableSubjects: infoCells,
            kSectionHeader: OALocalizedString(@"shared_string_info"),
            kSectionHeaderHeight: @56.
    }];
    [tableSections addObject:infoSectionData];

    self.tableData = [OAGPXTableData withData:@{
            kTableKey: @"table_tab_overview",
            kTableSubjects: tableSections
    }];

    self.isGeneratedData = YES;
}

- (NSString *) findFirstImageURL:(NSString *)htmlText
{
    NSRange openImgTagRange = [htmlText rangeOfString:@"<img"];
    if (openImgTagRange.location != NSNotFound)
    {
        NSString *trimmedString = [htmlText substringFromIndex:openImgTagRange.location + openImgTagRange.length];
        NSRange openSrcTagRange = [trimmedString rangeOfString:@"src=\""];
        if (openSrcTagRange.location != NSNotFound)
        {
            trimmedString = [trimmedString substringFromIndex:openSrcTagRange.location + openSrcTagRange.length];
            NSRange closeSrcTagRange = [trimmedString rangeOfString:@"\""];
            if (closeSrcTagRange.location != NSNotFound)
            {
                trimmedString = [trimmedString substringToIndex:closeSrcTagRange.location];
                return trimmedString;
            }
        }
    }
    return nil;
}
- (NSAttributedString *)generateDescriptionAttrString
{
    return [OAUtilities createAttributedString:
                    [_description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
                                          font:[UIFont systemFontOfSize:17]
                                         color:UIColor.blackColor
                                   strokeColor:nil
                                   strokeWidth:0
                                     alignment:NSTextAlignmentNatural];
}

- (NSString *)generateCreatedOnString
{
    return self.trackMenuDelegate ? [self.trackMenuDelegate getCreatedOn] : @"";
}

- (NSString *)generateDirName
{
    return self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"";
}

- (OAGPXTableCellData *)generateCreatedOnCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"created_on",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_created_on"),
            kCellDesc: [self generateCreatedOnString]
    }];
}

- (OAGPXTableCellData *)generateLocationCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"location",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"sett_arr_loc"),
            kCellDesc: [self generateDirName]
    }];
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

    if ([tableData.key isEqualToString:@"description"])
    {
        tableData.values[@"attr_string_value"] = [self generateDescriptionAttrString];
    }
    else if ([tableData.key isEqualToString:@"size"] && self.trackMenuDelegate)
    {
        [tableData setData:@{ kCellDesc: [self.trackMenuDelegate getGpxFileSize] }];
    }
    else if ([tableData.key isEqualToString:@"created_on"])
    {
        [tableData setData:@{ kCellDesc: [self generateCreatedOnString] }];
    }
    else if ([tableData.key isEqualToString:@"location"])
    {
        [tableData setData:@{ kCellDesc: [self generateDirName] }];
    }
    else if ([tableData.key isEqualToString:@"section_description"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;
        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"section_info"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;

        OAGPXTableCellData *createdOnCellData = [sectionData getSubject:@"created_on"];
        BOOL hasCreatedOn = createdOnCellData != nil;
        if (hasCreatedOn)
            [self updateData:createdOnCellData];
        else
            createdOnCellData = [self generateCreatedOnCellData];

        if (createdOnCellData.desc && createdOnCellData.desc.length > 0 && !hasCreatedOn)
            [sectionData.subjects insertObject:createdOnCellData atIndex:kInfoCreatedOnCell];
        else if (!createdOnCellData.desc || createdOnCellData.desc.length == 0 && hasCreatedOn)
            [sectionData.subjects removeObject:createdOnCellData];

        BOOL isCurrentTrack = self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack];
        OAGPXTableCellData *locationCellData = [sectionData getSubject:@"location"];
        BOOL hasLocation = locationCellData != nil;
        if (!hasLocation)
            locationCellData = [self generateCreatedOnCellData];

        if (!isCurrentTrack && !hasLocation)
            [sectionData.subjects addObject:locationCellData];
        else if (isCurrentTrack && hasLocation)
            [sectionData.subjects removeObject:locationCellData];

        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"table_tab_overview"])
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

    if ([tableData.key isEqualToString:@"add_description"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openDescriptionEditor];
    }
    else if ([tableData.key isEqualToString:@"edit_description"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openDescriptionEditor];
    }
    else if ([tableData.key isEqualToString:@"read_full_description"] && self.trackMenuDelegate)
    {
        [self.trackMenuDelegate openDescription];
    }
}

@end
