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
#import "OAWebViewCell.h"
#import "OAColors.h"
#import "OAWikiArticleHelper.h"
#import "OAImageDescTableViewCell.h"

#define kInfoCreatedOnCell 0

@interface OATrackMenuTabOverview ()

@property (nonatomic) OAGPXTableData *tableData;

@end

@implementation OATrackMenuTabOverview
{
    NSMutableArray *_results;
    NSMutableString *_parsedString;
    NSXMLParser *_xmlParser;
}

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
    NSString *description = self.trackMenuDelegate ? [self.trackMenuDelegate generateDescription] : @"";
    NSMutableArray<OAGPXTableCellData *> *descriptionCells = [NSMutableArray array];
    
    if ((!imageURL || imageURL.length == 0) && description && description.length > 0)
        imageURL = [self findFirstImageURL:description];
    if (imageURL)
    {
        OAGPXTableCellData *imageCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"image",
                kCellType: [OAImageDescTableViewCell getCellIdentifier],
                kTableValues: @{ @"img": imageURL }
        }];
        [descriptionCells addObject:imageCellData];
    }

    if (!description || description.length == 0)
    {
        OAGPXTableCellData *addDescriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"add_description",
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
        
        OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
                kSectionCells: descriptionCells,
                kSectionHeader: OALocalizedString(@"description"),
                kSectionHeaderHeight: @56.
        }];
        [tableSections addObject:descriptionSectionData];
    }
    else
    {
        description = [OAWikiArticleHelper getFirstParagraph:description];
        
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
        descriptionCellData.updateData = ^() {
            [descriptionCellData setData:@{ kTableValues: @{ @"attr_string_value": generateDescriptionAttrString() } }];
        };
        [descriptionCells addObject:descriptionCellData];

        OAGPXTableCellData *editDescriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"context_menu_edit_descr",
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
        
        OAGPXTableCellData *readFullDescriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"read_full_description",
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
        
        [descriptionCells addObject:editDescriptionCellData];
        [descriptionCells addObject:readFullDescriptionCellData];

        OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
                kSectionCells: descriptionCells,
                kSectionHeader: OALocalizedString(@"description"),
                kSectionHeaderHeight: @56.
        }];
        descriptionSectionData.updateData = ^() {
            for (OAGPXTableCellData *cellData in descriptionSectionData.cells)
            {
                if (cellData.updateData)
                    cellData.updateData();
            }
        };

        [tableSections addObject:descriptionSectionData];
    }

    NSMutableArray<OAGPXTableCellData *> *infoCells = [NSMutableArray array];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kCellKey: @"size",
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
                kCellKey: @"created_on",
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
                kCellKey: @"location",
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
        BOOL hasCreatedOn = [infoSectionData containsCell:@"created_on"];
        if (createdOn.length > 0 && !hasCreatedOn)
            [infoSectionData.cells insertObject:generateDataForCreatedOnCellData() atIndex:kInfoCreatedOnCell];
        else if (createdOn.length == 0 && hasCreatedOn)
            [infoSectionData.cells removeObjectAtIndex:kInfoCreatedOnCell];

        BOOL isCurrentTrack = self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack];
        BOOL hasLocation = [infoSectionData.cells.lastObject.key isEqualToString:@"location"];
        if (!isCurrentTrack && !hasLocation)
            [infoSectionData.cells addObject:generateDataForLocationCellData()];
        else if (isCurrentTrack && hasLocation)
            [infoSectionData.cells removeObject:infoSectionData.cells.lastObject];

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
