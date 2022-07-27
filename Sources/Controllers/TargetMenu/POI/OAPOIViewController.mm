//
//  OAPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIViewController.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAPOILocationType.h"
#import "OACollapsableLabelView.h"
#import "OAColors.h"
#import "OATransportStopType.h"
#import "OATransportStopRoute.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "Localization.h"
#import "OACollapsableNearestPoiTypeView.h"
#import "OAOsmAndFormatter.h"
#import "OAResourcesUIHelper.h"
#import "OALabel.h"
#import "OAWikiArticleHelper.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

#define WIKI_LINK @".wikipedia.org/w"

static const NSInteger AMENITY_ID_RIGHT_SHIFT = 1;
static const NSInteger NON_AMENITY_ID_RIGHT_SHIFT = 7;
static const NSInteger WAY_MODULO_REMAINDER = 1;

@interface OAPOIViewController ()

@end

@implementation OAPOIViewController
{
    OAPOIHelper *_poiHelper;
    std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> _openingHoursInfo;
}

static const NSArray<NSString *> *kContactUrlTags = @[@"youtube", @"facebook", @"instagram", @"twitter", @"vk", @"ok", @"webcam", @"telegram", @"linkedin", @"pinterest", @"foursquare", @"xing", @"flickr", @"email", @"mastodon", @"diaspora", @"gnusocial", @"skype"];
static const NSArray<NSString *> *kContactPhoneTags = @[PHONE, MOBILE, @"whatsapp", @"viber"];

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (id) initWithPOI:(OAPOI *)poi
{
    self = [self init];
    if (self)
    {
        _poi = poi;
        if (poi.hasOpeningHours)
            _openingHoursInfo = OpeningHoursParser::getInfo([poi.openingHours UTF8String]);
        
        if ([poi.type.category.name isEqualToString:@"transportation"])
        {
            BOOL showTransportStops = NO;
            OAPOIFilter *f = [poi.type.category getPoiFilterByName:@"public_transport"];
            if (f)
            {
                for (OAPOIType *t in f.poiTypes)
                {
                    if ([t.name isEqualToString:poi.type.name])
                    {
                        showTransportStops = YES;
                        break;
                    }
                }
            }
            if (showTransportStops)
                [self processTransportStop];
        }
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (NSString *) getTypeStr
{
    OAPOIType *type = self.poi.type;
    NSMutableString *str = [NSMutableString string];
    if ([self.poi.nameLocalized isEqualToString:self.poi.type.nameLocalized])
    {
        /*
         if (type.filter && type.filter.nameLocalized)
         {
         [str appendString:type.filter.nameLocalized];
         }
         else*/ if (type.category && type.category.nameLocalized)
         {
             [str appendString:type.category.nameLocalized];
         }
    }
    else if (type.nameLocalized)
    {
        [str appendString:type.nameLocalized];
    }
    
    if (str.length == 0)
    {
        return [self getCommonTypeStr];
    }
    
    if (self.localMapIndexItem && self.localMapIndexItem.sizePkg && self.localMapIndexItem.sizePkg > 0)
    {
        return [NSString stringWithFormat:@"%@ - %@", str, [NSByteCountFormatter stringFromByteCount:self.localMapIndexItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
    }
    
    return str;
}

- (UIColor *) getAdditionalInfoColor
{
    if (!_openingHoursInfo.empty())
    {
        bool open = false;
        for (auto info : _openingHoursInfo)
        {
            if (info->opened || info->opened24_7)
            {
                open = true;
                break;
            }
        }
        return open ? UIColorFromRGB(color_ctx_menu_amenity_opened_text) : UIColorFromRGB(color_ctx_menu_amenity_closed_text);
    }
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    if (!_openingHoursInfo.empty())
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        UIColor *colorOpen = UIColorFromRGB(color_ctx_menu_amenity_opened_text);
        UIColor *colorClosed = UIColorFromRGB(color_ctx_menu_amenity_closed_text);
        for (int i = 0; i < _openingHoursInfo.size(); i ++)
        {
            auto info = _openingHoursInfo[i];

            if (str.length > 0)
                [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

            NSString *time = [NSString stringWithUTF8String:info->getInfo().c_str()];

            NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", time]];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            BOOL opened = info->fallback && i > 0 ? _openingHoursInfo[i - 1]->opened : info->opened;
            attachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_travel_time"]
                                                                             color:opened ? colorOpen : colorClosed];
            
            NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
            [s replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:strWithImage];
            [s addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            [s addAttribute:NSForegroundColorAttributeName value:opened ? colorOpen : colorClosed range:NSMakeRange(0, s.length)];
            [str appendAttributedString:s];
        }
        
        UIFont *font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, str.length)];
        
        return str;
    }
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (id) getTargetObj
{
    return self.poi;
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (BOOL) showNearestPoi
{
    return YES;
}

- (BOOL) showRegionNameOnDownloadButton
{
    return YES;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    BOOL hasWiki = NO;
    NSString *preferredLang = [OAUtilities preferredLang];
    NSMutableArray<OARowInfo *> *infoRows = [NSMutableArray array];
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];

    NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *poiAdditionalCategories = [NSMutableDictionary dictionary];
    OARowInfo *cuisineRow;
    NSMutableArray<OAPOIType *> *collectedPoiTypes = [NSMutableArray array];

    BOOL osmEditingEnabled = [OAPlugin isEnabled:OAOsmEditingPlugin.class];

    for (NSString *key in [self.poi getAdditionalInfo].allKeys)
    {
        NSString *iconId;
        UIImage *icon;
        UIColor *textColor;
        NSString *vl = [self.poi getAdditionalInfo][key];

        if ([key isEqualToString:@"image"]
                || [key isEqualToString:MAPILLARY]
                || [key isEqualToString:@"subway_region"]
                || ([key isEqualToString:@"note"] && !osmEditingEnabled)
                || [key hasPrefix:@"lang_yes"])
            continue;

        NSString *textPrefix = @"";
        OACollapsableView *collapsableView;
        BOOL collapsable = NO;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = !([key isEqualToString:@"population"] || [key isEqualToString:@"height"] || [key isEqualToString:OPENING_HOURS]);
        BOOL needIntFormatting = [key isEqualToString:@"population"];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        BOOL isCuisine = NO;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";

        OAPOIType *poiType = [self.poi.type.category getPoiTypeByKeyName:key];
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
        if (!pt && vl && vl.length > 0 && vl.length < 50)
            pt = [_poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", key, vl]];

        OAPOIType *pType = nil;
        if (pt)
        {
            pType = (OAPOIType *) pt;
            if (pType.filterOnly)
                continue;

            poiTypeOrder = pType.order;
            poiTypeKeyName = pType.name;
        }

        if ([vl hasPrefix:@"http://"] || [vl hasPrefix:@"https://"] || [vl hasPrefix:@"HTTP://"] || [vl hasPrefix:@"HTTPS://"])
        {
            isUrl = YES;
            textColor = UIColorFromRGB(kHyperlinkColor);
        }
        else if (needLinks)
        {
            NSString *socialMediaUrl = [self getSocialMediaUrl:key value:vl];
            if (socialMediaUrl)
            {
                isUrl = YES;
                textColor = UIColorFromRGB(kHyperlinkColor);
            }
        }

        if (pType && !pType.isText)
        {
            NSString *categoryName = pType.poiAdditionalCategory;
            if (categoryName && categoryName.length > 0)
            {
                NSMutableArray<OAPOIType *> *poiAdditionalCategoryTypes = poiAdditionalCategories[categoryName];
                if (!poiAdditionalCategoryTypes)
                {
                    poiAdditionalCategoryTypes = [NSMutableArray array];
                    poiAdditionalCategories[categoryName] = poiAdditionalCategoryTypes;
                }
                [poiAdditionalCategoryTypes addObject:pType];
                continue;
            }
        }

        if ([self.poi.type.category isWiki])
        {
            if (!hasWiki)
            {
                NSString *articleLang = [OAPlugin onGetMapObjectsLocale:self.poi preferredLocale:preferredLang];
                NSString *lng = [self.poi getContentLanguage:@"content" lang:articleLang defLang:@"en"];
                if (!lng || lng.length == 0)
                    lng = @"en";

                NSString *langSelected = lng;
                NSString *content = [self.poi getDescription:langSelected];
                vl = content != nil ? [OAWikiArticleHelper getPartialContent:content] : @"";
                vl = vl == nil ? @"" : vl;
                hasWiki = YES;
                needLinks = NO;
            }
            else
            {
                continue;
            }
        }
        else if ([key hasPrefix:@"name:"])
        {
            continue;
        }
        else if ([key isEqualToString:COLLECTION_TIMES] || [key isEqualToString:SERVICE_TIMES])
        {
            iconId = @"ic_action_time";
            needLinks = NO;
        }
        else if ([key isEqualToString:OPENING_HOURS])
        {
            iconId = @"ic_action_time";
            collapsableView = [[OACollapsableLabelView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            collapsableView.collapsed = YES;
            ((OACollapsableLabelView *) collapsableView).label.text =
                    [[[self.poi getAdditionalInfo][key] stringByReplacingOccurrencesOfString:@"; " withString:@"\n"]
                                                        stringByReplacingOccurrencesOfString:@"," withString:@", "];
            collapsable = YES;
            auto rs = OpeningHoursParser::parseOpenedHours([[self.poi getAdditionalInfo][key] UTF8String]);
            if (rs != nullptr)
            {
                vl = [NSString stringWithUTF8String:rs->toLocalString().c_str()];
                BOOL opened = rs->isOpenedForTime([NSDate.date toTm]);
                textColor = opened ? UIColorFromRGB(color_place_open) : UIColorFromRGB(color_place_closed);
            }
            vl = [vl stringByReplacingOccurrencesOfString:@"; " withString:@"\n"];
            needLinks = NO;
        }
        else if ([kContactPhoneTags containsObject:key])
        {
            iconId = @"ic_phone_number";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isPhoneNumber = YES;
        }
        else if ([key isEqualToString:WEBSITE] || [kContactUrlTags containsObject:key])
        {
            if ([kContactUrlTags containsObject:key])
            {
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:key]];
                if (!icon)
                    icon = [OATargetInfoViewController getIcon:[OAUtilities drawablePath:[@"mm_" stringByAppendingString:key]]];
            }
            iconId = @"ic_website";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isUrl = YES;
        }
        else if ([key isEqualToString:CUISINE])
        {
            isCuisine = YES;
            iconId = @"ic_cuisine";
            NSMutableString *sb = [NSMutableString string];
            for (NSString *c in [vl componentsSeparatedByString:@";"])
            {
                if (sb.length > 0)
                {
                    [sb appendString:@", "];
                    [sb appendString:[_poiHelper getPhraseByName:[[@"cuisine_" stringByAppendingString:c] lowercaseString]]];
                }
                else
                {
                    [sb appendString:[_poiHelper getPhraseByName:[@"cuisine_" stringByAppendingString:c]]];
                }
            }
            textPrefix = [_poiHelper getPhraseByName:@"cuisine"];
            vl = sb;
        }
        else if ([key containsString:ROUTE]
                || [key isEqualToString:WIKIDATA]
                || [key isEqualToString:WIKIMEDIA_COMMONS])
        {
            continue;
        }
        else
        {
            if ([key containsString:DESCRIPTION])
            {
                iconId = @"ic_description";
            }
            else if (isUrl && [vl containsString:WIKI_LINK])
            {
                iconId = @"ic_custom_wikipedia";
            }
            else if ([key isEqualToString:@"addr:housename"] || [key isEqualToString:@"whitewater:rapid_name"])
            {
                iconId = @"ic_custom_poi_name";
            }
            else if ([key isEqualToString:@"operator"] || [key isEqualToString:@"brand"])
            {
                iconId = @"ic_custom_poi_brand";
            }
            else if ([key isEqualToString:@"internet_access_fee_yes"])
            {
                iconId = @"ic_custom_internet_access_fee";
            }
            else
            {
                iconId = @"ic_operator";
            }
            if (pType)
            {
                poiTypeOrder = pType.order;
                poiTypeKeyName = pType.name;
                if (pType.parentType && [pType.parentType isKindOfClass:OAPOIType.class])
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@_%@_%@", ((OAPOIType *) pType.parentType).tag, [pType.tag stringByReplacingOccurrencesOfString:@":" withString:@"_"], pType.value]];
                }
                if (!pType.isText)
                {
                    vl = pType.nameLocalized;
                }
                else
                {
                    isText = YES;
                    isDescription = [iconId isEqualToString:@"ic_description"];
                    textPrefix = pType.nameLocalized;
                    if (needIntFormatting && [self isNumericValue:vl])
                    {
                        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                        NSInteger population = [vl integerValue];
                        vl = [numberFormatter stringFromNumber:@(population)];
                    }
                }
                if (!isDescription && !icon)
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
                    if (isText && icon)
                        textPrefix = @"";
                }
                if (!icon && isText && !iconId)
                    iconId = @"ic_description";
            }
            else if (poiType)
            {
                [collectedPoiTypes addObject:poiType];
            }
            else
            {
                textPrefix = key.capitalizedString;
            }
        }

        NSArray<NSString *> *formattedPrefixAndText = [self getFormattedPrefixAndText:key prefix:textPrefix value:vl amenity:self.poi];
        textPrefix = formattedPrefixAndText[0];
        vl = formattedPrefixAndText[1];

        if ([key isEqualToString:@"ele"] && [self isNumericValue:vl])
        {
            float distance = [vl floatValue];
            vl = [OAOsmAndFormatter getFormattedAlt:distance];
            NSString *collapsibleVal;
            EOAMetricsConstant metricSystem = [[OAAppSettings sharedManager].metricSystem get];
            if (metricSystem == MILES_AND_FEET || metricSystem == MILES_AND_YARDS)
                collapsibleVal = [OAOsmAndFormatter getFormattedAlt:distance mc:KILOMETERS_AND_METERS];
            else
                collapsibleVal = [OAOsmAndFormatter getFormattedAlt:distance mc:MILES_AND_FEET];

            collapsableView = [[OACollapsableLabelView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            collapsableView.collapsed = YES;
            ((OACollapsableLabelView *) collapsableView).label.text = collapsibleVal;
            collapsable = YES;
        }

        OARowInfo *row;
        if (isDescription)
        {
            row = [[OARowInfo alloc] initWithKey:key
                                           icon:[UIImage imageNamed:@"ic_description"]
                                      textPrefix:textPrefix
                                            text:vl
                                       textColor:nil
                                          isText:YES
                                       needLinks:YES
                                           order:0
                                        typeName:@""
                                   isPhoneNumber:NO
                                           isUrl:NO];
        }
        else
        {
            row = [[OARowInfo alloc] initWithKey:key
                                            icon:icon ? icon : [OATargetInfoViewController getIcon:iconId]
                                      textPrefix:textPrefix
                                            text:vl
                                       textColor:textColor
                                          isText:isText
                                       needLinks:needLinks
                                           order:poiTypeOrder
                                        typeName:poiTypeKeyName
                                   isPhoneNumber:isPhoneNumber
                                           isUrl:isUrl];
        }
        row.collapsable = collapsable;
        row.collapsed = YES;
        row.collapsableView = collapsableView;

        if (isDescription)
            [descriptions addObject:row];
        else if (isCuisine)
            cuisineRow = row;
        else if (!poiType)
            [infoRows addObject:row];
    }

    if (cuisineRow)
    {
        BOOL hasCuisineOrDish = poiAdditionalCategories[CUISINE] != nil || poiAdditionalCategories[DISH] != nil;
        if (!hasCuisineOrDish)
            [infoRows addObject:cuisineRow];
    }

    [poiAdditionalCategories enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull categoryName, NSArray<OAPOIType *> * _Nonnull categoryTypes, BOOL * _Nonnull stop) {
        if (categoryTypes.count > 0)
        {
            UIImage *icon;
            OAPOIType *pType = categoryTypes.firstObject;
            NSString *poiAdditionalCategoryName = pType.poiAdditionalCategory;
            NSString *poiAdditionalIconName = [_poiHelper getPoiAdditionalCategoryIcon:poiAdditionalCategoryName];
            if (poiAdditionalIconName)
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:poiAdditionalIconName]];
            if (!icon)
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:poiAdditionalCategoryName]];
            if (!icon)
                icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
            if (!icon)
                icon = [UIImage imageNamed:@"ic_description"];

            NSMutableString *sb = [NSMutableString new];
            for (OAPOIType *pt in categoryTypes)
            {
                if (sb.length > 0)
                    [sb appendString:@" • "];
                [sb appendString:pt.nameLocalized];
            }

            BOOL cuisineOrDish = [categoryName isEqualToString:CUISINE] || [categoryName isEqualToString:DISH];
            OACollapsableNearestPoiTypeView *collapsableView = [[OACollapsableNearestPoiTypeView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            collapsableView.collapsed = YES;
            [collapsableView setData:categoryTypes
                             amenity:self.poi
                                 lat:self.poi.latitude
                                 lon:self.poi.longitude
                     isPoiAdditional:YES
                             textRow:cuisineOrDish ? cuisineRow : nil];
            OARowInfo *row = [[OARowInfo alloc] initWithKey:poiAdditionalCategoryName
                                                       icon:icon
                                                 textPrefix:pType.poiAdditionalCategoryLocalized
                                                       text:sb
                                                  textColor:nil
                                                     isText:NO
                                                  needLinks:NO
                                                      order:pType.order
                                                   typeName:pType.name
                                              isPhoneNumber:NO
                                                      isUrl:NO];
            row.collapsed = YES;
            row.collapsable = YES;
            row.collapsableView = collapsableView;
            [infoRows addObject:row];
        }
    }];

    if (collectedPoiTypes.count > 0)
    {
        OACollapsableNearestPoiTypeView *collapsableView = [[OACollapsableNearestPoiTypeView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
        collapsableView.collapsed = YES;
        [collapsableView setData:collectedPoiTypes
                         amenity:self.poi
                             lat:self.poi.latitude
                             lon:self.poi.longitude
                 isPoiAdditional:NO
                         textRow:nil];
        OAPOIType *poiCategory = self.poi.type;
        UIImage *icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", poiCategory.name]];
        NSMutableString *sb = [NSMutableString new];
        for (OAPOIType *pt in collectedPoiTypes)
        {
            if (sb.length > 0)
                [sb appendString:@" • "];
            [sb appendString:pt.nameLocalized];
        }
        OARowInfo *row = [[OARowInfo alloc] initWithKey:poiCategory.name
                                                   icon:icon
                                             textPrefix:poiCategory.nameLocalized
                                                   text:sb
                                              textColor:nil
                                                 isText:NO
                                              needLinks:NO
                                                  order:40
                                               typeName:poiCategory.name
                                          isPhoneNumber:NO
                                                  isUrl:NO];
        row.collapsed = YES;
        row.collapsable = YES;
        row.collapsableView = collapsableView;
        [infoRows addObject:row];
    }

    [infoRows sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
            return NSOrderedAscending;
        else if (row1.order == row2.order)
            return [row1.typeName localizedCompare:row2.typeName];
        else
            return NSOrderedDescending;
    }];

    for (OARowInfo *row in infoRows)
    {
        [rows addObject:row];
    }

    NSString *langSuffix = [@":" stringByAppendingString:preferredLang];
    OARowInfo *descInPrefLang;
    for (OARowInfo *desc in descriptions)
    {
        if (desc.key.length > langSuffix.length
                && [[desc.key substringFromIndex:desc.key.length - langSuffix.length] isEqualToString:langSuffix])
        {
            descInPrefLang = desc;
            break;
        }
    }
    if (descInPrefLang)
    {
        [descriptions removeObject:descInPrefLang];
        [descriptions insertObject:descInPrefLang atIndex:0];
    }
    for (OARowInfo *desc in descriptions)
    {
        [rows addObject:desc];
    }

    long long objectId = self.poi.obfId;
    if (osmEditingEnabled && (objectId > 0 && ((objectId % 2 == AMENITY_ID_RIGHT_SHIFT) || (objectId >> NON_AMENITY_ID_RIGHT_SHIFT) < INT_MAX)))
    {
        OAPOIType *poiType = self.poi.type;
        BOOL isAmenity = poiType && ![poiType isKindOfClass:[OAPOILocationType class]];

        long long entityId = objectId >> (isAmenity ? AMENITY_ID_RIGHT_SHIFT : NON_AMENITY_ID_RIGHT_SHIFT);
        BOOL isWay = objectId % 2 == WAY_MODULO_REMAINDER; // check if mapObject is a way
        NSString *link = isWay ? @"https://www.openstreetmap.org/way/" : @"https://www.openstreetmap.org/node/";
        [rows addObject:[[OARowInfo alloc] initWithKey:nil
                                                  icon:[UIImage imageNamed:@"ic_custom_osm_edits"]
                                            textPrefix:nil
                                                  text:[NSString stringWithFormat:@"%@%llu", link, entityId]
                                             textColor:UIColorFromRGB(kHyperlinkColor)
                                                isText:YES
                                             needLinks:YES
                                                 order:10000
                                              typeName:nil
                                         isPhoneNumber:NO
                                                 isUrl:YES]];
    }
}

- (NSString *)getSocialMediaUrl:(NSString *)key value:(NSString *)value
{
    // Remove leading and closing slashes
    NSMutableString *sb = [NSMutableString stringWithString:[value trim]];
    if ([sb characterAtIndex:0] == '/')
        [sb deleteCharactersInRange:NSMakeRange(0, 1)];
    NSInteger lastIdx = sb.length - 1;
    if ([sb characterAtIndex:lastIdx] == '/')
        [sb deleteCharactersInRange:NSMakeRange(lastIdx, 1)];

    // It cannot be username
    if ([sb containsString:@"/"])
        return [@"https://" stringByAppendingString:value];

    NSMutableDictionary<NSString *, NSString *> *urls = [NSMutableDictionary dictionary];
    urls[@"facebook"] = @"https://facebook.com/";
    urls[@"vk"] = @"https://vk.com/";
    urls[@"instagram"] = @"https://instagram.com/";
    urls[@"twitter"] = @"https://twitter.com/";
    urls[@"ok"] = @"https://ok.ru/";
    urls[@"telegram"] = @"https://t.me/";
    urls[@"flickr"] = @"https://flickr.com/";

    if ([urls.allKeys containsObject:key])
        return [urls[key] stringByAppendingString:value];
    else
        return nil;
}

- (NSArray<NSString *> *)getFormattedPrefixAndText:(NSString *)key
                                            prefix:(NSString *)prefix
                                             value:(NSString *)value
                                           amenity:(OAPOI *)amenity
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.decimalSeparator = @".";

    EOAMetricsConstant metricSystem = [[OAAppSettings sharedManager].metricSystem get];

    NSString *formattedValue = value;
    NSString *formattedPrefix = prefix;
    if ([key isEqualToString:@"width"])
    {
        formattedPrefix = OALocalizedString(@"shared_string_width");
    }
    else if ([key isEqualToString:@"height"])
    {
        formattedPrefix = OALocalizedString(@"shared_string_height");
    }
    else if (([key isEqualToString:@"depth"] || [key isEqualToString:@"seamark_height"]) && [self isNumericValue:value])
    {
        double valueAsDouble = [value doubleValue];
        if (metricSystem == MILES_AND_FEET)
        {
            valueAsDouble *= FEET_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"units_ft")];
        }
        else if (metricSystem == MILES_AND_YARDS)
        {
            valueAsDouble *= YARDS_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"units_yd")];
        }
        else
        {
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"units_m")];
        }
    }
    else if ([key isEqualToString:@"distance"] && [self isNumericValue:value])
    {
        float valueAsFloatInMeters = [value floatValue] * 1000;
        if (metricSystem == KILOMETERS_AND_METERS)
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"units_km")];
        else
            formattedValue = [OAOsmAndFormatter getFormattedDistance:valueAsFloatInMeters];

        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_distance")];
    }
    else if ([key isEqualToString:@"capacity"] && [self isNumericValue:value] && ([amenity.subType isEqualToString:@"water_tower"] || [amenity.subType isEqualToString:@"storage_tank"]))
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"units_cubic_m")];
    }
    else if ([key isEqualToString:@"maxweight"] && [self isNumericValue:value])
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"units_t")];
    }
    else if (([key isEqualToString:@"students"] || [key isEqualToString:@"spots"] || [key isEqualToString:@"seats"]) && [self isNumericValue:value])
    {
        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_capacity")];
    }
    else if ([key isEqualToString:@"wikipedia"])
    {
        formattedPrefix = OALocalizedString(@"product_title_wiki");
    }
    return @[formattedPrefix, formattedValue];
}

