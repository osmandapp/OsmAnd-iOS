//
//  OAOsmAndFormatterParams.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAOsmAndFormatterParams.h"

@implementation OAOsmAndFormatterParams

+ (instancetype)defaultParams
{
    OAOsmAndFormatterParams *params = [[self alloc] init];
    params.forceTrailingZerosInDecimalMainUnit = YES;
    params.extraDecimalPrecision = 1;
    params.useLowerBound = NO;
    return params;
}

+ (instancetype)useLowerBoundsParams
{
    OAOsmAndFormatterParams *params = [[self alloc] init];
    params.forceTrailingZerosInDecimalMainUnit = YES;
    params.extraDecimalPrecision = 0;
    params.useLowerBound = YES;
    return params;
}

+ (instancetype)noTrailingZerosParams
{
    OAOsmAndFormatterParams *params = [[self alloc] init];
    params.forceTrailingZerosInDecimalMainUnit = NO;
    params.extraDecimalPrecision = 1;
    params.useLowerBound = NO;
    return params;
}

- (instancetype)setTrailingZerosForMainUnit:(BOOL)forceTrailingZeros
{
    self.forceTrailingZerosInDecimalMainUnit = forceTrailingZeros;
    return self;
}

@end
