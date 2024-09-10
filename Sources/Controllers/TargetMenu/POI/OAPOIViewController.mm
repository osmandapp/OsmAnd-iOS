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
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIHelper.h"
#import "OAPOILocationType.h"
#import "OACollapsableLabelView.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
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
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

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
static const NSArray<NSString *> *kContactPhoneTags = @[PHONE_TAG, MOBILE_TAG, @"whatsapp", @"viber"];
static const NSArray<NSString *> *kPrefixTags = @[@"start_date"];

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
        self.poi = poi;
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
    return [self.poi getSubTypeStr];
}

- (UIColor *) getAdditionalInfoColor
{
    return [OANativeUtilities getOpeningHoursColor:_openingHoursInfo];
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return [OANativeUtilities getOpeningHoursDescr:_openingHoursInfo];
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

- (NSDictionary *)groupAdditionalInfo:(NSDictionary *)originalDict
              withCurrentLocalization:(NSString *)currentLocalization
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *localizationsDict = [NSMutableDictionary dictionary];
    
    for (NSString *key in originalDict)
    {
        NSString *convertedKey = [self convertKey:key];
        
        if ([_poiHelper isNameTag:convertedKey])
        {
            [self processNameTagWithKey:key
                              convertedKey:convertedKey
                          originalDict:originalDict
                      localizationsDict:localizationsDict];
        }
        else
        {
            [self processAdditionalTypeWithKey:key
                                    convertedKey:convertedKey
                                originalDict:originalDict
                            localizationsDict:localizationsDict
                                  resultDict:resultDict];
        }
    }
    
    NSMutableDictionary *finalDict = [self finalizeLocalizationDict:localizationsDict
                                            withCurrentLocalization:currentLocalization];
    
    [self addRemainingEntriesFrom:resultDict to:finalDict];
    
    return [finalDict copy];
}

- (NSString *)convertKey:(NSString *)key
{
    return [key stringByReplacingOccurrencesOfString:@"_-_" withString:@":"];
}

- (void)processNameTagWithKey:(NSString *)key
                  convertedKey:(NSString *)convertedKey
                  originalDict:(NSDictionary *)originalDict
              localizationsDict:(NSMutableDictionary *)localizationsDict
{
    if ([key containsString:@":"])
    {
        NSArray *components = [convertedKey componentsSeparatedByString:@":"];
        if (components.count == 2)
        {
            NSString *baseKey = components[0];
            NSString *localeKey = [NSString stringWithFormat:@"%@:%@", baseKey, components[1]];
            
            NSMutableDictionary *nameDict = [self dictionaryForKey:@"name" inDict:localizationsDict];
            [nameDict setObject:originalDict[convertedKey] forKey:localeKey];
        }
    }
    else
    {
        NSMutableDictionary *nameDict = [self dictionaryForKey:@"name" inDict:localizationsDict];
        [nameDict setObject:originalDict[key] forKey:convertedKey];
    }
}

- (void)processAdditionalTypeWithKey:(NSString *)key
                          convertedKey:(NSString *)convertedKey
                          originalDict:(NSDictionary *)originalDict
                      localizationsDict:(NSMutableDictionary *)localizationsDict
                            resultDict:(NSMutableDictionary *)resultDict
{
    OAPOIBaseType *poiType = [_poiHelper getAnyPoiAdditionalTypeByKey:convertedKey];
    
    if (poiType.lang && [key containsString:@":"])
    {
        NSArray *components = [key componentsSeparatedByString:@":"];
        if (components.count == 2)
        {
            NSString *baseKey = components[0];
            NSString *localeKey = [NSString stringWithFormat:@"%@:%@", baseKey, components[1]];
            
            NSMutableDictionary *baseDict = [self dictionaryForKey:baseKey inDict:localizationsDict];
            [baseDict setObject:originalDict[key] forKey:localeKey];
        }
    }
    else
    {
        [resultDict setObject:originalDict[key] forKey:key];
    }
}

- (NSMutableDictionary *)dictionaryForKey:(NSString *)key inDict:(NSMutableDictionary *)dict
{
    NSMutableDictionary *subDict = dict[key];
    if (!subDict)
    {
        subDict = [NSMutableDictionary dictionary];
        dict[key] = subDict;
    }
    return subDict;
}

