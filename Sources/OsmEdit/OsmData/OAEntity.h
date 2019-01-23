//
//  OAEntity.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAOSMSettings.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, EOAEntityType)
{
    UNDEFINED = -1,
    NODE,
    WAY,
    RELATION,
    WAY_BOUNDARY
};

@interface OAEntity : NSObject

-(id)initWithId:(long)identifier;
-(id)initWithId:(long)identifier latitude:(double)lat longitude:(double)lon;
-(id)initWithEntity:(OAEntity *)copy identifier:(long)identifier;


-(NSSet<NSString *> *) getChangedTags;
-(void) setChangedTags:(NSSet<NSString *> *)changedTags;
-(NSInteger) getModify;
-(void)setModify:(NSInteger)modify;
-(long) getId;
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

@end


@interface OAEntityId : NSObject

-(id) initWithEntityType:(EOAEntityType)type identifier:(long)identifier;
+(OAEntityId *) valueOf:(OAEntity *)entity;
-(NSString *) toNSString;
-(EOAEntityType) getType;
-(long) getId;
-(NSString *) getOsmUrl;

@end


@protocol OAEntityProtocol <NSObject>

@required
-(void)initializeLinks:(NSDictionary<OAEntityId *, OAEntity *> *)entities;
-(CLLocationCoordinate2D)getLatLon;

@end

NS_ASSUME_NONNULL_END
