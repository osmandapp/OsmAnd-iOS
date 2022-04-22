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
    NSMutableArray *_results;
    NSMutableString *_parsedString;
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
    NSMutableArray<OAGPXTableCellData *> *descriptionCells = [NSMutableArray array];

    __block OAGPXTableCellData *addDescriptionCellData;
    __block OAGPXTableCellData *descriptionCellData;
    __block OAGPXTableCellData *editDescriptionCellData;
    __block OAGPXTableCellData *readFullDescriptionCellData;

    __block NSString *description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
    __block NSString *imageURL;

    void (^generateImageURL) (void) = ^{
        imageURL = self.trackMenuDelegate ? [self.trackMenuDelegate getMetadataImageLink] : nil;
        if ((!imageURL || imageURL.length == 0) && description && description.length > 0)
            imageURL = [self findFirstImageURL:description];
    };
    generateImageURL();

    OAGPXTableCellData *imageCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"image",
            kCellType: [OAImageDescTableViewCell getCellIdentifier]
    }];
    if (imageURL)
        [imageCellData setData:@{ kTableValues: @{ @"img": imageURL } }];

    imageCellData.updateData = ^() {
        generateImageURL();
        if (imageURL)
            [imageCellData setData:@{ kTableValues: @{ @"img": imageURL } }];
    };

    NSAttributedString * (^generateDescriptionAttrString) (NSString *) = ^(NSString *descriptionFirstParagraph){
        return [OAUtilities createAttributedString:[descriptionFirstParagraph
                        componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
                                              font:[UIFont systemFontOfSize:17]
                                             color:UIColor.blackColor
                                       strokeColor:nil
                                       strokeWidth:0
                                         alignment:NSTextAlignmentNatural];
    };

    void (^generateDescriptionAddCell) (void) = ^{
        addDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"add_description",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"add_description"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        addDescriptionCellData.onButtonPressed = ^{
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openDescriptionEditor];
        };
        [descriptionCells addObject:addDescriptionCellData];
    };

    void (^generateDescriptionReadCells) (void) = ^{
        descriptionCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"description",
                kCellType: [OATextViewSimpleCell getCellIdentifier],
                kTableValues: @{
                        @"attr_string_value": generateDescriptionAttrString([OAWikiArticleHelper getFirstParagraph:description])
                }
        }];
        descriptionCellData.updateData = ^() {
            [descriptionCellData setData:@{
                    kTableValues: @{
                            @"attr_string_value": generateDescriptionAttrString([OAWikiArticleHelper getFirstParagraph:description])
                    }
            }];
        };

        editDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"context_menu_edit_descr",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"context_menu_edit_descr"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        editDescriptionCellData.onButtonPressed = ^{
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openDescriptionEditor];
        };

        readFullDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"read_full_description",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kTableValues: @{ @"font_value": [UIFont systemFontOfSize:17. weight:UIFontWeightMedium] },
                kCellTitle: OALocalizedString(@"read_full_description"),
                kCellToggle: @YES,
                kCellTintColor: @color_primary_purple
        }];
        readFullDescriptionCellData.onButtonPressed = ^{
            if (self.trackMenuDelegate)
                [self.trackMenuDelegate openDescription];
        };

        [descriptionCells addObject:descriptionCellData];
        [descriptionCells addObject:editDescriptionCellData];
        [descriptionCells addObject:readFullDescriptionCellData];
    };

    if (imageURL && imageURL.length > 0)
        [descriptionCells insertObject:imageCellData atIndex:kDescriptionImageCell];

    if (description && description.length > 0)
        generateDescriptionReadCells();
    else
        generateDescriptionAddCell();

    OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
            kTableDataKey: @"description_section",
            kSectionCells: descriptionCells,
            kSectionHeader: OALocalizedString(@"description"),
            kSectionHeaderHeight: @56.
    }];
    descriptionSectionData.updateData = ^() {
        BOOL hasOldDescription = description && description.length > 0;
        description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
        BOOL hasNewDescription = description && description.length > 0;

        BOOL hasOldImageURL = imageURL && imageURL.length > 0;
        generateImageURL();
        BOOL hasNewImageURL = imageURL && imageURL.length > 0;

        if (!hasOldImageURL && hasNewImageURL)
            [descriptionCells insertObject:imageCellData atIndex:kDescriptionImageCell];
        else if (hasOldImageURL && !hasNewImageURL)
            [descriptionCells removeObject:imageCellData];
        else if (imageCellData.updateData)
            imageCellData.updateData();

        if (!hasOldDescription && hasNewDescription)
        {
            [descriptionCells removeObject:addDescriptionCellData];
            generateDescriptionReadCells();
        }
        else if (hasOldDescription && !hasNewDescription)
        {
            [descriptionCells removeObject:descriptionCellData];
            [descriptionCells removeObject:editDescriptionCellData];
            [descriptionCells removeObject:readFullDescriptionCellData];
            generateDescriptionAddCell();
        }
        else
        {
            for (OAGPXTableCellData *cellData in descriptionSectionData.cells)
            {
                if (cellData.updateData && ![cellData.key isEqualToString:@"image"])
                    cellData.updateData();
            }
        }
    };
    [tableSections addObject:descriptionSectionData];

    NSMutableArray<OAGPXTableCellData *> *infoCells = [NSMutableArray array];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kTableDataKey: @"size",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_size"),
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @""
    }];
    sizeCellData.updateData = ^() {
        [sizeCellData setData:@{ kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @"" }];
    };

    [infoCells addObject:sizeCellData];

    NSString * (^generateCreatedOnString) (void) = ^{
        return self.trackMenuDelegate ? [self.trackMenuDelegate getCreatedOn] : @"";
    };
    __block NSString *createdOn = generateCreatedOnString();

    OAGPXTableCellData * (^generateDataForCreatedOnCellData) (void) = ^{
        OAGPXTableCellData *createdOnCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"created_on",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"res_created_on"),
                kCellDesc: createdOn
        }];
        createdOnCellData.updateData = ^() {
            createdOn = generateCreatedOnString();
            [createdOnCellData setData:@{ kCellDesc: createdOn }];
        };

        return createdOnCellData;
    };

    if (createdOn.length > 0)
        [infoCells addObject:generateDataForCreatedOnCellData()];

    OAGPXTableCellData * (^generateDataForLocationCellData) (void) = ^{
        OAGPXTableCellData *locationCellData = [OAGPXTableCellData withData:@{
                kTableDataKey: @"location",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"sett_arr_loc"),
                kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @""
        }];
        locationCellData.updateData = ^() {
            [locationCellData setData:@{ kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getDirName] : @"" }];
        };
        return locationCellData;
    };

    if (self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack])
        [infoCells addObject:generateDataForLocationCellData()];

    OAGPXTableSectionData *infoSectionData = [OAGPXTableSectionData withData:@{
            kSectionCells: infoCells,
            kSectionHeader: OALocalizedString(@"shared_string_info"),
            kSectionHeaderHeight: @56.
    }];
    infoSectionData.updateData = ^() {
        createdOn = generateCreatedOnString();
        OAGPXTableCellData *createdOnCellData = [infoSectionData getCell:@"created_on"];
        if (createdOn.length > 0 && !createdOnCellData)
            [infoSectionData.cells insertObject:generateDataForCreatedOnCellData() atIndex:kInfoCreatedOnCell];
        else if (createdOn.length == 0 && createdOnCellData)
            [infoSectionData.cells removeObject:createdOnCellData];

        BOOL isCurrentTrack = self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack];
        OAGPXTableCellData *locationCellData = [infoSectionData getCell:@"location"];
        if (!isCurrentTrack && !locationCellData)
            [infoSectionData.cells addObject:generateDataForLocationCellData()];
        else if (isCurrentTrack && locationCellData)
            [infoSectionData.cells removeObject:locationCellData];

        for (OAGPXTableCellData *cellData in infoSectionData.cells)
        {
            if (cellData.updateData)
                cellData.updateData();
        }
    };

    [tableSections addObject:infoSectionData];

    self.tableData = [OAGPXTableData withData:@{ kTableSections: tableSections }];
    self.tableData.updateData = ^() {
        for (OAGPXTableSectionData *sectionData in tableSections)
        {
            if (sectionData.updateData)
                sectionData.updateData();
        }
    };

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

@end
