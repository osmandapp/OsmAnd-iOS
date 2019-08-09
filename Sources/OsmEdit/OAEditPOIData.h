//
//  OAEditPOIData.h
//  OsmAnd
//
//  Created by Paul on 1/25/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/EditPoiData.java
//  git revision dcd05c455facb38793c06dda9ba5a14e93423450

#import <Foundation/Foundation.h>

#define POI_TYPE_TAG @"poi_type_tag"
#define REMOVE_TAG_PREFIX @"----"
#define REMOVE_TAG_VALUE @"DELETE"

NS_ASSUME_NONNULL_BEGIN

@class OAEntity;
@class OAPOIType;
@class OAPOICategory;
@class OAObservable;

@interface OAEditPOIData : NSObject

@property (readonly) OAObservable *tagsChangedObservable;

-(id) initWithEntity:(OAEntity *)entity;

-(NSDictionary<NSString *, OAPOIType *> *)getAllTranslatedSubTypes;

-(void)updateType:(OAPOICategory *)type;
-(OAPOICategory *)getPoiCategory;
-(OAPOIType *)getCurrentPoiType;
-(OAPOIType *) getPoiTypeDefined;
-(NSString *) getPoiTypeString;
-(OAEntity *) getEntity;
-(NSString *) getTag:(NSString *) key;
-(void)updateTags:(NSDictionary<NSString *, NSString *> *) tagMap;
-(NSDictionary<NSString *, NSString *> *)getTagValues;
-(void)putTag:(NSString *)tag value:(NSString *)value;
-(void)removeTag:(NSString *)tag;

-(void)setIsInEdit:(BOOL)isInEdit;
-(BOOL)isInEdit;
-(NSSet<NSString *> *)getChangedTags;
-(NSArray*) getTranslatedSubTypesMatchingWith:(NSString*) searchString;

//public void addListener(TagsChangedListener listener)
//public void deleteListener(TagsChangedListener listener)
//public interface TagsChangedListener
//-(void) notifyToUpdateUI;

-(BOOL)hasChangesBeenMade;
-(void)updateTypeTag:(NSString *)newTag userChanges:(BOOL)userChanges;

@end

NS_ASSUME_NONNULL_END
