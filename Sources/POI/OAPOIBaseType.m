//
//  OAPOIBaseType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAUtilities.h"

@implementation OAPOIBaseType

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name;
    }
    return self;
}

- (UIImage *)icon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@", [OAUtilities drawablePostfix], self.name]];
    
    return [OAUtilities applyScaleFactorToImage:img];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIBaseType class]]) {
        OAPOIBaseType *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isAdditional
{
    return [self isKindOfClass:[OAPOIType class]] && [((OAPOIType *) self) isAdditional];
}

- (void)addPoiAdditional:(OAPOIType *)poiType
{
    if (!_poiAdditionals)
    {
        _poiAdditionals = @[poiType];
    }
    else
    {
        _poiAdditionals = [_poiAdditionals arrayByAddingObject:poiType];
    }
}

@end