- (NSMutableDictionary *)finalizeLocalizationDict:(NSDictionary *)localizationsDict
                      withCurrentLocalization:(NSString *)currentLocalization
{
    NSMutableDictionary *finalDict = [NSMutableDictionary dictionary];
    
    for (NSString *baseKey in localizationsDict)
    {
        NSMutableDictionary *entryDict = [NSMutableDictionary dictionary];
        NSDictionary *localizations = localizationsDict[baseKey];
        
        NSString *nameKey = [NSString stringWithFormat:@"%@:%@", baseKey, currentLocalization];
        NSString *nameValue = localizations[nameKey] ?: [localizations allValues].firstObject;
        
        entryDict[@"name"] = nameValue;
        entryDict[@"localization"] = localizations;
        [finalDict setObject:[entryDict copy] forKey:baseKey];
    }
    
    return finalDict;
}

- (void)addRemainingEntriesFrom:(NSDictionary *)resultDict to:(NSMutableDictionary *)finalDict {
    for (NSString *key in resultDict)
    {
        if (![finalDict objectForKey:key])
        {
            [finalDict setObject:resultDict[key] forKey:key];
        }
    }
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    BOOL hasWiki = NO;
    NSString *preferredLang = [OAUtilities preferredLang];
    NSMutableArray<OARowInfo *> *infoRows = [NSMutableArray array];
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    NSMutableArray<OARowInfo *> *urlRows = [NSMutableArray array];
    
    NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *poiAdditionalCategories = [NSMutableDictionary dictionary];
    OARowInfo *cuisineRow;
    
    NSMutableDictionary<NSString *, NSMutableArray<OAPOIType *> *> *collectedPoiTypes = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *additionalInfo = [[self.poi getAdditionalInfo] mutableCopy];

    BOOL osmEditingEnabled = [OAPluginsHelper isEnabled:OAOsmEditingPlugin.class];
    CGSize iconSize = {20, 20};
    if (self.poi.localizedNames.count > 0)
        [self addLocalizedNamesTagsToInfo:additionalInfo];
    NSString *languageCode = NSLocale.currentLocale.languageCode;
    
    NSDictionary *dic = [self groupAdditionalInfo:additionalInfo withCurrentLocalization:languageCode];

    for (NSString *key in dic.allKeys)
    {
        NSString *iconId;
        UIImage *icon;
        UIColor *textColor; 
        NSString *vl = @"";
    
        id value = dic[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            vl = value[@"name"] ?: @"";
        } else {
            vl = value;
        }
        
        NSString *convertedKey = [self convertKey:key];
        
        if ([convertedKey isEqualToString:@"image"]
            || [convertedKey isEqualToString:MAPILLARY_TAG]
            || [convertedKey isEqualToString:@"subway_region"]
            || ([convertedKey isEqualToString:@"note"] && !osmEditingEnabled)
            || [convertedKey hasPrefix:@"lang_yes"]
            || [convertedKey hasPrefix:@"top_index_"])
            continue;

        NSString *textPrefix = @"";
        OACollapsableView *collapsableView;
        BOOL collapsable = NO;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = !([convertedKey isEqualToString:@"population"] || [convertedKey isEqualToString:@"height"] || [convertedKey isEqualToString:OPENING_HOURS_TAG]);
        BOOL needIntFormatting = [convertedKey isEqualToString:@"population"];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        BOOL isCuisine = NO;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";
        NSString *categoryIconId;
        UIImage *categoryIcon;

        OAPOIType *poiType = [self.poi.type.category getPoiTypeByKeyName:convertedKey];
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:convertedKey];

        if (!pt && vl && vl.length > 0 && vl.length < 50)
            pt = [_poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", convertedKey, vl]];
        
        if (poiType == nil && pt == nil)
        {
            poiType = [_poiHelper getPoiTypeByKey:key];
        }

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
            textColor = [UIColor colorNamed:ACColorNameTextColorActive];
        }
        else if (needLinks)
        {
            NSString *socialMediaUrl = [self getSocialMediaUrl:convertedKey value:vl];
            if (socialMediaUrl)
            {
                isUrl = YES;
                textColor = [UIColor colorNamed:ACColorNameTextColorActive];
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
                NSString *articleLang = [OAPluginsHelper onGetMapObjectsLocale:self.poi preferredLocale:preferredLang];
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
        else if ([convertedKey isEqualToString:COLLECTION_TIMES_TAG] || [convertedKey isEqualToString:SERVICE_TIMES_TAG])
        {
            iconId = @"ic_action_time";
            needLinks = NO;
        }
        else if ([convertedKey isEqualToString:OPENING_HOURS_TAG])
        {
            iconId = @"ic_action_time";
            collapsableView = [[OACollapsableLabelView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            collapsableView.collapsed = YES;
            ((OACollapsableLabelView *) collapsableView).label.text =
                    [[additionalInfo[key] stringByReplacingOccurrencesOfString:@"; " withString:@"\n"]
                                                        stringByReplacingOccurrencesOfString:@"," withString:@", "];
            collapsable = YES;
            auto rs = OpeningHoursParser::parseOpenedHours([additionalInfo[key] UTF8String]);
            if (rs != nullptr)
            {
                vl = [NSString stringWithUTF8String:rs->toLocalString().c_str()];
                BOOL opened = rs->isOpenedForTime([NSDate.date toTm]);
                textColor = opened ? UIColorFromRGB(color_place_open) : UIColorFromRGB(color_place_closed);
            }
            vl = [vl stringByReplacingOccurrencesOfString:@"; " withString:@"\n"];
            needLinks = NO;
        }
        else if ([kContactPhoneTags containsObject:convertedKey])
        {
            iconId = @"ic_phone_number";
            textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            isPhoneNumber = YES;
        }
        else if ([convertedKey isEqualToString:WEBSITE_TAG] || [convertedKey isEqualToString:URL_TAG] || [kContactUrlTags containsObject:convertedKey])
        {
            if ([kContactUrlTags containsObject:convertedKey])
            {
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:convertedKey] size:iconSize];
            }
            iconId = @"ic_website";
            textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            isUrl = YES;
        }
        else if ([convertedKey isEqualToString:CUISINE_TAG])
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
        else if ([convertedKey containsString:ROUTE_TAG]
                || [convertedKey isEqualToString:WIKIDATA_TAG]
                || [convertedKey isEqualToString:WIKIMEDIA_COMMONS_TAG])
        {
            continue;
        }
        else
        {
            if ([convertedKey containsString:DESCRIPTION_TAG])
            {
                iconId = @"ic_description";
            }
            else if (isUrl && [vl containsString:WIKI_LINK])
            {
                iconId = @"ic_custom_wikipedia";
            }
            else if ([convertedKey isEqualToString:@"addr:housename"] || [convertedKey isEqualToString:@"whitewater:rapid_name"])
            {
                iconId = @"ic_custom_poi_name";
            }
            else if ([convertedKey isEqualToString:@"operator"] || [convertedKey isEqualToString:@"brand"])
            {
                iconId = @"ic_custom_poi_brand";
            }
            else if ([convertedKey isEqualToString:@"internet_access_fee_yes"])
            {
                iconId = @"ic_custom_internet_access_fee";
            }
            else
            {
                iconId = @"ic_operator";
            }
            if (pType)
            {
                NSString *category = [pType.tag stringByReplacingOccurrencesOfString:@":" withString:@"_"];
                if (category && category.length > 0)
                {
                    categoryIconId = [NSString stringWithFormat:@"mx_%@", category];
                    categoryIcon = [OATargetInfoViewController getIcon:categoryIconId size:iconSize];
                    iconId = categoryIcon ? categoryIconId : iconId;
                }
                
                poiTypeOrder = pType.order;
                poiTypeKeyName = pType.name;
                if (pType.parentType && [pType.parentType isKindOfClass:OAPOIType.class])
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@_%@_%@", ((OAPOIType *) pType.parentType).tag, category, pType.value] size:iconSize];
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
                        NSInteger numberValue = [vl integerValue];
                        vl = [numberFormatter stringFromNumber:@(numberValue)];
                    }
                }
                if (!isDescription && !icon)
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]] size:iconSize];
                    if (isText && icon && ![kPrefixTags containsObject:convertedKey])
                        textPrefix = @"";
                }
                if (!icon && isText && !iconId)
                    iconId = @"ic_description";
            }
            else if (poiType)
            {
                NSString * catKey = poiType.category.name;
                NSMutableArray<OAPOIType *> *list = collectedPoiTypes[catKey];
                if (!list)
                {
                    list = [[NSMutableArray alloc] init];
                    collectedPoiTypes[catKey] = list;
                }
                [list addObject:poiType];
            }
            else
            {
                textPrefix = convertedKey.capitalizedString;
            }
        }

        NSArray<NSString *> *formattedPrefixAndText = [self getFormattedPrefixAndText:convertedKey prefix:textPrefix value:vl amenity:self.poi];
        textPrefix = formattedPrefixAndText[0];
        vl = formattedPrefixAndText[1];

        if ([convertedKey isEqualToString:@"ele"] && [self isNumericValue:vl])
        {
            float distance = [vl floatValue];
            vl = [OAOsmAndFormatter getFormattedAlt:distance];
            NSString *collapsibleVal;
            EOAMetricsConstant metricSystem = [[OAAppSettings sharedManager].metricSystem get];
            if (metricSystem == MILES_AND_FEET || metricSystem == MILES_AND_YARDS || metricSystem == NAUTICAL_MILES_AND_FEET)
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
            row = [[OARowInfo alloc] initWithKey:convertedKey
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
            UIImage *rowIcon;
            if (icon)
                rowIcon = icon;
            else if ([iconId isEqualToString:categoryIconId] && categoryIcon)
                rowIcon = categoryIcon;
            else
                rowIcon = [OATargetInfoViewController getIcon:iconId size:iconSize];

            row = [[OARowInfo alloc] initWithKey:convertedKey
                                            icon:rowIcon
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
        [self configureRowValue:value dic:dic convertedKey:convertedKey row:row];
        row.collapsable = collapsable;
        row.collapsed = YES;
        row.collapsableView = collapsableView;

        if (isDescription)
            [descriptions addObject:row];
        else if (isCuisine)
            cuisineRow = row;
        else if (isUrl)
            [self addRowIfNotExists:row toDestinationRows:urlRows];
        else if (!poiType)
            [infoRows addObject:row];
    }

    if (cuisineRow)
    {
        BOOL hasCuisineOrDish = poiAdditionalCategories[CUISINE_TAG] != nil || poiAdditionalCategories[DISH_TAG] != nil;
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
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:poiAdditionalIconName] size:iconSize];
            if (!icon)
                icon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:poiAdditionalCategoryName] size:iconSize];
            if (!icon)
                icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]] size:iconSize];
            if (!icon)
                icon = [UIImage imageNamed:@"ic_description"];

            NSMutableString *sb = [NSMutableString new];
            for (OAPOIType *pt in categoryTypes)
            {
                if (sb.length > 0)
                    [sb appendString:@" • "];
                [sb appendString:pt.nameLocalized];
            }

            BOOL cuisineOrDish = [categoryName isEqualToString:CUISINE_TAG] || [categoryName isEqualToString:DISH_TAG];
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

    if (collectedPoiTypes.count > 0) {
        for (NSString *key in collectedPoiTypes) {
            NSMutableArray<OAPOIType *> *poiTypeList = collectedPoiTypes[key];
            
            OACollapsableNearestPoiTypeView *collapsableView = [[OACollapsableNearestPoiTypeView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            collapsableView.collapsed = YES;
            [collapsableView setData:poiTypeList
                             amenity:self.poi
                                 lat:self.poi.latitude
                                 lon:self.poi.longitude
                     isPoiAdditional:NO
                             textRow:nil];
            
            OAPOICategory *poiCategory = self.poi.type.category;
            NSMutableString *sb = [NSMutableString new];
            
            for (OAPOIType *pt in poiTypeList) {
                if (sb.length > 0) {
                    [sb appendString:@" • "];
                }
                [sb appendString:pt.nameLocalized];
                poiCategory = pt.category;
            }
            
            UIImage *icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", poiCategory.name] size:iconSize];
            
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
    }

    [infoRows addObjectsFromArray:urlRows];
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
                                             textColor:[UIColor colorNamed:ACColorNameTextColorActive]
                                                isText:YES
                                             needLinks:YES
                                                 order:10000
                                              typeName:nil
                                         isPhoneNumber:NO
                                                 isUrl:YES]];
    }
}

