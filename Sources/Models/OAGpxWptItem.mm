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
        self.color = [OAUtilities colorFromString:self.point.color];
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
    UIImage *resultImg;
    NSString *backgrounfIconName = [@"bg_point_" stringByAppendingString:_point.getBackgroundIcon];
    UIImage *backgroundImg = [UIImage imageNamed:backgrounfIconName];
    backgroundImg = [OAUtilities tintImageWithColor:backgroundImg color:_point.getColor];
    
    NSString *iconName = [@"mx_" stringByAppendingString:_point.getIcon];
    UIImage *iconImg = [UIImage imageNamed:[OAUtilities drawablePath:iconName]];
    iconImg = [OAUtilities tintImageWithColor:iconImg color:UIColor.whiteColor];
    CGFloat smallIconSize = 26;
    iconImg  = [OAUtilities resizeImage:iconImg newSize:CGSizeMake(smallIconSize, smallIconSize)];
    CGFloat centredIconOffset = (backgroundImg.size.width - iconImg.size.width) / 2;
    
    UIGraphicsBeginImageContext(backgroundImg.size);
    [backgroundImg drawInRect:CGRectMake(0, 0, backgroundImg.size.width, backgroundImg.size.height)];
    [iconImg drawInRect:CGRectMake(centredIconOffset, centredIconOffset, iconImg.size.width, iconImg.size.height)];
    resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImg;
}

@end
