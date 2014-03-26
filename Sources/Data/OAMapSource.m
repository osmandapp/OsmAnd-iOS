//
//  OAMapSource.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSource.h"

#import "OAMapSourcesCollection.h"

@implementation OAMapSource
{
    OAMapSourcesCollection* _owner;
}

- (id)init
{
    [NSException raise:@"NSInitUnsupported" format:@"-init is unsupported"];
    return nil;
}

- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey andType:(OAMapSourceType)type andTypedReferenceId:(NSString*)typedReferenceId
{
    self = [super init];
    if (self) {
        [self ctor];
        _localizedNameKey = [localizedNameKey copy];
        _type = type;
        _typedReferenceId = [typedReferenceId copy];
        _presets = [[OAMapSourcePresetsCollection alloc] initWithOwner:self];
    }
    return self;
}

- (void)ctor
{
    _changeObservable = [[OAObservable alloc] init];
    _nameChangeObservable = [[OAObservable alloc] init];
    _activePresetIdChangeObservable = [[OAObservable alloc] init];
}

- (void)registerAs:(NSUUID*)uniqueId in:(OAMapSourcesCollection*)owner
{
    _uniqueId = uniqueId;
    _owner = owner;
}

@synthesize uniqueId = _uniqueId;

@synthesize changeObservable = _changeObservable;

@synthesize name = _name;
@synthesize nameChangeObservable = _nameChangeObservable;

- (NSString*)name
{
    @synchronized(self)
    {
        if(_name != nil)
            return [_name copy];
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
        _name = [name copy];
        
        [_nameChangeObservable notifyEventWithKey:self andValue:_name];
        [_changeObservable notifyEventWithKey:self];
    }
}

@synthesize localizedNameKey = _localizedNameKey;

- (NSString*)localizedNameKey
{
    @synchronized(self)
    {
        return [_localizedNameKey copy];
    }
}

@synthesize type = _type;
@synthesize typedReferenceId = _typedReferenceId;
@synthesize presets = _presets;

@synthesize activePresetId = _activePresetId;
@synthesize activePresetIdChangeObservable = _activePresetIdChangeObservable;

- (NSUUID*)activePresetId
{
    @synchronized(self)
    {
        return _activePresetId;
    }
}

- (void)setActivePresetId:(NSUUID *)activePresetId
{
    @synchronized(self)
    {
        if(_activePresetId != nil && [_activePresetId isEqual:activePresetId])
            return;
        _activePresetId = activePresetId;
        
        [_activePresetIdChangeObservable notifyEventWithKey:self andValue:_activePresetId];
        [_changeObservable notifyEventWithKey:self];
    }
}

#pragma mark - NSCoding

#define kName @"name"
#define kLocalizedNameKey @"localized_name_key"
#define kType @"type"
#define kTypedReferenceId @"typed_ref_id"
#define kPresets @"presets"
#define kActivePresetId @"active_preset_id"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:kName];
    [aCoder encodeObject:_localizedNameKey forKey:kLocalizedNameKey];
    [aCoder encodeInteger:_type forKey:kType];
    [aCoder encodeObject:_typedReferenceId forKey:kTypedReferenceId];
    [aCoder encodeObject:_presets forKey:kPresets];
    [aCoder encodeObject:_activePresetId forKey:kActivePresetId];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _name = [aDecoder decodeObjectForKey:kName];
        _localizedNameKey = [aDecoder decodeObjectForKey:kLocalizedNameKey];
        _type = [aDecoder decodeIntegerForKey:kType];
        _typedReferenceId = [aDecoder decodeObjectForKey:kTypedReferenceId];
        _presets = [aDecoder decodeObjectForKey:kPresets];
        _activePresetId = [aDecoder decodeObjectForKey:kActivePresetId];

        [_presets setOwner:self];
    }
    return self;
}

#pragma mark -

@end
