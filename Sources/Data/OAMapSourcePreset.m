//
//  OAMapSourcePreset.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcePreset.h"

#import "OAMapSourcePresetsCollection.h"
#import "OAMapSource.h"

@implementation OAMapSourcePreset
{
    OAMapSourcePresetsCollection* _owner;
}

- (id)init
{
    [NSException raise:@"NSInitUnsupported" format:@"-init is unsupported"];
    return nil;
}

- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey andType:(OAMapSourcePresetType)type andValues:(NSDictionary*)values;
{
    self = [super init];
    if (self) {
        [self ctor];
        _localizedNameKey = [localizedNameKey copy];
        _type = type;
        _values = [[OAMapSourcePresetValues alloc] initWithOwner:self];
    }
    return self;
}

- (void)ctor
{
    _changeObservable = [[OAObservable alloc] init];
}

- (void)registerAs:(NSUUID *)uniqueId in:(OAMapSourcePresetsCollection *)owner
{
    _uniqueId = uniqueId;
    _owner = owner;
}

@synthesize changeObservable = _changeObservable;
@synthesize uniqueId = _uniqueId;

@synthesize name = _name;
@synthesize nameChangeObservable = _nameChangeObservable;

- (NSString*)name
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
        if(_name != nil && [_name isEqualToString:name])
            return;

        _name = name;

        [_nameChangeObservable notifyEventWithKey:self andValue:_name];
        [_changeObservable notifyEventWithKey:self];
        [_owner.owner.anyPresetChangeObservable notifyEventWithKey:self];
    }
}

@synthesize localizedNameKey = _localizedNameKey;

@synthesize iconImageName = _iconImageName;
@synthesize iconImageNameChangeObservable = _iconImageNameChangeObservable;

- (NSString*)iconImageName
{
    @synchronized(self)
    {
        return [_iconImageName copy];
    }
}

- (void)setIconImageName:(NSString *)iconImageName
{
    @synchronized(self)
    {
        if(_iconImageName != nil && [_iconImageName isEqualToString:iconImageName])
            return;

        _iconImageName = iconImageName;

        [_iconImageNameChangeObservable notifyEventWithKey:self andValue:_iconImageName];
        [_changeObservable notifyEventWithKey:self];
        [_owner.owner.anyPresetChangeObservable notifyEventWithKey:self];
    }
}

@synthesize type = _type;
@synthesize typeChangeObservable = _typeChangeObservable;

- (OAMapSourcePresetType)type
{
    @synchronized(self)
    {
        return _type;
    }
}

- (void)setType:(OAMapSourcePresetType)type
{
    @synchronized(self)
    {
        if(_type == type)
            return;

        _type = type;

        [_typeChangeObservable notifyEventWithKey:self andValue:[NSNumber numberWithInteger:_type]];
        [_changeObservable notifyEventWithKey:self];
        [_owner.owner.anyPresetChangeObservable notifyEventWithKey:self];
    }
}

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
        _values.owner = self;
    }
    return self;
}

#pragma mark -

@end
