//
//  OARoutingProfilesHolder.m
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingProfilesHolder.h"
#import "OARoutingDataObject.h"

@implementation OARoutingProfilesHolder
{
    NSMutableDictionary<NSString *, OARoutingDataObject *> *_map;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (OARoutingDataObject *)get:(NSString *)routingProfileKey derivedProfile:(NSString *)derivedProfile
{
    return _map[[self createFullKey:routingProfileKey derivedProfile:derivedProfile]];
}

- (void)add:(OARoutingDataObject *)profile
{
    _map[[self createFullKey:profile.stringKey derivedProfile:profile.derivedProfile]] = profile;
}

- (void)setSelected:(OARoutingDataObject *)selected
{
    for (OARoutingDataObject *profile in _map.allValues)
    {
        profile.isSelected = NO;
    }
    selected.isSelected = YES;
}

- (NSString *)createFullKey:(NSString *)routingProfileKey derivedProfile:(NSString *)derivedProfile
{
    if (!derivedProfile || derivedProfile.length == 0)
        derivedProfile = @"default";
    return [NSString stringWithFormat:@"%@_%@", routingProfileKey, derivedProfile];
}

@end
