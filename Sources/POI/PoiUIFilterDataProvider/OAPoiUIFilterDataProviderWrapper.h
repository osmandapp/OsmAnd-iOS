//
//  OAPoiUIFilterDataProviderWrapper.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAPOI;
@class OASearchPoiTypeFilter;
@class OATopIndexFilter;
@class OAResultMatcher<ObjectType>;

@interface OAPoiUIFilterDataProviderWrapper : NSObject

+ (NSArray<OAPOI *> *)searchAmenities:(OASearchPoiTypeFilter *)searchFilter
                     additionalFilter:(nullable OATopIndexFilter *)additionalFilter
                          topLatitude:(double)topLatitude
                       bottomLatitude:(double)bottomLatitude
                        leftLongitude:(double)leftLongitude
                       rightLongitude:(double)rightLongitude
                        includeTravel:(BOOL)includeTravel
                              matcher:(nullable OAResultMatcher<OAPOI *> *)matcher
                              publish:(nullable BOOL(^)(OAPOI *poi))publish;

@end

NS_ASSUME_NONNULL_END