- (void)configureRowValue:(id)value
                      dic:(NSDictionary *)dic
             convertedKey:(NSString *)convertedKey
                      row:(OARowInfo *)row
{
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSMutableArray *array = [NSMutableArray array];
        NSDictionary *val = dic[convertedKey][@"localization"];
        if ([_poiHelper isNameTag:convertedKey])
        {
            row.text = self.poi.name;
            row.textPrefix = OALocalizedString(@"shared_string_name");
        }
        if (val.allKeys.count > 0)
        {
            for (NSString *key in val.allKeys)
            {
                OAPOIBaseType *poi = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
                NSString *formattedKey = [key stringByReplacingOccurrencesOfString:convertedKey withString:@"name"];

                [array addObject:@{
                    @"key": formattedKey,
                    @"value": val[key],
                    @"localizedTitle": poi ? poi.nameLocalized : @""
                }];
            }
            [row setDetailsArray:array];
        }
    }
}

- (void) addLocalizedNamesTagsToInfo:(NSMutableDictionary<NSString *, NSString *> *)additionalInfo
{
    [[self filteredLocalizedNames] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *name, BOOL *stop) {
        NSString *nameKey = [NSString stringWithFormat:@"name:%@", key];
        if (key.length > 0 && ![key isEqualToString:[OAAppSettings sharedManager].settingPrefMapLanguage.get] && !additionalInfo[nameKey])
            additionalInfo[nameKey] = name;
    }];
}

