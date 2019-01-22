//
//  OAEntity.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAEntity.h"

static const int MODIFY_UNKNOWN = 0;
static const int MODIFY_DELETED = -1;
static const int MODIFY_MODIFIED = 1;
static const int MODIFY_CREATED = 2;

@implementation OAEntity
{
    NSMutableDictionary <NSString *, NSString *> *_tags;
    NSSet<NSString *> *_changedTags;
    long _id;
    BOOL _dataLoaded;
    NSInteger _modify;
    NSInteger _version;
    double latitude;
    double longitude;
}





-(long) getId
{
    return _id;
}

@end

@implementation OAEntityId
{
    EOAEntityType _entityType;
    long _identifier;
}

-(id) initWithEntityType:(EOAEntityType)type identifier:(long)identifier
{
    self = [super init];
    if (self) {
        _entityType = type;
        _identifier = identifier;
    }
    return self;
}

+ (OAEntityId *) valueOf:(OAEntity *)entity
{
    return [[OAEntityId alloc] initWithEntityType:[OAEntity typeOf:entity] identifier:[entity getId]];
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + (!_identifier ? 0 : [[NSNumber numberWithLong:_identifier] hash]);
    result = prime * result + (!_entityType ? 0 : [[NSNumber numberWithInteger:_entityType] hash]);
    return result;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"%ld %ld", _entityType, _identifier];
}

-(EOAEntityType) getType
{
    return _entityType;
}

-(long) getId
{
    return _identifier;
}

-(NSString *) getOsmUrl
{
    static const NSString *browseUrl = @"https://www.openstreetmap.org/browse/";
    if (_entityType == NODE)
        return [NSString stringWithFormat:@"%@node/%ld", browseUrl, _identifier];
    if (_entityType == WAY)
        return [NSString stringWithFormat:@"%@way/%ld", browseUrl, _identifier];
    return nil;
}

-(BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    if (![object isKindOfClass:self.class])
        return NO;
    OAEntityId *other = (OAEntityId *) object;
    if (!_identifier) {
        if ([other getId])
            return NO;
    } else if (_identifier != [other getId])
        return NO;
    if (!_entityType) {
        if ([other getType])
            return NO;
    } else if (_entityType != [other getType])
        return NO;
    return YES;
}

@end
