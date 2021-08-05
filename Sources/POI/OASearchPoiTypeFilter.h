//
//  OASearchPoiTypeFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOICategory;

@interface OASearchPoiTypeFilter : NSObject

typedef BOOL(^OASearchPoiTypeFilterAccept)(OAPOICategory *type, NSString *subcategory);
@property (nonatomic) OASearchPoiTypeFilterAccept acceptFunction;

typedef BOOL(^OASearchPoiTypeFilterIsEmpty)();
@property (nonatomic) OASearchPoiTypeFilterIsEmpty emptyFunction;

typedef NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *>* (^OASearchPoiTypeFilterGetTypes)();
@property (nonatomic) OASearchPoiTypeFilterGetTypes getAcceptedTypesFunction;

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory;

- (BOOL) isEmpty;

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes;
- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypesOrigin;

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(OASearchPoiTypeFilterGetTypes)tFunction;


@end
