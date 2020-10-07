//
//  OARelation.m
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARelation.h"
#import <CoreLocation/CoreLocation.h>

@interface OARelationMember()

@property (nonatomic) OAEntity *entity;
@property (nonatomic) OAEntityId *entityId;
@property (nonatomic) NSString *role;

@end

@implementation OARelationMember

-(id)initWithEntityId:(OAEntityId *)entityId role:(NSString *)role
{
    self = [super init];
    if (self) {
        _entityId = entityId;
        _role = role;
    }
    return self;
}

-(OAEntityId *)getEntityId
{
    if(!_entityId && _entity) {
        return [OAEntityId valueOf:_entity];
    }
    return _entityId;
}

-(NSString *)getRole
{
    return _role;
}

-(OAEntity *)getEntity
{
    return _entity;
}

-(NSString *)toNSString
{
    return [NSString stringWithFormat:@"%@ %@", [_entityId toNSString], _role];
}

@end

@implementation OARelation
{
    NSMutableArray<OARelationMember *> *_members;
}


-(void)addMember:(long long)identifier entityType:(EOAEntityType)type role:(NSString *)role
{
    [self addMember:[[OAEntityId alloc] initWithEntityType:type identifier:identifier] role:role];
}

- (void) addMember:(OAEntityId *)identifier role:(NSString *)role
{
    if (!_members)
        _members = [NSMutableArray new];
    [_members addObject:[[OARelationMember alloc] initWithEntityId:identifier role:role]];
}

-(NSArray<OARelationMember *> *)getMembers:(NSString *)role
{
    if (!_members)
        return [NSArray new];
    if (!role) {
        return _members;
    }
    NSMutableArray<OARelationMember *> *l = [NSMutableArray new];
    for (OARelationMember *m in _members) {
        if ([role isEqualToString:[m getRole]]) {
            [l addObject:m];
        }
    }
    return l;
}
-(NSArray<OARelationMember *> *)getMembers
{
    if(!_members)
        return [NSArray new];
    
    return _members;
}

-(void)removeEntity:(OAEntityId *) key
{
    if(_members) {
        NSMutableArray<OARelationMember *> *toKeep = [NSMutableArray new];
        for (OARelationMember *m in _members) {
            if (![key isEqual:[m getEntityId]]) {
                [toKeep addObject:m];
            }
        }
        [_members setArray:toKeep];
    }
}
-(void)removeRelationMember:(OARelationMember *)key
{
    if (_members)
        [_members removeObject:key];
}

- (CLLocationCoordinate2D) getLatLon
{
    return kCLLocationCoordinate2DInvalid;
}

- (void)initializeLinks:(nonnull NSDictionary<OAEntityId *,OAEntity *> *)entities {
    if (_members) {
        for(OARelationMember *rm in _members) {
            if([rm getEntityId] && [entities objectForKey:[rm getEntityId]]) {
                rm.entity = [entities objectForKey:[rm getEntityId]];
            }
        }
    }
}

- (void) update:(OARelationMember *)r newEntityId:(OAEntityId *)newEntityId
{
    r.entity = nil;
    r.entityId = newEntityId;
}

- (void) updateRole:(OARelationMember*)r newRole:(NSString *)newRole
{
    r.role = newRole;
}

// Unused in Android
//public List<Entity> getMemberEntities(String role) {
//    if (members == null) {
//        return Collections.emptyList();
//    }
//    List<Entity> l = new ArrayList<>();
//    for (RelationMember m : members) {
//        if (role == null || role.equals(m.role)) {
//            if(m.entity != null) {
//                l.add(m.entity);
//            }
//        }
//    }
//    return l;
//}

@end
