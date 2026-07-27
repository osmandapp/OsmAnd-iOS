//
//  OASearchPoiTypeFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOICategory;

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^OASearchPoiTypeFilterAccept)(OAPOICategory *type, NSString *subcategory);
typedef BOOL (^OASearchPoiTypeFilterIsEmpty)(void);
typedef NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *_Nullable (^OASearchPoiTypeFilterGetTypes)(void);

@interface OASearchPoiTypeFilter : NSObject

@property (nonatomic) OASearchPoiTypeFilterAccept acceptFunction;
@property (nonatomic) OASearchPoiTypeFilterIsEmpty emptyFunction;
@property (nonatomic, nullable) OASearchPoiTypeFilterGetTypes getAcceptedTypesFunction;

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory;

- (BOOL) isEmpty;

- (nullable NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes;
- (nullable NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypesOrigin;

+ (instancetype)acceptAllPoiTypeFilter;
- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(nullable OASearchPoiTypeFilterGetTypes)tFunction;


@end

NS_ASSUME_NONNULL_END