- (NSDictionary *)filteredLocalizedNames
{
    NSMutableDictionary *filteredDict = [self.poi.localizedNames mutableCopy];
    [filteredDict removeObjectForKey:@"brand"];
    return [filteredDict copy];
}

- (void) addRowIfNotExsists:(OARowInfo *)newRow toDestinationRows:(NSMutableArray<OARowInfo *> *)rows
{
    if (![rows containsObject:newRow])
        [rows addObject:newRow];
}

- (NSString *)getSocialMediaUrl:(NSString *)key value:(NSString *)value
{
    if (!value || value.length == 0)
        return nil;
    
    // Remove leading and closing slashes
    NSMutableString *sb = [NSMutableString stringWithString:[value trim]];
    if ([sb characterAtIndex:0] == '/')
        [sb deleteCharactersInRange:NSMakeRange(0, 1)];
    NSInteger lastIdx = sb.length - 1;
    if ([sb characterAtIndex:lastIdx] == '/')
        [sb deleteCharactersInRange:NSMakeRange(lastIdx, 1)];

    // It cannot be username
    if ([sb isValidURL])
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
        if (metricSystem == MILES_AND_FEET || metricSystem == NAUTICAL_MILES_AND_FEET)
        {
            valueAsDouble *= FEET_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"foot")];
        }
        else if (metricSystem == MILES_AND_YARDS)
        {
            valueAsDouble *= YARDS_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"yard")];
        }
        else
        {
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"m")];
        }
    }
    else if ([key isEqualToString:@"distance"] && [self isNumericValue:value])
    {
        float valueAsFloatInMeters = [value floatValue] * 1000;
        if (metricSystem == KILOMETERS_AND_METERS)
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"km")];
        else
            formattedValue = [OAOsmAndFormatter getFormattedDistance:valueAsFloatInMeters];

        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_distance")];
    }
    else if ([key isEqualToString:@"capacity"] && [self isNumericValue:value] && ([amenity.subType isEqualToString:@"water_tower"] || [amenity.subType isEqualToString:@"storage_tank"]))
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"cubic_m")];
    }
    else if ([key isEqualToString:@"maxweight"] && [self isNumericValue:value])
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"metric_ton")];
    }
    else if (([key isEqualToString:@"students"] || [key isEqualToString:@"spots"] || [key isEqualToString:@"seats"]) && [self isNumericValue:value])
    {
        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_capacity")];
    }
    else if ([key isEqualToString:@"wikipedia"])
    {
        formattedPrefix = OALocalizedString(@"download_wikipedia_maps");
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

@end
