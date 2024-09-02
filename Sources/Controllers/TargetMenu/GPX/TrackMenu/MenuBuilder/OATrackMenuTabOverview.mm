//
//  OATrackMenuTabOverview.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuTabOverview.h"
#import "OATextMultilineTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAWikiArticleHelper.h"
#import "OAImageDescTableViewCell.h"
#import "OAPOIType.h"
#import "OARouteKey.h"
#import "OAPOIHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAOsmEditingPlugin.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

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
    NSMutableArray<NSDictionary *> *_nameTags;
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

    BOOL hasArticle = NO;
    if (self.trackMenuDelegate)
    {
        OAMetadata *metadata = [self.trackMenuDelegate getMetadata];
        if (metadata)
        {
            OAGpxExtension *articleTitleExtension = [metadata getExtensionByKey:@"article_title"];
            if (articleTitleExtension)
            {
                OAGPXTableSectionData *wikivoyageSectionData = [OAGPXTableSectionData withData:@{
                    kTableKey: @"sectionWikivoyage",
                    kSectionHeader: OALocalizedString(@"shared_string_wikivoyage"),
                    kSectionHeaderHeight: @56.
                }];
                [self.tableData.subjects addObject:wikivoyageSectionData];
                
                OATravelObfHelper *helper = [OATravelObfHelper shared];
                OAGpxExtension *articleLangExtension = [metadata getExtensionByKey:@"article_lang"];
                NSString *lang = articleLangExtension ? articleLangExtension.value : @"en";
                OATravelArticle *article = [helper getArticleByTitle:articleTitleExtension.value lang:lang];
                if (article)
                {
                    hasArticle = YES;
                    NSString *geoDescription = [article getGeoDescription];
                    NSString *iconName = @"";
                    if (article.imageTitle && article.imageTitle.length > 0)
                    {
                        iconName = [OATravelArticle getImageUrlWithImageTitle:article.imageTitle ? article.imageTitle : @"" thumbnail:NO];
                    }
                    OAGPXTableCellData *articleRow = [OAGPXTableCellData withData:@{
                        kTableKey: @"article",
                        kCellType: [OAArticleTravelCell getCellIdentifier],
                        kCellTitle: article.title ? article.title : @"nil",
                        kCellDesc: [OATravelGuidesHelper getPatrialContent:article.content],
                        kCellRightIconName: iconName,
                        kTableValues: @{
                            @"isPartOf": geoDescription ? geoDescription : @"",
                            @"article": article,
                            @"lang": lang
                        }
                    }];
                    [wikivoyageSectionData.subjects addObject:articleRow];

                    OAGPXTableCellData *readCellData = [OAGPXTableCellData withData:@{
                        kTableKey: @"readArticle",
                        kCellType: [OASimpleTableViewCell getCellIdentifier],
                        kCellTitle: OALocalizedString(@"shared_string_read"),
                        kTableValues: @{ @"articleId": [article generateIdentifier], @"lang": lang }
                    }];
                    [wikivoyageSectionData.subjects addObject:readCellData];
                }
            }
        }

        if (!hasArticle)
        {
            OAGPXTableSectionData *descriptionSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_description",
                kSectionHeader: OALocalizedString(@"shared_string_description"),
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
        }

        OARouteKey *key = self.trackMenuDelegate.getRouteKey;
        [self populateRouteInfoSection:self.tableData routeKey:key];
    }

    OAGPXTableSectionData *generalSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_general",
            kSectionHeader: OALocalizedString(@"general_settings"),
            kSectionHeaderHeight: @56.
    }];
    [self.tableData.subjects addObject:generalSectionData];

    OAGPXTableCellData *createdOnCellData = [self generateCreatedOnCellData];
    if (createdOnCellData.desc && createdOnCellData.desc.length > 0)
        [generalSectionData.subjects addObject:createdOnCellData];

    OAGPXTableCellData *sizeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"size",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"shared_string_size"),
            kCellDesc: self.trackMenuDelegate ? [self.trackMenuDelegate getGpxFileSize] : @""
    }];
    [generalSectionData.subjects addObject:sizeCellData];

    OAGPXTableCellData *locationCellData = [self generateLocationCellData];
    if (self.trackMenuDelegate && ![self.trackMenuDelegate currentTrack])
        [generalSectionData.subjects addObject:locationCellData];

    OAGPXTableSectionData *infoSectionData = [self generateInfoSectionData];
    if (infoSectionData)
        [self.tableData.subjects addObject:infoSectionData];

    OAGPXTableSectionData *authorSectionData = [self generateAuthorSectionData];
    if (authorSectionData)
        [self.tableData.subjects addObject:authorSectionData];

    OAGPXTableSectionData *copyrightSectionData = [self generateCopyrightSectionData];
    if (copyrightSectionData)
        [self.tableData.subjects addObject:copyrightSectionData];

    self.isGeneratedData = YES;
}

