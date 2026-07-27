//
//  OACustomSearchPoiFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACustomSearchPoiFilter.h"
#import "OAPOI.h"
#import "OAResultMatcher.h"

@implementation OACustomSearchPoiFilter

- (nullable NSString *)getFilterId
{
    return nil; //override
}

-(nullable NSString *)getName
{
    return nil; //override
}

-(nullable NSObject *)getIconResource
{
    return nil; // override
}

-(nullable OAResultMatcher<OAPOI *> *)wrapResultMatcher:(nullable OAResultMatcher<OAPOI *> *)matcher
{
    return nil; // override
}

- (OASearchSortType) getDefaultSearchType
{
    return OASearchSortTypeUnknown; // override
}

-(instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(nullable OASearchPoiTypeFilterGetTypes)tFunction
{
    return [super initWithAcceptFunc:aFunction emptyFunction:eFunction getTypesFunction:tFunction];
}

@end
