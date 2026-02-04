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
#import "OAPOI.h"
#import "OADefaultFavorite.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGpxWptItem

+ (instancetype)withGpxWpt:(OASWptPt *)gpxWpt
{
    OAGpxWptItem *gpxWptItem = [[OAGpxWptItem alloc] init];
    if (gpxWptItem)
    {
        gpxWptItem.point = gpxWpt;
    }
    return gpxWptItem;
}

- (void)setPoint:(OASWptPt *)point
{
    _point = point;
    [self acquireColor];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self applyColor];
}

- (OAPOI *)getAmenity
{
    NSDictionary<NSString *, NSString *> *extensions = [_point getExtensionsToRead];
    if (extensions.count > 0)
    {
        return [OAPOI fromTagValue:extensions privatePrefix:@"amenity_" osmPrefix:@"osm_tag_"];
    }
    return nil;
}

- (void) setAmenity:(OAPOI *)amenity
{
     [_point setAmenity:amenity];
}

- (NSString *) getAmenityOriginName
{
    return [_point getAmenityOriginName];
}

- (void) setAmenityOriginName:(NSString *)originName
{
    [_point setAmenityOriginNameOriginName:originName];
}

- (void) applyColor
{
    if (!self.point)
        return;
    OASInt *color = [[OASInt alloc] initWithInt:[self.color toARGBNumber]];
    [self.point setColorColor:color];
}

- (void)acquireColor
{
    self.color = self.point.getColor == 0 ? [OADefaultFavorite getDefaultColor] : UIColorFromARGB(self.point.getColor);
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
    NSString *iconName = _point.getIconName ?: DEFAULT_ICON_NAME_KEY;
    NSString *backgroundIconName = _point.getBackgroundType ?: DEFAULT_ICON_SHAPE_KEY;
    return [OAFavoritesHelper getCompositeIcon:iconName backgroundIcon:backgroundIconName color:UIColorFromARGB([_point getColor])];
}

@end
