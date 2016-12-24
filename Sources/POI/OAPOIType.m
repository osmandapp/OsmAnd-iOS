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

-(id)copyWithZone:(NSZone *)zone
{
    OAPOIType* clone = [super copyWithZone:zone];
    clone.tag = [self.tag copyWithZone:zone];
    clone.value = [self.value copyWithZone:zone];
    clone.category = [self.category copyWithZone:zone];
    clone.filter = [self.filter copyWithZone:zone];
    clone.parentType = [self.parentType copyWithZone:zone];
    clone.referenceType = [self.referenceType copyWithZone:zone];
    clone.parent = self.parent;
    clone.poiAdditionalCategory = [self.poiAdditionalCategory copyWithZone:zone];
    clone.poiAdditionalCategoryLocalized = [self.poiAdditionalCategoryLocalized copyWithZone:zone];
    clone.isText = self.isText;
    clone.reference = self.reference;
    clone.mapOnly = self.mapOnly;
    clone.order = self.order;
    return clone;
}

- (instancetype)initWithName:(NSString *)name category:(OAPOICategory *)category;
{
    self = [super initWithName:name];
    if (self)
    {
        _category = category;
    }
    return self;
}

- (UIImage *)icon
{
    UIImage *img = [super icon];
    if (!img)
    {
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value]];
        return [OAUtilities applyScaleFactorToImage:img];
    }
    return img;
}

-(NSString *)iconName
{
    return [NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value];
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
    if ([object isKindOfClass:[OAPOIType class]])
    {
        OAPOIType *obj = object;
        return [self.name isEqualToString:obj.name] && [self.tag isEqualToString:obj.tag];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [self.name hash] + (_tag ? [_tag hash] : 1);
}

- (void)setAdditional:(OAPOIBaseType *)parentType
{
    _parentType = parentType;
}

- (BOOL)isAdditional
{
    return _parentType != nil;
}


-(NSMutableDictionary<OAPOICategory *,NSMutableSet<NSString *> *> *)putTypes:(NSMutableDictionary<OAPOICategory *,NSMutableSet<NSString *> *> *)acceptedTypes
{
    if (self.isAdditional)
        return [_parentType putTypes:acceptedTypes];

    OAPOIType *poiType = self.referenceType ? self.referenceType : self;
    if (![acceptedTypes objectForKey:poiType.category])
        [acceptedTypes setObject:[NSMutableSet set] forKey:poiType.category];

    NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:poiType.category];
    if (set)
        [set addObject:poiType.name];
    
    return acceptedTypes;
}
@end
