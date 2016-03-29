//
//  OAOpeningHoursParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAOpeningHoursParser.h"

@implementation OAOpeningHoursParser

- (instancetype)initWithOpeningHours:(NSString *) openingHours
{
    self = [super init];
    if (self)
    {
        _openingHours = [openingHours copy];
    }
    return self;
}

- (BOOL) isOpenedForTime:(NSDate *) time
{
    // todo: needs implementation
    return false;
}

@end
