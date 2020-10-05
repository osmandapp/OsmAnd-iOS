//
//  OAExitInfo.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAExitInfo.h"

@implementation OAExitInfo
{
    NSString *_ref;
    NSString *_exitStreetName;
}

- (NSString *) getRef
{
    return _ref;
}

- (void) setRef:(NSString *)ref
{
    _ref = ref;
}

- (NSString *) getExitStreetName
{
    return _exitStreetName;
}

- (void) setExitStreetName:(NSString *) exitStreetName
{
    _exitStreetName = exitStreetName;
}

@end