- (void) populateRouteInfoSection:(OAGPXTableData *)data routeKey:(OARouteKey *)routeKey
{
    if (!routeKey)
        return;
    
    OAGPXTableSectionData *infoSectionData = [OAGPXTableSectionData withData:@{
        kTableKey: @"route_info",
        kSectionHeader: OALocalizedString(@"route_info"),
        kSectionHeaderHeight: @56.
    }];
    [data.subjects addObject:infoSectionData];

    NSString *tag = routeKey.routeKey.getTag().toNSString();
    OAGPXTableCellData *routeCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"route",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"layer_route"),
            kCellDesc: routeKey.getActivityTypeTitle
    }];
    [infoSectionData.subjects addObject:routeCellData];

    NSMutableArray<OAGPXTableCellData *> *subjects = [NSMutableArray array];
    QMap<QString, QString> tagsToGpx = routeKey.routeKey.tagsToGpx();
    _nameTags = [[NSMutableArray alloc] init];
    BOOL hasName = NO;
    for (auto i = tagsToGpx.cbegin(), end = tagsToGpx.cend(); i != end; ++i)
    {
        NSString *routeTagKey = i.key().toNSString();
        if ([routeTagKey hasPrefix:@"osmc"]
            || [routeTagKey isEqualToString:@"name"]
            || ([routeTagKey isEqualToString:@"relation_id"] && ![OAPluginsHelper isEnabled:OAOsmEditingPlugin.class]))
            continue;
        OAPOIBaseType *poiType = [[OAPOIHelper sharedInstance] getAnyPoiAdditionalTypeByKey:routeTagKey];
        if (!poiType && ![routeTagKey isEqualToString:@"symbol"]
            && ![routeTagKey isEqualToString:@"colour"]
            && ![routeTagKey isEqualToString:@"relation_id"])
            continue;
        NSString *routeTagTitle = poiType ? poiType.nameLocalized : @"";
        NSNumber *routeTagOrder = poiType && [poiType isKindOfClass:OAPOIType.class] ? @(((OAPOIType *) poiType).order) : @(90);

        NSString *routeTagValue = i.value().toNSString();
        if ([routeTagKey isEqualToString:@"ascent"] || [routeTagKey isEqualToString:@"descent"])
            routeTagValue = [NSString stringWithFormat:@"%@ %@", routeTagValue, OALocalizedString(@"m")];
        else if ([routeTagKey isEqualToString:@"distance"])
            routeTagValue = [NSString stringWithFormat:@"%@ %@", routeTagValue, OALocalizedString(@"km")];
        else if ([routeTagKey isEqualToString:@"network"])
            routeTagValue = [OAPOIHelper.sharedInstance getPhraseByName:[NSString stringWithFormat:@"route_%@_%@_poi", tag, routeTagValue]];
        else if ([routeTagKey isEqualToString:@"wikipedia"])
            routeTagValue = [OAWikiAlgorithms getWikiUrlWithText:routeTagValue];

        if (!hasName && [[OAPOIHelper sharedInstance] isNameTag:routeTagKey])
        {
            OAGPXTableCellData *routeNameCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"name",
                kCellType: [OAValueTableViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"shared_string_name"),
                kCellDesc: [self.trackMenuDelegate getGpxName],
                kTableValues: @{ @"order": routeTagOrder },
                kCellToggle: @YES
            }];
            [subjects addObject:routeNameCellData];
            hasName = YES;
        }
        // TODO: brand

        if ([routeTagKey isEqualToString:@"colour"])
        {
            routeTagTitle = OALocalizedString(@"shared_string_color");
            NSString *stringKey = [NSString stringWithFormat:@"rendering_value_%@_name", routeTagValue];
            routeTagValue = OALocalizedString(stringKey);
            if ([routeTagValue isEqualToString:stringKey])
                routeTagValue = i.value().toNSString().uppercaseString;
        }
        else if ([routeTagKey isEqualToString:@"symbol"])
        {
            routeTagTitle = OALocalizedString(@"shared_string_symbol");
        }
        else if ([routeTagKey isEqualToString:@"relation_id"])
        {
            routeTagTitle = OALocalizedString(@"osm_id");
        }
        else if ([[OAPOIHelper sharedInstance] isNameTag:routeTagKey])
        {
            [_nameTags addObject:@{
                @"key": routeTagKey,
                @"value": routeTagValue,
                @"localizedTitle": routeTagTitle
            }];
            continue;
        }
        // TODO: brand
        
        OAGPXTableCellData *routeCellData = [OAGPXTableCellData withData:@{
            kTableKey: routeTagKey,
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kCellTitle: routeTagTitle,
            kCellDesc: routeTagValue,
            kTableValues: @{ @"order": routeTagOrder }
        }];
        if ([routeTagKey hasPrefix:@"description"])
            [routeCellData setData:@{ kCellToggle: @YES }];
        [subjects addObject:routeCellData];
    }

    [subjects sortUsingComparator:^NSComparisonResult(OAGPXTableCellData * _Nonnull cellData1, OAGPXTableCellData * _Nonnull cellData2) {
        int order1 = [cellData1.values[@"order"] intValue];
        int order2 = [cellData2.values[@"order"] intValue];
        return [OAUtilities compareInt:order1 y:order2];
    }];

    [infoSectionData.subjects addObjectsFromArray:subjects];
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
                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                         color:[UIColor colorNamed:ACColorNameTextColorPrimary]
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
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"created_on"),
            kCellDesc: [self generateCreatedOnString]
    }];
}

