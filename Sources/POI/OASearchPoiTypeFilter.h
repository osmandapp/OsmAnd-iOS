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

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory;

- (BOOL) isEmpty;

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction;

@end
