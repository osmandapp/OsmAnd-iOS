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

#define TYPE @"type"
#define SUBTYPE @"subtype"
#define OPENING_HOURS @"opening_hours"

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
    if (_type)
        return [_type icon];
    else
        return nil;
}

- (NSString *)iconName
{
    if (_type)
        return [_type iconName];
    else
        return nil;
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

- (NSDictionary<NSString *, NSString *> *) toTagValue:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary dictionary];
    if (self.subType)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, SUBTYPE];
        result[savingKey] = self.subType;
    }
    if (self.type)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, TYPE];
        result[savingKey] = self.type.name;
    }
    if (self.openingHours)
    {
        NSString *savingKey = [NSString stringWithFormat:@"%@%@", privatePrefix, OPENING_HOURS];
        result[savingKey] = self.openingHours;
    }
    
    NSDictionary<NSString *, NSString *> *additionalInfo = [self getAdditionalInfo];
    if (additionalInfo && additionalInfo.count > 0)
    {
        for (NSString *key in additionalInfo.allKeys)
        {
            NSString *value = additionalInfo[key];
            NSString *savingKey = [NSString stringWithFormat:@"%@%@", osmPrefix, key];
            result[savingKey] = value;
        }
    }
    return [NSDictionary dictionaryWithDictionary:result];
}

+ (OAPOI *) fromTagValue:(NSDictionary<NSString *, NSString *> *)map privatePrefix:(NSString *)privatePrefix osmPrefix:(NSString *)osmPrefix
{
    OAPOI *amenity = nil;
    if (map && map.count > 0)
    {
        OAPOIType *type = nil;
        NSString *subType = nil;
        NSString *openingHours = nil;
        NSMutableDictionary<NSString *, NSString *> *additionalInfo = [NSMutableDictionary dictionary];
        
        for (NSString *key in map.allKeys)
        {
            if ([key hasPrefix:privatePrefix])
            {
                NSString *shortKey = [key stringByReplacingOccurrencesOfString:privatePrefix withString:@""];
                if ([shortKey isEqualToString:TYPE])
                {
                    type = [OAPOIHelper.sharedInstance getPoiTypeByName:map[key]];
                    if (!type)
                        type = [OAPOIHelper.sharedInstance getPoiTypeByName:@"user_defined_other"];
                }
                else if ([shortKey isEqualToString:SUBTYPE])
                {
                    subType = map[key];
                }
                else if ([shortKey isEqualToString:OPENING_HOURS])
                {
                    openingHours = map[key];
                }
            }
            else if ([key hasPrefix:osmPrefix])
            {
                NSString *shortKey = [key stringByReplacingOccurrencesOfString:osmPrefix withString:@""];
                additionalInfo[shortKey] = map[key];
            }
        }
        
        if (type)
        {
            amenity = [[OAPOI alloc] init];
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
