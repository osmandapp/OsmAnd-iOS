//
//  OAPOI.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOI.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"

#define OSM_DELETE_VALUE @"delete"
#define OSM_DELETE_TAG @"osmand_change"

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

- (NSString *) getTagContent:(NSString *)tag lang:(NSString *)lang
{
    if (lang)
    {
        NSString *translateName = _values[[NSString stringWithFormat:@"%@:%@", tag, lang]];
        if (translateName.length > 0)
            return translateName;
    }
    NSString *plainName = _values[tag];
    if (plainName.length > 0)
        return plainName;
    
    NSString *enName = _values[[tag stringByAppendingString:@":en"]];
    if (enName.length > 0)
        return enName;
    
    NSString *tagPrefix = [tag stringByAppendingString:@":"];
    for (NSString *nm in _values.allKeys)
        if ([nm hasPrefix:tagPrefix])
            return _values[nm];
    
    return nil;
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
