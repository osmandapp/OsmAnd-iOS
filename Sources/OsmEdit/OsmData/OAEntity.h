//
//  OAEntity.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, EOAEntityType)
{
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

-(NSString *) removeTag:(NSString *)key;
-(void)removeTags:(NSArray<NSString *> *)keys;

-(NSString *)putTag:(NSString *)key value:(NSString *)value;
-(NSString *) putTagNoLC:(NSString *)key value:(NSString *)value;

-(void)replaceTags:(NSMutableDictionary<NSString *, NSString *> *)toPut;

// TODO continue porting! Do not dorget to find LinkedHashMap alternative!!!
//
//public String getTag(OSMTagKey key) {
//    return getTag(key.getValue());
//}
//
//public String getTag(String key) {
//    if (tags == null) {
//        return null;
//    }
//    return tags.get(key);
//}
//
//public Map<String, String> getNameTags() {
//    Map<String, String> result = new LinkedHashMap<String, String>();
//    for (Map.Entry<String, String> e : tags.entrySet()) {
//        if (e.getKey().startsWith("name:")) {
//            result.put(e.getKey(), e.getValue());
//        }
//    }
//    return result;
//}
//
//public int getVersion() {
//    return version;
//}
//
//public void setVersion(int version) {
//    this.version = version;
//}
//
//public Map<String, String> getTags() {
//    if (tags == null) {
//        return Collections.emptyMap();
//    }
//    return Collections.unmodifiableMap(tags);
//}
//
//
//public Collection<String> getTagKeySet() {
//    if (tags == null) {
//        return Collections.emptyList();
//    }
//    return tags.keySet();
//}


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

NS_ASSUME_NONNULL_END
