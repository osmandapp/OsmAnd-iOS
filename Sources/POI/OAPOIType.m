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

- (instancetype) initWithName:(NSString *)name category:(OAPOICategory *)category;
{
    self = [super initWithName:name];
    if (self)
    {
        _category = category;
    }
    return self;
}

- (instancetype) initWithName:(NSString *)name category:(OAPOICategory *)category filter:(OAPOIFilter *)filter
{
    self = [super initWithName:name];
    if (self)
    {
        _category = category;
        _filter = filter;
    }
    return self;
}

- (UIImage *) icon
{
    UIImage *img = [super icon];
    if (!img)
    {
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value]];
        if (img)
        {
            return [OAUtilities applyScaleFactorToImage:img];
        }
        else if (self.parentType)
        {
            return [self.parentType icon];
        }
        else if (self.filter)
        {
            return [self.filter icon];
        }
        else if (self.category)
        {
            return [self.category icon];
        }
    }
    return img;
}

- (NSString *) iconName
{
    return [NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value];
}

- (UIImage *) mapIcon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mm_%@", [OAUtilities drawablePostfix], [self.name stringByReplacingOccurrencesOfString:@"osmand_" withString:@""]]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mm_%@_%@", [OAUtilities drawablePostfix], self.tag, self.value]];
    
    return [OAUtilities applyScaleFactorToImage:img];
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIType class]])
    {
        OAPOIType *obj = object;
        return [self.name isEqualToString:obj.name] && [self.tag isEqualToString:obj.tag];
    }
    return NO;
}

- (NSUInteger) hash
{
    return [self.name hash] + (_tag ? [_tag hash] : 1);
}

- (void) setAdditional:(OAPOIBaseType *)parentType
{
    _parentType = parentType;
}

- (BOOL) isAdditional
{
    return _parentType != nil;
}


- (NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *) putTypes:(NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *)acceptedTypes
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
