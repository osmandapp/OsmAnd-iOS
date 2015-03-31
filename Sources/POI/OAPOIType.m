//
//  OAPOI.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIType.h"
#import "OAUtilities.h"

@implementation OAPOIType

- (UIImage *)icon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@", [OAUtilities drawablePostfix], self.name]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value]];
    
    return [OAUtilities applyScaleFactorToImage:img];
}

- (UIImage *)mapIcon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mm_%@", [OAUtilities drawablePostfix], self.name]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mm_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value]];
    
    return [OAUtilities applyScaleFactorToImage:img];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIType class]]) {
        OAPOIType *obj = object;
        return [self.name isEqualToString:obj.name] && [self.tag isEqualToString:obj.tag];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [_name hash] + (_tag ? [_tag hash] : 1);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAPOIType* clone = [[OAPOIType allocWithZone:zone] init];
    
    clone.name = self.name;
    clone.tag = self.tag;
    clone.value = self.value;
    clone.nameLocalized = self.nameLocalized;
    clone.nameLocalizedEN = self.nameLocalizedEN;

    clone.category = self.category;
    clone.categoryLocalized = self.categoryLocalized;
    clone.categoryLocalizedEN = self.categoryLocalizedEN;

    clone.filter = self.filter;
    clone.filterLocalized = self.filterLocalized;
    clone.filterLocalizedEN = self.filterLocalizedEN;
    
    clone.reference = self.reference;
    
    return clone;
}

@end