- (NSString *)formatPrefix:(NSString *)prefix units:(NSString *)units
{
    return prefix != nil && prefix.length > 0 ? [NSString stringWithFormat:@"%@, %@", prefix, units] : units;
}

- (BOOL) isNumericValue:(NSString *)value
{
    return [value rangeOfCharacterFromSet: [ [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"] invertedSet] ].location == NSNotFound;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES; 
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (void) processTransportStop
{
    NSMutableArray<OATransportStopRoute *> *routes = [NSMutableArray array];

    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    BOOL isSubwayEntrance = [self.poi.type.name isEqualToString:@"subway_entrance"];

    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.poi.latitude, self.poi.longitude));
    auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(isSubwayEntrance ? 400 : 150, point31);
    searchCriteria->bbox31 = bbox31;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.left() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.bottom() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.right() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM));
    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport));

    const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
    search->performSearch(*searchCriteria,
                          [self, routes, dataInterface, prefLang, transliterate, isSubwayEntrance]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto transportStop = ((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop;
                              auto dist = OsmAnd::Utilities::distance(transportStop->location.longitude, transportStop->location.latitude, self.poi.longitude, self.poi.latitude);
                              [self addRoutes:routes dataInterface:dataInterface s:transportStop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance];
                          });
    
    [routes sortUsingComparator:^NSComparisonResult(OATransportStopRoute* _Nonnull o1, OATransportStopRoute* _Nonnull o2) {
        if (o1.distance != o2.distance)
            return [OAUtilities compareInt:o1.distance y:o2.distance];
        
        int i1 = [OAUtilities extractFirstIntegerNumber:o1.desc];
        int i2 = [OAUtilities extractFirstIntegerNumber:o2.desc];
        if (i1 != i2)
            return [OAUtilities compareInt:i1 y:i2];
        
        return [o1.desc compare:o2.desc];
    }];
    
    self.routes = [NSArray arrayWithArray:routes];
}

