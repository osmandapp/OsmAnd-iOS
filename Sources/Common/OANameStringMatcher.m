//
//  OANameStringMatcher.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANameStringMatcher.h"

@implementation OANameStringMatcher
{
    OACollatorStringMatcher *_sm;
}

- (instancetype) initWithLastWord:(NSString *)lastWordTrim mode:(StringMatcherMode)mode
{
    self = [self init];
    if (self)
    {
        _sm = [[OACollatorStringMatcher alloc] initWithPart:lastWordTrim mode:mode];
    }
    return self;
}

- (BOOL) matchesMap:(NSArray<NSString *>  *)map
{
    if (!map)
        return NO;
    
    for (NSString *v in map)
    {
        if ([_sm matches:v])
            return YES;
    }
    return NO;
}

- (BOOL) matches:(NSString *)name
{
    return [_sm matches:name];
}

@end
