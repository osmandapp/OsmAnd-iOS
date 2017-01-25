//
//  OACustomSearchPoiFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACustomSearchPoiFilter.h"
#import "OAPOI.h"

@implementation OACustomSearchPoiFilter

-(NSString *)getName
{
    return nil; //override
}

-(NSObject *)getIconResource
{
    return nil; // override
}

-(OAResultMatcher<OAPOI *> *)wrapResultMatcher:(OAResultMatcher<OAPOI *> *)matcher
{
    return nil; // override
}

-(instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(OASearchPoiTypeFilterGetTypes)tFunction
{
    return [super initWithAcceptFunc:aFunction emptyFunction:eFunction getTypesFunction:tFunction];
}

@end
