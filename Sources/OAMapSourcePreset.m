//
//  OAMapSourcePreset.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcePreset.h"

@implementation OAMapSourcePreset
{
}

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey andType:(OAMapSourcePresetType)type andValues:(NSDictionary*)values;
{
    self = [super init];
    if (self) {
        [self ctor];
        _localizedNameKey = localizedNameKey;
        _type = type;
        _values = [[NSMutableDictionary alloc] initWithDictionary:values];
    }
    return self;
}

- (void)ctor
{
    _type = OAMapSourcePresetTypeUndefined;
}

@synthesize name = _name;

- (NSString*)getName
{
    @synchronized(self)
    {
        if(_name != nil)
            return _name;
        return [[NSBundle mainBundle] localizedStringForKey:_localizedNameKey
                                                      value:nil
                                                      table:nil];
    }
}

- (void)setName:(NSString *)name
{
    @synchronized(self)
    {
        _name = name;
    }
}

@synthesize localizedNameKey = _localizedNameKey;

@synthesize iconImageName = _iconImageName;

@synthesize type = _type;

@synthesize values = _values;

#pragma mark - NSCoding

#define kName @"name"
#define kLocalizedNameKey @"localized_name_key"
#define kIconImageName @"icon_image_name"
#define kType @"type"
#define kValues @"values"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:kName];
    [aCoder encodeObject:_localizedNameKey forKey:kLocalizedNameKey];
    [aCoder encodeObject:_iconImageName forKey:kIconImageName];
    [aCoder encodeInteger:_type forKey:kType];
    [aCoder encodeObject:_values forKey:kValues];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _name = [aDecoder decodeObjectForKey:kName];
        _localizedNameKey = [aDecoder decodeObjectForKey:kLocalizedNameKey];
        _iconImageName = [aDecoder decodeObjectForKey:kIconImageName];
        _type = [aDecoder decodeIntegerForKey:kType];
        _values = [aDecoder decodeObjectForKey:kValues];
    }
    return self;
}

#pragma mark -

@end
