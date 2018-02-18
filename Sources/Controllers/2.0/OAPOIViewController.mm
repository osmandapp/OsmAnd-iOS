//
//  OAPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIViewController.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAPOILocationType.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAPOIMyLocationType.h"
#import "OACollapsableLabelView.h"

#include <openingHoursParser.h>

@interface OAPOIViewController ()

@end

@implementation OAPOIViewController
{
    OAPOIHelper *_poiHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (id)initWithPOI:(OAPOI *)poi
{
    self = [self init];
    if (self)
    {
        _poi = poi;
    }
    return self;
}

- (NSString *)getTypeStr;
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
    
    return str;
}

- (BOOL)supportFullScreen
{
    return self.poi.type
                && ![self.poi.type isKindOfClass:[OAPOILocationType class]]
                && ![self.poi.type isKindOfClass:[OAPOIMyLocationType class]];
}

-(id)getTargetObj
{
    return self.poi;
}

-(BOOL)showNearestWiki
{
    return YES;
}

- (void)buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    if (!prefLang)
        prefLang = [OAUtilities currentLang];
    
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    
    if (self.poi.type
        && ![self.poi.type isKindOfClass:[OAPOILocationType class]]
        && ![self.poi.type isKindOfClass:[OAPOIMyLocationType class]])
    {
        UIImage *icon = [self.poi.type icon];
        [rows addObject:[[OARowInfo alloc] initWithKey:self.poi.type.name icon:icon textPrefix:nil text:[self getTypeStr] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    [self.poi.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        BOOL skip = NO;
        NSString *iconId = nil;
        UIImage *icon = nil;
        UIColor *textColor = nil;
        NSString *textPrefix = nil;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = ![@"population" isEqualToString:key];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";
        BOOL collapsable = NO;
        BOOL collapsed = YES;
        OACollapsableView *collapsableView = nil;
        
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
        if (!pt && value && value.length > 0 && value.length < 50)
            pt = [_poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", key, value]];

        OAPOIType *pType = nil;
        if (pt)
        {
            pType = (OAPOIType *) pt;
            poiTypeOrder = pType.order;
            poiTypeKeyName = pType.name;
        }
        
        if ([key hasPrefix:@"wiki_lang"])
        {
            skip = YES;
        }
        else if ([key hasPrefix:@"name:"])
        {
            skip = YES;
        }
        else if ([key isEqualToString:@"opening_hours"])
        {
            iconId = @"ic_working_time.png";
            
            auto parser = OpeningHoursParser::parseOpenedHours([value UTF8String]);
            bool isOpened = parser->isOpened();
            textColor = isOpened ? UIColorFromRGB(0x2BBE31) : UIColorFromRGB(0xDA3A3A);

            collapsable = YES;
            collapsed = YES;            
            collapsableView = [[OACollapsableLabelView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            ((OACollapsableLabelView *)collapsableView).label.text = value;
        }
        else if ([key isEqualToString:@"phone"])
        {
            iconId = @"ic_phone_number.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isPhoneNumber = YES;
        }
        else if ([key isEqualToString:@"website"])
        {
            iconId = @"ic_website.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isUrl = YES;
        }
        else if ([key isEqualToString:@"wikipedia"])
        {
            iconId = @"ic_website.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isUrl = YES;
        }
        else if ([key isEqualToString:@"cuisine"])
        {
            iconId = @"ic_cuisine.png";
            NSMutableString *sb = [NSMutableString string];
            NSArray* arr = [value componentsSeparatedByString: @";"];
            if (arr.count > 0)
            {
                for (NSString *c in arr)
                {
                    if (sb.length > 0) {
                        [sb appendString:@", "];
                    } else {
                        [sb appendString:[_poiHelper getPhraseByName:@"cuisine"]];
                        [sb appendString:@": "];
                    }
                    [sb appendString:[_poiHelper getPhraseByName:[[@"cuisine_" stringByAppendingString:c] lowercaseString]]];
                }
            }
            value = sb;
        }
        else
        {
            if ([key rangeOfString:@"description"].length != 0)
            {
                iconId = @"ic_description.png";
            }
            else
            {
                iconId = @"ic_operator.png";
            }
            if (pType)
            {
                poiTypeOrder = pType.order;
                poiTypeKeyName = pType.name;
                if (pType.parentType && [pType.parentType isKindOfClass:[OAPOIType class]])
                {
                    icon = [self getIcon:[NSString stringWithFormat:@"mx_%@_%@_%@.png", ((OAPOIType *) pType.parentType).tag, [pType.tag stringByReplacingOccurrencesOfString:@":" withString:@"_"], pType.value]];
                }
                if (!pType.isText)
                {
                    if (pType.poiAdditionalCategory) {
                        value = [NSString stringWithFormat:@"%@: %@", pType.poiAdditionalCategoryLocalized, pType.nameLocalized];
                    } else {
                        value = pType.nameLocalized;
                    }
                }
                else
                {
                    isText = YES;
                    isDescription = [iconId isEqualToString:@"ic_description.png"];
                    textPrefix = pType.nameLocalized;
                }
                if (!isDescription && !icon)
                {
                    icon = [self getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
                    if (isText && icon)
                    {
                        textPrefix = @"";
                    }
                }
                if (!icon && isText)
                {
                    iconId = @"ic_description.png";
                }
            }
            else
            {
                textPrefix = [OAUtilities capitalizeFirstLetterAndLowercase:key];
            }
        }
        
        if (!skip)
        {
            if (isDescription)
            {
                [descriptions addObject:[[OARowInfo alloc] initWithKey:key icon:[self getIcon:@"ic_description.png"] textPrefix:textPrefix text:value textColor:nil isText:YES needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
            }
            else
            {
                OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:key icon:(icon ? icon : [self getIcon:iconId]) textPrefix:textPrefix text:value textColor:textColor isText:isText needLinks:needLinks order:poiTypeOrder typeName:poiTypeKeyName isPhoneNumber:isPhoneNumber isUrl:isUrl];
                rowInfo.collapsable = collapsable;
                rowInfo.collapsed = collapsed;
                rowInfo.collapsableView = collapsableView;
                [rows addObject:rowInfo];
            }
        }
    }];
    
    
    NSString *langSuffix = [NSString stringWithFormat:@":%@", prefLang];
    OARowInfo *descInPrefLang = nil;
    for (OARowInfo *desc in descriptions)
    {
        if (desc.key.length > langSuffix.length
            && [[desc.key substringFromIndex:desc.key.length - langSuffix.length] isEqualToString:langSuffix])
        {
            descInPrefLang = desc;
            break;
        }
    }
    
    [descriptions sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
        {
            return NSOrderedAscending;
        }
        else if (row1.order == row2.order)
        {
            return [row1.typeName localizedCompare:row2.typeName];
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    
    if (descInPrefLang)
    {
        [descriptions removeObject:descInPrefLang];
        [descriptions insertObject:descInPrefLang atIndex:0];
    }
    
    int i = 10000;
    for (OARowInfo *desc in descriptions)
    {
        desc.order = i++;
        [rows addObject:desc];
    }
}

@end
