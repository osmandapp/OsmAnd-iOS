//
//  OATargetPoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetPoint.h"

@implementation OATargetPoint

-(BOOL)isLocationHiddenInTitle
{
    return (self.titleAddress.length > 0 && [self.title rangeOfString:self.titleAddress].length == 0);
}

@end
