//
//  OASearchPoiTypeFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOICategory;

typedef BOOL(^OASearchPoiTypeFilterAccept)(OAPOICategory *type, NSString *subcategory);
typedef BOOL(^OASearchPoiTypeFilterIsEmpty)();
typedef NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *>* (^OASearchPoiTypeFilterGetTypes)();

@interface OASearchPoiTypeFilter : NSObject

@property (nonatomic) OASearchPoiTypeFilterAccept acceptFunction;
@property (nonatomic) OASearchPoiTypeFilterIsEmpty emptyFunction;
@property (nonatomic) OASearchPoiTypeFilterGetTypes getAcceptedTypesFunction;

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory;

- (BOOL) isEmpty;

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes;
- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypesOrigin;

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(OASearchPoiTypeFilterGetTypes)tFunction;


@end
