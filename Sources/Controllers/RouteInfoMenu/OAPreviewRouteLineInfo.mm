//
//  OAPreviewRouteLineInfo.mm
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAPreviewRouteLineInfo.h"
#import "OAColoringType.h"

@implementation OAPreviewRouteLineInfo

- (instancetype)initWithCustomColorDay:(NSInteger)customColorDay
                      customColorNight:(NSInteger)customColorNight
                          coloringType:(OAColoringType *)coloringType
                    routeInfoAttribute:(NSString *)routeInfoAttribute
                                 width:(NSString *)width
                        showTurnArrows:(BOOL)showTurnArrows
{
    self = [super init];
    if (self)
    {
        _customColorDay = customColorDay;
        _customColorNight = customColorNight;
        _coloringType = coloringType;
        _routeInfoAttribute = routeInfoAttribute;
        _width = width;
        _showTurnArrows = showTurnArrows;
    }
    return self;
}

- (void)setCustomColor:(NSInteger)color nightMode:(BOOL)nightMode
{
    if (nightMode)
        _customColorNight = color;
    else
        _customColorDay = color;
}

/*- (void)setRouteColoringType:(OAColoringType *)coloringType
{
    _coloringType = coloringType;
}

- (void)setRouteInfoAttribute:(NSString *)routeInfoAttribute
{
    _routeInfoAttribute = routeInfoAttribute;
}

- (void)setWidth:(NSString *)width
{
    _width = width;
}

- (void)setShowTurnArrows:(BOOL)showTurnArrows
{
    _showTurnArrows = showTurnArrows;
}*/

- (NSInteger)getCustomColor:(BOOL)nightMode
{
    return nightMode ? self.customColorNight : self.customColorDay;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;

    if (![self isKindOfClass:[other class]])
    {
        return NO;
    }
    else
    {
        OAPreviewRouteLineInfo *that = (OAPreviewRouteLineInfo *) other;

        if ([self getCustomColor:NO] != [that getCustomColor:NO])
            return NO;
        if ([self getCustomColor:YES] != [that getCustomColor:YES])
            return NO;
        if (![self.coloringType isEqual:that.coloringType])
            return NO;
        if (![self.routeInfoAttribute isEqualToString:that.routeInfoAttribute])
            return NO;
        return [self.width isEqualToString:that.width];
    }
}

- (NSUInteger)hash
{
    NSUInteger result = self.customColorDay;
    result = 31 * result + self.customColorNight;
    result = 31 * result + [[OAColoringType getRouteColoringTypes] indexOfObject:self.coloringType];
    result = 31 * result + (self.routeInfoAttribute != nil ? self.routeInfoAttribute.hash : 0);
    result = 31 * result + (self.width != nil ? self.width.hash : 0);
    return result;
}

@end
