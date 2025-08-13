//
//  OAExitInfo.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAExitInfo.h"

@implementation OAExitInfo

- (BOOL) isEmpty
{
    return _ref == nil && _exitStreetName == nil;
}

@end
