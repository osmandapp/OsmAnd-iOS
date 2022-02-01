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
#import "OAFavoritesHelper.h"

@implementation OAGpxWptItem

+ (instancetype)withGpxWpt:(OAGpxWpt *)gpxWpt
{
    OAGpxWptItem *gpxWptItem = [[OAGpxWptItem alloc] init];
    if (gpxWptItem)
    {
        gpxWptItem.point = gpxWpt;
    }
    return gpxWptItem;
}

- (void) setPoint:(OAGpxWpt *)point
{
    _point = point;
    [self acquireColor];
}

- (void) setColor:(UIColor *)color
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
        self.color = [UIColor colorFromString:self.point.color];
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OAGpxWptItem *wptItem = (OAGpxWptItem *) o;
    if (!self.docPath && wptItem.docPath)
        return NO;
    if (self.docPath && ![self.docPath isEqualToString:wptItem.docPath])
        return NO;
    if (!self.point && wptItem.point)
        return NO;
    if (self.point && ![self.point isEqual:wptItem.point])
        return NO;
    if (!self.color && wptItem.color)
        return NO;
    if (self.color && ![self.color isEqual:wptItem.color])
        return NO;
    if (self.groups.count != wptItem.groups.count)
        return NO;

    return YES;
}

- (NSUInteger) hash
{
    NSUInteger result = self.docPath ? [self.docPath hash] : 0;
    result = 31 * result + (self.groups ? [self.groups hash] : 0);
    result = 31 * result + (self.color ? [self.color hash] : 0);
    return result;
}

- (UIImage *) getCompositeIcon
{
    return [OAFavoritesHelper getCompositeIcon:_point.getIcon backgroundIcon:_point.getBackgroundIcon color:_point.getColor];
}

@end
