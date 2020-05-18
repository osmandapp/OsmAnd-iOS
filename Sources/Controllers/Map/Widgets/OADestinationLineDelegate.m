//
//  OADestinationLineDelegate.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 21.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADestinationLineDelegate.h"

@implementation OADestinationLineDelegate

-(id) initWithDestinationLine:(OADestinationsLineWidget *)destinationLine
{
    self = [super init];
    if (self)
    {
        [self commonInit:destinationLine];
    }
    return self;
}

- (void) commonInit:(OADestinationsLineWidget *)line
{
    _destinationLine = line;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_destinationLine drawDestinationLineLayer:layer inContext:ctx];
}

@end
