//
//  OAGpxWptItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"

@implementation OAGpxWptItem

- (void)setPoint:(OAGpxWpt *)point
{
    _point = point;
    [self acquireColor];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self applyColor];
}

- (void) applyColor
{
    if (!self.point)
        return;
    
    self.point.color = [OAUtilities colorToString:self.color];
}

- (void) acquireColor
{
    if (self.point.color.length > 0)
        self.color = [OAUtilities colorFromString:self.point.color];
}

@end
