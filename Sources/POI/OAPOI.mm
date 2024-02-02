//
//  OAPOI.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOI.h"
#import "OAAppSettings.h"
#import "OAPOIHelper.h"
#import "OAGPXDocumentPrimitives.h"

#include <OsmAndCore/ICU.h>

#define TYPE @"type"
#define SUBTYPE @"subtype"
#define POI_NAME @"name"
#define COLLAPSABLE_PREFIX @"collapsable_"
#define SEPARATOR @";"

static NSArray<NSString *> *const HIDDEN_EXTENSIONS = @[
    COLOR_NAME_EXTENSION,
    ICON_NAME_EXTENSION,
    BACKGROUND_TYPE_EXTENSION,
    PROFILE_TYPE_EXTENSION,
    ADDRESS_EXTENSION,
    [NSString stringWithFormat:@"%@%@", PRIVATE_PREFIX, AMENITY_NAME],
    [NSString stringWithFormat:@"%@%@", PRIVATE_PREFIX, TYPE],
    [NSString stringWithFormat:@"%@%@", PRIVATE_PREFIX, SUBTYPE]
];

@implementation OAPOIRoutePoint

@end

@implementation OAPOI

-(void)setType:(OAPOIType *)type
{
    _type = type;
    _type.parent = self;
}

- (UIImage *)icon
{
    if (_mapIconName && _mapIconName.length > 0 && ![_mapIconName hasSuffix:@"_small"])
        return [UIImage mapSvgImageNamed:[NSString stringWithFormat:@"mx_%@", _mapIconName]];
    else if (_type)
        return [_type icon];
    else
        return nil;
}

- (NSString *)iconName
{
    if (_mapIconName && _mapIconName.length > 0)
        return [NSString stringWithFormat:@"mx_%@", _mapIconName];
    else if (_type)
        return [_type iconName];
    else
        return nil;
}

- (NSString *)gpxIcon
{
    return _values[@"gpx_icon"];
}

-(void)setValues:(NSDictionary *)values
{
    _values = values;
    [self processValues];
}

- (void) processValues
{
    if (self.values)
    {
        NSString __block *_prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        NSMutableDictionary __block *content = [NSMutableDictionary dictionary];
        NSString __block *descFieldLoc;
        if (_prefLang)
            descFieldLoc = [@"description:" stringByAppendingString:_prefLang];

        [self.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop)
        {
            if ([key hasPrefix:@"content"])
            {
                NSString *loc;
                if (key.length > 8)
                    loc = [[key substringFromIndex:8] lowercaseString];
                else
                    loc = @"";
                
                [content setObject:value forKey:loc];
            }
            
            if (_prefLang && !self.nameLocalized)
            {
                NSString *langTag = [NSString stringWithFormat:@"%@%@", @"name:", _prefLang];
                if ([key isEqualToString:langTag])
                {
                    self.nameLocalized = value;
                }
            }
            
            if ([key hasPrefix:@"description"] && !self.desc)
            {
                self.desc = value;
            }
            if (descFieldLoc && [key isEqualToString:descFieldLoc])
            {
                self.desc = value;
            }
            
            if ([key isEqualToString:@"opening_hours"])
            {
                self.hasOpeningHours = YES;
                self.openingHours = value;
            }
            
        }];
     
        self.localizedContent = content;
    }
}

- (BOOL)isClosed
{
    NSString *val = _values[OSM_DELETE_TAG];
    return val && [val isEqualToString:OSM_DELETE_VALUE];
}

- (NSSet<NSString *> *)getSupportedContentLocales
{
    NSMutableSet<NSString *> *supported = [NSMutableSet new];
    [supported addObjectsFromArray:[self getNames:@"wiki_lang" defTag:@"en"]];
    return supported;
}

- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag
{
    NSMutableArray<NSString *> *l = [NSMutableArray new];
    for (NSString *nm in _values.allKeys)
    {
        if ([nm hasPrefix:[NSString stringWithFormat:@"%@:", tag]])
            [l addObject:[nm substringFromIndex:tag.length + 1]];
        else if ([nm isEqualToString:tag])
            [l addObject:defTag];
    }
    return l;
}

- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate
{
    if (lang != nil && lang.length > 0)
    {
        NSString *nm;
        if ([lang isEqualToString:@"en"])
        {
            nm = _localizedNames[@"en"];
            if (!nm || nm.length == 0)
                nm = OsmAnd::ICU::transliterateToLatin(QString::fromNSString(_name)).toNSString();
            return nm;
        }
        nm = _localizedNames[lang];
        if (transliterate)
            nm = OsmAnd::ICU::transliterateToLatin(QString::fromNSString(nm)).toNSString();
        return nm;
    }
    return _name;
}

- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn
{
    if ((!includeEn || !_name || _name.length == 0) && (!_localizedNames || _localizedNames.count == 0))
    {
        return [NSDictionary dictionary];
    }
    else
    {
        NSMutableDictionary *mp = [NSMutableDictionary dictionary];
        if (_localizedNames || _localizedNames.count != 0)
        {
            for (NSString *key in _localizedNames.allKeys)
                mp[key] = _localizedNames[key];
        }
        
        if (includeEn && !_name && _name.length > 0)
            mp[@"en"] = _name;
        
        return mp;
    }
}

- (NSString *)getContentLanguage:(NSString *)tag lang:(NSString *)lang defLang:(NSString *)defLang
{
    if (lang)
    {
        NSString *translateName = [self getAdditionalInfo][[NSString stringWithFormat:@"%@:%@", tag, lang]];
        if (translateName && translateName.length > 0)
            return translateName;
    }
    NSString *plainContent = [self getAdditionalInfo][tag];
    if (plainContent && plainContent.length > 0)
        return defLang;

    NSString *enName = [self getAdditionalInfo][[tag stringByAppendingString:@":en"]];
    if (enName && enName.length > 0)
        return @"en";

    NSInteger maxLen = 0;
    NSString *lng = defLang;
    for (NSString *nm in [self getAdditionalInfo].allKeys)
    {
        if ([nm hasPrefix:[NSString stringWithFormat:@"%@:", tag]])
        {
            NSString *key = [nm substringFromIndex:tag.length + 1];
            NSString *cnt = [self getAdditionalInfo][[NSString stringWithFormat:@"%@:%@", tag, key]];
            if (cnt && cnt.length > 0  && cnt.length > maxLen)
            {
                maxLen = cnt.length;
                lng = key;
            }
        }
    }
    return lng;
}

- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang
{
    if (lang)
    {
        NSString *translateName = [self getAdditionalInfo][[NSString stringWithFormat:@"%@:%@", tag, lang]];
        if (translateName && translateName.length > 0)
            return translateName;
    }
    NSString *plainName = [self getAdditionalInfo][tag];
    if (plainName && plainName.length > 0)
        return plainName;

    NSString *enName = [self getAdditionalInfo][[NSString stringWithFormat:@"%@:en", tag]];
    if (enName && enName.length > 0)
        return enName;

    return nil;
}

- (NSString *)getTagContent:(NSString *)tag
{
    return [self getTagContent:tag lang:nil];
}

- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang
{
    NSString *translateName = [self getStrictTagContent:tag lang:lang];
    if (translateName)
        return translateName;

    for (NSString *nm in [self getAdditionalInfo].allKeys)
    {
        if ([nm hasPrefix:[NSString stringWithFormat:@"%@:", tag]])
            return [self getAdditionalInfo][nm];
    }
    return nil;
}

- (NSString *)getLocalizedContent:(NSString *)tag lang:(NSString *)lang
{
    NSString *selectedLang = lang;
    if (!selectedLang || selectedLang.length == 0)
        selectedLang = @"en";
    
    NSString *key = [NSString stringWithFormat:@"%@:%@", tag, selectedLang];
    NSString *result = _localizedContent[key];
    if (result && result.length > 0)
        return result;
    
    key = [NSString stringWithFormat:@"%@:en", tag];
    result = _localizedContent[key];
    if (result && result.length > 0)
        return result;
        
    for (NSString *key in [_localizedContent allKeys])
    {
        if ([key hasPrefix:[NSString stringWithFormat:@"%@:", tag]])
            return _localizedContent[key];
    }
    
    return nil;
}

