//
//  OAAbstractWriter.m
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAbstractWriter.h"

@implementation OAAbstractWriter
{
    BOOL _cancelled;
}

- (BOOL) isCancelled
{
    return _cancelled;
}

- (void) cancel
{
    _cancelled = YES;
}

- (void) write:(OASettingsItem *)item
{
    // Override
}

@end
