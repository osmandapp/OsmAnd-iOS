//
//  OAPoiUIFilterDataProviderWrapper.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.01.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAPoiUIFilterDataProviderWrapper.h"
#import "OAAmenitySearcher.h"

@implementation OAPoiUIFilterDataProviderWrapper

+ (NSArray<OAPOI *> *)searchAmenities:(OASearchPoiTypeFilter *)searchFilter
                     additionalFilter:(OATopIndexFilter *)additionalFilter
                          topLatitude:(double)topLatitude
                       bottomLatitude:(double)bottomLatitude
                        leftLongitude:(double)leftLongitude
                       rightLongitude:(double)rightLongitude
                        includeTravel:(BOOL)includeTravel
                              matcher:(OAResultMatcher<OAPOI *> *)matcher
                              publish:(BOOL(^)(OAPOI *poi))publish
{
    return [OAAmenitySearcher searchAmenities:searchFilter
                             additionalFilter:additionalFilter
                                  topLatitude:topLatitude
                               bottomLatitude:bottomLatitude
                                leftLongitude:leftLongitude
                               rightLongitude:rightLongitude
                                includeTravel:includeTravel
                                      matcher:matcher
                                      publish:publish];
}

@end