- (NSString *)getTagSuffix:(NSString *)tagPrefix
{
    for (NSString *infoTag in [self getAdditionalInfo].allKeys)
    {
        if ([infoTag hasPrefix:tagPrefix])
            return [infoTag substringFromIndex:tagPrefix.length];
    }
    return nil;
}

- (NSString *)getDescription:(NSString *)lang
{
    NSString *info = [self getTagContent:@"description" lang:lang];
    if (info && info.length > 0)
        return info;

    return [self getTagContent:@"content" lang:lang];
}

- (NSDictionary<NSString *, NSString *> *) getAdditionalInfo
{
    NSMutableDictionary<NSString *, NSString *> *res = [NSMutableDictionary new];
    if (!_values)
        return res;
    
    for (NSString *key in _values)
    {
        if (![key isEqualToString:@"name"])
            res[key] = _values[key];
    }
    return res;
}

- (NSString *)getSite
{
    return [self getAdditionalInfo][@"website"];
}

- (NSString *)getColor
{
    return [self getAdditionalInfo][@"color"];
}

- (NSString *)getRef
{
    return [self getAdditionalInfo][@"ref"];
}

- (NSString *)getRouteId
{
    return [self getAdditionalInfo][@"route_id"];
}

- (NSString *)toStringEn
{
    NSString *nameEn = self.localizedNames[@"en"] ? self.localizedNames[@"en"] : @"";
    NSString *type = self.type.category.name ? self.type.category.name : @"";
    NSString *subType = self.type.name ? self.type.name : @"";
    return [NSString stringWithFormat:@"Amenity:%@: %@:%@", nameEn, type, subType];
}

- (NSDictionary<NSString *, NSString *> *) toTagValue:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSArray<OAPOIType *> *> *collectedPoiAdditionalCategories = [NSMutableDictionary dictionary];
    if (self.name)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, POI_NAME];
        result[savingKey] = self.name;
    }
    if (self.type)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, SUBTYPE];
        result[savingKey] = self.type.name;
    }
    if (self.type.category)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, TYPE];
        result[savingKey] = self.type.category.name;
    }
    if (self.openingHours)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, OPENING_HOURS_TAG];
        result[savingKey] = self.openingHours;
    }
    
    NSDictionary<NSString *, NSString *> *additionalInfo = [self getAdditionalInfo];
    if (additionalInfo.count > 0)
    {
        OAPOIHelper *poiHelper = OAPOIHelper.sharedInstance;
        [additionalInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            OAPOIBaseType *pt = [poiHelper getAnyPoiAdditionalTypeByKey:key];
            if (pt == nil && value.length > 0 && value.length < 50)
            {
                pt = [poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", key, value]];
            }
            OAPOIType *pType = nil;
            if (pt)
            {
                pType = (OAPOIType *) pt;
                if (pType.filterOnly)
                    return;
            }
            if (pType != nil && !pType.isText)
            {
                NSString *categoryName = pType.poiAdditionalCategory;
                if (categoryName.length > 0)
                {
                    NSArray<OAPOIType *> *poiAdditionalCategoryTypes = collectedPoiAdditionalCategories[categoryName];
                    if (poiAdditionalCategoryTypes == nil)
                        collectedPoiAdditionalCategories[categoryName] = @[pType];
                    else
                        collectedPoiAdditionalCategories[categoryName] = [poiAdditionalCategoryTypes arrayByAddingObject:pType];
                    return;
                }
            }
            
            //save all other values to separate lines
            if ([key hasSuffix:OPENING_HOURS_TAG])
                return;
            
//            if (!HIDING_EXTENSIONS_AMENITY_TAGS.contains(key)) {
//                key = OSM_PREFIX + key;
//            }
            NSString *savingKey = [NSString stringWithFormat:@"%@%@", osmPrefix, key];
            result[savingKey] = value;
        }];
        
        [collectedPoiAdditionalCategories enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<OAPOIType *> * _Nonnull categoryTypes, BOOL * _Nonnull stop)
         {
            NSString *categoryName = [NSString stringWithFormat:@"%@%@", COLLAPSABLE_PREFIX, key];
            if (categoryTypes.count > 0)
            {
                NSMutableString *res = [NSMutableString string];
                for (OAPOIType *poiType in categoryTypes)
                {
                    if (res.length > 0)
                    {
                        [res appendString:SEPARATOR];
                    }
                    [res appendString:poiType.name];
                }
                result[categoryName] = res;
            }
        }];
        
    }
    return result;
}

