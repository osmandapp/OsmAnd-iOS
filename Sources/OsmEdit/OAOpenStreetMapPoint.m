//
//  OAOpenStreetMapPoint.m
//  OsmAnd
//
//  Created by Paul on 1/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOpenStreetMapPoint.h"
#import "OAEntity.h"
#import "OAOSMSettings.h"
#import "OAEditPOIData.h"
#import "Localization.h"

@implementation OAOpenStreetMapPoint
{
    OAEntity *_entity;
    NSString *_comment;
}


-(NSString *)getName
{
    NSString *ret = [_entity getTag:NAME];
    if (!ret)
        return @"";
    return ret;
}

-(NSString *) getType
{
    NSString *type = @"amenity";
    for (NSString *key in [_entity getTagKeySet]) {
        if (![[OAOSMSettings getOSMKey:NAME] isEqualToString:key] && ![[OAOSMSettings getOSMKey:OPENING_HOURS] isEqualToString:key] &&
            ![key hasPrefix:REMOVE_TAG_PREFIX]) {
            type = key;
            break;
        }
    }
    return type;
}

-(NSString *) getSubType
{
    if([[self getType] length] == 0)
        return @"";
    return [_entity getTagFromString:[self getType]];
}

-(OAEntity *) getEntity
{
    return _entity;
}
-(NSString *) getComment
{
    return _comment;
}

-(void) setEntity:(OAEntity *)entity
{
    _entity = entity;
}

-(void) setComment:(NSString *)comment
{
    _comment = comment;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"Openstreetmap Point %@ %@ (%lld): [%@/%@ (%f, %f)]", [self getActionString], [self getName],
            [self getId], [self getType], [self getSubType], [self getLatitude], [self getLongitude]];
}

- (EOAGroup)getGroup { 
    return POI;
}

- (long long)getId { 
    return [_entity getId];
}

- (double)getLatitude { 
    return [_entity getLatitude];
}

- (double)getLongitude { 
    return [_entity getLongitude];
}

- (NSString *)getTagsString
{
    NSMutableString *sb;
    for (NSString *tag in [_entity getTags].allKeys)
    {
        NSString *val = [_entity getTags][tag];
        if ([_entity isNotValid:tag])
        {
            continue;
        }
        [sb appendString:[NSString stringWithFormat:@"%@ : %@; ", tag, val]];
    }
    return sb;
}

-(NSDictionary<NSString *, NSString *> *)getTags
{
    return _entity ? _entity.getTags : [NSDictionary new];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (![self isKindOfClass:[other class]]) {
        return NO;
    } else {
        OAOpenStreetMapPoint *otherPoint = (OAOpenStreetMapPoint *)other;
        BOOL res = [self.getName isEqualToString:otherPoint.getName];
        res = res && [OAUtilities isCoordEqual:self.getLatitude srcLon:self.getLongitude destLat:otherPoint.getLatitude destLon:otherPoint.getLongitude];
        if (self.getType)
            res = res && [self.getType isEqualToString:otherPoint.getType];
        if (self.getSubType)
            res = res && [self.getSubType isEqualToString:otherPoint.getSubType];
        if (self.getTagsString)
            res = res && [self.getTagsString isEqualToString:otherPoint.getTagsString];
        res = res && self.getId == otherPoint.getId;
        return res;
    }
}

- (NSUInteger)hash
{
    NSUInteger result = self.getName ? self.getName.hash : 0;
    result = 31 * result + @(self.getLatitude).hash;
    result = 31 * result + @(self.getLongitude).hash;
    result = 31 * result + (self.getType ? self.getType.hash : 0);
    result = 31 * result + (self.getSubType ? self.getSubType.hash : 0);
    result = 31 * result + (self.getTagsString ? self.getTagsString.hash : 0);
    result = 31 * result + @(self.getId).hash;
    return result;
}


@end
