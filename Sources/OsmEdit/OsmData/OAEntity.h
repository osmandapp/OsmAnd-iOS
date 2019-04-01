//
//  OAEntity.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/Entity.java
//  git revision cc94ead73db0af7a3793cd56ba08a750d2c992f9

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAOSMSettings.h"

static const int MODIFY_UNKNOWN = 0;
static const int MODIFY_DELETED = -1;
static const int MODIFY_MODIFIED = 1;
static const int MODIFY_CREATED = 2;

NS_ASSUME_NONNULL_BEGIN
@class OAEntityId;
@class OAEntity;

typedef NS_ENUM(NSInteger, EOAEntityType)
{
    UNDEFINED = -1,
    NODE,
    WAY,
    RELATION,
    WAY_BOUNDARY
};

@protocol OAEntityProtocol <NSObject>

@required
-(void)initializeLinks:(NSDictionary<OAEntityId *, OAEntity *> *)entities;
-(CLLocationCoordinate2D)getLatLon;

@end

@interface OAEntity : NSObject <OAEntityProtocol>

-(id)initWithId:(long long)identifier;
-(id)initWithId:(long long)identifier latitude:(double)lat longitude:(double)lon;
-(id)initWithEntity:(OAEntity *)copy identifier:(long long)identifier;


-(NSSet<NSString *> *) getChangedTags;
-(void) setChangedTags:(NSSet<NSString *> *)changedTags;
-(NSInteger) getModify;
-(void)setModify:(NSInteger)modify;
-(long long) getId;
-(double)getLatitude;
-(double) getLongitude;

-(void)setLatitude:(double) latitude;
-(void) setLongitude:(double) longitude;

-(void)removeTag:(NSString *)key;
-(void)removeTags:(NSArray<NSString *> *)keys;

-(void)putTag:(NSString *)key value:(NSString *)value;
-(void)putTagNoLC:(NSString *)key value:(NSString *)value;

-(void)replaceTags:(NSDictionary<NSString *, NSString *> *)toPut;

-(NSString *)getTag:(EOAOsmTagKey)key;
-(NSString *)getTagFromString:(NSString *) key;
-(NSDictionary<NSString *, NSString *> *)getNameTags;
-(NSInteger)getVersion;

-(void)setVersion:(NSInteger)version;
-(NSDictionary<NSString *, NSString *> *)getTags;
-(NSArray<NSString *> *)getTagKeySet;

-(BOOL)isDataLoaded;
-(NSString *) toNSString;

+(EOAEntityType)typeOf:(OAEntity *)entity;
+(EOAEntityType)typeFromString:(NSString *)entityName;
+(NSString *)stringTypeOf:(OAEntity *)entity;

@end


@interface OAEntityId : NSObject

-(id) initWithEntityType:(EOAEntityType)type identifier:(long long)identifier;
+(OAEntityId *) valueOf:(OAEntity *)entity;
-(NSString *) toNSString;
-(EOAEntityType) getType;
-(long long) getId;
-(NSString *) getOsmUrl;

@end


NS_ASSUME_NONNULL_END