+ (OAPOI *) fromTagValue:(NSDictionary<NSString *, NSString *> *)map privatePrefix:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix
{
    OAPOI *amenity = nil;
    if (map && map.count > 0)
    {
        NSString *name = nil;
        OAPOIType *type = nil;
        NSString *typeStr = nil;
        NSString *subType = nil;
        NSString *openingHours = nil;
        NSMutableDictionary<NSString *, NSString *> *additionalInfo = [NSMutableDictionary dictionary];

        for (NSString *key in map.allKeys)
        {
            if ([key hasPrefix:privatePrefix])
            {
                NSString *shortKey = [key stringByReplacingOccurrencesOfString:privatePrefix withString:@""];
                if ([shortKey isEqualToString:POI_NAME])
                {
                    name = map[key];
                }
                else if ([shortKey isEqualToString:TYPE])
                {
                    typeStr = map[key];
                    type = [OAPOIHelper.sharedInstance getPoiTypeByName:typeStr];
                }
                else if ([shortKey isEqualToString:SUBTYPE])
                {
                    subType = map[key];
                }
                else if ([shortKey isEqualToString:OPENING_HOURS_TAG] && map[key].length > 0)
                {
                    openingHours = map[key];
                    additionalInfo[shortKey] = openingHours;
                }
            }
            else if ([key hasPrefix:osmPrefix])
            {
                NSString *shortKey = [key stringByReplacingOccurrencesOfString:osmPrefix withString:@""];
                additionalInfo[shortKey] = map[key];
            }
            else
            {
                NSString *shortKey = [key componentsSeparatedByString:@":"].lastObject;
                if (![HIDDEN_EXTENSIONS containsObject:shortKey] && ![HIDDEN_EXTENSIONS containsObject:key] && map[key].length > 0)
                    additionalInfo[key] = map[key];
            }
        }
        if (!type)
            type = [OAPOIHelper.sharedInstance getPoiType:typeStr value:subType];
        if (!type)
            type = [OAPOIHelper.sharedInstance getDefaultOtherCategoryType];
        if (type)
        {
            amenity = [[OAPOI alloc] init];
            amenity.name = name;
            amenity.type = type;
            if (subType)
                amenity.subType = subType;
            if (openingHours)
                amenity.openingHours = openingHours;
            [amenity setValues:additionalInfo];
        }
    }
    return amenity;
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OAPOI *poi = (OAPOI *) o;
    
    if (self.obfId != poi.obfId)
        return NO;
    if (!self.type && poi.type)
        return NO;
    if (self.type && ![self.type isEqual:poi.type])
        return NO;
    if (![OAUtilities isCoordEqual:self.latitude srcLon:self.longitude destLat:poi.latitude destLon:poi.longitude upToDigits:4])
        return NO;
    
    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.obfId;
    result = 31 * result + (self.name ? [self.name hash] : 0);
    result = 31 * result + (self.type ? [self.type hash] : 0);
    result = 31 * result + [@(self.latitude) hash];
    result = 31 * result + [@(self.longitude) hash];
    return result;
}

@end