- (OAGPXTableCellData *)generateLocationCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"location",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"shared_string_location"),
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
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"add_description"),
            kCellToggle: @YES,
            kCellTintColor: [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (OAGPXTableCellData *)generateDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"description",
            kCellType: [OATextMultilineTableViewCell getCellIdentifier],
            kTableValues: @{ @"attr_string_value": [self generateDescriptionAttrString] }
    }];
}

- (OAGPXTableCellData *)generateEditDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"edit_description",
            kCellType: [OASimpleTableViewCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"context_menu_edit_descr"),
            kCellToggle: @YES,
            kCellTintColor: [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (OAGPXTableCellData *)generateReadFullDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"read_full_description",
            kCellType: [OASimpleTableViewCell getCellIdentifier],
            kTableValues: @{ @"font_value": [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium] },
            kCellTitle: OALocalizedString(@"read_full_description"),
            kCellToggle: @YES,
            kCellTintColor: [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (OAGPXTableSectionData *)generateInfoSectionData
{
    NSString *keywords = self.trackMenuDelegate ? [self.trackMenuDelegate getKeywords] : nil;
    NSArray<OALink *> *links = self.trackMenuDelegate ? [self.trackMenuDelegate getLinks] : nil;
    BOOL hasKeywords = keywords && keywords.length > 0;
    BOOL hasLinks = links && links.count > 0;
    if (hasKeywords || hasLinks)
    {
        OAGPXTableSectionData *infoSectionData = [OAGPXTableSectionData withData:@{
            kTableKey: @"section_info",
            kSectionHeader: OALocalizedString(@"info_button"),
            kSectionHeaderHeight: @56.
        }];

        if (hasKeywords)
        {
            OAGPXTableCellData *keywordsCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"keywords",
                kCellType: [OAValueTableViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"shared_string_keywords"),
                kCellDesc: keywords
            }];
            [infoSectionData.subjects addObject:keywordsCellData];
        }
        if (hasLinks)
        {
            for (NSInteger i = 0; i < links.count; i++)
            {
                OALink *link = links[i];
                BOOL hasText = link.text && link.text.length > 0;
                OAGPXTableCellData *linkCellData = [OAGPXTableCellData withData:@{
                    kTableKey: [NSString stringWithFormat:@"link_%ld", i],
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_link"),
                    kCellDesc: hasText ? link.text : link.url.absoluteString
                }];
                if (hasText)
                    linkCellData.values[@"url"] = link.url.absoluteString;
                [infoSectionData.subjects addObject:linkCellData];
            }
        }
        return infoSectionData;
    }
    return nil;
}

- (OAGPXTableSectionData *)generateAuthorSectionData
{
    OAAuthor *author = self.trackMenuDelegate ? [self.trackMenuDelegate getAuthor] : nil;
    BOOL hasAuthorName = author && author.name.length > 0;
    BOOL hasAuthorEmail = author && author.email.length > 0;
    BOOL hasAuthorLink = author && author.link;
    if (hasAuthorName || hasAuthorEmail || hasAuthorLink)
    {
        OAGPXTableSectionData *authorSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_author",
                kSectionHeader: OALocalizedString(@"shared_string_author"),
                kSectionHeaderHeight: @56.
        }];

        if (hasAuthorName)
        {
            OAGPXTableCellData *nameCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"author_name",
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_name"),
                    kCellDesc: author.name
            }];
            [authorSectionData.subjects addObject:nameCellData];
        }
        if (hasAuthorEmail)
        {
            OAGPXTableCellData *emailCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"email_author",
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_email"),
                    kCellDesc: author.email
            }];
            [authorSectionData.subjects addObject:emailCellData];
        }
        if (hasAuthorLink)
        {
            BOOL hasText = author.link.text && author.link.text.length > 0;
            OAGPXTableCellData *linkCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"link_author",
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_link"),
                    kCellDesc: hasText ? author.link.text : author.link.url.absoluteString
            }];
            if (hasText)
                linkCellData.values[@"url"] = author.link.url.absoluteString;
            [authorSectionData.subjects addObject:linkCellData];
        }
        return authorSectionData;
    }
    return nil;
}

