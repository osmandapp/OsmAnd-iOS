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
#import "OAPOIHelper.h"

static NSMutableSet<NSString *> *nullTypeSetInstance;

@interface OAPOIBaseType ()

@property (nonatomic, readwrite) NSString *name;

@end

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

- (NSString *)nameLocalized
{
    if (!_nameLocalized)
        _nameLocalized = [OAPOIHelper.sharedInstance getPhraseByName:_name];
    return _nameLocalized;
}

- (NSString *)nameLocalizedEN
{
    if (!_nameLocalizedEN)
        _nameLocalizedEN = [OAPOIHelper.sharedInstance getPhraseENByName:_name];
    return _nameLocalizedEN;
}

- (NSString *)nameSynonyms
{
    if (!_nameSynonyms)
        _nameSynonyms = [OAPOIHelper.sharedInstance getSynonymsByName:_name];
    return _nameSynonyms;
}

- (UIImage *)icon
{
    return [UIImage mapSvgImageNamed:[NSString stringWithFormat:@"mx_%@", self.name]];
}

- (NSString *)iconName
{
    return [NSString stringWithFormat:@"mx_%@", self.name];
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
            _poiAdditionalsCategorized = [_poiAdditionalsCategorized arrayByAddingObject:poiType];
    }
}

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) putTypes:(NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *)acceptedTypes
{
    return nil; // override
}

- (void) addExcludedPoiAdditionalCategories:(NSArray<NSString *> *)excluded
{
    if (!_excludedPoiAdditionalCategories)
        _excludedPoiAdditionalCategories = [NSArray array];
    
    _excludedPoiAdditionalCategories = [_excludedPoiAdditionalCategories arrayByAddingObjectsFromArray:excluded];
}

- (void) setNonEditableOsm:(BOOL)nonEditableOsm
{
    _nonEditableOsm = nonEditableOsm;
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
