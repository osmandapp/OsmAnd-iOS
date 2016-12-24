//
//  OAPOIBaseType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIBaseType.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAUtilities.h"

static NSMutableSet<NSString *> *nullTypeSetInstance;

@interface OAPOIBaseType ()

@property (nonatomic, readwrite) NSString *name;

@end

@implementation OAPOIBaseType

-(id)copyWithZone:(NSZone *)zone
{
    OAPOIBaseType *clone = [[self class] allocWithZone:zone];
    clone.name = [self.name copyWithZone:zone];
    clone.nameLocalizedEN = [self.nameLocalizedEN copyWithZone:zone];
    clone.nameLocalized = [self.nameLocalized copyWithZone:zone];
    clone.top = self.top;
    clone.baseLangType = [self.baseLangType copyWithZone:zone];
    clone.lang = [self.lang copyWithZone:zone];
    clone.poiAdditionals = [self.poiAdditionals copyWithZone:zone];
    clone.poiAdditionalsCategorized = [self.poiAdditionalsCategorized copyWithZone:zone];
    return clone;
}

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

- (NSString *)iconName
{
    return [NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@", [OAUtilities drawablePostfix], self.name];
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
        _poiAdditionals = @[poiType];
    else
        _poiAdditionals = [_poiAdditionals arrayByAddingObject:poiType];
    
    if (poiType.poiAdditionalCategory)
    {
        if (!_poiAdditionalsCategorized)
            _poiAdditionalsCategorized = @[poiType];
        else
            [_poiAdditionalsCategorized arrayByAddingObject:poiType];
    }
}

- (NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *) putTypes:(NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *)acceptedTypes
{
    return nil; // override
}

+(NSMutableSet<NSString *> *)nullSet
{
    if (!nullTypeSetInstance)
        nullTypeSetInstance = [NSMutableSet set];
    
    return nullTypeSetInstance;
}

+(BOOL)isNullSet:(NSMutableSet<NSString *> *)set
{
    return set == [self.class nullSet];
}

@end