- (void) addRoutes:(NSMutableArray<OATransportStopRoute *> *)routes dataInterface:(std::shared_ptr<OsmAnd::ObfDataInterface>)dataInterface s:(std::shared_ptr<const OsmAnd::TransportStop>)s lang:(NSString *)lang transliterate:(BOOL)transliterate dist:(int)dist isSubwayEntrance:(BOOL)isSubwayEntrance
{
    QList< std::shared_ptr<const OsmAnd::TransportRoute> > rts;
    auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();

    if (dataInterface->getTransportRoutes(s, &rts, stringTable.get()))
    {
        for (auto rs : rts)
        {
            if (![self containsRef:routes transportRoute:rs])
            {
                OATransportStopType *t = [OATransportStopType findType:rs->type.toNSString()];
                if (isSubwayEntrance && t.type != TST_SUBWAY && dist > 150)
                    continue;
                
                OATransportStopRoute *r = [[OATransportStopRoute alloc] init];
                r.type = t;
                r.desc = rs->getName(QString::fromNSString(lang), transliterate).toNSString();
                r.route = rs;
                r.stop = s;
                if ([OAUtilities isCoordEqual:self.poi.latitude srcLon:self.poi.longitude destLat:s->location.latitude destLon:s->location.longitude] || (isSubwayEntrance && t.type == TST_SUBWAY))
                    r.refStop = s;
                
                r.distance = dist;
                [routes addObject:r];
            }
        }
    }
}

- (BOOL) containsRef:(NSArray<OATransportStopRoute *> *)routes transportRoute:(std::shared_ptr<const OsmAnd::TransportRoute>)transportRoute
{
    for (OATransportStopRoute *route in routes)
        if (route.route->ref == transportRoute->ref)
            return YES;

    return NO;
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    NSMutableArray<OATransportStopRoute *> *res = [NSMutableArray array];
    for (OATransportStopRoute *route in self.routes)
    {
        BOOL isCurrentRouteLocal = route.refStop && route.refStop->getName("", false) == route.stop->getName("", false);
        if (!nearby && isCurrentRouteLocal)
            [res addObject:route];
        else if (nearby && !route.refStop)
            [res addObject:route];
    }
    return res;
}

@end
