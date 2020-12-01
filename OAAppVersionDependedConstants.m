//
//  OAAppVersionDependedConstants.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAppVersionDependedConstants.h"

@implementation OAAppVersionDependedConstants

+ (NSString *) getShortAppVersionWithSeparator
{
    [self getShortAppVersionWithSeparator:@"_"];
}

+ (NSString *) getShortAppVersionWithSeparator:(NSString *)separator
{
    NSString *fullVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSArray *subversions = [fullVersion componentsSeparatedByString:@"."];
    
    if (subversions && subversions.count > 1)
    {
        return [NSString stringWithFormat:@"%@%@%@", subversions[0], separator, subversions[1]];
    }
    else
    {
        return @"3_80";
    }
}

@end
