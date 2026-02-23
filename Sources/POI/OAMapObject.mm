//
//  OAMapObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"
#import "OAUtilities.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMapObject
{
    NSMutableDictionary<NSString *, NSString *> *_localizedNames;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _x = [NSMutableArray new];
        _y = [NSMutableArray new];
        _localizedNames = [NSMutableDictionary new];
    }
    return self;
}

- (CLLocation *) getLocation
{
    return [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
}

- (void) addLocation:(int)x y:(int)y
{
    [_x addObject:@(x)];
    [_y addObject:@(y)];
}

- (void) setName:(NSString * _Nullable)lang name:(NSString * _Nonnull)name
{
    if (!lang || lang.length == 0)
    {
        self.name = name;
    }
    else if ([lang isEqualToString:@"en"])
    {
        [self setEnName:name];
    }
    else
    {
        _localizedNames[lang] = name;
    }
}

- (NSString *) enName
{
    return _localizedNames[@"en"];
}

- (void)setEnName:(NSString *)enName
{
    _localizedNames[@"en"] = enName;
}

- (void)copyNames:(NSString *)otherName otherEnName:(NSString *)otherEnName otherNames:(NSDictionary<NSString *, NSString *> *)otherNames overwrite:(BOOL)overwrite
{
    if (!NSStringIsEmpty(otherName) && (overwrite || NSStringIsEmpty(self.name)))
    {
        self.name = otherName;
    }
    if (!NSStringIsEmpty(otherEnName) && (overwrite || NSStringIsEmpty(self.enName)))
    {
        self.enName = otherEnName;
    }
    if (!NSDictionaryIsEmpty(otherNames))
    {
        if ([otherNames.allKeys containsObject:@"name:en"])
            self.enName = otherNames[@"name:en"];
        else if ([otherNames.allKeys containsObject:@"en"])
            self.enName = otherNames[@"en"];
        
        for (NSString *originalKey in otherNames.allKeys)
        {
            NSString *key = originalKey;
            NSString *value = otherNames[key];
            
            if ([key hasPrefix:@"name:"])
                key = [key substringFromIndex:@"name:".length];
            if (!self.localizedNames)
                self.localizedNames = [NSMutableDictionary new];
            if (overwrite || NSStringIsEmpty(self.localizedNames[key]))
                self.localizedNames[key] = value;
        }
    }
}

- (void)copyNames:(NSString *)otherName otherEnName:(NSString *)otherEnName otherNames:(NSDictionary<NSString *, NSString *> *)otherNames
{
    [self copyNames:otherName otherEnName:otherEnName otherNames:otherNames overwrite:NO];
}

- (void)copyNames:(OAMapObject *)s copyName:(BOOL)copyName copyEnName:(BOOL)copyEnName overwrite:(BOOL)overwrite
{
    NSString *name = copyName ? s.name : nil;
    NSString *enName = copyEnName ? s.enName : nil;
    [self copyNames:name otherEnName:enName otherNames:s.localizedNames overwrite:overwrite];
}

- (void)copyNames:(OAMapObject *)s
{
    [self copyNames:s copyName:YES copyEnName:YES overwrite:NO];
}

- (QVector< OsmAnd::LatLon >) getPolygon
{
    QVector<OsmAnd::LatLon> res;
    if (!_x)
        return res;
    for (int i = 0; i < _x.count; i++)
    {
        res.push_back(OsmAnd::LatLon(OsmAnd::Utilities::get31LatitudeY(_y[i].intValue), OsmAnd::Utilities::get31LongitudeX(_x[i].intValue)));
    }
    return res;
}

- (QVector< OsmAnd::PointI >) getPointsPolygon
{
    QVector<OsmAnd::PointI> res;
    if (!_x)
        return res;
    for (int i = 0; i < _x.count; i++)
    {
        res.push_back(OsmAnd::PointI(_y[i].intValue, _x[i].intValue));
    }
    return res;
}

+ (BOOL) isNameLangTag:(NSString *)tag
{
    NSString *prefix = @"name:";
    if ([tag hasPrefix:prefix])
    {
        // languages code <= 3
        if (tag.length <= prefix.length + 3)
            return YES;
        
        int l = [tag indexOf:@"-"];
        if (l <= prefix.length + 3)
            return YES;
    }
    return NO;
}

+ (void)parseNamesJSON:(NSString *)json
                object:(OAMapObject *)object
{
    if (!json)
        return;

    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (!data)
    {
        NSLog(@"Error: Could not convert string to UTF-8 data");
        return;
    }

    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&error];

    if (error)
    {
        NSLog(@"Error parsing json: %@", error.localizedDescription);
        return;
    }

    if ([jsonDict isKindOfClass:[NSDictionary class]])
        object.localizedNames = [jsonDict mutableCopy];
}

@end
