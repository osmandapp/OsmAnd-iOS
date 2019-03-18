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

@implementation OAOpenStreetMapPoint
{
    OAEntity *_entity;
    NSString *_comment;
}


-(NSString *)getName
{
    NSString *ret = [_entity getTag:NAME];
    if (!ret)
        return [NSString stringWithFormat:@"%@ • %@", [self getLocalizedAction], self.getSubType];
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
    return [NSString stringWithFormat:@"Openstreetmap Point %@ %@ (%ld): [%@/%@ (%f, %f)]", [self getActionString], [self getName],
            [self getId], [self getType], [self getSubType], [self getLatitude], [self getLongitude]];
}

- (EOAGroup)getGroup { 
    return POI;
}

- (long)getId { 
    return [_entity getId];
}

- (double)getLatitude { 
    return [_entity getLatitude];
}

- (double)getLongitude { 
    return [_entity getLongitude];
}

-(NSDictionary<NSString *, NSString *> *)getTags
{
    return _entity ? _entity.getTags : [NSDictionary new];
}

@end
