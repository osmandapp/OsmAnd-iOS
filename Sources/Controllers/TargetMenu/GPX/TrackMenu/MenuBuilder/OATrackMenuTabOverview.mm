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

#define kDescriptionImageCell 0
#define kInfoCreatedOnCell 0

@interface OATrackMenuTabOverview ()

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OATrackMenuTabOverview
{
    NSString *_description;
    NSString *_imageURL;
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
    self.tableData = [OAGPXTableData withData:@{ kTableKey: @"table_tab_overview" }];

    OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_description",
            kSectionHeader: OALocalizedString(@"description"),
            kSectionHeaderHeight: @56.
    }];
    [self.tableData.subjects addObject:descriptionSectionData];

    [self generateDescription];
    [self generateImageURL];

    if (_imageURL && _imageURL.length > 0)
        [descriptionSectionData.subjects addObject:[self generateImageCellData]];

    if (_description && _description.length > 0)
    {
        [descriptionSectionData.subjects addObject:[self generateDescriptionCellData]];
        [descriptionSectionData.subjects addObject:[self generateEditDescriptionCellData]];
        [descriptionSectionData.subjects addObject:[self generateReadFullDescriptionCellData]];
    }
    else
    {
        [descriptionSectionData.subjects addObject:[self generateAddDescriptionCellData]];
    }

    OAGPXTableSectionData *infoSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_info",
            kSectionHeader: OALocalizedString(@"shared_string_info"),
            kSectionHeaderHeight: @56.
    }];
    [self.tableData.subjects addObject:infoSectionData];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"size",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_size"),
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @""
    }];
    [infoSectionData.subjects addObject:sizeCellData];

    OAGPXTableCellData *createdOnCellData = [self generateCreatedOnCellData];
    if (createdOnCellData.desc && createdOnCellData.desc.length > 0)
        [infoSectionData.subjects addObject:createdOnCellData];

    OAGPXTableCellData *locationCellData = [self generateLocationCellData];
    if (self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack])
        [infoSectionData.subjects addObject:locationCellData];

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
                    [[OAWikiArticleHelper getFirstParagraph:_description] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
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

- (void)generateDescription
{
    _description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
}

- (void)generateImageURL
{
    _imageURL = self.trackMenuDelegate ? [self.trackMenuDelegate getMetadataImageLink] : nil;
    if ((!_imageURL || _imageURL.length == 0) && _description && _description.length > 0)
        _imageURL = [self findFirstImageURL:_description];
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

- (OAGPXTableCellData *)generateImageCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"image",
            kCellType: [OAImageDescTableViewCell getCellIdentifier],
            kTableValues: @{ @"img": _imageURL }
    }];
}
- (OAGPXTableCellData *)generateAddDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"add_description",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"add_description"),
            kCellToggle: @YES,
            kCellTintColor: @color_primary_purple
    }];
}

- (OAGPXTableCellData *)generateDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"description",
            kCellType: [OATextViewSimpleCell getCellIdentifier],
            kTableValues: @{ @"attr_string_value": [self generateDescriptionAttrString] }
    }];
}

- (OAGPXTableCellData *)generateEditDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"edit_description",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"context_menu_edit_descr"),
            kCellToggle: @YES,
            kCellTintColor: @color_primary_purple
    }];
}

- (OAGPXTableCellData *)generateReadFullDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"read_full_description",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"read_full_description"),
            kCellToggle: @YES,
            kCellTintColor: @color_primary_purple
    }];
}

#pragma mark - Cell action methods

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
    else if ([tableData.key isEqualToString:@"image"])
    {
        [self generateImageURL];
        if (_imageURL)
            tableData.values[@"img"] = _imageURL;
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

        BOOL hasOldDescription = _description && _description.length > 0;
        [self generateDescription];
        BOOL hasNewDescription = _description && _description.length > 0;

        BOOL hasOldImageURL = _imageURL && _imageURL.length > 0;
        [self generateImageURL];
        BOOL hasNewImageURL = _imageURL && _imageURL.length > 0;

        if (!hasOldImageURL && hasNewImageURL)
        {
            [sectionData.subjects insertObject:[self generateImageCellData] atIndex:kDescriptionImageCell];
        }
        else if (hasOldImageURL && !hasNewImageURL)
        {
            OAGPXTableCellData *imageCellData = [sectionData getSubject:@"image"];
            if (imageCellData)
                [sectionData.subjects removeObject:imageCellData];
        }
        else
        {
            OAGPXTableCellData *imageCellData = [sectionData getSubject:@"image"];
            if (imageCellData && hasNewImageURL)
                imageCellData.values[@"img"] = _imageURL;
        }

        if (!hasOldDescription && hasNewDescription)
        {
            OAGPXTableCellData *addDescriptionCellData = [sectionData getSubject:@"add_description"];
            if (addDescriptionCellData)
                [sectionData.subjects removeObject:addDescriptionCellData];

            [sectionData.subjects addObject:[self generateDescriptionCellData]];
            [sectionData.subjects addObject:[self generateEditDescriptionCellData]];
            [sectionData.subjects addObject:[self generateReadFullDescriptionCellData]];
        }
        else if (hasOldDescription && !hasNewDescription)
        {
            OAGPXTableCellData *descriptionCellData = [sectionData getSubject:@"description"];
            if (descriptionCellData)
                [sectionData.subjects removeObject:descriptionCellData];

            OAGPXTableCellData *editDescriptionCellData = [sectionData getSubject:@"edit_description"];
            if (editDescriptionCellData)
                [sectionData.subjects removeObject:editDescriptionCellData];

            OAGPXTableCellData *readFullDescriptionCellData = [sectionData getSubject:@"read_full_description"];
            if (readFullDescriptionCellData)
                [sectionData.subjects removeObject:readFullDescriptionCellData];

            [sectionData.subjects addObject:[self generateAddDescriptionCellData]];
        }
        else
        {
            for (OAGPXTableCellData *cellData in sectionData.subjects)
            {
                if (![cellData.key isEqualToString:@"image"])
                    [self updateData:cellData];
            }
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
