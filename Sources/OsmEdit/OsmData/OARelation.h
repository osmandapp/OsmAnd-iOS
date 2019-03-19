//
//  OARelation.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/Relation.java
//  git revision db3b280a26eaf721222ec918e8c0baf4dca9b1fd

#import "OAEntity.h"

NS_ASSUME_NONNULL_BEGIN


@interface OARelationMember : NSObject

-(id)initWithEntityId:(OAEntityId *)entityId role:(NSString *)role;

-(OAEntityId *)getEntityId;
-(NSString *)getRole;
-(OAEntity *)getEntity;
-(NSString *)toNSString;

@end

@interface OARelation : OAEntity <OAEntityProtocol>

-(void)addMember:(long) identifier entityType:(EOAEntityType)type role:(NSString *)role;
-(NSArray<OARelationMember *> *)getMembers:(NSString *)role;
-(NSArray<OARelationMember *> *)getMembers;

-(void)removeEntity:(OAEntityId *) key;
-(void)removeRelationMember:(OARelationMember *)key;

// unused
//-(NSArray<OAEntity *> *)getMemberEntities:(NSString *) role;

@end

NS_ASSUME_NONNULL_END
