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

+ (instancetype)withGpxWpt:(OAWptPt *)gpxWpt
{
    OAGpxWptItem *gpxWptItem = [[OAGpxWptItem alloc] init];
    if (gpxWptItem)
    {
        gpxWptItem.point = gpxWpt;
    }
    return gpxWptItem;
}

- (void) setPoint:(OAWptPt *)point
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
    
    [self.point setColor:[OAUtilities colorToNumber:self.color]];
}

- (void) acquireColor
{
    int color = [self.point getColor:0];
    if (color != 0)
        self.color = UIColorFromRGBA(color);
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
    backgroundImg = [OAUtilities tintImageWithColor:backgroundImg color:UIColorFromRGBA([_point getColor:0])];

    NSString *iconName = [@"mx_" stringByAppendingString:_point.getIcon];
    UIImage *iconImg = [UIImage imageNamed:[OAUtilities drawablePath:iconName]];
    iconImg = [OAUtilities tintImageWithColor:iconImg color:UIColor.whiteColor];
 
    CGFloat scaledIconSize = backgroundImg.size.width * backgroundImg.scale;
    backgroundImg  = [OAUtilities resizeImage:backgroundImg newSize:CGSizeMake(scaledIconSize, scaledIconSize)];
    CGFloat centredIconOffset = (backgroundImg.size.width - iconImg.size.width) / 2;
    
    UIGraphicsBeginImageContext(backgroundImg.size);
    [backgroundImg drawInRect:CGRectMake(0, 0, backgroundImg.size.width, backgroundImg.size.height)];
    [iconImg drawInRect:CGRectMake(centredIconOffset, centredIconOffset, iconImg.size.width, iconImg.size.height)];
    resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImg;
}

@end