- (OAGPXTableSectionData *)generateCopyrightSectionData
{
    OACopyright *copyright = self.trackMenuDelegate ? [self.trackMenuDelegate getCopyright] : nil;
    BOOL hasCopyrightAuthor = copyright && copyright.author.length > 0;
    BOOL hasCopyrightLicense = copyright && copyright.license.length > 0;
    if (hasCopyrightAuthor || hasCopyrightLicense)
    {
        OAGPXTableSectionData *copyrightSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_copyright",
                kSectionHeader: OALocalizedString(@"shared_string_author"),
                kSectionHeaderHeight: @56.
        }];

        if (hasCopyrightAuthor)
        {
            NSString *author = copyright.year.length > 0
                ? [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_comma"), copyright.author, copyright.year]
                : copyright.author;
            OAGPXTableCellData *nameCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"copyright_author",
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_author"),
                    kCellDesc: author
            }];
            [copyrightSectionData.subjects addObject:nameCellData];
        }
        if (hasCopyrightLicense)
        {
            OAGPXTableCellData *linkCellData = [OAGPXTableCellData withData:@{
                    kTableKey: @"link_license",
                    kCellType: [OAValueTableViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"shared_string_license"),
                    kCellDesc: copyright.license
            }];
            [copyrightSectionData.subjects addObject:linkCellData];
        }
        return copyrightSectionData;
    }
    return nil;
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
    else if ([tableData.key isEqualToString:@"section_general"])
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
        else if (!createdOnCellData.desc || (createdOnCellData.desc.length == 0 && hasCreatedOn))
            [sectionData.subjects removeObject:createdOnCellData];

        BOOL isCurrentTrack = [self.trackMenuDelegate currentTrack];
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

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData sourceView:(UIView *)sourceView
{
    if (self.trackMenuDelegate)
    {
        if ([tableData.key isEqualToString:@"add_description"])
        {
            [self.trackMenuDelegate openDescriptionEditor];
        }
        else if ([tableData.key isEqualToString:@"edit_description"])
        {
            [self.trackMenuDelegate openDescriptionEditor];
        }
        else if ([tableData.key isEqualToString:@"read_full_description"])
        {
            [self.trackMenuDelegate openDescription];
        }
        else if ([tableData.key isEqualToString:@"readArticle"])
        {
            [self.trackMenuDelegate openArticleById:tableData.values[@"articleId"] lang:tableData.values[@"lang"]];
        }
        else if ([tableData isKindOfClass:OAGPXTableCellData.class])
        {
            OAGPXTableCellData *cellData = (OAGPXTableCellData *) tableData;
            if ([cellData.key isEqualToString:@"wiki"])
            {
                [self.trackMenuDelegate openURL:cellData.desc sourceView:sourceView];
            }
            else if (([cellData.key isEqualToString:@"website"] || [OAWikiAlgorithms isUrl:cellData.desc]))
            {
                [self.trackMenuDelegate openURL:cellData.desc sourceView:sourceView];
            }
            else if ([cellData.key hasPrefix:@"link_"])
            {
                NSString *url = [cellData.values.allKeys containsObject:@"url"] ? cellData.values[@"url"] : cellData.desc;
                [self.trackMenuDelegate openURL:url sourceView:sourceView];
            }
            else if ([cellData.key hasPrefix:@"email_"])
            {
                [self.trackMenuDelegate openURL:cellData.desc sourceView:sourceView];
            }
            else if ([cellData.key isEqualToString:@"relation_id"])
            {
                [self.trackMenuDelegate openURL:[kOsmRelation stringByAppendingString:cellData.desc] sourceView:sourceView];
            }
            else if ([cellData.key hasPrefix:@"description"])
            {
                [self.trackMenuDelegate openDescriptionReadOnly:cellData.desc];
            }
            else if ([cellData.key isEqualToString:@"name"])
            {
                [self.trackMenuDelegate openNameTagsScreenWith:_nameTags];
            }
        }
    }
}

@end
