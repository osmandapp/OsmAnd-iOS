//
//  OAPOIType.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
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
        img = [UIImage mapSvgImageNamed:[self iconName]];
        if (img)
        {
            return img;
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
    NSString *iconName = [super iconName];
    if (![OAUtilities hasMapImage:iconName])
    {
        NSString *tvName = [NSString stringWithFormat:@"mx_%@_%@", self.getOsmTag, self.getOsmValue];
        if ([OAUtilities hasMapImage:tvName])
        {
            return tvName;
        }
        else if (self.parentType)
        {
            return [self.parentType iconName];
        }
        else if (self.filter)
        {
            return [self.filter iconName];
        }
        else if (self.category)
        {
            return [self.category iconName];
        }
    }
    return iconName;
}

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIType class]])
    {
        OAPOIType *obj = object;
        return [self.name isEqualToString:obj.name] && [self.tag isEqualToString:obj.tag] && (self.parentType == obj.parentType || [self.parentType isEqual:obj.parentType]);
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
    {
        [_parentType putTypes:acceptedTypes];
        if (_filterOnly)
        {
            NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:_category];
            for (OAPOIType *pt in _category.poiTypes)
            {
                NSArray<OAPOIType *> *poiAdditionals = pt.poiAdditionals;
                if (!poiAdditionals)
                    continue;
                
                for (OAPOIType *poiType in poiAdditionals)
                {
                    if ([poiType.name isEqualToString:self.name])
                        [set addObject:pt.name];
                }
            }
        }
        return acceptedTypes;
    }

    OAPOIType *poiType = self.referenceType ? self.referenceType : self;
    if (![acceptedTypes objectForKey:poiType.category])
        [acceptedTypes setObject:[NSMutableSet set] forKey:poiType.category];

    NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:poiType.category];
    if (set)
        [set addObject:poiType.name];
    
    return acceptedTypes;
}

- (NSString *) getEditOsmTag
{
    if (self.reference)
        return _referenceType.getEditOsmTag;
    if (!_editTag)
        return [self getOsmTag];
    
    return _editTag;
}

-(NSString *) getEditOsmValue
{
    if (self.reference)
        return [_referenceType getEditOsmValue];
    if (!_editValue) {
        return [self getOsmValue];
    }
    return _editValue;
}

-(NSString *) getOsmValue
{
    if(self.reference)
        return [_referenceType getOsmValue];
    if (self.editValue)
        return self.editValue;
    return _value;
}

-(NSString *) getOsmValue2
{
    if(self.reference)
        return [_referenceType getOsmValue2];
    return _value2;
}

-(NSString *) getOsmTag
{
    if(self.reference)
        return [_referenceType getOsmTag];
    if (self.editTag)
        return self.editTag;
    if(_tag && [_tag hasPrefix:@"osmand_amenity"])
        return @"amenity";
    return _tag;
}

-(NSString *) getOsmTag2
{
    if(self.reference) {
        return [_referenceType getOsmTag2];
    }
    return _tag2;
}

- (BOOL)isReference
{
    return _referenceType != nil;
}

@end
